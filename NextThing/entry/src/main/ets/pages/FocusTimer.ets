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
import { ActiveSession, FocusOutcome } from '../data/PersistenceModels';
import { restoreFocusSession } from '../focus/FocusSessionRecovery';

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

  aboutToAppear(): void {
    const params = router.getParams() as FocusTimerParams;
    this.taskName = params.taskName;
    this.durationMinutes = params.durationMinutes;
    const restoredSession = this.readRestoredSession(params.restoredSession);
    if (restoredSession !== undefined) {
      this.pendingRecordId = restoredSession.pendingRecordId;
      this.pageState = restoredSession.pageState;
      this.timer = restoreFocusSession({
        durationSeconds: this.durationMinutes * 60,
        remainingSeconds: restoredSession.remainingSeconds,
        targetEndTime: restoredSession.targetEndTime,
        isRunning: restoredSession.isRunning
      }, Date.now());
      if (this.timer.remainingSeconds === 0 && this.pageState !== 'result') {
        this.enterResult();
        return;
      }
      if (this.pageState === 'running' && this.timer.isRunning) {
        this.startTicker();
      }
      this.saveSession();
      return;
    }
    this.timer = createFocusTimer(this.durationMinutes, Date.now());
    this.pageState = this.timer.isRunning ? 'running' : 'result';
    if (this.pageState === 'running') {
      this.startTicker();
    }
    this.saveSession();
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
    return JSON.parse(value) as ActiveSession;
  }

  private enterResult(): void {
    this.pageState = 'result';
    this.stopTicker();
    if (this.pendingRecordId === 0) {
      appRepository.createPendingRecord({
        taskTitle: this.taskName,
        plannedMinutes: this.durationMinutes,
        actualSeconds: this.timer.durationSeconds - this.timer.remainingSeconds,
        endedAt: Date.now(),
        outcome: 'pending'
      }).then((id: number) => {
        this.pendingRecordId = id;
        this.saveSession();
      });
      return;
    }
    this.saveSession();
  }

  private saveSession(): void {
    appRepository.saveActiveSession({
      taskName: this.taskName,
      durationMinutes: this.durationMinutes,
      remainingSeconds: this.timer.remainingSeconds,
      targetEndTime: this.timer.targetEndTime,
      isRunning: this.timer.isRunning,
      pageState: this.pageState === 'result' ? 'result' : (this.timer.isRunning ? 'running' : 'paused'),
      pendingRecordId: this.pendingRecordId
    });
  }

  private finishWith(outcome: FocusOutcome): void {
    if (this.pendingRecordId === 0) {
      return;
    }
    appRepository.updateRecordOutcome(this.pendingRecordId, outcome).then(() => {
      return appRepository.clearActiveSession();
    }).then(() => {
      this.stopTicker();
      router.replaceUrl({ url: 'pages/Index' });
    });
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
            this.finishWith('completed');
          })

        Button('还没完成')
          .id('unfinished-button')
          .width('100%')
          .height(48)
          .backgroundColor('#E8EDF5')
          .fontColor('#1F2937')
          .onClick(() => {
            this.finishWith('unfinished');
          })

        Button('换一件事')
          .id('change-task-button')
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
