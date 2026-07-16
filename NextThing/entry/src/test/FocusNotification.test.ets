import { describe, expect, it } from '@ohos/hypium';
import { createFocusSession } from '../main/ets/focus/FocusSession';
import { pauseFocusTimer } from '../main/ets/focus/FocusTimerEngine';
import { createFocusNotificationPresentation } from '../main/ets/focus/FocusNotification';

export default function focusNotificationTest() {
  describe('focus notification presentation', () => {
    it('renders an end time for a running focus session', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 0);
      const presentation = createFocusNotificationPresentation(session);
      expect(presentation === null).assertFalse();
      expect(presentation?.title).assertEqual('正在专注');
      expect(presentation?.text).assertEqual('阅读计划书 · 专注至 00:05');
      expect(presentation?.isCountDown).assertTrue();
    });

    it('renders stable remaining time for a paused focus session', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 0);
      session.timer = pauseFocusTimer(session.timer, 60_000);
      const presentation = createFocusNotificationPresentation(session);
      expect(presentation?.title).assertEqual('专注已暂停');
      expect(presentation?.text).assertEqual('阅读计划书 · 剩余 04:00');
      expect(presentation?.isCountDown).assertFalse();
    });

    it('does not create a notification for a result session', 0, () => {
      const session = createFocusSession('阅读计划书', 5, 0);
      session.pageState = 'result';
      expect(createFocusNotificationPresentation(session) === null).assertTrue();
    });
  });
}
