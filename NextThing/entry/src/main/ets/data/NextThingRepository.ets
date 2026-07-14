import relationalStore from '@ohos.data.relationalStore';
import { common } from '@kit.AbilityKit';
import { ActiveSession, FocusOutcome, FocusRecord, InboxTask, PendingFocusRecord } from './PersistenceModels';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'nextthing.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const CREATE_INBOX = 'CREATE TABLE IF NOT EXISTS inbox_tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, created_at INTEGER NOT NULL)';
const CREATE_RECORD = 'CREATE TABLE IF NOT EXISTS focus_records (id INTEGER PRIMARY KEY AUTOINCREMENT, task_title TEXT NOT NULL, planned_minutes INTEGER NOT NULL, actual_seconds INTEGER NOT NULL, ended_at INTEGER NOT NULL, outcome TEXT NOT NULL)';
const CREATE_STATE = 'CREATE TABLE IF NOT EXISTS app_state (state_key TEXT PRIMARY KEY, state_value TEXT NOT NULL)';

export function normalizeTaskTitle(title: string): string {
  return title.trim();
}

export class NextThingRepository {
  private store: relationalStore.RdbStore | undefined;

  async initialize(context: common.Context): Promise<void> {
    this.store = await relationalStore.getRdbStore(context, STORE_CONFIG);
    await this.store.executeSql(CREATE_INBOX);
    await this.store.executeSql(CREATE_RECORD);
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
    return value.length === 0 ? undefined : JSON.parse(value) as ActiveSession;
  }

  async createPendingRecord(record: PendingFocusRecord): Promise<number> {
    return await this.getStore().insert('focus_records', {
      task_title: record.taskTitle, planned_minutes: record.plannedMinutes,
      actual_seconds: record.actualSeconds, ended_at: record.endedAt, outcome: record.outcome
    });
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
