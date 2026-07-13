import { describe, expect, it } from '@ohos/hypium';
import {
  createFocusTimer,
  formatRemainingTime,
  pauseFocusTimer,
  refreshFocusTimer,
  resumeFocusTimer
} from '../main/ets/focus/FocusTimerEngine';

export default function focusTimerEngineTest() {
  describe('focus timer engine', () => {
    it('derives remaining seconds from the target end time', 0, () => {
      const timer = createFocusTimer(5, 1_000);
      expect(refreshFocusTimer(timer, 2_500).remainingSeconds).assertEqual(299);
    });

    it('keeps the remaining time stable while paused', 0, () => {
      const paused = pauseFocusTimer(createFocusTimer(5, 1_000), 61_000);
      expect(refreshFocusTimer(paused, 181_000).remainingSeconds).assertEqual(240);
      expect(paused.isRunning).assertFalse();
    });

    it('resumes with a fresh target timestamp', 0, () => {
      const paused = pauseFocusTimer(createFocusTimer(5, 1_000), 61_000);
      const resumed = resumeFocusTimer(paused, 200_000);
      expect(resumed.targetEndTime).assertEqual(440_000);
      expect(resumed.isRunning).assertTrue();
    });

    it('stops at zero and formats minutes and seconds', 0, () => {
      const ended = refreshFocusTimer(createFocusTimer(5, 1_000), 301_000);
      expect(ended.remainingSeconds).assertEqual(0);
      expect(ended.isRunning).assertFalse();
      expect(formatRemainingTime(65)).assertEqual('01:05');
    });
  });
}
