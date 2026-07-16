import router from '@ohos.router';
import {
  createFocusTimer,
  FocusTimerState,
  formatRemainingTime,
  pauseFocusTimer,
  refreshFocusTimer,
  resumeFocusTimer
} from '../focus/FocusTimerEngine';
import { appRepository } from '../data/AppRepository';
import { parseActiveSession } from '../data/NextThingRepository';
import { ActiveSession, FocusOutcome } from '../data/PersistenceModels';
import { restoreFocusSession } from '../focus/FocusSessionRecovery';
import { needsPendingRecord } from '../focus/FocusResultPersistence';
import { canFinishResult, shouldPersistActiveSession } from '../focus/FocusPersistenceGuards';
import { common } from '@kit.AbilityKit';
import { FocusSession } from '../focus/FocusSession';
import { FocusNotificationCoordinator } from '../focus/FocusNotificationCoordinator';

interface FocusTimerParams {
  taskName: string;
  durationMinutes: number;
  restoredSession?: string;
}

@Entry
@Component
struct FocusTimer {
  @State taskName: string = '';
  @State durationMinutes: number = 0;
  @State timer: FocusTimerState = createFocusTimer(0, 0);
  @State pageState: string = 'running';
  private intervalId: number = -1;
  private pendingRecordId: number = 0;
  private resultKey: string = '';
  private isFinished: boolean = false;
  @State isCreatingResult: boolean = false;
  @State isFinishing: boolean = false;
  @State persistenceFeedback: string = '';
  private focusNotificationCoordinator: FocusNotificationCoordinator | undefined = undefined;

  aboutToAppear(): void {
    const params = router.getParams() as FocusTimerParams;
    this.taskName = params.taskName;
    this.durationMinutes = params.durationMinutes;
    const restoredSession = this.readRestoredSession(params.restoredSession);
    if (restoredSession !== undefined) {
      this.pendingRecordId = restoredSession.pendingRecordId;
      this.resultKey = restoredSession.resultKey ?? '';
      this.pageState = restoredSession.pageState;
      this.timer = restoreFocusSession({
        durationSeconds: this.durationMinutes * 60,
        remainingSeconds: restoredSession.remainingSeconds,
        targetEndTime: restoredSession.targetEndTime,
        isRunning: restoredSession.isRunning
      }, Date.now());
      if (needsPendingRecord(restoredSession)) {
        this.enterResult();
        return;
      }
      if (this.timer.remainingSeconds === 0 && this.pageState !== 'result') {
        this.enterResult();
        return;
      }
      if (this.pageState === 'running' && this.timer.isRunning) {
        this.startTicker();
      }
      this.saveSession();
      this.requestNotificationPermission();
      return;
    }
    this.timer = createFocusTimer(this.durationMinutes, Date.now());
    this.pageState = this.timer.isRunning ? 'running' : 'result';
    if (this.pageState === 'running') {
      this.startTicker();
    }
    this.saveSession();
    this.requestNotificationPermission();
  }

  onPageShow(): void {
    if (this.pageState === 'running' && this.timer.isRunning) {
      this.refreshTimer();
      this.startTicker();
    }
  }

  aboutToDisappear(): void {
    this.saveSession();
    this.stopTicker();
  }

  private refreshTimer(): void {
    this.timer = refreshFocusTimer(this.timer, Date.now());
    if (this.timer.remainingSeconds === 0) {
      this.enterResult();
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

  private getNotificationCoordinator(): FocusNotificationCoordinator | undefined {
    if (this.focusNotificationCoordinator !== undefined) {
      return this.focusNotificationCoordinator;
    }
    try {
      this.focusNotificationCoordinator = new FocusNotificationCoordinator(getContext(this) as common.UIAbilityContext);
      return this.focusNotificationCoordinator;
    } catch (_) {
      return undefined;
    }
  }

  private requestNotificationPermission(): void {
    const coordinator = this.getNotificationCoordinator();
    if (coordinator === undefined) {
      return;
    }
    coordinator.requestPermission().then(() => this.syncNotification());
  }

  private syncNotification(): void {
    const session: FocusSession = {
      taskName: this.taskName,
      durationMinutes: this.durationMinutes,
      timer: this.timer,
      pageState: this.pageState === 'result' ? 'result' : 'running'
    };
    this.getNotificationCoordinator()?.sync(session);
  }

  private toggleTimer(): void {
    if (this.timer.isRunning) {
      this.timer = pauseFocusTimer(this.timer, Date.now());
      this.stopTicker();
      this.saveSession();
      return;
    }

    this.timer = resumeFocusTimer(this.timer, Date.now());
    this.startTicker();
    this.saveSession();
  }

  private endEarly(): void {
    this.timer = pauseFocusTimer(this.timer, Date.now());
    this.enterResult();
  }

  private readRestoredSession(value: string | undefined): ActiveSession | undefined {
    if (value === undefined || value.length === 0) {
      return undefined;
    }
    return parseActiveSession(value);
  }

  private enterResult(): void {
    if (this.pageState === 'result' && (this.pendingRecordId !== 0 || this.isCreatingResult)) {
      return;
    }
    this.pageState = 'result';
    this.stopTicker();
    this.syncNotification();
    if (this.pendingRecordId !== 0) {
      this.saveSession();
      return;
    }
    this.isCreatingResult = true;
    this.persistenceFeedback = '';
    if (this.resultKey.length === 0) {
      this.resultKey = `result-${Date.now()}`;
    }
    this.persistSession().then(() => {
      return appRepository.findOrCreatePendingRecord({
        taskTitle: this.taskName,
        plannedMinutes: this.durationMinutes,
        actualSeconds: this.timer.durationSeconds - this.timer.remainingSeconds,
        endedAt: Date.now(),
        outcome: 'pending',
        resultKey: this.resultKey
      });
    }).then((id: number) => {
      this.pendingRecordId = id;
      this.isCreatingResult = false;
      this.saveSession();
    }).catch(() => {
      this.isCreatingResult = false;
      this.persistenceFeedback = '记录保存失败，请重试';
    });
  }

  private saveSession(): void {
    this.syncNotification();
    if (!shouldPersistActiveSession(this.isFinished)) {
      return;
    }
    this.persistSession().catch(() => {
      this.persistenceFeedback = '当前进度保存失败，请稍后重试';
    });
  }

  private persistSession(): Promise<void> {
    return appRepository.saveActiveSession({
      taskName: this.taskName,
      durationMinutes: this.durationMinutes,
      remainingSeconds: this.timer.remainingSeconds,
      targetEndTime: this.timer.targetEndTime,
      isRunning: this.timer.isRunning,
      pageState: this.pageState === 'result' ? 'result' : (this.timer.isRunning ? 'running' : 'paused'),
      pendingRecordId: this.pendingRecordId,
      resultKey: this.resultKey
    });
  }

  private finishWith(outcome: FocusOutcome): void {
    if (!canFinishResult(this.pendingRecordId, this.isFinishing)) {
      return;
    }
    this.isFinishing = true;
    this.persistenceFeedback = '';
    appRepository.updateRecordOutcome(this.pendingRecordId, outcome).then(() => {
      return appRepository.clearActiveSession();
    }).then(() => {
      this.isFinished = true;
      this.stopTicker();
      router.replaceUrl({ url: 'pages/Index' });
    }).catch(() => {
      this.isFinishing = false;
      this.persistenceFeedback = '结果保存失败，请重试';
    });
  }

  build() {
    Column({ space: 20 }) {
      if (this.persistenceFeedback.length > 0) {
        Text(this.persistenceFeedback)
          .id('persistence-feedback')
          .fontSize(15)
          .fontColor('#C62828')
      }
      if (this.pageState === 'result' && this.pendingRecordId === 0 && !this.isCreatingResult) {
        Button('重试保存')
          .id('retry-save-button')
          .width('100%')
          .height(48)
          .backgroundColor('#E8EDF5')
          .fontColor('#1F2937')
          .onClick(() => {
            this.enterResult();
          })
      }
      if (this.pageState === 'result') {
        Text('这次专注结束了')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)

        Text(this.taskName)
          .fontSize(18)
          .fontColor('#5F6B7A')

        Button('完成了')
          .id('completed-button')
          .enabled(!this.isCreatingResult && !this.isFinishing)
          .width('100%')
          .height(48)
          .backgroundColor('#16794C')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.finishWith('completed');
          })

        Button('还没完成')
          .id('unfinished-button')
          .enabled(!this.isCreatingResult && !this.isFinishing)
          .width('100%')
          .height(48)
          .backgroundColor('#E8EDF5')
          .fontColor('#1F2937')
          .onClick(() => {
            this.finishWith('unfinished');
          })

        Button('换一件事')
          .id('change-task-button')
          .enabled(!this.isCreatingResult && !this.isFinishing)
          .width('100%')
          .height(48)
          .backgroundColor('#E8EDF5')
          .fontColor('#1F2937')
          .onClick(() => {
            this.finishWith('changed');
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
