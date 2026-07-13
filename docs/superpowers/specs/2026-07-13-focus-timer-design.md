# Focus Timer Design

## Scope

Build the second-week focus loop without persistent storage: start a task from the
home page, run a focus countdown, pause or resume it, end early or naturally, choose
an outcome, and return to the home page. Preferences, RDB, history, notifications,
and cross-process recovery are outside this change.

## Navigation And Input

The home page continues to validate and trim the task title. A valid Start action
navigates to `pages/FocusTimer` with two route parameters: `taskName` and
`durationMinutes`. The timer page reads those parameters once when it is created.
The duration choices remain 5, 10, and 25 minutes.

## Timer Model

Timer rules live in `focus/FocusTimerEngine.ets`, independently from ArkUI widgets.
The model contains `durationSeconds`, `remainingSeconds`, `targetEndTime`, and
`isRunning`.

- Starting or resuming sets `targetEndTime` to `Date.now() + remainingSeconds * 1000`
  and sets `isRunning` to true.
- Every refresh derives `remainingSeconds` from
  `max(0, floor((targetEndTime - Date.now()) / 1000))`.
- Pausing refreshes first, then sets `isRunning` to false and clears `targetEndTime`.
- Refreshing at zero ends the active timer and transitions the page to the result
  selection state.

The page owns one-second refresh scheduling while active. It also refreshes when the
page becomes visible, so elapsed wall-clock time is reflected after foregrounding.

## Timer Page

The timer page uses the selected progress-first layout:

- large `mm:ss` remaining time;
- progress bar based on elapsed seconds divided by the selected duration;
- task name below the progress indicator;
- a primary Pause or Resume control;
- a separate End control.

The page has three UI states: `running`, `paused`, and `result`. Ending early or
reaching zero both enter `result`. In the result state the page displays
`这次专注结束了` and actions `完成了`, `还没完成`, and `换一件事`. Each action replaces
the timer page with the home page. The selected outcome is intentionally not stored
in this iteration.

## Testing And Verification

Pure timer operations are covered with Hypium test source for timestamp refresh,
pause, resume, zero handling, and `mm:ss` formatting. The current Hvigor setup does
not expose a local test execution task, so final acceptance also requires the
HarmonyOS API 24 simulator:

1. Start 5, 10, and 25 minute tasks from the home page and confirm task and duration.
2. Confirm the countdown format and progress bar update.
3. Pause, wait, and confirm the remaining time is unchanged; resume and confirm it
   decreases again.
4. Use End and confirm the result options appear.
5. Exercise natural completion with a short test timer through the engine or a
   simulator test hook, then confirm the same result options.
6. Confirm each result action returns to the home page.
