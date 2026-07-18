import { common, Want } from '@kit.AbilityKit';
import notificationManager from '@ohos.notificationManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import { FocusSession } from './FocusSession';
import { createFocusNotificationPresentation, FOCUS_NOTIFICATION_ID } from './FocusNotification';
import { ensureNotificationPermission } from './NotificationPermission';

const BUNDLE_NAME = 'com.zhaoxin.nextthing';
const ABILITY_NAME = 'EntryAbility';

export class FocusNotificationCoordinator {
  private readonly context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async requestPermission(): Promise<void> {
    await this.ensurePermission();
  }

  async sync(session: FocusSession): Promise<void> {
    const presentation = createFocusNotificationPresentation(session);
    if (presentation === null) {
      await this.cancel();
      return;
    }

    if (!await this.ensurePermission()) return;

    try {
      const want: Want = { bundleName: BUNDLE_NAME, abilityName: ABILITY_NAME };
      const agent = await wantAgent.getWantAgent({
        wants: [want],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: FOCUS_NOTIFICATION_ID
      });
      await notificationManager.publish({
        id: FOCUS_NOTIFICATION_ID,
        isOngoing: true,
        tapDismissed: false,
        isAlertOnce: true,
        isCountDown: presentation.isCountDown,
        wantAgent: agent,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: { title: presentation.title, text: presentation.text }
        }
      });
    } catch (_) {}
  }

  async cancel(): Promise<void> {
    try {
      await notificationManager.cancel(FOCUS_NOTIFICATION_ID);
    } catch (_) {}
  }

  private async ensurePermission(): Promise<boolean> {
    return ensureNotificationPermission(
      () => notificationManager.isNotificationEnabledSync(),
      () => notificationManager.requestEnableNotification(this.context)
    );
  }
}
