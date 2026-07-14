import { describe, expect, it } from '@ohos/hypium';
import { restoreFocusSession } from '../main/ets/focus/FocusSessionRecovery';
import { needsPendingRecord } from '../main/ets/focus/FocusResultPersistence';
import { canFinishResult, shouldPersistActiveSession } from '../main/ets/focus/FocusPersistenceGuards';
import { parseActiveSession } from '../main/ets/data/NextThingRepository';

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

    it('retries an interrupted result record creation without returning to running', 0, () => {
      expect(needsPendingRecord({
        taskName: '整理资料',
        durationMinutes: 5,
        remainingSeconds: 0,
        targetEndTime: 0,
        isRunning: false,
        pageState: 'result',
        pendingRecordId: 0,
        resultKey: 'result-1'
      })).assertTrue();
    });

    it('does not create another record after the pending record id is saved', 0, () => {
      expect(needsPendingRecord({
        taskName: '整理资料',
        durationMinutes: 5,
        remainingSeconds: 0,
        targetEndTime: 0,
        isRunning: false,
        pageState: 'result',
        pendingRecordId: 42,
        resultKey: 'result-1'
      })).assertFalse();
    });

    it('does not write an active session after its result was confirmed', 0, () => {
      expect(shouldPersistActiveSession(true)).assertFalse();
      expect(shouldPersistActiveSession(false)).assertTrue();
    });

    it('allows a result choice only once after a pending record is ready', 0, () => {
      expect(canFinishResult(42, false)).assertTrue();
      expect(canFinishResult(42, true)).assertFalse();
      expect(canFinishResult(0, false)).assertFalse();
    });

    it('ignores corrupted active session data', 0, () => {
      expect(parseActiveSession('{broken')).assertEqual(undefined);
    });

    it('accepts a complete active session with valid runtime values', 0, () => {
      const session = parseActiveSession('{"taskName":"整理资料","durationMinutes":5,"remainingSeconds":180,"targetEndTime":1000000,"isRunning":true,"pageState":"running","pendingRecordId":0,"resultKey":""}');
      expect(session === undefined).assertFalse();
    });

    it('rejects invalid active session field types, ranges, and page state', 0, () => {
      expect(parseActiveSession('{"taskName":42,"durationMinutes":5,"remainingSeconds":180,"targetEndTime":0,"isRunning":false,"pageState":"paused","pendingRecordId":0,"resultKey":""}')).assertEqual(undefined);
      expect(parseActiveSession('{"taskName":"整理资料","durationMinutes":5,"remainingSeconds":-1,"targetEndTime":0,"isRunning":false,"pageState":"paused","pendingRecordId":0,"resultKey":""}')).assertEqual(undefined);
      expect(parseActiveSession('{"taskName":"整理资料","durationMinutes":5,"remainingSeconds":180,"targetEndTime":0,"isRunning":false,"pageState":"invalid","pendingRecordId":0,"resultKey":""}')).assertEqual(undefined);
    });
  });
}
