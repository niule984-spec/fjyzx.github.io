import router from '@ohos.router';
import preferences from '@ohos.data.preferences';
import {
  createFocusTimer,
  FocusTimerState,
  formatRemainingTime,
  pauseFocusTimer,
  refreshFocusTimer,
  resumeFocusTimer
} from '../focus/FocusTimerEngine';
import { FocusPageState, FocusSession, restoreFocusSession } from '../focus/FocusSession';
import { FocusSessionStore } from '../focus/FocusSessionStore';
import { common } from '@kit.AbilityKit';
import { FocusNotificationCoordinator } from '../focus/FocusNotificationCoordinator';

interface FocusTimerParams {
  session?: FocusSession;
}

@Entry
@Component
struct FocusTimer {
  @State taskName: string = '';
  @State durationMinutes: number = 0;
  @State timer: FocusTimerState = createFocusTimer(0, 0);
  @State pageState: FocusPageState = 'running';
  private intervalId: number = -1;
  private focusSessionStore: FocusSessionStore | undefined = undefined;
  private shouldPersist: boolean = true;
  private focusNotificationCoordinator: FocusNotificationCoordinator | undefined = undefined;

  aboutToAppear(): void {
    this.shouldPersist = true;
    if (!this.restoreSession()) {
      router.replaceUrl({ url: 'pages/Index' });
      return;
    }

    if (this.pageState === 'running' && this.timer.isRunning) {
      this.startTicker();
    }
  }

  onPageShow(): void {
    if (this.pageState === 'running' && this.timer.isRunning) {
      this.refreshTimer();
      this.startTicker();
    }
  }

  aboutToDisappear(): void {
    this.stopTicker();
    if (this.shouldPersist) {
      this.persistSession();
    }
  }

  private getSessionStore(): FocusSessionStore | undefined {
    if (this.focusSessionStore !== undefined) {
      return this.focusSessionStore;
    }

    try {
      const preference = preferences.getPreferencesSync(getContext(this), { name: 'nextthing_focus_session' });
      this.focusSessionStore = new FocusSessionStore(preference);
      return this.focusSessionStore;
    } catch (_) {
      return undefined;
    }
  }

  private getNotificationCoordinator(): FocusNotificationCoordinator | undefined {
    if (this.focusNotificationCoordinator !== undefined) return this.focusNotificationCoordinator;
    try {
      this.focusNotificationCoordinator = new FocusNotificationCoordinator(getContext(this) as common.UIAbilityContext);
      return this.focusNotificationCoordinator;
    } catch (_) {
      return undefined;
    }
  }

  private toSession(): FocusSession {
    return {
      taskName: this.taskName,
      durationMinutes: this.durationMinutes,
      timer: this.timer,
      pageState: this.pageState
    };
  }

  private persistSession(): void {
    const session = this.toSession();
    this.getSessionStore()?.save(session);
    this.getNotificationCoordinator()?.sync(session);
  }

  private restoreSession(): boolean {
    const params = router.getParams() as FocusTimerParams;
    const storedSession = this.getSessionStore()?.load();
    const sourceSession = storedSession ?? params.session;
    if (sourceSession === undefined) {
      return false;
    }

    const session = restoreFocusSession(sourceSession, Date.now());
    this.taskName = session.taskName;
    this.durationMinutes = session.durationMinutes;
    this.timer = session.timer;
    this.pageState = session.pageState;
    this.persistSession();
    return true;
  }

  private refreshTimer(): void {
    this.timer = refreshFocusTimer(this.timer, Date.now());
    if (this.timer.remainingSeconds === 0) {
      this.pageState = 'result';
      this.stopTicker();
      this.persistSession();
    }
  }

  private startTicker(): void {
    this.stopTicker();
    this.intervalId = setInterval(() => {
      this.refreshTimer();
    }, 1_000);
  }

  private stopTicker(): void {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
      this.intervalId = -1;
    }
  }

  private toggleTimer(): void {
    if (this.timer.isRunning) {
      this.timer = pauseFocusTimer(this.timer, Date.now());
      this.stopTicker();
      this.persistSession();
      return;
    }

    this.timer = resumeFocusTimer(this.timer, Date.now());
    this.persistSession();
    this.startTicker();
  }

  private endEarly(): void {
    this.timer = pauseFocusTimer(this.timer, Date.now());
    this.pageState = 'result';
    this.stopTicker();
    this.persistSession();
  }

  private returnHome(): void {
    this.stopTicker();
    this.shouldPersist = false;
    this.getSessionStore()?.clear();
    this.getNotificationCoordinator()?.cancel();
    router.replaceUrl({ url: 'pages/Index' });
  }

  build() {
    Column({ space: 20 }) {
      if (this.pageState === 'result') {
        Text('这次专注结束了')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)

        Text(this.taskName)
          .fontSize(18)
          .fontColor('#5F6B7A')

        Button('完成了')
          .id('completed-button')
          .width('100%')
          .height(48)
          .backgroundColor('#16794C')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.returnHome();
          })

        Button('还没完成')
          .id('unfinished-button')
          .width('100%')
          .height(48)
          .backgroundColor('#E8EDF5')
          .fontColor('#1F2937')
          .onClick(() => {
            this.returnHome();
          })

        Button('换一件事')
          .id('change-task-button')
          .width('100%')
          .height(48)
          .backgroundColor('#E8EDF5')
          .fontColor('#1F2937')
          .onClick(() => {
            this.returnHome();
          })
      } else {
        Text('正在专注')
          .fontSize(16)
          .fontColor('#5F6B7A')

        Text(formatRemainingTime(this.timer.remainingSeconds))
          .id('remaining-time')
          .fontSize(52)
          .fontWeight(FontWeight.Bold)

        Progress({
          value: this.timer.durationSeconds - this.timer.remainingSeconds,
          total: this.timer.durationSeconds,
          type: ProgressType.Linear
        })
          .id('timer-progress')
          .width('100%')
          .color('#E87918')
          .backgroundColor('#FFE0C2')

        Text(this.taskName)
          .id('timer-task-name')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)

        Button(this.timer.isRunning ? '暂停' : '继续')
          .id('pause-resume-button')
          .width('100%')
          .height(48)
          .backgroundColor('#E87918')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.toggleTimer();
          })

        Button('结束')
          .id('end-button')
          .width('100%')
          .height(48)
          .backgroundColor('#E8EDF5')
          .fontColor('#1F2937')
          .onClick(() => {
            this.endEarly();
          })
      }
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
  }
}
