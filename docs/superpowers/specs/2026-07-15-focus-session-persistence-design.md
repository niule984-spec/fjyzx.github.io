# Focus Session Persistence Design

## Scope

Persist the one active focus session locally so an unfinished task survives an
application restart. This change does not add task history, completed-session
history, notifications, cloud synchronization, or an RDB database.

## Storage Approach

The application stores one serialized active session in HarmonyOS Preferences.
Preferences is appropriate because the app has exactly one recoverable session
and does not need queries, ordering, or a history table.

The storage implementation lives in `focus/FocusSessionStore.ets`. It owns
opening the Preferences file, encoding a session, decoding stored data, and
clearing the active session. `FocusTimerEngine.ets` remains independent from
HarmonyOS storage APIs and continues to own only timer calculations.

## Persisted Session

The saved record includes:

- `taskName`: the validated task title.
- `durationMinutes`: the user-selected duration.
- `timer`: the existing `FocusTimerState` fields: `durationSeconds`,
  `remainingSeconds`, `targetEndTime`, and `isRunning`.
- `pageState`: either `running` or `result`.

The absolute `targetEndTime` is the source of truth while a session is running.
The app does not write to storage on every one-second screen refresh.

## Lifecycle And Recovery

Starting a valid task creates and saves a session before the timer page is
shown. The timer page saves the updated session after pause, resume, or early
end. It also saves its current state when it disappears.

On app startup, the home page checks for an active session. When one exists, it
navigates directly to the focus timer page. The timer page restores that record
instead of creating a new countdown.

- A running session is refreshed against `Date.now()`, so elapsed wall-clock
  time is reflected after a restart.
- A paused session remains paused with its stored remaining seconds.
- A session whose running countdown reaches zero while the app is closed opens
  directly in the result state.
- An early-ended session remains in the result state after restart.
- Choosing any result action clears the stored session before returning home.

## Failure Handling

Missing, malformed, or structurally invalid saved data is cleared and treated
as no active session. The home page remains usable and the user can start a new
task.

A write failure does not stop the in-memory timer or prevent navigation. It
only means that a later app restart may not recover the session. The change does
not add a new user-facing persistence warning in this iteration.

## Testing And Verification

Pure session conversion and recovery rules receive Hypium test coverage:

1. A running session restores with its original target end time and derives the
   remaining time from the current clock.
2. A paused session restores without decrementing its remaining seconds.
3. A running session that expires while closed restores into the result state.
4. An early-ended result session restores into the result state.
5. Invalid stored data is rejected and does not produce a recoverable session.
6. Clearing a session removes the persisted active record.

Manual API 24 simulator verification covers starting a task, closing and
reopening the app while running, repeating the test while paused, reopening
after natural completion, and confirming that a chosen result is not restored.
