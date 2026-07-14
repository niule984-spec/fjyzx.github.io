# 清空脑袋全局滚动实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 让清空脑袋页面搜索置顶，并由单一全局纵向滚动容器承载全部内容。

**Architecture:** 仅修改 `Index.inboxTab` 的 ArkUI 布局树：外层 `Scroll` 包裹 `Column`，任务项使用普通 `ForEach`，不再使用独立可滚动 `List`。

**Tech Stack:** ArkTS、ArkUI、Hvigor、HarmonyOS API 24。

### Task 1: 调整布局与验收

**Files:** Modify `NextThing/entry/src/main/ets/pages/Index.ets`; modify `NextThing/README.md`.

- [ ] 将 `inboxTab` 根 `Column` 替换为 `Scroll` 内的 `Column`，设置宽度 100%、顶部对齐和现有内边距。
- [ ] 把搜索 `TextInput` 移至内容区第一项；其后保留新增任务、时长、排序、反馈与任务列表。
- [ ] 用普通 `Column/ForEach` 替换现有任务 `List`，删除 `layoutWeight(1)`，保留任务稳定 ID key 和所有操作。
- [ ] 执行 `hvigorw.bat --no-daemon clean` 和 `hvigorw.bat --no-daemon assembleApp -p product=default`，预期 `BUILD SUCCESSFUL`。
- [ ] 在 API 24 模拟器验证搜索位于页面顶部、任务很多时整页可滚动、任务操作仍可点击；README 只记录实际结果。
