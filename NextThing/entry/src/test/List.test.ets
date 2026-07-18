import localUnitTest from './LocalUnit.test';
import focusSessionRecoveryTest from './FocusSessionRecovery.test';
import taskManagementTest from './TaskManagement.test';
import legacySessionMigrationTest from './LegacySessionMigration.test';
import notificationPermissionTest from './NotificationPermission.test';

export default function testsuite() {
  localUnitTest();
  focusSessionRecoveryTest();
  taskManagementTest();
  legacySessionMigrationTest();
  notificationPermissionTest();
}
