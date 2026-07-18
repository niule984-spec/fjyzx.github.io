import { describe, expect, it } from '@ohos/hypium';
import { createFocusSession } from '../main/ets/focus/FocusSession';
import { pauseFocusTimer } from '../main/ets/focus/FocusTimerEngine';
import { toActiveSession } from '../main/ets/focus/LegacySessionMigration';

export default function legacySessionMigrationTest() {
  describe('legacy focus session migration', () => {
    it('preserves a running legacy session for RDB recovery', 0, () => {
      const legacy = createFocusSession('迁移任务', 25, 1_000);
      const active = toActiveSession(legacy);
      expect(active.taskName).assertEqual('迁移任务');
      expect(active.remainingSeconds).assertEqual(1_500);
      expect(active.targetEndTime).assertEqual(1_501_000);
      expect(active.isRunning).assertTrue();
      expect(active.pageState).assertEqual('running');
      expect(active.pendingRecordId).assertEqual(0);
    });

    it('preserves paused time without restarting the timer', 0, () => {
      const legacy = createFocusSession('暂停迁移', 5, 0);
      legacy.timer = pauseFocusTimer(legacy.timer, 60_000);
      const active = toActiveSession(legacy);
      expect(active.isRunning).assertFalse();
      expect(active.remainingSeconds).assertEqual(240);
      expect(active.pageState).assertEqual('paused');
    });
  });
}
