# Focus Live Notification Design

## Scope

Show the active focus session in the HarmonyOS notification area while keeping
the existing timer and local session persistence behavior unchanged. The
notification opens the application when tapped and is removed when the focus
session ends or the user selects an outcome.

This change does not add cloud messaging, notification history, a persistent
background timer service, or direct notification-bar pause and end actions.

## Platform Boundary

The API 24 SDK marks `NotificationSystemLiveViewContent` as system-proxy-only:
a third-party application cannot create a system live view directly. NextThing
is a normal third-party application, so it must not publish that privileged
content type or promise a capsule/live-window presentation.

The app publishes an ongoing standard notification. If a device or system
service chooses to associate the notification with a system live presentation,
the app continues to update the same notification ID. On systems that do not,
the standard notification is the complete, supported fallback.

## Notification Content

One fixed notification ID represents the one active focus session.

- Running: title `正在专注`; text contains the task name and `专注至 HH:mm`.
- Paused: title `专注已暂停`; text contains the task name and the exact
  remaining `mm:ss`.
- Result: the notification is cancelled instead of publishing a completed
  summary.

The standard fallback deliberately displays the absolute end time while
running rather than a countdown that could become stale after the app enters
the background. A system-rendered live presentation may render its own time or
progress according to device capability, but that presentation is not under
application control.

Tapping the notification opens `EntryAbility`. The existing home-page recovery
logic reads the saved session and routes to the focus timer page.

## Components And Lifecycle

`focus/FocusNotificationCoordinator.ets` owns notification permissions and
the notification manager calls. It accepts a `FocusSession`, maps it to a
standard notification request, publishes the request using the fixed ID, and
cancels that ID. It catches notification permission and publishing errors so
the timer remains usable when notifications are unavailable.

`FocusTimer.ets` remains the source of timer state. It calls the coordinator
when a session is restored, paused, resumed, ended early, reaches zero, or
leaves the page. It does not republish on each one-second screen refresh.
`Index.ets` requests notification permission only when the user starts a new
focus session; rejection or failure does not block navigation.

The coordinator republishing a restored session keeps the notification aligned
with the persisted timer after an app restart. Cancelling occurs before the
result actions return home, preventing `aboutToDisappear` from recreating it.

## Permission And Failure Behavior

The app requests notification permission at the first user-initiated focus
start. It does not repeatedly prompt during resume, recovery, pause, or end.

If permission is denied, the notification manager rejects publishing, or the
device does not offer a live presentation, the focus timer and local session
continue normally. The iteration adds no in-app error banner for notification
failures.

## Testing And Verification

Pure notification mapping is covered by Hypium test source for running,
paused, and result states. The current project exposes no local Hypium runner,
so the API 24 simulator is also required to verify:

1. Starting a task publishes the ongoing notification with task name and end
   time.
2. Pausing changes the notification to the paused content and fixed remaining
   time.
3. Resuming restores the running content.
4. Ending early, natural completion, and choosing any result action remove the
   notification.
5. Restarting an active or paused session republishes its matching
   notification.
6. A notification permission denial leaves the timer and session recovery
   functional.
