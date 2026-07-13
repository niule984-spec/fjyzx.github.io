# Focus Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (\`- [ ]\`) syntax for tracking.

**Goal:** Build a timestamp-based focus countdown from task entry through result selection and return to home.

**Architecture:** \`FocusTimerEngine.ets\` owns timestamp calculations; \`FocusTimer.ets\` owns ArkUI rendering, routing, and one-second refreshes. \`Index.ets\` passes the trimmed task and selected duration through the router. No storage is introduced.

**Tech Stack:** HarmonyOS API 24, ArkTS, ArkUI, \`@ohos.router\`, Hypium test source, Hvigor, HarmonyOS API 24 simulator.

---

### Task 1: Timestamp Timer Engine

**Files:**
- Create: \`NextThing/entry/src/main/ets/focus/FocusTimerEngine.ets\`
- Create: \`NextThing/entry/src/test/FocusTimerEngine.test.ets\`

- [ ] **Step 1: Write failing test source**

\`\`\`ts
import { describe, expect, it } from '@ohos/hypium';
import { createFocusTimer, formatRemainingTime, pauseFocusTimer, refreshFocusTimer, resumeFocusTimer } from '../main/ets/focus/FocusTimerEngine';

export default function focusTimerEngineTest() {
  describe('focus timer engine', () => {
    it('derives remaining seconds from target end time', 0, () => {
      expect(refreshFocusTimer(createFocusTimer(5, 1_000), 2_500).remainingSeconds).assertEqual(299);
    });
    it('keeps time stable while paused', 0, () => {
      const paused = pauseFocusTimer(createFocusTimer(5, 1_000), 61_000);
      expect(refreshFocusTimer(paused, 181_000).remainingSeconds).assertEqual(240);
    });
    it('resumes with a fresh timestamp and formats time', 0, () => {
      const paused = pauseFocusTimer(createFocusTimer(5, 1_000), 61_000);
      expect(resumeFocusTimer(paused, 200_000).targetEndTime).assertEqual(440_000);
      expect(formatRemainingTime(65)).assertEqual('01:05');
    });
  });
}
\`\`\`

- [ ] **Step 2: Confirm the current runner limitation**

Run: \`hvigorw.bat --no-daemon tasks\`

Expected: no local test-runner task. Keep the Hypium source as a regression contract and use Task 4 simulator checks as executable behavior verification.

- [ ] **Step 3: Implement the engine**

\`\`\`ts
export interface FocusTimerState {
  durationSeconds: number;
  remainingSeconds: number;
  targetEndTime: number;
  isRunning: boolean;
}

export function createFocusTimer(durationMinutes: number, now: number): FocusTimerState {
  const durationSeconds = Math.max(0, Math.floor(durationMinutes * 60));
  return { durationSeconds, remainingSeconds: durationSeconds, targetEndTime: now + durationSeconds * 1_000, isRunning: durationSeconds > 0 };
}

export function refreshFocusTimer(timer: FocusTimerState, now: number): FocusTimerState {
  if (!timer.isRunning) return timer;
  const remainingSeconds = Math.max(0, Math.floor((timer.targetEndTime - now) / 1_000));
  return { ...timer, remainingSeconds, targetEndTime: remainingSeconds === 0 ? 0 : timer.targetEndTime, isRunning: remainingSeconds > 0 };
}

export function pauseFocusTimer(timer: FocusTimerState, now: number): FocusTimerState {
  const refreshed = refreshFocusTimer(timer, now);
  return { ...refreshed, targetEndTime: 0, isRunning: false };
}

export function resumeFocusTimer(timer: FocusTimerState, now: number): FocusTimerState {
  return timer.remainingSeconds === 0 ? timer : { ...timer, targetEndTime: now + timer.remainingSeconds * 1_000, isRunning: true };
}

export function formatRemainingTime(remainingSeconds: number): string {
  const safe = Math.max(0, Math.floor(remainingSeconds));
  return Math.floor(safe / 60).toString().padStart(2, '0') + ':' + (safe % 60).toString().padStart(2, '0');
}
\`\`\`

- [ ] **Step 4: Compile and commit**

Run: \`hvigorw.bat --no-daemon assembleApp -p product=default\`

Expected: \`BUILD SUCCESSFUL\`.

\`\`\`powershell
git add NextThing/entry/src/main/ets/focus/FocusTimerEngine.ets NextThing/entry/src/test/FocusTimerEngine.test.ets
git commit -m "feat: implement timestamp based countdown"
\`\`\`

### Task 2: Route From Home to FocusTimer

**Files:**
- Modify: \`NextThing/entry/src/main/ets/pages/Index.ets\`
- Modify: \`NextThing/entry/src/main/resources/base/profile/main_pages.json\`
- Create: \`NextThing/entry/src/main/ets/pages/FocusTimer.ets\`

- [ ] **Step 1: Replace local confirmation with valid-task navigation**

\`\`\`ts
import router from '@ohos.router';

private startTask(): void {
  const result = validateTaskTitle(this.taskTitle);
  if (!result.isValid) {
    this.feedback = '请输入任务内容';
    return;
  }
  router.pushUrl({
    url: 'pages/FocusTimer',
    params: { taskName: result.taskTitle, durationMinutes: this.selectedMinutes }
  });
}
\`\`\`

- [ ] **Step 2: Register the page**

\`\`\`json
{
  "src": ["pages/Index", "pages/FocusTimer"]
}
\`\`\`

- [ ] **Step 3: Create the initial route-parameter page**

\`\`\`ts
import router from '@ohos.router';

interface FocusTimerParams {
  taskName: string;
  durationMinutes: number;
}

@Entry
@Component
struct FocusTimer {
  @State taskName: string = '';
  @State durationMinutes: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as FocusTimerParams;
    this.taskName = params.taskName;
    this.durationMinutes = params.durationMinutes;
  }

  build() {
    Column({ space: 16 }) {
      Text(this.taskName)
      Text(this.durationMinutes + ' 分钟')
    }
  }
}
\`\`\`

- [ ] **Step 4: Build, install, and verify parameters**

Run: \`hvigorw.bat --no-daemon assembleApp -p product=default\`

Expected: selecting 5, 10, and 25 minutes enters \`FocusTimer\` with the entered task and matching duration.

- [ ] **Step 5: Commit**

\`\`\`powershell
git add NextThing/entry/src/main/ets/pages/Index.ets NextThing/entry/src/main/ets/pages/FocusTimer.ets NextThing/entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat: pass task and duration to focus timer"
\`\`\`

### Task 3: Timer UI, Pause/Resume, and Results

**Files:**
- Modify: \`NextThing/entry/src/main/ets/pages/FocusTimer.ets\`

- [ ] **Step 1: Add page state and scheduler**

\`\`\`ts
@State timer: FocusTimerState = createFocusTimer(0, 0);
@State pageState: string = 'running';
private intervalId: number = -1;

private refreshTimer(): void {
  this.timer = refreshFocusTimer(this.timer, Date.now());
  if (this.timer.remainingSeconds === 0) {
    this.pageState = 'result';
    this.stopTicker();
  }
}

private startTicker(): void {
  this.stopTicker();
  this.intervalId = setInterval(() => this.refreshTimer(), 1_000);
}

private stopTicker(): void {
  if (this.intervalId !== -1) {
    clearInterval(this.intervalId);
    this.intervalId = -1;
  }
}
\`\`\`

- [ ] **Step 2: Initialize, foreground-refresh, and dispose**

\`\`\`ts
aboutToAppear(): void {
  const params = router.getParams() as FocusTimerParams;
  this.taskName = params.taskName;
  this.durationMinutes = params.durationMinutes;
  this.timer = createFocusTimer(this.durationMinutes, Date.now());
  this.startTicker();
}

onPageShow(): void {
  if (this.pageState === 'running') {
    this.refreshTimer();
    this.startTicker();
  }
}

aboutToDisappear(): void {
  this.stopTicker();
}
\`\`\`

- [ ] **Step 3: Render the progress-first active state**

\`\`\`ts
Text(formatRemainingTime(this.timer.remainingSeconds))
  .fontSize(52)
  .fontWeight(FontWeight.Bold)

Progress({
  value: this.timer.durationSeconds - this.timer.remainingSeconds,
  total: this.timer.durationSeconds,
  type: ProgressType.Linear
}).width('100%')

Text(this.taskName).fontSize(18).fontWeight(FontWeight.Medium)

Button(this.timer.isRunning ? '暂停' : '继续').onClick(() => {
  this.timer = this.timer.isRunning
    ? pauseFocusTimer(this.timer, Date.now())
    : resumeFocusTimer(this.timer, Date.now());
  this.timer.isRunning ? this.startTicker() : this.stopTicker();
})

Button('结束').onClick(() => {
  this.timer = pauseFocusTimer(this.timer, Date.now());
  this.pageState = 'result';
  this.stopTicker();
})
\`\`\`

- [ ] **Step 4: Render results and return home**

\`\`\`ts
private returnHome(): void {
  this.stopTicker();
  router.replaceUrl({ url: 'pages/Index' });
}

if (this.pageState === 'result') {
  Text('这次专注结束了')
  Button('完成了').onClick(() => this.returnHome())
  Button('还没完成').onClick(() => this.returnHome())
  Button('换一件事').onClick(() => this.returnHome())
}
\`\`\`

- [ ] **Step 5: Clean-build and commit**

Run: \`hvigorw.bat --no-daemon clean\`

Run: \`hvigorw.bat --no-daemon assembleApp -p product=default\`

Expected: both commands report \`BUILD SUCCESSFUL\`.

\`\`\`powershell
git add NextThing/entry/src/main/ets/pages/FocusTimer.ets
git commit -m "feat: add pause resume and finish actions"
\`\`\`

### Task 4: Simulator Acceptance and Documentation

**Files:**
- Modify: \`NextThing/README.md\`

- [ ] **Step 1: Build, install, and launch**

\`\`\`powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --no-daemon assembleApp -p product=default
hdc -t 127.0.0.1:5555 install -r entry\build\default\outputs\default\entry-default-unsigned.hap
hdc -t 127.0.0.1:5555 shell aa start -a EntryAbility -b com.zhaoxin.nextthing
\`\`\`

- [ ] **Step 2: Execute acceptance checks**

Verify 5, 10, and 25 minute inputs route correctly; the timer is \`mm:ss\`; progress updates; pause keeps time stable for at least two seconds; resume decreases it again; End shows the three result actions; each action returns home. For natural completion, temporarily initialize the engine with one remaining second, confirm the same result state, then restore normal 5/10/25 minute UI inputs before committing.

- [ ] **Step 3: Record checks, rebuild, and commit**

\`\`\`md
## Focus Timer Verification

- Verified 5, 10, and 25 minute task routing on the API 24 simulator.
- Verified timestamp countdown, pause/resume, early end, natural end, and all result actions returning home.
\`\`\`

Run: \`hvigorw.bat --no-daemon assembleApp -p product=default\`

Expected: \`BUILD SUCCESSFUL\`.

\`\`\`powershell
git add NextThing/README.md docs/superpowers/plans/2026-07-13-focus-timer.md
git commit -m "docs: record focus timer verification"
\`\`\`

