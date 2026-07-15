# Focus Session Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist the single active focus session so it resumes correctly after an application restart.

**Architecture:** Keep session validation, serialization, and time-aware recovery in a pure `FocusSession.ets` module. Keep HarmonyOS Preferences calls in `FocusSessionStore.ets`, while `Index.ets` creates or detects sessions and `FocusTimer.ets` restores, updates, and clears them. The existing timer engine remains responsible only for timer arithmetic.

**Tech Stack:** HarmonyOS API 24, ArkTS, ArkUI, `@ohos.data.preferences`, `@ohos.router`, Hypium test source, Hvigor, HarmonyOS API 24 simulator.

---

### Task 1: Create The Pure Focus Session Model

**Files:**
- Create: `NextThing/entry/src/main/ets/focus/FocusSession.ets`
- Create: `NextThing/entry/src/test/FocusSession.test.ets`

- [ ] **Step 1: Write the failing Hypium test source**

Create `NextThing/entry/src/test/FocusSession.test.ets`:

```ts
import { describe, expect, it } from '@ohos/hypium';
import {
  createFocusSession,
  decodeFocusSession,
  restoreFocusSession
} from '../main/ets/focus/FocusSession';
import { pauseFocusTimer } from '../main/ets/focus/FocusTimerEngine';

export default function focusSessionTest() {
  describe('focus session', () => {
    it('restores a running session from its absolute target timestamp', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 1_000);
      const restored = restoreFocusSession(session, 2_500);
      expect(restored.timer.remainingSeconds).assertEqual(299);
      expect(restored.pageState).assertEqual('running');
    });

    it('keeps a paused session stable after restart', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 1_000);
      session.timer = pauseFocusTimer(session.timer, 61_000);
      const restored = restoreFocusSession(session, 181_000);
      expect(restored.timer.remainingSeconds).assertEqual(240);
      expect(restored.timer.isRunning).assertFalse();
      expect(restored.pageState).assertEqual('running');
    });

    it('turns an expired running session into a result session', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 1_000);
      const restored = restoreFocusSession(session, 301_000);
      expect(restored.timer.remainingSeconds).assertEqual(0);
      expect(restored.pageState).assertEqual('result');
    });

    it('keeps an early-ended result session in the result state', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 1_000);
      session.timer = pauseFocusTimer(session.timer, 61_000);
      session.pageState = 'result';
      const restored = restoreFocusSession(session, 181_000);
      expect(restored.timer.remainingSeconds).assertEqual(240);
      expect(restored.pageState).assertEqual('result');
    });

    it('rejects malformed and structurally invalid session data', 0, () => {
      expect(decodeFocusSession('not-json') === null).assertTrue();
      expect(decodeFocusSession('{"taskName":"","durationMinutes":5}') === null).assertTrue();
    });
  });
}
```

- [ ] **Step 2: Confirm the missing-module failure**

Run from `NextThing`:

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon tasks
```

Expected: the project has no local Hypium execution task, matching the existing timer-test limitation. Open `FocusSession.test.ets` in DevEco Studio and confirm the import from `focus/FocusSession` is unresolved before creating the module.

- [ ] **Step 3: Implement the session model**

Create `NextThing/entry/src/main/ets/focus/FocusSession.ets`:

```ts
import { createFocusTimer, FocusTimerState, refreshFocusTimer } from './FocusTimerEngine';

export type FocusPageState = 'running' | 'result';

export interface FocusSession {
  taskName: string;
  durationMinutes: number;
  timer: FocusTimerState;
  pageState: FocusPageState;
}

export function createFocusSession(taskName: string, durationMinutes: number, now: number): FocusSession {
  return {
    taskName,
    durationMinutes,
    timer: createFocusTimer(durationMinutes, now),
    pageState: 'running'
  };
}

export function restoreFocusSession(session: FocusSession, now: number): FocusSession {
  const timer = session.pageState === 'running'
    ? refreshFocusTimer(session.timer, now)
    : session.timer;
  return {
    taskName: session.taskName,
    durationMinutes: session.durationMinutes,
    timer,
    pageState: session.pageState === 'result' || timer.remainingSeconds === 0 ? 'result' : 'running'
  };
}

export function decodeFocusSession(raw: string): FocusSession | null {
  try {
    const value = JSON.parse(raw) as FocusSession;
    if (
      typeof value.taskName !== 'string' || value.taskName.trim().length === 0 ||
      !Number.isInteger(value.durationMinutes) || value.durationMinutes <= 0 ||
      typeof value.timer !== 'object' || value.timer === null ||
      !Number.isInteger(value.timer.durationSeconds) || value.timer.durationSeconds <= 0 ||
      !Number.isInteger(value.timer.remainingSeconds) || value.timer.remainingSeconds < 0 ||
      value.timer.remainingSeconds > value.timer.durationSeconds ||
      typeof value.timer.targetEndTime !== 'number' || value.timer.targetEndTime < 0 ||
      typeof value.timer.isRunning !== 'boolean' ||
      (value.pageState !== 'running' && value.pageState !== 'result')
    ) {
      return null;
    }
    return value;
  } catch (_) {
    return null;
  }
}
```

- [ ] **Step 4: Verify the model compiles**

Run from `NextThing`:

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon assembleApp -p product=default
```

Expected: `BUILD SUCCESSFUL`. Because the current repository exposes no local Hypium runner, retain the test source as a regression contract and run the behavior checks in Task 4 on the simulator.

- [ ] **Step 5: Commit the pure session model**

```powershell
git add NextThing/entry/src/main/ets/focus/FocusSession.ets NextThing/entry/src/test/FocusSession.test.ets
git commit -m "feat: add recoverable focus session model"
```

### Task 2: Add The Preferences Adapter

**Files:**
- Create: `NextThing/entry/src/main/ets/focus/FocusSessionStore.ets`
- Modify: `NextThing/entry/src/test/FocusSession.test.ets`

- [ ] **Step 1: Extend the failing test source with round-trip coverage**

Replace the `FocusSession` import and add this test to the `describe` block in `NextThing/entry/src/test/FocusSession.test.ets`:

```ts
import {
  createFocusSession,
  decodeFocusSession,
  encodeFocusSession,
  restoreFocusSession
} from '../main/ets/focus/FocusSession';

it('round-trips a valid focus session', 0, () => {
  const session = createFocusSession('阅读计划书', 25, 1_000);
  const decoded = decodeFocusSession(encodeFocusSession(session));
  expect(decoded === null).assertFalse();
  expect(decoded?.taskName).assertEqual('阅读计划书');
  expect(decoded?.timer.targetEndTime).assertEqual(1_501_000);
});
```

- [ ] **Step 2: Confirm the new assertion is not yet supported**

Open the test file in DevEco Studio before adding `encodeFocusSession` to its import. Confirm that `encodeFocusSession` is unresolved, then add the import shown in Step 1. This project has no command-line Hypium task, so the IDE diagnostic is the available red check.

- [ ] **Step 3: Implement the Preferences wrapper**

Append this serializer to `NextThing/entry/src/main/ets/focus/FocusSession.ets`:

```ts
export function encodeFocusSession(session: FocusSession): string {
  return JSON.stringify(session);
}
```

Create `NextThing/entry/src/main/ets/focus/FocusSessionStore.ets`:

```ts
import preferences from '@ohos.data.preferences';
import { decodeFocusSession, encodeFocusSession, FocusSession } from './FocusSession';

const ACTIVE_SESSION_KEY = 'active_focus_session';

export class FocusSessionStore {
  constructor(private readonly preferences: preferences.Preferences) {}

  load(): FocusSession | null {
    try {
      const raw = this.preferences.getSync(ACTIVE_SESSION_KEY, '');
      if (typeof raw !== 'string' || raw.length === 0) {
        return null;
      }
      const session = decodeFocusSession(raw);
      if (session === null) {
        this.clear();
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  save(session: FocusSession): boolean {
    try {
      this.preferences.putSync(ACTIVE_SESSION_KEY, encodeFocusSession(session));
      this.preferences.flushSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  clear(): boolean {
    try {
      this.preferences.deleteSync(ACTIVE_SESSION_KEY);
      this.preferences.flushSync();
      return true;
    } catch (_) {
      return false;
    }
  }
}
```

- [ ] **Step 4: Compile the Preferences adapter**

Run from `NextThing`:

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon assembleApp -p product=default
```

Expected: `BUILD SUCCESSFUL` with no new dependency in either `oh-package.json5` file.

- [ ] **Step 5: Commit the storage adapter and test contract**

```powershell
git add NextThing/entry/src/main/ets/focus/FocusSessionStore.ets NextThing/entry/src/test/FocusSession.test.ets
git commit -m "feat: persist active focus sessions"
```

### Task 3: Restore And Maintain Sessions In The Pages

**Files:**
- Modify: `NextThing/entry/src/main/ets/pages/Index.ets`
- Modify: `NextThing/entry/src/main/ets/pages/FocusTimer.ets`

- [ ] **Step 1: Add session imports and a store helper to both pages**

In `Index.ets`, add:

```ts
import preferences from '@ohos.data.preferences';
import { createFocusSession } from '../focus/FocusSession';
import { FocusSessionStore } from '../focus/FocusSessionStore';
```

In `FocusTimer.ets`, add:

```ts
import preferences from '@ohos.data.preferences';
import { FocusSession, restoreFocusSession } from '../focus/FocusSession';
import { FocusSessionStore } from '../focus/FocusSessionStore';
```

In each component, add this field and helper:

```ts
private focusSessionStore: FocusSessionStore | undefined = undefined;

private getSessionStore(): FocusSessionStore | undefined {
  if (this.focusSessionStore !== undefined) {
    return this.focusSessionStore;
  }
  try {
    const preference = preferences.getPreferencesSync(getContext(this), { name: 'nextthing_focus_session' });
    this.focusSessionStore = new FocusSessionStore(preference);
    return this.focusSessionStore;
  } catch (_) {
    return undefined;
  }
}
```

- [ ] **Step 2: Persist before initial navigation and auto-route on launch**

In `Index.ets`, add this lifecycle method and helper:

```ts
aboutToAppear(): void {
  const session = this.getSessionStore()?.load();
  if (session !== null && session !== undefined) {
    router.replaceUrl({ url: 'pages/FocusTimer', params: { session } });
  }
}
```

Replace the final `router.pushUrl` block in `startTask` with:

```ts
const session = createFocusSession(result.taskTitle, this.selectedMinutes, Date.now());
this.getSessionStore()?.save(session);
router.pushUrl({
  url: 'pages/FocusTimer',
  params: { session }
});
```

The route parameter keeps the newly created task usable if Preferences writes fail; cold-start recovery always comes from Preferences.

- [ ] **Step 3: Restore, persist transitions, and clear results**

In `FocusTimer.ets`, replace `FocusTimerParams` with:

```ts
interface FocusTimerParams {
  session?: FocusSession;
}
```

Add this field and methods to the component:

```ts
private shouldPersist: boolean = true;

private toSession(): FocusSession {
  return {
    taskName: this.taskName,
    durationMinutes: this.durationMinutes,
    timer: this.timer,
    pageState: this.pageState === 'result' ? 'result' : 'running'
  };
}

private persistSession(): void {
  this.getSessionStore()?.save(this.toSession());
}

private restoreSession(): boolean {
  const params = router.getParams() as FocusTimerParams;
  const storedSession = this.getSessionStore()?.load();
  const sourceSession = storedSession ?? params.session;
  if (sourceSession === undefined) {
    return false;
  }
  const session = restoreFocusSession(sourceSession, Date.now());
  this.taskName = session.taskName;
  this.durationMinutes = session.durationMinutes;
  this.timer = session.timer;
  this.pageState = session.pageState;
  this.persistSession();
  return true;
}
```

Replace `aboutToAppear` with:

```ts
aboutToAppear(): void {
  this.shouldPersist = true;
  if (!this.restoreSession()) {
    router.replaceUrl({ url: 'pages/Index' });
    return;
  }
  if (this.pageState === 'running' && this.timer.isRunning) {
    this.startTicker();
  }
}
```

Replace `aboutToDisappear` with:

```ts
aboutToDisappear(): void {
  this.stopTicker();
  if (this.shouldPersist) {
    this.persistSession();
  }
}
```

Add `this.persistSession();` at the end of `toggleTimer` and `endEarly`. In `refreshTimer`, call `this.persistSession();` only in the branch where `remainingSeconds === 0`, after setting `pageState` to `result`; do not write on each normal one-second refresh.

Replace `returnHome` with:

```ts
private returnHome(): void {
  this.stopTicker();
  this.shouldPersist = false;
  this.getSessionStore()?.clear();
  router.replaceUrl({ url: 'pages/Index' });
}
```

- [ ] **Step 4: Compile after the page integration**

Run from `NextThing`:

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon clean
& $hvigor --no-daemon assembleApp -p product=default
```

Expected: both commands report `BUILD SUCCESSFUL`.

- [ ] **Step 5: Commit recovery behavior**

```powershell
git add NextThing/entry/src/main/ets/pages/Index.ets NextThing/entry/src/main/ets/pages/FocusTimer.ets
git commit -m "feat: restore active focus sessions"
```

### Task 4: Verify Recovery On A Device And Document It

**Files:**
- Modify: `NextThing/README.md`

- [ ] **Step 1: Build, install, and launch the app**

Run from `NextThing`:

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon assembleApp -p product=default
hdc -t 127.0.0.1:5555 install -r entry\build\default\outputs\default\entry-default-unsigned.hap
hdc -t 127.0.0.1:5555 shell aa start -a EntryAbility -b com.zhaoxin.nextthing
```

Expected: the app launches to the home page when no saved session exists.

- [ ] **Step 2: Execute persistence acceptance checks**

Run these checks on the API 24 simulator:

1. Start a 5-minute task, close the app, reopen it, and confirm the timer page restores with less remaining time.
2. Pause a task, close the app, reopen it, and confirm the timer remains paused with unchanged remaining time.
3. Start a task, use a temporary one-second duration during local verification, close the app before it ends, reopen it after it expires, and confirm the result actions appear.
4. Use End on a task, close and reopen, and confirm the result actions still appear.
5. Select any result action, close and reopen, and confirm the app remains on the home page rather than restoring a task.

- [ ] **Step 3: Record the verified behavior**

Append this section to `NextThing/README.md`:

```md
## 专注会话持久化验收记录（2026-07-15）

- 已验证运行中任务在应用重开后按目标结束时间继续倒计时。
- 已验证暂停任务在应用重开后保持暂停和剩余时间。
- 已验证应用关闭期间自然结束与提前结束的任务都会恢复到结果页。
- 已验证选择任一结果后会清除本地会话，不会在下次启动时恢复。
```

- [ ] **Step 4: Perform the final build check**

Run from `NextThing`:

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon assembleApp -p product=default
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Commit the verification record and plan**

```powershell
git add NextThing/README.md docs/superpowers/plans/2026-07-15-focus-session-persistence.md
git commit -m "docs: record focus session persistence verification"
```
