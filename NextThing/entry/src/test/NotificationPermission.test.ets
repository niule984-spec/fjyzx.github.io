import { describe, expect, it } from '@ohos/hypium';
import { ensureNotificationPermission } from '../main/ets/focus/NotificationPermission';

export default function notificationPermissionTest() {
  describe('notification permission', () => {
    it('waits for notification permission before allowing a publish', 0, async () => {
      let enabled = false;
      let requested = false;

      const canPublish = await ensureNotificationPermission(
        () => enabled,
        async () => {
          requested = true;
          enabled = true;
        }
      );

      expect(requested).assertTrue();
      expect(canPublish).assertTrue();
    });
  });
}
