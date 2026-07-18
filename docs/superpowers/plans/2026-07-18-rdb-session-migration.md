# RDB 会话迁移与合并验收 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将旧 Preferences 专注会话安全迁移至 RDB，并完成合并后功能、通知和 Git 状态的验收。

**Architecture:** 新增纯转换函数，把旧 `FocusSession` 映射到新 `ActiveSession`。`Index` 只在 RDB 没有活跃会话时读取旧 Preferences，成功写入 RDB 后才删除旧数据；无可恢复会话时取消旧通知。模拟器通过“旧构建创建数据，再覆盖安装当前构建”验证真实升级路径。

**Tech Stack:** HarmonyOS API 24、ArkTS、Preferences、RDB、Hypium、Hvigor、HDC、Git。

---

### Task 1: 建立隔离工作区与基线

**Files:**
- Modify: `docs/superpowers/plans/2026-07-18-rdb-session-migration.md`

- [ ] **Step 1: 创建由 `main` 派生的 ASCII 路径工作区**

Run:

```powershell
git -C 'C:\Users\zhaoxin\OneDrive\文档\New project 2' worktree add -b codex/rdb-session-migration 'C:\Users\zhaoxin\codex-worktrees\next-thing-rdb-session-migration' main
```

Expected: 新工作区位于 ASCII 路径，分支为 `codex/rdb-session-migration`。

- [ ] **Step 2: 在工作区执行干净构建基线**

Run:

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --cwd 'C:\Users\zhaoxin\codex-worktrees\next-thing-rdb-session-migration\NextThing' clean
& $hvigor --cwd 'C:\Users\zhaoxin\codex-worktrees\next-thing-rdb-session-migration\NextThing' assembleApp
```

Expected: `BUILD SUCCESSFUL`。记录既有 ArkTS 弃用警告，但不得出现编译错误。

### Task 2: 添加旧会话转换的失败测试

**Files:**
- Create: `NextThing/entry/src/test/LegacySessionMigration.test.ets`
- Modify: `NextThing/entry/src/test/List.test.ets`
- Create: `NextThing/entry/src/main/ets/focus/LegacySessionMigration.ets`

- [ ] **Step 1: 写入旧会话转换的失败测试**

```ts
import { describe, expect, it } from '@ohos/hypium';
import { createFocusSession } from '../main/ets/focus/FocusSession';
import { pauseFocusTimer } from '../main/ets/focus/FocusTimerEngine';
import { toActiveSession } from '../main/ets/focus/LegacySessionMigration';

export default function legacySessionMigrationTest() {
  describe('legacy focus session migration', () => {
    it('preserves a running legacy session for RDB recovery', 0, () => {
      const legacy = createFocusSession('迁移任务', 25, 1_000);
      const active = toActiveSession(legacy);
      expect(active.taskName).assertEqual('迁移任务');
      expect(active.remainingSeconds).assertEqual(1_500);
      expect(active.targetEndTime).assertEqual(1_501_000);
      expect(active.isRunning).assertTrue();
      expect(active.pageState).assertEqual('running');
      expect(active.pendingRecordId).assertEqual(0);
    });

    it('preserves paused time without restarting the timer', 0, () => {
      const legacy = createFocusSession('暂停迁移', 5, 0);
      legacy.timer = pauseFocusTimer(legacy.timer, 60_000);
      const active = toActiveSession(legacy);
      expect(active.isRunning).assertFalse();
      expect(active.remainingSeconds).assertEqual(240);
      expect(active.pageState).assertEqual('paused');
    });
  });
}
```

Add `legacySessionMigrationTest()` to `List.test.ets`.

- [ ] **Step 2: 运行测试入口或记录其不可执行原因**

Run the project-supported Hypium target discovered from Hvigor. If no local target exists, run `assembleApp` and record that the test source is compiled but device-side Hypium execution remains unavailable.

Expected before implementation: test compilation fails because `LegacySessionMigration.ets` does not export `toActiveSession`.

- [ ] **Step 3: 实现最小纯转换函数**

```ts
import { ActiveSession } from '../data/PersistenceModels';
import { FocusSession } from './FocusSession';

export function toActiveSession(session: FocusSession): ActiveSession {
  return {
    taskName: session.taskName,
    durationMinutes: session.durationMinutes,
    remainingSeconds: session.timer.remainingSeconds,
    targetEndTime: session.timer.targetEndTime,
    isRunning: session.timer.isRunning,
    pageState: session.pageState === 'result' ? 'result' : (session.timer.isRunning ? 'running' : 'paused'),
    pendingRecordId: 0,
    resultKey: ''
  };
}
```

- [ ] **Step 4: 重新构建并提交转换模块和测试**

Run `assembleApp`; then commit:

```powershell
git add NextThing/entry/src/main/ets/focus/LegacySessionMigration.ets NextThing/entry/src/test/LegacySessionMigration.test.ets NextThing/entry/src/test/List.test.ets
git commit -m 'feat: map legacy focus sessions to RDB state'
```

### Task 3: 在首页执行一次性迁移和旧通知清理

**Files:**
- Modify: `NextThing/entry/src/main/ets/pages/Index.ets`
- Modify: `NextThing/entry/src/main/ets/focus/FocusSessionStore.ets` only if a read-only legacy accessor is required
- Test: `NextThing/entry/src/test/LegacySessionMigration.test.ets`

- [ ] **Step 1: 在 `Index` 加入旧存储和通知协调器边界**

Import `preferences`, `common`, `FocusSessionStore`, `toActiveSession`, and `FocusNotificationCoordinator`. Add lazy accessors following the existing `FocusTimer.getNotificationCoordinator()` pattern:

```ts
private getLegacySessionStore(): FocusSessionStore | undefined {
  try {
    const preference = preferences.getPreferencesSync(getContext(this), { name: 'nextthing_focus_session' });
    return new FocusSessionStore(preference);
  } catch (_) {
    return undefined;
  }
}
```

- [ ] **Step 2: 将首页恢复流程替换为 RDB 优先的迁移流程**

Implement `loadOrMigrateActiveSession()` with this exact ordering:

```ts
return appRepository.loadActiveSession().then((rdbSession) => {
  if (rdbSession !== undefined) return rdbSession;
  const legacyStore = this.getLegacySessionStore();
  const legacySession = legacyStore?.load() ?? null;
  if (legacySession === null) {
    this.getNotificationCoordinator()?.cancel();
    return undefined;
  }
  const migrated = toActiveSession(legacySession);
  return appRepository.saveActiveSession(migrated).then(() => {
    legacyStore?.clear();
    return migrated;
  });
});
```

Call this method from `aboutToAppear()` in place of the direct `appRepository.loadActiveSession()` call. On RDB save failure, leave Preferences untouched and show the existing recovery feedback.

- [ ] **Step 3: 构建并检查不会覆盖现有 RDB 会话**

Run `assembleApp`. Inspect the implementation so the `rdbSession !== undefined` return occurs before the Preferences store is opened.

- [ ] **Step 4: 提交迁移协调逻辑**

```powershell
git add NextThing/entry/src/main/ets/pages/Index.ets NextThing/entry/src/main/ets/focus/FocusSessionStore.ets
git commit -m 'fix: migrate legacy focus sessions to RDB'
```

### Task 4: 在模拟器执行升级与功能验收

**Files:**
- Modify: `NextThing/README.md`

- [ ] **Step 1: 构建迁移前版本并创建旧会话**

Create a detached ASCII worktree at `2b1a575`, build it, install with `hdc install -r`, create a running focus task, and authorize notifications.

- [ ] **Step 2: 覆盖安装迁移分支构建并验证旧会话恢复**

Install the new HAP with `hdc install -r`, start `EntryAbility`, and inspect `uitest dumpLayout`. Verify the task, remaining time, and running or paused state match the old session. Open notification center and verify one notification with ID `1001` has current text.

- [ ] **Step 3: 验证无旧会话会取消遗留通知**

Complete the restored result, then restart the application and inspect the notification center. Expected: no NextThing notification remains.

- [ ] **Step 4: 验证清空脑袋和回顾完整路径**

Using HDC UI test input, add two tasks, edit one title and minutes, enable manual sort then move an item, set it as the next task, force-stop/restart, and confirm the selected task and inbox survive. Complete a focus result and verify its status and duration in 今日回顾.

- [ ] **Step 5: 验证通知完整生命周期**

Create a new focus task; verify running notification; pause and verify fixed remaining time; resume and verify end time text; end it and verify cancellation; force-stop/restart an active session and verify notification republish.

- [ ] **Step 6: 记录验收证据**

Append exact observed behaviors, device target, build command, and unresolved test-runner limitation to `NextThing/README.md`; commit with:

```powershell
git add NextThing/README.md
git commit -m 'docs: record migration and feature verification'
```

### Task 5: 提交现有文档并收尾 Git

**Files:**
- Add: `docs/superpowers/plans/2026-07-16-canva-ui.md`

- [ ] **Step 1: 提交 Canva UI 计划文档**

```powershell
git add docs/superpowers/plans/2026-07-16-canva-ui.md
git commit -m 'docs: add Canva UI implementation plan'
```

- [ ] **Step 2: 验证主分支状态并清理临时工作区**

Run `git status --short --branch`. Remove only the agent-created `C:\Users\zhaoxin\codex-worktrees\next-thing-main-verify` worktree after confirming it is clean.

- [ ] **Step 3: 推送合并后的主分支**

```powershell
git push origin main
```

Expected: `origin/main` advances to the local `main` HEAD. Do not force-push.

### Task 6: 最终验证

**Files:**
- Verify: `NextThing/entry/src/main/ets/pages/Index.ets`
- Verify: `NextThing/entry/src/main/ets/pages/FocusTimer.ets`
- Verify: `NextThing/README.md`

- [ ] **Step 1: 执行最终干净构建**

Run `clean` followed by `assembleApp` in the ASCII migration worktree. Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 2: 核对 Git 与远程状态**

Run:

```powershell
git status --short --branch
git log origin/main..main --oneline
```

Expected: 工作区干净，第二条命令没有输出。
