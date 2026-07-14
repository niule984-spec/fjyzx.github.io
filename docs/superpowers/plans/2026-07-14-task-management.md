# 任务管理实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 在收件箱实现搜索、编辑名称和时长、四种排序、手动顺序持久化，并预填到首页。

**Architecture:** `TaskManagement` 提供搜索、排序、分钟验证；RDB 仓储迁移任务字段与保存顺序；`Index` 负责界面状态和中文反馈。

### Task 1: 模型和纯函数

**Files:** Create `NextThing/entry/src/main/ets/inbox/TaskManagement.ets`; modify `NextThing/entry/src/main/ets/data/PersistenceModels.ets`; create `NextThing/entry/src/test/TaskManagement.test.ets`; modify `NextThing/entry/src/test/List.test.ets`.

- [ ] 写 Hypium 契约：`validatePlannedMinutes('0')` 返回 `undefined`，`validatePlannedMinutes('30')` 返回 `30`；搜索不区分大小写；名称排序稳定。
- [ ] 运行 `hvigorw.bat --no-daemon tasks`，记录本项目没有本地 Hypium runner。
- [ ] 新增 `InboxSortMode = 'newest' | 'oldest' | 'title' | 'manual'`；给 `InboxTask` 增加 `plannedMinutes` 与 `sortOrder`；实现正整数分钟验证、标题包含搜索、四种排序。
- [ ] 运行 `hvigorw.bat --no-daemon assembleApp -p product=default`，预期 `BUILD SUCCESSFUL`，提交 `feat: add task management helpers`。

### Task 2: RDB 迁移和仓储

**Files:** Modify `NextThing/entry/src/main/ets/data/NextThingRepository.ets`; modify `NextThing/entry/src/test/NextThingRepository.test.ets`.

- [ ] 写契约：结构化 `next_task` 读取时得到保存分钟数；旧纯文本 `next_task` 回退为 25 分钟。
- [ ] 通过 `PRAGMA table_info(inbox_tasks)` 迁移 `planned_minutes INTEGER NOT NULL DEFAULT 25` 与 `sort_order INTEGER NOT NULL DEFAULT 0`；把既有 `sort_order=0` 更新为 `id`。
- [ ] 扩展 `addInboxTask(title, plannedMinutes)`、`updateInboxTask(id, title, plannedMinutes)`、`updateManualOrder(tasks)`；读列表带新字段；手动顺序在事务中保存。
- [ ] 将 `next_task` 存为名称和分钟数 JSON；旧文本兼容解析为 25 分钟。
- [ ] clean 后构建，预期 `BUILD SUCCESSFUL`，提交 `feat: persist task details and order`。

### Task 3: 收件箱界面

**Files:** Modify `NextThing/entry/src/main/ets/pages/Index.ets`.

- [ ] 增加 `inboxSearch`、`inboxSortMode`、`editingTaskId`、`editingTitle`、`editingMinutes` 状态。
- [ ] 顶部新增搜索输入与排序选择；显示内容使用搜索再排序的任务数组。
- [ ] 每条任务显示分钟数及“设为下一件事、编辑、删除”。手动排序模式显示上移、下移图标，边界禁用。
- [ ] 展开单项编辑区：名称输入、5/10/25 快捷选择、自定义分钟输入、保存、取消。名称为空或分钟非正整数显示中文反馈；写入失败保持编辑区。
- [ ] 设为下一件事时保存名称与时长、切换现在标签并预填，绝不自动开始。
- [ ] clean 后构建，预期 `BUILD SUCCESSFUL`，提交 `feat: add inbox task management UI`。

### Task 4: 集中验收

**Files:** Modify `NextThing/README.md`.

- [ ] 连接 API 24 模拟器后 clean、assemble、安装 HAP、启动 EntryAbility。
- [ ] 集中验证：新增、搜索、两种编辑时长、四排序、重启后顺序、首页预填；并验证已完成的会话恢复、专注记录、今日回顾。
- [ ] README 只记录实际验证结果；设备未连接则明确标记运行时验收未完成。提交 `docs: record task management verification`。
