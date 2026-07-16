import { describe, expect, it } from '@ohos/hypium';
import { normalizeTaskTitle } from '../main/ets/data/NextThingRepository';

export default function repositoryTest() {
  describe('repository helpers', () => {
    it('rejects blank inbox task titles', 0, () => {
      expect(normalizeTaskTitle('   ')).assertEqual('');
    });

    it('trims a saved next task title', 0, () => {
      expect(normalizeTaskTitle('  整理资料  ')).assertEqual('整理资料');
    });
  });
}
