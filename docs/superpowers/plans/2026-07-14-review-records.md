# 今日回顾记录列表实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 展示当天倒序专注记录，正确区分已完成、未完成、已放弃，且统计和重启持久化准确。

**Architecture:** `ReviewCalculator` 扩展为统计与状态标签的纯函数；现有 RDB 查询继续提供当天记录；`Index.reviewTab` 渲染摘要、空状态和倒序记录列表。

**Tech Stack:** HarmonyOS API 24、ArkTS、ArkUI、RDB、Hypium、Hvigor。

### Task 1: 统计与状态函数

**Files:** Modify `NextThing/entry/src/main/ets/data/PersistenceModels.ets`; modify `NextThing/entry/src/main/ets/data/ReviewCalculator.ets`; modify `NextThing/entry/src/test/ReviewCalculator.test.ets`.

- [ ] 写测试契约：completed、unfinished、changed 各一条时，分钟为实际秒数总和；完成、未完成、已放弃次数各为 1；`reviewStatusLabel('changed')` 返回“已放弃”。
- [ ] 运行 `hvigorw.bat --no-daemon tasks`，记录无可执行 Hypium runner。
- [ ] 给 `TodayReview` 增加 `abandonedCount`；统计中 `unfinished` 只计入未完成，`changed` 只计入已放弃；新增 `reviewStatusLabel` 和 `formatReviewTime`。
- [ ] 构建 `hvigorw.bat --no-daemon assembleApp -p product=default`，预期 `BUILD SUCCESSFUL`；提交 `feat: add review status summaries`。

### Task 2: 今日回顾时间线

**Files:** Modify `NextThing/entry/src/main/ets/pages/Index.ets`.

- [ ] 给页面增加 `@State reviewRecords: FocusRecord[] = []`，在 `loadTodayReview` 读取当天记录后按 `endedAt` 倒序写入该状态。
- [ ] 摘要区增加“已放弃次数”；保留总次数、总分钟、完成、未完成。
- [ ] 当记录为空时显示“今天还没有结束的专注记录”。有记录时用 `List/ForEach` 渲染任务、实际分钟、`formatReviewTime(endedAt)`、状态标签；使用记录 ID 作为稳定 key。
- [ ] 记录按最新结束时间在前；页面出现和切到今日回顾标签均调用 `loadTodayReview`。
- [ ] clean 后构建，预期 `BUILD SUCCESSFUL`；提交 `feat: show today review records`。

### Task 3: 模拟器验收和文档

**Files:** Modify `NextThing/README.md`.

- [ ] 安装最新 HAP 后依次创建 completed、unfinished、changed 记录；打开今日回顾核对三种标签、分钟、次数与时间倒序。
- [ ] 清空或使用新数据库验证空状态；杀掉并重启应用，确认记录仍在。
- [ ] README 只记录实际成功与未成功的验收结果；提交 `docs: record review timeline verification`。
