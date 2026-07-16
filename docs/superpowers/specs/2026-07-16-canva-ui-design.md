# Canva UI Design

## Deliverable

Create one editable Canva design containing four 360 x 780 mobile screens placed
side by side. The screens represent the core flow of the HarmonyOS app
"下一件事": Now, Focus Timer, Clear, and Today Review. The design is a product UI
artifact, without phone frames, marketing copy, or landing-page content.

## Visual System

The visual direction is warm, quiet, and low pressure: a lightweight focus tool
with a subtle meditation-app calm, rather than a task-management dashboard.

- Background: `#FAF8F2`; cards: `#FFFFFF`; primary text: `#252525`; secondary
  text: `#777777`; borders: `#E8E6E0`.
- Use muted green `#4FA36C` for starting and completing, muted mist blue `#7A9CC6`
  for calm focus cues, and muted orange `#C9855B` for incomplete or early-ended
  outcomes. These accents remain low saturation.
- Use a clear Chinese sans-serif typeface, generous whitespace, 12-16px card
  corners, very light shadows, and simple line icons.
- Avoid gradients, strong shadows, glass effects, decorative illustration,
  achievement mechanics, rankings, streaks, badges, and dense task-management UI.

## Screens

### Now

Show the quiet summary “今天已专注 20 分钟，完成 2 次”, the headline
“现在只做这一件事”, and one task card for “写数学作业的第一题”. Place a segmented
5 / 10 / 25 minute picker below it with 25 minutes selected, then a wide green
“开始专注” button. Highlight “现在” in the three-item bottom navigation.

### Focus Timer

Use `#18201C` as the full-screen background. Show the current task near the top,
a restrained circular green progress ring around `24:58`, and the supportive line
“先做一小步就好”. Place primary pause/resume icon control and outlined
“提前结束” control near the bottom. Do not show bottom navigation or unrelated
statistics.

### Clear

Use “脑子里有什么，先写下来” and “不用整理，先放在这里” as the heading and
subheading. Add a chat-like input with “想到什么就写什么” placeholder and an add or
send icon. List four thoughts, each with a primary “设为下一件事” action and a
weakened delete icon. Highlight “清空” in bottom navigation.

### Today Review

Show “今日回顾”, two parallel summary blocks for “总专注 35 分钟” and “完成 3 次”,
then reverse-chronological focus records. Include the three supplied example rows
and distinguish complete and incomplete states with muted green and orange. The
tone should show what was done without suggesting assessment or pressure. Highlight
“回顾” in bottom navigation.

## Acceptance Criteria

Every Chinese label is fully visible and never overlaps. Layout density supports
one-handed mobile use. The four screens share the same color, type, spacing, card,
and icon treatment while the timer screen intentionally enters a focused dark mode.
