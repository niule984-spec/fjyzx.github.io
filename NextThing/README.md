# 下一件事（NextThing）

## 当前阶段

本阶段只完成 HarmonyOS/ArkTS 基础工程：开发环境确认、空项目骨架、构建、安装和启动验证，以及 Git/README 基础记录。首页业务、计时器、本地存储和 MVP 页面尚未实现。

## 已确认环境

- 操作系统：Windows 10 Pro for Workstations 2009 x64
- DevEco Studio：6.1.1.290 / DS-243.24978.46.36.611290
- HarmonyOS SDK：API 24 / 6.1.1.125 Release
- 目标设备：HarmonyPhone_API24 / Pura 90 Pro API24 x86_64 4GB
- 设备连接：`hdc 127.0.0.1:5555`
- Git：2.54.0
- Hvigor：6.24.3
- ohpm：6.1.2.285

DevEco Studio 安装器原始文件名不可追溯，因此以上版本以已安装产品元数据为准。

工作区使用 ASCII 路径 `C:\Users\zhaoxin\codex-worktrees\next-thing-foundation`。Hvigor 会拒绝包含中文字符的工程路径，因而项目从中文路径迁移到此目录。

## 运行步骤

### DevEco Studio

1. 使用 DevEco Studio 打开 `NextThing` 目录。
2. 等待 Sync/Index 完成，并确认已安装 API 24 SDK。
3. 启动 `HarmonyPhone_API24` 模拟器，或连接可用的 API 24 真机。
4. 在设备选择器中确认目标为 `Pura 90 Pro API24 x86_64 4GB`，然后运行 `entry` 模块。
5. 应用启动后，首页应显示基础工程成功文本。

### Hvigor 命令行

在 `NextThing` 目录执行以下命令（Windows PowerShell）：

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --cwd (Get-Location) clean
& $hvigor --cwd (Get-Location) assembleHap
```

构建完成后，可使用 DevEco Studio 的 Run/Deploy 流程安装到已连接设备。确认设备连接：

```powershell
hdc list targets
```

Task 5 已完成 build/install/start 验证。Task 6 已将首页文本设置为 `下一件事基础工程运行成功`；由于 UI Automation 限制，GUI close/reopen 尚未完成，但 CLI clean/build/install/start 已成功，仍需人工执行一次 smoke test。

## 下一步

1. 在模拟器或真机上人工完成 close/reopen smoke test。
2. 按项目计划实现“现在做什么”首页。
3. 再加入任务数据、本地存储、计时状态和其余 MVP 页面。

不要将账号、私钥、签名文件或其他凭据提交到仓库。

## Foundation 验收记录（2026-07-12）

- CLI `clean`、`assembleApp`、`hdc install -r` 和 `aa start` 验证通过。
- `com.zhaoxin.nextthing` 的 `EntryAbility` 已确认处于 `FOREGROUND`。
- DevEco Studio GUI close/reopen 未由 UI Automation 完成，保留为人工 smoke test；本记录不声称 GUI 已通过。
- 本阶段未加入计时器、任务列表、Preferences、RDB、通知、后端或额外依赖。

## 本地数据与今日回顾验收记录（2026-07-14）

- 在 ASCII 工作树 `C:\Users\zhaoxin\codex-worktrees\next-thing-persistence-review\NextThing` 执行 `hvigor --no-daemon clean` 和 `hvigor --no-daemon assembleApp -p product=default`，两条命令均以 `BUILD SUCCESSFUL` 结束。
- 本次构建产物为 `entry\build\default\outputs\default\entry-default-unsigned.hap`。
- 尝试连接 API 24 模拟器前执行 `hdc list targets`，命令返回为空；因此本次未执行 HAP 安装、应用启动或界面交互验收。
- 本次记录不宣称已在模拟器验证任务保存、会话恢复、清空脑袋或今日回顾的运行时行为。

## 专注计时验收记录（2026-07-13）

- 首页已将任务名称和 5/10/25 分钟时长传递给专注计时页。
- 计时器使用目标结束时间推导剩余秒数，暂停时保持剩余时间，继续时重新计算目标结束时间。
- 已在 API 24 模拟器验证倒计时格式、进度条、暂停/继续、提前结束、自然归零结果页，以及完成后返回首页。
- 本阶段不保存完成结果；Preferences、RDB 和历史记录留待后续阶段。
