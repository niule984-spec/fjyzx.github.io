import { validateTaskTitle } from '../home/HomePageValidation';
import router from '@ohos.router';
import { appRepository } from '../data/AppRepository';
import { ActiveSession } from '../data/PersistenceModels';

@Entry
@Component
struct Index {
  @State taskTitle: string = '';
  @State selectedMinutes: number = 25;
  @State feedback: string = '';

  aboutToAppear(): void {
    appRepository.loadNextTask().then((title: string) => {
      if (title.length > 0) {
        this.taskTitle = title;
      }
      return appRepository.loadActiveSession();
    }).then((session: ActiveSession | undefined) => {
      if (session === undefined) {
        return;
      }
      router.pushUrl({
        url: 'pages/FocusTimer',
        params: {
          taskName: session.taskName,
          durationMinutes: session.durationMinutes,
          restoredSession: JSON.stringify(session)
        }
      });
    });
  }

  private selectDuration(minutes: number): void {
    this.selectedMinutes = minutes;
    this.feedback = '';
  }

  private startTask(): void {
    const result = validateTaskTitle(this.taskTitle);
    if (!result.isValid) {
      this.feedback = '请输入任务内容';
      return;
    }

    appRepository.saveNextTask(result.taskTitle).then(() => {
      router.pushUrl({
        url: 'pages/FocusTimer',
        params: {
          taskName: result.taskTitle,
          durationMinutes: this.selectedMinutes
        }
      });
    });
  }

  build() {
    Column({ space: 16 }) {
      Text('下一件事')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text('只选择现在最重要的一件事')
        .fontSize(16)
        .fontColor('#5F6B7A')
        .width('100%')

      TextInput({ placeholder: '请输入下一件事', text: this.taskTitle })
        .id('task-input')
        .width('100%')
        .height(48)
        .backgroundColor('#F3F5F8')
        .onChange((value: string) => {
          this.taskTitle = value;
          this.feedback = '';
        })

      Text('预计时长')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Row({ space: 8 }) {
        Button('5 分钟')
          .id('duration-5')
          .layoutWeight(1)
          .backgroundColor(this.selectedMinutes === 5 ? '#0A59F7' : '#E8EDF5')
          .fontColor(this.selectedMinutes === 5 ? '#FFFFFF' : '#1F2937')
          .onClick(() => {
            this.selectDuration(5);
          })

        Button('10 分钟')
          .id('duration-10')
          .layoutWeight(1)
          .backgroundColor(this.selectedMinutes === 10 ? '#0A59F7' : '#E8EDF5')
          .fontColor(this.selectedMinutes === 10 ? '#FFFFFF' : '#1F2937')
          .onClick(() => {
            this.selectDuration(10);
          })

        Button('25 分钟')
          .id('duration-25')
          .layoutWeight(1)
          .backgroundColor(this.selectedMinutes === 25 ? '#0A59F7' : '#E8EDF5')
          .fontColor(this.selectedMinutes === 25 ? '#FFFFFF' : '#1F2937')
          .onClick(() => {
            this.selectDuration(25);
          })
      }
      .width('100%')

      Button('开始')
        .id('start-button')
        .width('100%')
        .height(48)
        .backgroundColor('#0A59F7')
        .fontColor('#FFFFFF')
        .onClick(() => {
          this.startTask();
        })

      if (this.feedback.length > 0) {
        Text(this.feedback)
          .id('home-feedback')
          .fontSize(15)
          .fontColor(this.feedback === '请输入任务内容' ? '#C62828' : '#16794C')
          .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
  }
}
