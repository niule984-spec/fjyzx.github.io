# Device-Side Hypium Test Runner Design

## Goal

Make the existing pure ArkTS logic tests executable on the API 24 simulator through the project's existing `ohosTest` target.

## Scope

The device-side entry point will invoke the test suites exported by `entry/src/test/List.test.ets`. It will not import repository tests that require a live RDB context, add a new testing dependency, or change application behavior.

## Architecture

`entry/src/ohosTest/ets/test/Ability.test.ets` becomes the single Hypium entry point. It imports the existing suite registry and invokes it from its default export alongside the retained smoke assertion. The `ohosTest` target packages this entry point for device execution.

The source test registry remains authoritative: new pure tests continue to be registered in `entry/src/test/List.test.ets` and are automatically included in device execution. Tests that need a database or UI context stay outside that registry until they provide their own environment setup.

## Verification

Build the `ohosTest` target with Hvigor, install the generated test HAP on the API 24 simulator, and run the registered test suite through the HarmonyOS test command. A successful run reports the existing focus, migration, notification-permission, validation, and task-management tests without compilation errors.

## Failure Handling

If device-side execution cannot discover the test HAP or command, retain the built test artifact and record the exact unavailable tool command in the README. The application build remains a separate verification step.
