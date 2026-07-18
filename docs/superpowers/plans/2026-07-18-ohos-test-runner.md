# Device-Side Hypium Test Runner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Execute the existing pure ArkTS logic suites on the API 24 simulator through the existing `ohosTest` Hypium module.

**Architecture:** The test module's registry invokes the source registry, keeping one authoritative list of pure test suites. The generated `ohosTest` HAP is built, installed alongside the app, and executed through the HarmonyOS test command. Repository tests that require an RDB context remain out of this shared registry.

**Tech Stack:** HarmonyOS API 24, ArkTS, Hypium, Hvigor, HDC.

---

### Task 1: Register Pure Suites in the Device Test Module

**Files:**
- Modify: `NextThing/entry/src/ohosTest/ets/test/List.test.ets`
- Test: `NextThing/entry/src/test/List.test.ets`

- [ ] **Step 1: Preserve the existing device smoke suite and import the source registry**

Replace `NextThing/entry/src/ohosTest/ets/test/List.test.ets` with:

```ts
import abilityTest from './Ability.test';
import sourceTestSuite from '../../../test/List.test';

export default function testsuite() {
  abilityTest();
  sourceTestSuite();
}
```

- [ ] **Step 2: Build the device test target**

Run:

```powershell
$hvigor = 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
& $hvigor --mode module -p module=entry@ohosTest assembleHap
```

Expected: ArkTS compiles `Ability.test.ets`, the source registry, and its registered pure suites without an unresolved import.

- [ ] **Step 3: Commit the test registry bridge**

```powershell
git add NextThing/entry/src/ohosTest/ets/test/List.test.ets
git commit -m 'test: run pure suites through ohosTest'
```

### Task 2: Run the Test HAP on the API 24 Simulator

**Files:**
- Verify: `NextThing/entry/build/`

- [ ] **Step 1: Locate the generated test HAP**

Run:

```powershell
Get-ChildItem -Recurse -Filter '*ohosTest*.hap' NextThing\entry\build
```

Expected: one signed or unsigned HAP produced from the `ohosTest` target.

- [ ] **Step 2: Install and execute the test module**

Run:

```powershell
hdc -t 127.0.0.1:5555 install -r <test-hap-path>
hdc -t 127.0.0.1:5555 shell aa test -b com.zhaoxin.nextthing -m entry_test
```

Expected: Hypium reports the smoke test and the source-registry suites as passing. If the installed API 24 image does not expose `aa test`, record the exact command error and retain the built HAP as the verification artifact.

- [ ] **Step 3: Commit only if test-runner support files change**

```powershell
git status --short
```

Expected: no additional source changes are required unless the build reveals an SDK-specific test-module configuration requirement.

### Task 3: Document Repeatable Verification

**Files:**
- Modify: `NextThing/README.md`

- [ ] **Step 1: Add the verified build, install, and execution commands**

Append a short `Device-side Hypium verification` section containing the exact Hvigor target, generated HAP path, simulator target, and observed test outcome. If execution is unavailable, state the platform limitation and command error instead of claiming a passing suite.

- [ ] **Step 2: Run the application build after the test build**

Run:

```powershell
& $hvigor clean
& $hvigor assembleApp
```

Expected: `BUILD SUCCESSFUL`; existing application packaging remains intact.

- [ ] **Step 3: Commit verification documentation**

```powershell
git add NextThing/README.md
git commit -m 'docs: record device-side Hypium verification'
```

### Task 4: Final Integration

**Files:**
- Verify: `NextThing/entry/src/ohosTest/ets/test/List.test.ets`
- Verify: `NextThing/README.md`

- [ ] **Step 1: Inspect the branch state**

Run:

```powershell
git status --short --branch
git log main..HEAD --oneline
```

Expected: only the registry bridge and verification documentation commits are ahead of `main`.

- [ ] **Step 2: Merge and push after review**

```powershell
git -C 'C:\Users\zhaoxin\OneDrive\文档\New project 2' merge --no-ff codex/ohos-test-runner
git -C 'C:\Users\zhaoxin\OneDrive\文档\New project 2' push origin main
```

Expected: `main` contains the device test entry and documentation; no force-push is used.
