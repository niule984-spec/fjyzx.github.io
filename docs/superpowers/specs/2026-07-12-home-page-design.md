# Home Page Design

## Scope

Replace the template welcome page with the first usable screen of `NextThing`.
The screen lets a user enter one task, choose 5, 10, or 25 minutes, and request a start.
This change does not add a timer page, persistence, routing, or focus-session lifecycle.

## User Interface

The page is a vertical ArkUI `Column` with a title, a task `TextInput`, three duration
buttons, a start button, and a status line. The default duration is 25 minutes. The
selected duration is visually distinct from the other two choices.

## State And Behavior

`taskTitle` stores the current input. `selectedMinutes` stores the active duration.
`feedback` stores validation or confirmation text. Clicking Start trims `taskTitle`:

- If the result is empty, the page keeps its current selection and displays `请输入任务内容`.
- Otherwise, the page displays `已准备开始：<trimmed task>（<minutes> 分钟）`.

No timer is started in this feature.

## Verification

The validation rule is isolated in a small source module so it can be covered by a
Hypium test. The project currently exposes no local Hvigor test task, so acceptance
also requires assembling the app and manually verifying empty and valid task flows on
the HarmonyOS simulator.
