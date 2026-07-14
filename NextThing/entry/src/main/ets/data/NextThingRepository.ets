import relationalStore from '@ohos.data.relationalStore';
import { common } from '@kit.AbilityKit';
import { ActiveSession, FocusOutcome, FocusRecord, InboxTask, PendingFocusRecord } from './PersistenceModels';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'nextthing.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const CREATE_INBOX = 'CREATE TABLE IF NOT EXISTS inbox_tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, created_at INTEGER NOT NULL)';
const CREATE_RECORD = 'CREATE TABLE IF NOT EXISTS focus_records (id INTEGER PRIMARY KEY AUTOINCREMENT, task_title TEXT NOT NULL, planned_minutes INTEGER NOT NULL, actual_seconds INTEGER NOT NULL, ended_at INTEGER NOT NULL, outcome TEXT NOT NULL, result_key TEXT NOT NULL DEFAULT \'\')';
const ADD_RESULT_KEY = 'ALTER TABLE focus_records ADD COLUMN result_key TEXT NOT NULL DEFAULT \'\'';
const CREATE_RESULT_KEY_INDEX = 'CREATE UNIQUE INDEX IF NOT EXISTS idx_focus_records_result_key ON focus_records(result_key) WHERE result_key <> \'\'';
const CREATE_STATE = 'CREATE TABLE IF NOT EXISTS app_state (state_key TEXT PRIMARY KEY, state_value TEXT NOT NULL)';

interface ActiveSessionCandidate {
  taskName?: string;
  durationMinutes?: number;
  remainingSeconds?: number;
  targetEndTime?: number;
  isRunning?: boolean;
  pageState?: string;
  pendingRecordId?: number;
  resultKey?: string;
}

function isNonNegativeInteger(value: number): boolean {
  return Number.isFinite(value) && value >= 0 && Math.floor(value) === value;
}

export function parseActiveSession(value: string): ActiveSession | undefined {
  if (value.length === 0) {
    return undefined;
  }
  try {
    const candidate = JSON.parse(value) as ActiveSessionCandidate;
    if (candidate === null || typeof candidate !== 'object') {
      return undefined;
    }
    const durationMinutes = candidate.durationMinutes;
    const remainingSeconds = candidate.remainingSeconds;
    const targetEndTime = candidate.targetEndTime;
    const pendingRecordId = candidate.pendingRecordId;
    const isValidPageState = candidate.pageState === 'running' || candidate.pageState === 'paused' || candidate.pageState === 'result';
    const hasValidDuration = typeof durationMinutes === 'number' && isNonNegativeInteger(durationMinutes) && durationMinutes > 0;
    const hasValidRemaining = typeof remainingSeconds === 'number' && isNonNegativeInteger(remainingSeconds) && typeof durationMinutes === 'number' && remainingSeconds <= durationMinutes * 60;
    const hasValidTarget = typeof targetEndTime === 'number' && isNonNegativeInteger(targetEndTime) && (!candidate.isRunning || targetEndTime > 0);
    if (typeof candidate.taskName !== 'string' || !hasValidDuration || !hasValidRemaining || !hasValidTarget ||
      typeof candidate.isRunning !== 'boolean' || !isValidPageState ||
      typeof pendingRecordId !== 'number' || !isNonNegativeInteger(pendingRecordId) ||
      typeof candidate.resultKey !== 'string') {
      return undefined;
    }
    return candidate as ActiveSession;
  } catch (_error) {
    return undefined;
  }
}

export function normalizeTaskTitle(title: string): string {
  return title.trim();
}

export class NextThingRepository {
  private store: relationalStore.RdbStore | undefined;

  async initialize(context: common.Context): Promise<void> {
    this.store = await relationalStore.getRdbStore(context, STORE_CONFIG);
    await this.store.executeSql(CREATE_INBOX);
    await this.store.executeSql(CREATE_RECORD);
    await this.ensureResultKeyColumn();
    await this.store.executeSql(CREATE_RESULT_KEY_INDEX);
    await this.store.executeSql(CREATE_STATE);
  }

  private getStore(): relationalStore.RdbStore {
    if (this.store === undefined) {
      throw new Error('数据库尚未初始化');
    }
    return this.store;
  }

  async addInboxTask(title: string): Promise<InboxTask> {
    const normalized = normalizeTaskTitle(title);
    if (normalized.length === 0) throw new Error('任务不能为空');
    const createdAt = Date.now();
    const id = await this.getStore().insert('inbox_tasks', { title: normalized, created_at: createdAt });
    return { id, title: normalized, createdAt };
  }

  async listInboxTasks(): Promise<InboxTask[]> {
    const cursor = await this.getStore().querySql('SELECT id, title, created_at FROM inbox_tasks ORDER BY created_at DESC');
    const tasks: InboxTask[] = [];
    while (cursor.goToNextRow()) {
      tasks.push({ id: cursor.getLong(0), title: cursor.getString(1), createdAt: cursor.getLong(2) });
    }
    cursor.close();
    return tasks;
  }

  async deleteInboxTask(id: number): Promise<void> {
    await this.getStore().executeSql('DELETE FROM inbox_tasks WHERE id = ?', [id]);
  }

  async saveNextTask(title: string): Promise<void> { await this.saveState('next_task', normalizeTaskTitle(title)); }
  async loadNextTask(): Promise<string> { return this.loadState('next_task'); }
  async saveActiveSession(session: ActiveSession): Promise<void> { await this.saveState('active_session', JSON.stringify(session)); }
  async clearActiveSession(): Promise<void> { await this.getStore().executeSql('DELETE FROM app_state WHERE state_key = ?', ['active_session']); }

  async loadActiveSession(): Promise<ActiveSession | undefined> {
    const value = await this.loadState('active_session');
    const session = parseActiveSession(value);
    if (session === undefined && value.length > 0) {
      try {
        await this.clearActiveSession();
      } catch (_error) {
        // Returning no session keeps malformed persisted state from blocking startup.
      }
    }
    return session;
  }

  async createPendingRecord(record: PendingFocusRecord): Promise<number> {
    return await this.getStore().insert('focus_records', {
      task_title: record.taskTitle, planned_minutes: record.plannedMinutes,
      actual_seconds: record.actualSeconds, ended_at: record.endedAt, outcome: record.outcome,
      result_key: record.resultKey
    });
  }

  async findOrCreatePendingRecord(record: PendingFocusRecord): Promise<number> {
    const existingId = await this.findPendingRecordId(record.resultKey);
    if (existingId !== 0) {
      return existingId;
    }
    try {
      return await this.createPendingRecord(record);
    } catch (_error) {
      const racedId = await this.findPendingRecordId(record.resultKey);
      if (racedId !== 0) {
        return racedId;
      }
      throw new Error('无法创建专注记录');
    }
  }

  private async ensureResultKeyColumn(): Promise<void> {
    const cursor = await this.getStore().querySql('PRAGMA table_info(focus_records)');
    let hasResultKey = false;
    while (cursor.goToNextRow()) {
      if (cursor.getString(1) === 'result_key') {
        hasResultKey = true;
      }
    }
    cursor.close();
    if (!hasResultKey) {
      await this.getStore().executeSql(ADD_RESULT_KEY);
    }
  }

  private async findPendingRecordId(resultKey: string): Promise<number> {
    const cursor = await this.getStore().querySql('SELECT id FROM focus_records WHERE result_key = ? LIMIT 1', [resultKey]);
    if (cursor.goToNextRow()) {
      const id = cursor.getLong(0);
      cursor.close();
      return id;
    }
    cursor.close();
    return 0;
  }

  async updateRecordOutcome(id: number, outcome: FocusOutcome): Promise<void> {
    await this.getStore().executeSql('UPDATE focus_records SET outcome = ? WHERE id = ?', [outcome, id]);
  }

  async listTodayRecords(dayStart: number, dayEnd: number): Promise<FocusRecord[]> {
    const cursor = await this.getStore().querySql('SELECT id, task_title, planned_minutes, actual_seconds, ended_at, outcome FROM focus_records WHERE ended_at >= ? AND ended_at < ? ORDER BY ended_at DESC', [dayStart, dayEnd]);
    const records: FocusRecord[] = [];
    while (cursor.goToNextRow()) {
      records.push({ id: cursor.getLong(0), taskTitle: cursor.getString(1), plannedMinutes: cursor.getLong(2), actualSeconds: cursor.getLong(3), endedAt: cursor.getLong(4), outcome: cursor.getString(5) as FocusOutcome });
    }
    cursor.close();
    return records;
  }

  private async saveState(key: string, value: string): Promise<void> {
    await this.getStore().executeSql('INSERT OR REPLACE INTO app_state (state_key, state_value) VALUES (?, ?)', [key, value]);
  }

  private async loadState(key: string): Promise<string> {
    const cursor = await this.getStore().querySql('SELECT state_value FROM app_state WHERE state_key = ?', [key]);
    const value = cursor.goToNextRow() ? cursor.getString(0) : '';
    cursor.close();
    return value;
  }
}
