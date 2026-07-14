import { describe, expect, it } from '@ohos/hypium';
import { restoreFocusSession } from '../main/ets/focus/FocusSessionRecovery';

export default function focusSessionRecoveryTest() {
  describe('focus session recovery', () => {
    it('deducts elapsed time from a running session', 0, () => {
      const restored = restoreFocusSession({
        remainingSeconds: 300,
        targetEndTime: 1_000_000,
        isRunning: true
      }, 820_000);

      expect(restored.remainingSeconds).assertEqual(180);
      expect(restored.isRunning).assertTrue();
    });

    it('keeps a paused session at its stored remaining time', 0, () => {
      const restored = restoreFocusSession({
        remainingSeconds: 300,
        targetEndTime: 0,
        isRunning: false
      }, 820_000);

      expect(restored.remainingSeconds).assertEqual(300);
      expect(restored.isRunning).assertFalse();
    });

    it('ends a running session that expired while the app was closed', 0, () => {
      const restored = restoreFocusSession({
        remainingSeconds: 300,
        targetEndTime: 1_000_000,
        isRunning: true
      }, 1_020_000);

      expect(restored.remainingSeconds).assertEqual(0);
      expect(restored.isRunning).assertFalse();
    });

    it('preserves the original duration for restored focus accounting', 0, () => {
      const restored = restoreFocusSession({
        durationSeconds: 600,
        remainingSeconds: 180,
        targetEndTime: 1_000_000,
        isRunning: false
      }, 820_000);

      expect(restored.durationSeconds).assertEqual(600);
    });
  });
}
