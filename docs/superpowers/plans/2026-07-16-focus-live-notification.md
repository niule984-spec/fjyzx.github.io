# 专注实况通知实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标：** 为运行中的专注会话发布一条可更新的常驻普通通知，并在暂停、恢复、结束和应用重启时与已保存会话保持一致。

**架构：** `FocusNotification.ets` 只负责将 `FocusSession` 映射为可测试的通知展示文案；`FocusNotificationCoordinator.ets` 负责通知权限、通知发布、点按跳转和取消。页面仅在会话状态转换时调用协调器，不在每秒刷新时重复发布通知。

**技术栈：** HarmonyOS API 24、ArkTS、ArkUI、`@ohos.notificationManager`、`@ohos.app.ability.wantAgent`、Hypium 测试源码、Hvigor、HarmonyOS API 24 模拟器。

---

### 任务 1：建立可测试的通知展示模型

**文件：**
- 新建：`NextThing/entry/src/main/ets/focus/FocusNotification.ets`
- 新建：`NextThing/entry/src/test/FocusNotification.test.ets`

- [ ] **步骤 1：先编写失败的 Hypium 测试源码**

新建 `NextThing/entry/src/test/FocusNotification.test.ets`：

```ts
import { describe, expect, it } from '@ohos/hypium';
import { createFocusSession } from '../main/ets/focus/FocusSession';
import { pauseFocusTimer } from '../main/ets/focus/FocusTimerEngine';
import { createFocusNotificationPresentation } from '../main/ets/focus/FocusNotification';

export default function focusNotificationTest() {
  describe('focus notification presentation', () => {
    it('renders an end time for a running focus session', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 0);
      const presentation = createFocusNotificationPresentation(session);
      expect(presentation === null).assertFalse();
      expect(presentation?.title).assertEqual('正在专注');
      expect(presentation?.text).assertEqual('阅读计划书 · 专注至 00:05');
      expect(presentation?.isCountDown).assertTrue();
    });

    it('renders stable remaining time for a paused focus session', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 0);
      session.timer = pauseFocusTimer(session.timer, 60_000);
      const presentation = createFocusNotificationPresentation(session);
      expect(presentation?.title).assertEqual('专注已暂停');
      expect(presentation?.text).assertEqual('阅读计划书 · 剩余 04:00');
      expect(presentation?.isCountDown).assertFalse();
    });

    it('does not create a notification for a result session', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 0);
      session.pageState = 'result';
      expect(createFocusNotificationPresentation(session) === null).assertTrue();
    });
  });
}
```

- [ ] **步骤 2：确认当前工程没有可执行的本地测试任务**

在 `NextThing` 目录执行：

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon tasks
```

预期：任务列表没有 Hypium 测试任务。打开测试文件时，`FocusNotification` 导入处于未解析状态；该 IDE 诊断是当前可获得的红灯验证。

- [ ] **步骤 3：实现最小通知展示模型**

新建 `NextThing/entry/src/main/ets/focus/FocusNotification.ets`：

```ts
import { FocusSession } from './FocusSession';
import { formatRemainingTime } from './FocusTimerEngine';

export const FOCUS_NOTIFICATION_ID = 1001;

export interface FocusNotificationPresentation {
  title: string;
  text: string;
  isCountDown: boolean;
}

function formatEndTime(timestamp: number): string {
  const date = new Date(timestamp);
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  return `${hours}:${minutes}`;
}

export function createFocusNotificationPresentation(session: FocusSession): FocusNotificationPresentation | null {
  if (session.pageState === 'result') {
    return null;
  }

  if (session.timer.isRunning) {
    return {
      title: '正在专注',
      text: `${session.taskName} · 专注至 ${formatEndTime(session.timer.targetEndTime)}`,
      isCountDown: true
    };
  }

  return {
    title: '专注已暂停',
    text: `${session.taskName} · 剩余 ${formatRemainingTime(session.timer.remainingSeconds)}`,
    isCountDown: false
  };
}
```

- [ ] **步骤 4：构建验证模型可编译**

在 `NextThing` 目录执行：

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon clean
& $hvigor --no-daemon assembleApp -p product=default
```

预期：两条命令均显示 `BUILD SUCCESSFUL`。保留测试源码作为回归契约，模拟器行为验证在任务 3 完成。

- [ ] **步骤 5：提交展示模型**

```powershell
git add NextThing/entry/src/main/ets/focus/FocusNotification.ets NextThing/entry/src/test/FocusNotification.test.ets
git commit -m "feat: add focus notification presentation"
```

### 任务 2：添加通知权限与发布协调器

**文件：**
- 新建：`NextThing/entry/src/main/ets/focus/FocusNotificationCoordinator.ets`
- 修改：`NextThing/entry/src/test/FocusNotification.test.ets`

- [ ] **步骤 1：实现通知协调器**

新建 `NextThing/entry/src/main/ets/focus/FocusNotificationCoordinator.ets`：

```ts
import { common, Want } from '@kit.AbilityKit';
import notificationManager from '@ohos.notificationManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import { FocusSession } from './FocusSession';
import {
  createFocusNotificationPresentation,
  FOCUS_NOTIFICATION_ID
} from './FocusNotification';

const BUNDLE_NAME = 'com.zhaoxin.nextthing';
const ABILITY_NAME = 'EntryAbility';

export class FocusNotificationCoordinator {
  private readonly context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async requestPermission(): Promise<void> {
    try {
      if (!notificationManager.isNotificationEnabledSync()) {
        await notificationManager.requestEnableNotification(this.context);
      }
    } catch (_) {}
  }

  async sync(session: FocusSession): Promise<void> {
    const presentation = createFocusNotificationPresentation(session);
    if (presentation === null) {
      await this.cancel();
      return;
    }

    try {
      const want: Want = { bundleName: BUNDLE_NAME, abilityName: ABILITY_NAME };
      const agent = await wantAgent.getWantAgent({
        wants: [want],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: FOCUS_NOTIFICATION_ID
      });
      await notificationManager.publish({
        id: FOCUS_NOTIFICATION_ID,
        isOngoing: true,
        tapDismissed: false,
        isAlertOnce: true,
        isCountDown: presentation.isCountDown,
        wantAgent: agent,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: { title: presentation.title, text: presentation.text }
        }
      });
    } catch (_) {}
  }

  async cancel(): Promise<void> {
    try {
      await notificationManager.cancel(FOCUS_NOTIFICATION_ID);
    } catch (_) {}
  }
}
```

此协调器只发布普通通知，不使用第三方无权直接创建的 `NotificationSystemLiveViewContent`。

- [ ] **步骤 2：构建通知 API 集成**

在 `NextThing` 目录执行：

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon clean
& $hvigor --no-daemon assembleApp -p product=default
```

预期：两条命令均显示 `BUILD SUCCESSFUL`，且不修改任何 `oh-package.json5` 依赖。

- [ ] **步骤 3：提交通知协调器**

```powershell
git add NextThing/entry/src/main/ets/focus/FocusNotificationCoordinator.ets NextThing/entry/src/test/FocusNotification.test.ets
git commit -m "feat: publish focus notifications"
```

### 任务 3：将通知同步接入会话生命周期

**文件：**
- 修改：`NextThing/entry/src/main/ets/pages/Index.ets`
- 修改：`NextThing/entry/src/main/ets/pages/FocusTimer.ets`

- [ ] **步骤 1：在首页创建协调器并请求权限**

在 `Index.ets` 添加导入与字段：

```ts
import { FocusNotificationCoordinator } from '../focus/FocusNotificationCoordinator';

private focusNotificationCoordinator: FocusNotificationCoordinator | undefined = undefined;
```

在 `getSessionStore` 后添加：

```ts
private getNotificationCoordinator(): FocusNotificationCoordinator | undefined {
  if (this.focusNotificationCoordinator !== undefined) {
    return this.focusNotificationCoordinator;
  }
  try {
    this.focusNotificationCoordinator = new FocusNotificationCoordinator(
      getContext(this) as common.UIAbilityContext
    );
    return this.focusNotificationCoordinator;
  } catch (_) {
    return undefined;
  }
}
```

同时将 `@kit.AbilityKit` 导入改为：

```ts
import { common } from '@kit.AbilityKit';
```

在 `startTask` 创建并保存 `session` 后、`router.pushUrl` 前加入：

```ts
this.getNotificationCoordinator()?.requestPermission();
this.getNotificationCoordinator()?.sync(session);
```

- [ ] **步骤 2：在计时页同步和取消通知**

在 `FocusTimer.ets` 添加与首页相同的 `common` 和 `FocusNotificationCoordinator` 导入、字段和 `getNotificationCoordinator` 方法。

将 `persistSession` 改为：

```ts
private persistSession(): void {
  const session = this.toSession();
  this.getSessionStore()?.save(session);
  this.getNotificationCoordinator()?.sync(session);
}
```

在 `returnHome` 中，在 `router.replaceUrl` 前加入：

```ts
this.getNotificationCoordinator()?.cancel();
```

保留 `shouldPersist = false`，因此结果操作先取消通知，随后 `aboutToDisappear` 不会重新发布。

- [ ] **步骤 3：在页面集成后进行干净构建**

在 `NextThing` 目录执行：

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon clean
& $hvigor --no-daemon assembleApp -p product=default
```

预期：两条命令均显示 `BUILD SUCCESSFUL`。

- [ ] **步骤 4：提交页面生命周期集成**

```powershell
git add NextThing/entry/src/main/ets/pages/Index.ets NextThing/entry/src/main/ets/pages/FocusTimer.ets
git commit -m "feat: sync focus notifications with timer"
```

### 任务 4：在模拟器验收并记录结果

**文件：**
- 修改：`NextThing/README.md`

- [ ] **步骤 1：构建、安装并启动应用**

在 `NextThing` 目录执行：

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon clean
& $hvigor --no-daemon assembleApp -p product=default
hdc -t 127.0.0.1:5555 install -r entry\build\default\outputs\default\entry-default-unsigned.hap
hdc -t 127.0.0.1:5555 shell aa start -a EntryAbility -b com.zhaoxin.nextthing
```

预期：应用启动，且没有保存会话时显示首页。

- [ ] **步骤 2：执行通知验收**

在 API 24 模拟器中依次验证：

1. 开始 5 分钟任务，展开通知中心，确认出现常驻通知，标题为 `正在专注`，正文包含任务名称和 `专注至`。
2. 点按通知，确认应用恢复到当前专注计时页。
3. 暂停任务，确认通知标题变为 `专注已暂停`，正文显示固定的剩余时间；等待两秒后仍不变化。
4. 继续任务，确认通知恢复为 `正在专注`。
5. 提前结束，确认结果页出现且通知被移除。
6. 新建任务后强制停止并启动应用，确认恢复会话时重新出现匹配状态的通知。
7. 在系统设置中关闭 NextThing 通知权限，开始新任务并确认计时、暂停、恢复和结束仍正常，且应用不反复请求权限。

- [ ] **步骤 3：记录已验证的行为**

在 `NextThing/README.md` 追加：

```md
## 专注实况通知验收记录（2026-07-16）

- 已验证运行中和暂停的专注会话会发布同一条常驻通知。
- 已验证运行中通知显示任务名称与结束时间，暂停通知显示固定剩余时间。
- 已验证点按通知可返回应用，提前结束和结果操作均会移除通知。
- 已验证应用重启后会为已恢复会话重新发布通知。
- 已验证拒绝通知权限不会影响计时和会话恢复。
```

- [ ] **步骤 4：执行最终构建检查**

在 `NextThing` 目录执行：

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon clean
& $hvigor --no-daemon assembleApp -p product=default
```

预期：两条命令均显示 `BUILD SUCCESSFUL`。

- [ ] **步骤 5：提交验收记录和实施计划**

```powershell
git add NextThing/README.md docs/superpowers/plans/2026-07-16-focus-live-notification.md
git commit -m "docs: record focus notification verification"
```
