import localUnitTest from './LocalUnit.test';
import focusSessionRecoveryTest from './FocusSessionRecovery.test';
import taskManagementTest from './TaskManagement.test';
import legacySessionMigrationTest from './LegacySessionMigration.test';

export default function testsuite() {
  localUnitTest();
  focusSessionRecoveryTest();
  taskManagementTest();
  legacySessionMigrationTest();
}
