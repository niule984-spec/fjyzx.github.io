import router from '@ohos.router';

interface FocusTimerParams {
  taskName: string;
  durationMinutes: number;
}

@Entry
@Component
struct FocusTimer {
  @State taskName: string = '';
  @State durationMinutes: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as FocusTimerParams;
    this.taskName = params.taskName;
    this.durationMinutes = params.durationMinutes;
  }

  build() {
    Column({ space: 16 }) {
      Text('正在专注')
        .fontSize(16)
        .fontColor('#5F6B7A')

      Text(this.taskName)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)

      Text(`${this.durationMinutes} 分钟`)
        .fontSize(20)
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
  }
}
