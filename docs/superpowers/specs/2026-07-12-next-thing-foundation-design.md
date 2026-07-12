# `下一件事` Foundation Design

## Goal

建立一个可重复、可验证的 HarmonyOS 开发基础，使项目能够在当前推荐的 DevEco Studio 与配套 SDK/API 上创建、编译、运行和提交一个最小 ArkTS 应用。此阶段不实现专注计时、数据存储或四个 MVP 页面。

## Scope

### Included

- 检查 Windows、磁盘空间、网络和开发者账号准备情况。
- 安装当前可用的 DevEco Studio 稳定版。
- 在 DevEco Studio 中安装与 IDE 配套的 HarmonyOS SDK/API，版本以安装器和官方文档当前推荐值为准，不在计划中写死一个可能过期的版本号。
- 创建 HarmonyOS Stage 模型、ArkTS 声明式 UI 的空项目。
- 在模拟器或鸿蒙真机上运行默认页面。
- 修改首页文本并重新构建，验证编辑、编译、部署链路。
- 初始化/确认 Git 仓库，建立 README，记录环境版本和运行步骤。
- 形成清晰的后续入口，下一阶段从首页“设置下一件事”开始。

### Excluded

- 任务输入、时长选择、倒计时、暂停/继续和完成状态。
- Preferences、RDB、后台时间恢复、通知和桌面卡片。
- 自定义视觉系统、复杂状态管理、第三方依赖和后端服务。
- 发布签名、应用市场上架和多设备协同；本阶段只验证开发/调试签名与本地运行。

## Recommended Approach

采用 DevEco Studio 图形化流程作为唯一主路径。它能直接管理 SDK、创建模板、连接模拟器/真机、显示构建错误并生成与 IDE 兼容的项目文件。命令行只用于 Git、目录检查和 README 编辑，不手工重建 HarmonyOS 工程配置。

项目使用 Stage 模型和 ArkTS/ArkUI 声明式 UI。SDK/API 版本不固定为历史编号，而是记录本机 DevEco 当前稳定版本及其配套 API；这样可以避免计划文件在工具升级后误导执行者。

## Project Shape After This Phase

```text
NextThing/
├── AppScope/
├── entry/
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/EntryAbility.ets
│       │   └── pages/Index.ets
│       └── resources/
├── build-profile.json5
├── hvigorfile.ts
├── hvigorw
├── oh-package.json5
└── README.md
```

实际模板目录和文件名以当前 DevEco Studio 生成结果为准；计划只要求验证关键职责，不要求为了匹配示例树而手工移动模板文件。

## Validation Flow

1. DevEco Studio 能打开项目且没有缺失 SDK/API 的错误。
2. 默认应用能在模拟器或真机启动并显示页面。
3. 修改页面文本后，重新运行能看到修改后的文本。
4. Git 状态只包含预期项目文件，且至少有一次可追溯提交。
5. README 能让另一位开发者知道使用的 IDE、API、设备和启动方式。

## Failure Handling

- 如果安装器找不到匹配 SDK，先使用 DevEco 的 SDK 管理器安装 IDE 建议的配套版本，不手动混用来源不明的 SDK。
- 如果模拟器启动失败，先记录错误并改用已授权的鸿蒙真机验证；设备验证失败时再回到签名、USB 调试和驱动检查。
- 如果构建失败，保留首次错误日志，确认项目模板和 SDK 版本后再修复，不直接复制网上的旧配置覆盖模板。
- 如果电脑不满足当前 DevEco 版本要求，记录实际系统信息，选择官方仍支持的 IDE 版本，并在 README 标明版本组合。

## Follow-up Boundary

完成本规格后，下一份实施计划只处理环境与项目骨架。其完成条件满足后，另起一个设计/计划阶段实现首页，而不是在同一批任务中提前加入完整 MVP。
