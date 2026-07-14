# 本地数据与今日回顾实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**目标：** 让下一件事、收件箱任务、当前专注会话和当天专注记录都保存在本地 RDB 中，并提供清空脑袋和今日回顾页面。

**架构：** FocusTimerEngine 继续负责时间戳计算；RDB 仓储集中管理 SQL；页面只调用仓储和呈现状态。计时开始、暂停、继续、结束及选择结果时都同步活动会话。

**技术栈：** HarmonyOS API 24、ArkTS、ArkUI、@ohos.data.relationalStore、Hypium 测试源码、Hvigor、API 24 模拟器。

---

### 任务 1：数据模型和统计规则

**文件：**
- 新建：NextThing/entry/src/main/ets/data/PersistenceModels.ets
- 新建：NextThing/entry/src/main/ets/data/ReviewCalculator.ets
- 新建：NextThing/entry/src/test/ReviewCalculator.test.ets

- [ ] **步骤 1：先写统计规则测试源码**

~~~ts
import { describe, expect, it } from '@ohos/hypium';
import { calculateTodayReview, localDayKey } from '../main/ets/data/ReviewCalculator';

export default function reviewCalculatorTest() {
  describe('today review calculator', () => {
    it('includes all ended records in actual focus time', 0, () => {
      const review = calculateTodayReview([
        { actualSeconds: 900, outcome: 'completed' },
        { actualSeconds: 300, outcome: 'unfinished' },
        { actualSeconds: 60, outcome: 'changed' }
      ]);
      expect(review.sessionCount).assertEqual(3);
      expect(review.actualMinutes).assertEqual(21);
      expect(review.completedCount).assertEqual(1);
      expect(review.unfinishedCount).assertEqual(1);
    });
    it('formats a local calendar day', 0, () => {
      expect(localDayKey(new Date(2026, 6, 14, 8, 0, 0))).assertEqual('2026-07-14');
    });
  });
}
~~~

- [ ] **步骤 2：确认当前测试运行限制**

运行：hvigorw.bat --no-daemon tasks

预期：没有本地 Hypium 测试任务。测试源码保留为回归契约，任务 5 在模拟器执行行为验收。

- [ ] **步骤 3：实现模型和计算函数**

~~~ts
export type FocusOutcome = 'pending' | 'completed' | 'unfinished' | 'changed';

export interface InboxTask {
  id: number;
  title: string;
  createdAt: number;
}

export interface FocusRecord {
  id: number;
  taskTitle: string;
  plannedMinutes: number;
  actualSeconds: number;
  endedAt: number;
  outcome: FocusOutcome;
}

export interface ActiveSession {
  taskName: string;
  durationMinutes: number;
  remainingSeconds: number;
  targetEndTime: number;
  isRunning: boolean;
  pageState: 'running' | 'result';
  pendingRecordId: number;
}

export function calculateTodayReview(records: FocusRecord[]): TodayReview {
  let actualSeconds = 0;
  let completedCount = 0;
  let unfinishedCount = 0;
  records.forEach((record) => {
    actualSeconds += record.actualSeconds;
    if (record.outcome === 'completed') completedCount++;
    if (record.outcome === 'unfinished') unfinishedCount++;
  });
  return {
    sessionCount: records.length,
    actualMinutes: Math.floor(actualSeconds / 60),
    completedCount,
    unfinishedCount
  };
}
~~~

- [ ] **步骤 4：编译并提交**

运行：hvigorw.bat --no-daemon assembleApp -p product=default

预期：BUILD SUCCESSFUL。

~~~powershell
git add NextThing/entry/src/main/ets/data/PersistenceModels.ets NextThing/entry/src/main/ets/data/ReviewCalculator.ets NextThing/entry/src/test/ReviewCalculator.test.ets
git commit -m "feat: add persistence data models"
~~~

### 任务 2：RDB 数据库和仓储

**文件：**
- 新建：NextThing/entry/src/main/ets/data/NextThingRepository.ets
- 新建：NextThing/entry/src/main/ets/data/AppRepository.ets
- 新建：NextThing/entry/src/test/NextThingRepository.test.ets

- [ ] **步骤 1：写仓储辅助函数测试契约**

~~~ts
import { describe, expect, it } from '@ohos/hypium';
import { normalizeTaskTitle } from '../main/ets/data/NextThingRepository';

export default function repositoryTest() {
  describe('repository helpers', () => {
    it('rejects blank inbox task titles', 0, () => {
      expect(normalizeTaskTitle('   ')).assertEqual('');
    });
    it('trims a saved next task title', 0, () => {
      expect(normalizeTaskTitle('  整理资料  ')).assertEqual('整理资料');
    });
  });
}
~~~

- [ ] **步骤 2：初始化 RDB 和三张表**

~~~ts
import relationalStore from '@ohos.data.relationalStore';
import { common } from '@kit.AbilityKit';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'nextthing.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const CREATE_INBOX = 'CREATE TABLE IF NOT EXISTS inbox_tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, created_at INTEGER NOT NULL)';
const CREATE_RECORD = 'CREATE TABLE IF NOT EXISTS focus_records (id INTEGER PRIMARY KEY AUTOINCREMENT, task_title TEXT NOT NULL, planned_minutes INTEGER NOT NULL, actual_seconds INTEGER NOT NULL, ended_at INTEGER NOT NULL, outcome TEXT NOT NULL)';
const CREATE_STATE = 'CREATE TABLE IF NOT EXISTS app_state (state_key TEXT PRIMARY KEY, state_value TEXT NOT NULL)';

async initialize(context: common.Context): Promise<void> {
  this.store = await relationalStore.getRdbStore(context, STORE_CONFIG);
  await this.store.executeSql(CREATE_INBOX);
  await this.store.executeSql(CREATE_RECORD);
  await this.store.executeSql(CREATE_STATE);
}
~~~

- [ ] **步骤 3：实现仓储接口**

实现以下全部方法，查询使用参数化 SQL，状态 JSON 只保存 next_task 和 active_session 两个键：

~~~ts
async addInboxTask(title: string): Promise<InboxTask>
async listInboxTasks(): Promise<InboxTask[]>
async deleteInboxTask(id: number): Promise<void>
async saveNextTask(title: string): Promise<void>
async loadNextTask(): Promise<string>
async saveActiveSession(session: ActiveSession): Promise<void>
async loadActiveSession(): Promise<ActiveSession | undefined>
async clearActiveSession(): Promise<void>
async createPendingRecord(record: Omit<FocusRecord, 'id'>): Promise<number>
async updateRecordOutcome(id: number, outcome: FocusOutcome): Promise<void>
async listTodayRecords(dayStart: number, dayEnd: number): Promise<FocusRecord[]>
~~~

- [ ] **步骤 4：编译并提交**

运行：hvigorw.bat --no-daemon assembleApp -p product=default

预期：BUILD SUCCESSFUL。

~~~powershell
git add NextThing/entry/src/main/ets/data/NextThingRepository.ets NextThing/entry/src/main/ets/data/AppRepository.ets NextThing/entry/src/test/NextThingRepository.test.ets
git commit -m "feat: add local RDB repository"
~~~

### 任务 3：保存和恢复专注会话

**文件：**
- 修改：NextThing/entry/src/main/ets/entryability/EntryAbility.ets
- 修改：NextThing/entry/src/main/ets/pages/Index.ets
- 修改：NextThing/entry/src/main/ets/pages/FocusTimer.ets

- [ ] **步骤 1：在应用启动时初始化仓储**

~~~ts
export const appRepository = new NextThingRepository();

export async function initializeRepository(context: common.Context): Promise<void> {
  await appRepository.initialize(context);
}
~~~

在 EntryAbility.onCreate 中调用 initializeRepository(this.context)，完成后再加载首页内容。

- [ ] **步骤 2：首页加载和保存下一件事**

~~~ts
const nextTask = await appRepository.loadNextTask();
if (nextTask.length > 0) {
  this.taskTitle = nextTask;
}
~~~

开始专注前保存 trim 后的任务标题；从清空脑袋设为下一件事后切换到现在页并更新 taskTitle，不自动路由。

- [ ] **步骤 3：保存活动会话和结束记录**

在开始、暂停、继续后保存：

~~~ts
await appRepository.saveActiveSession({
  taskName: this.taskName,
  durationMinutes: this.durationMinutes,
  remainingSeconds: this.timer.remainingSeconds,
  targetEndTime: this.timer.targetEndTime,
  isRunning: this.timer.isRunning,
  pageState: this.pageState as 'running' | 'result',
  pendingRecordId: this.pendingRecordId
});
~~~

归零或提前结束时，只在 pendingRecordId 为 0 时创建记录：

~~~ts
this.pendingRecordId = await appRepository.createPendingRecord({
  taskTitle: this.taskName,
  plannedMinutes: this.durationMinutes,
  actualSeconds: this.timer.durationSeconds - this.timer.remainingSeconds,
  endedAt: Date.now(),
  outcome: 'pending'
});
~~~

- [ ] **步骤 4：结果选择更新记录并清理活动会话**

~~~ts
private async finishWith(outcome: FocusOutcome): Promise<void> {
  await appRepository.updateRecordOutcome(this.pendingRecordId, outcome);
  await appRepository.clearActiveSession();
  this.stopTicker();
  router.replaceUrl({ url: 'pages/Index' });
}
~~~

完成了、还没完成、换一件事分别传入 completed、unfinished、changed。

- [ ] **步骤 5：编译并提交**

运行：hvigorw.bat --no-daemon clean

运行：hvigorw.bat --no-daemon assembleApp -p product=default

预期：两个命令均输出 BUILD SUCCESSFUL。

~~~powershell
git add NextThing/entry/src/main/ets/entryability/EntryAbility.ets NextThing/entry/src/main/ets/pages/Index.ets NextThing/entry/src/main/ets/pages/FocusTimer.ets
git commit -m "feat: persist active focus sessions"
~~~

### 任务 4：清空脑袋和今日回顾标签

**文件：**
- 修改：NextThing/entry/src/main/ets/pages/Index.ets
- 新建：NextThing/entry/src/main/ets/components/InboxTab.ets
- 新建：NextThing/entry/src/main/ets/components/TodayReviewTab.ets

- [ ] **步骤 1：建立三标签导航**

~~~ts
Tabs({ barPosition: BarPosition.End }) {
  TabContent() { NowTab() }.tabBar('现在')
  TabContent() { InboxTab() }.tabBar('清空脑袋')
  TabContent() { TodayReviewTab() }.tabBar('今日回顾')
}
~~~

把现有任务输入、时长选择和开始按钮迁入 NowTab，保留空任务校验。

- [ ] **步骤 2：实现 InboxTab 新增、删除和设为下一件事**

~~~ts
Button('添加').onClick(async () => {
  const title = normalizeTaskTitle(this.newTaskTitle);
  if (title.length === 0) {
    this.feedback = '请输入任务内容';
    return;
  }
  await appRepository.addInboxTask(title);
  this.newTaskTitle = '';
  await this.reloadTasks();
});

Button('设为下一件事').onClick(async () => {
  await appRepository.saveNextTask(task.title);
  this.onSetNextTask(task.title);
});

Button('删除').onClick(async () => {
  await appRepository.deleteInboxTask(task.id);
  await this.reloadTasks();
});
~~~

- [ ] **步骤 3：实现 TodayReviewTab 查询与显示**

~~~ts
const now = new Date();
const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
const dayEnd = dayStart + 24 * 60 * 60 * 1_000;
const records = await appRepository.listTodayRecords(dayStart, dayEnd);
this.review = calculateTodayReview(records);
~~~

显示专注次数、实际专注分钟、完成次数和未完成次数；页面每次显示时刷新。

- [ ] **步骤 4：编译并提交**

运行：hvigorw.bat --no-daemon assembleApp -p product=default

预期：BUILD SUCCESSFUL。

~~~powershell
git add NextThing/entry/src/main/ets/pages/Index.ets NextThing/entry/src/main/ets/components/InboxTab.ets NextThing/entry/src/main/ets/components/TodayReviewTab.ets
git commit -m "feat: add inbox and today review tabs"
~~~

### 任务 5：模拟器验收和文档

**文件：**
- 修改：NextThing/README.md

- [ ] **步骤 1：构建、安装和启动**

~~~powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon assembleApp -p product=default
hdc -t 127.0.0.1:5555 install -r entry\build\default\outputs\default\entry-default-unsigned.hap
hdc -t 127.0.0.1:5555 shell aa start -a EntryAbility -b com.zhaoxin.nextthing
~~~

- [ ] **步骤 2：执行验收序列**

1. 清空脑袋新增两项、删除一项、把另一项设为下一件事，确认现在页预填任务。
2. 启动后暂停，强制停止应用并重新打开，确认暂停和剩余时间恢复。
3. 启动运行中的专注，强制停止应用并重新打开，确认按目标时间戳计算正确剩余时间。
4. 提前结束并分别选择完成、未完成、换一件事，确认三种记录和返回首页。
5. 使用一次性短计时检查自然结束记录，完成后恢复正常 5/10/25 分钟入口。
6. 打开今日回顾，确认次数、实际分钟、完成数和未完成数符合刚刚生成的记录。

- [ ] **步骤 3：记录验收、重新构建并提交**

~~~md
## 本地数据与回顾验收记录（2026-07-14）

- RDB 保存下一件事、收件箱、活动会话和专注记录。
- 应用重启后可恢复下一件事和进行中/暂停中的会话。
- 已验证收件箱新增、删除、设为下一件事和今日回顾统计。
~~~

运行：hvigorw.bat --no-daemon assembleApp -p product=default

预期：BUILD SUCCESSFUL。

~~~powershell
git add NextThing/README.md docs/superpowers/plans/2026-07-14-persistence-review.md
git commit -m "docs: record persistence verification"
~~~

