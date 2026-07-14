import localUnitTest from './LocalUnit.test';
import focusSessionRecoveryTest from './FocusSessionRecovery.test';
import taskManagementTest from './TaskManagement.test';

export default function testsuite() {
  localUnitTest();
  focusSessionRecoveryTest();
  taskManagementTest();
}
