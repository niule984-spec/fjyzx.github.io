import { describe, expect, it } from '@ohos/hypium';
import { calculateTodayReview, localDayKey } from '../main/ets/data/ReviewCalculator';

export default function reviewCalculatorTest() {
  describe('today review calculator', () => {
    it('includes all ended records in actual focus time', 0, () => {
      const review = calculateTodayReview([
        { actualSeconds: 900, outcome: 'completed' },
        { actualSeconds: 300, outcome: 'unfinished' },
        { actualSeconds: 60, outcome: 'changed' }
      ]);
      expect(review.sessionCount).assertEqual(3);
      expect(review.actualMinutes).assertEqual(21);
      expect(review.completedCount).assertEqual(1);
      expect(review.unfinishedCount).assertEqual(1);
    });

    it('formats a local calendar day', 0, () => {
      expect(localDayKey(new Date(2026, 6, 14, 8, 0, 0))).assertEqual('2026-07-14');
    });
  });
}
