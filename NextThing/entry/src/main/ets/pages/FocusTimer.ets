import router from '@ohos.router';
import {
  createFocusTimer,
  FocusTimerState,
  formatRemainingTime,
  pauseFocusTimer,
  refreshFocusTimer,
  resumeFocusTimer
} from '../focus/FocusTimerEngine';

interface FocusTimerParams {
  taskName: string;
  durationMinutes: number;
}

@Entry
@Component
struct FocusTimer {
  @State taskName: string = '';
  @State durationMinutes: number = 0;
  @State timer: FocusTimerState = createFocusTimer(0, 0);
  @State pageState: string = 'running';
  private intervalId: number = -1;

  aboutToAppear(): void {
    const params = router.getParams() as FocusTimerParams;
    this.taskName = params.taskName;
    this.durationMinutes = params.durationMinutes;
    this.timer = createFocusTimer(this.durationMinutes, Date.now());
    this.pageState = this.timer.isRunning ? 'running' : 'result';
    if (this.pageState === 'running') {
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
  }

  private refreshTimer(): void {
    this.timer = refreshFocusTimer(this.timer, Date.now());
    if (this.timer.remainingSeconds === 0) {
      this.pageState = 'result';
      this.stopTicker();
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
      return;
    }

    this.timer = resumeFocusTimer(this.timer, Date.now());
    this.startTicker();
  }

  private endEarly(): void {
    this.timer = pauseFocusTimer(this.timer, Date.now());
    this.pageState = 'result';
    this.stopTicker();
  }

  private returnHome(): void {
    this.stopTicker();
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
