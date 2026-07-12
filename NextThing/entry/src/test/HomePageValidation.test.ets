import { describe, expect, it } from '@ohos/hypium';
import { validateTaskTitle } from '../main/ets/home/HomePageValidation';

export default function homePageValidationTest() {
  describe('home page task validation', () => {
    it('rejects an empty task after trimming', 0, () => {
      expect(validateTaskTitle('   ').isValid).assertFalse();
    });

    it('accepts a task and removes surrounding whitespace', 0, () => {
      const result = validateTaskTitle('  阅读计划书  ');
      expect(result.isValid).assertTrue();
      expect(result.taskTitle).assertEqual('阅读计划书');
    });
  });
}
