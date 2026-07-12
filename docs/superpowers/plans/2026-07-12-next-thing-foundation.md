# `下一件事` Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在当前推荐的 DevEco Studio 与配套 HarmonyOS SDK/API 上建立可运行、可提交、可复现的 `下一件事` ArkTS 项目骨架。

**Architecture:** 使用 DevEco Studio 创建 HarmonyOS Stage 模型项目，采用 ArkTS + ArkUI 声明式 UI 模板。IDE 负责模板、SDK、构建和调试配置；Git 与 README 负责版本记录和环境复现。本计划不实现业务页面或本地数据功能。

**Tech Stack:** DevEco Studio 当前稳定版、其 SDK Manager 提供的配套 HarmonyOS SDK/API、ArkTS、ArkUI、HarmonyOS Stage 模型、Git、PowerShell。

---

### Task 1: Confirm the Windows development machine

**Files:**
- Create: `README.md` (later in Task 7; no file change in this task)
- Test: PowerShell command output captured in the task notes

- [ ] **Step 1: Check operating system and architecture**

Run in PowerShell:

```powershell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsArchitecture
```

Expected: a supported Windows edition and `64-bit` architecture. Record the exact output in the future `README.md`.

- [ ] **Step 2: Check available disk space**

Run:

```powershell
Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free
```

Expected: the installation drive has enough free space for DevEco Studio, SDK images, emulator images, and build caches. If the drive is low, free space before installing; do not place SDK files in a temporary directory.

- [ ] **Step 3: Check Git**

Run:

```powershell
git --version
git config --get user.name
git config --get user.email
```

Expected: Git is installed. If the two config values are empty, configure the user’s own name and email before making project commits.

- [ ] **Step 4: Record the baseline**

Copy the OS, architecture, free-space, and Git results into a temporary note. The exact values will be recorded in `README.md` after the project exists.

### Task 2: Install DevEco Studio and the matched SDK

**Files:**
- Modify: `README.md` in Task 7 with installed versions
- Test: DevEco Studio startup and SDK Manager state

- [ ] **Step 1: Download the current stable DevEco Studio**

Open the official DevEco Studio download page at https://cn.devecostudio.huawei.com/ and choose the Windows installer that is marked stable and compatible with the current machine. Do not use a repackaged installer or a version copied from an unrelated tutorial.

Expected: the installer filename and version are recorded before installation.

- [ ] **Step 2: Install DevEco Studio**

Run the installer with the default IDE installation location unless the machine has a documented alternative. Allow the installer to create the Start Menu shortcut and file associations. Launch DevEco Studio after installation.

Expected: the IDE opens without an immediate missing-runtime error.

- [ ] **Step 3: Open SDK Manager**

In DevEco Studio, open the SDK Manager from the welcome screen or the IDE settings/tools menu. Use the HarmonyOS application development documentation at https://developer.huawei.com/consumer/cn/develop/ as the official reference, then select the HarmonyOS SDK/API components recommended by the currently installed DevEco Studio version.

Expected: the selected SDK components show as installed and the IDE reports no unresolved SDK path.

- [ ] **Step 4: Record the actual toolchain versions**

In the IDE, copy the DevEco Studio version, SDK/API version, Node/HVIGOR or build-tool versions shown by the project/SDK settings. Do not substitute a version number from the source plan.

Expected: a complete version tuple is available for `README.md`.

### Task 3: Prepare a debug device

**Files:**
- Modify: `README.md` in Task 7 with device choice and model
- Test: device appears as available to DevEco Studio

- [ ] **Step 1: Choose one validation target**

Choose exactly one for the first run:

```text
Simulator: DevEco Studio emulator configured with a supported HarmonyOS image
Device: an authorized HarmonyOS phone with developer/USB debugging enabled
```

Record the choice and model/image name.

- [ ] **Step 2: Configure the simulator if using one**

Open the Device Manager, create or select a virtual HarmonyOS device whose system image matches the installed SDK/API, and start it. Wait until the virtual device reaches its home screen before building the project.

Expected: the simulator is running and visible in DevEco Studio’s device selector.

- [ ] **Step 3: Configure the phone if using a real device**

Enable the phone’s developer mode and USB debugging according to the device’s system prompts. Connect it with a data-capable USB cable, accept the authorization prompt, and select it in DevEco Studio.

Expected: the device is authorized, not merely charging, and appears in the run-target list.

- [ ] **Step 4: Stop on an unavailable device**

If neither target appears, capture the exact device/driver/signing error and resolve that before creating application code. Do not mark the baseline as passing while the project has not been deployed anywhere.

### Task 4: Create the ArkTS Stage project

**Files:**
- Create: the DevEco-generated project directory selected by the user, named `NextThing`
- Test: DevEco project sync/indexing completes without missing SDK errors

- [ ] **Step 1: Start a new project**

In DevEco Studio choose the option to create a new application/project. Select the minimal phone application template that uses ArkTS and the Stage model. Keep the template’s default module structure.

Expected: the project wizard shows ArkTS source support and Stage application configuration.

- [ ] **Step 2: Set project identity**

Use these values unless the wizard requires a package-safe variant:

```text
Project name: NextThing
Bundle/package identifier: `com.zhaoxin.nextthing` (change only if the wizard rejects it)
Model: Stage
Language: ArkTS
Device: phone
```

Do not add optional libraries, network permissions, database modules, or third-party dependencies.

- [ ] **Step 3: Finish creation and wait for sync**

Choose a stable project directory outside temporary/download folders. Wait for indexing and dependency synchronization to finish before opening source files.

Expected: the project opens with no unresolved SDK/API marker and the build tool status is idle.

- [ ] **Step 4: Inspect the generated structure**

Confirm the generated project contains the application scope, `entry` module, `EntryAbility.ets`, the default page, resources, build profile, and build wrapper/configuration files. Do not rename or move template files during this baseline task.

### Task 5: Build and run the untouched template

**Files:**
- Modify: none
- Test: DevEco build/run action on the selected simulator or device

- [ ] **Step 1: Select the target**

Choose the simulator or authorized phone from DevEco Studio’s device selector.

Expected: the target is selected without a signing or compatibility warning that blocks deployment.

- [ ] **Step 2: Build the untouched template**

Run the IDE’s build action. Wait for the build result instead of starting a second build in parallel.

Expected: build succeeds with zero compilation errors.

- [ ] **Step 3: Run the application**

Run the application using the IDE run action.

Expected: the default application launches on the selected target and displays its generated page.

- [ ] **Step 4: Capture the baseline result**

Record the successful build/run date, target name, and any non-blocking warning. If the run fails, preserve the first error text and stop this task until the matching SDK, device authorization, or debug signing issue is corrected.

### Task 6: Verify the edit-build-run loop

**Files:**
- Modify: the DevEco-generated default page file only
- Test: second build/run showing modified text

- [ ] **Step 1: Locate the generated default page**

Open the page file generated by the template, commonly under `entry/src/main/ets/pages/`. Use the file that is actually referenced by the generated ability/router; do not create a parallel page.

- [ ] **Step 2: Make one visible text change**

Change one existing visible label to:

```text
下一件事基础工程运行成功
```

Keep the change limited to text so this task tests the toolchain rather than UI design.

- [ ] **Step 3: Build and run again**

Run the same build and deployment actions as Task 5.

Expected: the build succeeds and the target displays the new Chinese label.

- [ ] **Step 4: Reopen the project and run once more**

Close and reopen the project in DevEco Studio, wait for indexing, then run again.

Expected: the changed label remains and the project does not depend on an unsaved editor state.

### Task 7: Add project documentation and Git history

**Files:**
- Create: `README.md`
- Modify: generated project files only through the validated text edit from Task 6
- Test: Git status and clean checkout metadata

- [ ] **Step 1: Write the README**

Create `README.md` with this exact structure. Replace each bracketed field with the exact value recorded in Tasks 1–3; do not leave a bracketed field in the committed file:

```markdown
# 下一件事

## 当前阶段

已完成 DevEco Studio + HarmonyOS SDK/API + ArkTS Stage 空项目运行验证。
本阶段不包含专注计时、任务存储或完整 MVP 页面。

## 环境

- OS: [Windows edition and version]
- Architecture: [x64 or actual architecture]
- DevEco Studio: [installed version]
- HarmonyOS SDK/API: [installed version]
- Target: [simulator image or phone model]
- Git: [git version]

## 运行

1. 使用对应版本 DevEco Studio 打开项目。
2. 确认配套 HarmonyOS SDK/API 已安装。
3. 启动记录中的模拟器或连接已授权真机。
4. 选择设备并运行 `entry` 模块。

## 下一步

从首页“设置下一件事”开始设计和实现 MVP 功能。
```

- [ ] **Step 2: Review tracked and ignored files**

Run from the project root:

```powershell
git status --short --ignored
git diff --check
```

Expected: generated build/cache folders are ignored or excluded by the project template, `README.md` and the intended page edit are visible changes, and `git diff --check` emits no whitespace errors.

- [ ] **Step 3: Create the first project commit**

After verifying the README and the successful edit-build-run result, run:

```powershell
git add README.md entry
git commit -m "chore: bootstrap NextThing HarmonyOS project"
```

Expected: one commit records the foundation project and the verified label change. Do not commit SDK installers, emulator images, secrets, signing keys, or build output.

- [ ] **Step 4: Verify the commit**

Run:

```powershell
git log -1 --oneline
git status --short
```

Expected: the latest commit has the requested message and the working tree is clean except for files intentionally excluded by ignore rules.

### Task 8: Foundation acceptance check

**Files:**
- Read: `README.md`
- Test: full foundation acceptance checklist

- [ ] **Step 1: Reopen from the committed state**

Close and reopen the committed project in DevEco Studio, wait for indexing, and confirm the selected SDK/API is still resolved.

- [ ] **Step 2: Run from the committed state**

Run the app on the same target used in Tasks 5 and 6.

Expected: the app starts and still displays `下一件事基础工程运行成功`.

- [ ] **Step 3: Confirm the handoff boundary**

Verify that no timer, task list, Preferences store, RDB table, notification, backend, or extra dependency was added. The next design task begins with the homepage requirements from the source plan.

- [ ] **Step 4: Record completion**

Append a short dated entry to `README.md` stating that the foundation acceptance check passed, then commit it:

```powershell
git add README.md
git commit -m "docs: record foundation verification"
```

Expected: the repository contains a reproducible foundation and an explicit handoff to the next feature phase.

---

## Execution Notes

- Run the plan from `C:\Users\zhaoxin\OneDrive\文档\New project 2\.worktrees\next-thing-foundation` on branch `codex/next-thing-foundation`.
- Use the DevEco-generated files and current IDE labels as the source of truth when names differ from this plan.
- Never paste credentials, private keys, or signing material into `README.md` or Git.
- If a task fails, preserve the first error message and resolve the environment mismatch before continuing; do not mask it by deleting the project or copying old configuration files.
