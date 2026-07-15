import { describe, expect, it } from '@ohos/hypium';
import {
  createFocusSession,
  decodeFocusSession,
  encodeFocusSession,
  restoreFocusSession
} from '../main/ets/focus/FocusSession';
import { pauseFocusTimer } from '../main/ets/focus/FocusTimerEngine';

export default function focusSessionTest() {
  describe('focus session', () => {
    it('restores a running session from its absolute target timestamp', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 1_000);
      const restored = restoreFocusSession(session, 2_500);
      expect(restored.timer.remainingSeconds).assertEqual(299);
      expect(restored.pageState).assertEqual('running');
    });

    it('keeps a paused session stable after restart', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 1_000);
      session.timer = pauseFocusTimer(session.timer, 61_000);
      const restored = restoreFocusSession(session, 181_000);
      expect(restored.timer.remainingSeconds).assertEqual(240);
      expect(restored.timer.isRunning).assertFalse();
      expect(restored.pageState).assertEqual('running');
    });

    it('turns an expired running session into a result session', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 1_000);
      const restored = restoreFocusSession(session, 301_000);
      expect(restored.timer.remainingSeconds).assertEqual(0);
      expect(restored.pageState).assertEqual('result');
    });

    it('keeps an early-ended result session in the result state', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 1_000);
      session.timer = pauseFocusTimer(session.timer, 61_000);
      session.pageState = 'result';
      const restored = restoreFocusSession(session, 181_000);
      expect(restored.timer.remainingSeconds).assertEqual(240);
      expect(restored.pageState).assertEqual('result');
    });

    it('rejects malformed and structurally invalid session data', 0, () => {
      expect(decodeFocusSession('not-json') === null).assertTrue();
      expect(decodeFocusSession('{"taskName":"","durationMinutes":5}') === null).assertTrue();
    });

    it('round-trips a valid focus session', 0, () => {
      const session = createFocusSession('阅读计划书', 25, 1_000);
      const decoded = decodeFocusSession(encodeFocusSession(session));
      expect(decoded === null).assertFalse();
      expect(decoded?.taskName).assertEqual('阅读计划书');
      expect(decoded?.timer.targetEndTime).assertEqual(1_501_000);
    });
  });
}
