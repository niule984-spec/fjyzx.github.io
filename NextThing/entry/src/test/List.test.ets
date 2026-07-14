import localUnitTest from './LocalUnit.test';
import focusSessionRecoveryTest from './FocusSessionRecovery.test';

export default function testsuite() {
  localUnitTest();
  focusSessionRecoveryTest();
}
