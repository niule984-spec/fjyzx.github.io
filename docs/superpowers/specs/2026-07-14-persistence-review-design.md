# Persistence And Review Design

## Scope

Add local persistence to NextThing so current work survives process restarts, every
ended focus session produces a record, the user can manage an inbox, and the user can
review today's activity. This feature uses local RDB only. Cloud sync, notifications,
historical date browsing, and account features are out of scope.

## Navigation

The main page becomes a three-tab ArkUI interface:

- `现在`: current task input and duration selection; it pre-fills the saved next task.
- `清空脑袋`: inbox task capture, deletion, and setting a task as the next task.
- `今日回顾`: statistics for records whose end time falls on the local calendar day.

Setting an inbox task as next task stores it and switches to `现在`; it never starts a
focus session automatically.

## Local Data

Use a single RDB database with these tables:

| Table | Key fields | Purpose |
| --- | --- | --- |
| `inbox_tasks` | `id`, `title`, `created_at` | User-captured tasks awaiting action. |
| `focus_records` | `id`, `task_title`, `planned_minutes`, `actual_seconds`, `ended_at`, `outcome` | Immutable record of every ended session. |
| `app_state` | `state_key`, `state_value` | Saved next task and active session JSON. |

`focus_records.outcome` is `pending`, `completed`, `unfinished`, or `changed`.
Deleting an inbox task never deletes focus records.

## Active Session Recovery

`app_state` stores the current next-task title and, while a timer is active or paused,
the `taskName`, `durationMinutes`, `remainingSeconds`, `targetEndTime`, and
`isRunning` fields needed by the existing timestamp timer engine.

Starting, pausing, and resuming immediately writes the active session. On application
start, the current-tab view loads it. If a session is active, the app restores the
timer route; the engine derives remaining time from `targetEndTime`. If that result is
zero, it transitions to the result choice state. Completing a result choice clears the
active session.

## Records And Results

When a timer reaches zero or is ended early, create one record immediately with
`pending` outcome and actual seconds equal to planned seconds minus remaining seconds.
The result buttons update that record to `completed`, `unfinished`, or `changed`, then
return to `现在`. A restart on the result screen preserves the pending record and the
active-session result state until a choice is made.

## Inbox And Review

The inbox tab has one task input, an add action, and a compact list. Each item offers
set-as-next and delete controls. Empty or whitespace-only task titles cannot be added.

The review tab computes local-day totals from all ended records, including unfinished
and changed sessions: total sessions, actual focus minutes, completed count, and
unfinished count. Pending records are excluded from outcome counts but included in the
session and actual-time totals after they are created.

## Verification

Test source covers persistence mapping, local-day boundaries, actual-duration
calculation, and timestamp recovery. Manual API 24 simulator acceptance covers:

1. adding, deleting, and selecting inbox tasks;
2. closing and reopening the app with a next task and active/paused session;
3. generating records from early and natural completion;
4. selecting each result outcome;
5. today-review counts and actual duration.
