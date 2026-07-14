import { validateTaskTitle } from '../home/HomePageValidation';
import router from '@ohos.router';
import { appRepository } from '../data/AppRepository';
import { ActiveSession, InboxSortMode, InboxTask, NextTask, TodayReview } from '../data/PersistenceModels';
import { calculateTodayReview } from '../data/ReviewCalculator';
import { filterInboxTasks, sortInboxTasks, validatePlannedMinutes } from '../inbox/TaskManagement';

@Entry
@Component
struct Index {
  @State taskTitle: string = '';
  @State selectedMinutes: number = 25;
  @State feedback: string = '';
  @State selectedTab: number = 0;
  @State inboxDraft: string = '';
  @State inboxTasks: InboxTask[] = [];
  @State inboxFeedback: string = '';
  @State inboxSearch: string = '';
  @State inboxSortMode: InboxSortMode = 'newest';
  @State editingTaskId: number = 0;
  @State editingTitle: string = '';
  @State editingMinutes: string = '25';
  @State review: TodayReview = {
    sessionCount: 0,
    actualMinutes: 0,
    completedCount: 0,
    unfinishedCount: 0
  };
  @State reviewFeedback: string = '';

  aboutToAppear(): void {
    appRepository.loadNextTask().then((task: NextTask | undefined) => {
      if (task !== undefined) {
        this.taskTitle = task.title;
        this.selectedMinutes = task.plannedMinutes;
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
    }).catch(() => {
      this.feedback = '读取已保存任务失败，请继续使用首页。';
    });
    this.loadInbox();
    this.loadTodayReview();
  }

  private selectDuration(minutes: number): void {
    this.selectedMinutes = minutes;
    this.feedback = '';
  }

  private startTask(): void {
    const result = validateTaskTitle(this.taskTitle);
    if (!result.isValid) {
      this.feedback = '请输入任务内容。';
      return;
    }

    appRepository.saveNextTask(result.taskTitle, this.selectedMinutes).then(() => {
      router.pushUrl({
        url: 'pages/FocusTimer',
        params: {
          taskName: result.taskTitle,
          durationMinutes: this.selectedMinutes
        }
      });
    }).catch(() => {
      this.feedback = '任务保存失败，请重试。';
    });
  }

  private loadInbox(): void {
    appRepository.listInboxTasks().then((tasks: InboxTask[]) => {
      this.inboxTasks = tasks;
    }).catch(() => {
      this.inboxFeedback = '读取任务失败，请重试。';
    });
  }

  private addInboxTask(): void {
    const result = validateTaskTitle(this.inboxDraft);
    if (!result.isValid) {
      this.inboxFeedback = '请输入任务内容。';
      return;
    }
    appRepository.addInboxTask(result.taskTitle).then(() => {
      this.inboxDraft = '';
      this.inboxFeedback = '';
      this.loadInbox();
    }).catch(() => {
      this.inboxFeedback = '添加任务失败，请重试。';
    });
  }

  private deleteInboxTask(id: number): void {
    appRepository.deleteInboxTask(id).then(() => {
      this.inboxFeedback = '';
      this.loadInbox();
    }).catch(() => {
      this.inboxFeedback = '删除任务失败，请重试。';
    });
  }

  private chooseNextTask(task: InboxTask): void {
    appRepository.saveNextTask(task.title, task.plannedMinutes).then(() => {
      this.taskTitle = task.title;
      this.selectedMinutes = task.plannedMinutes;
      this.feedback = '';
      this.inboxFeedback = '';
      this.selectedTab = 0;
    }).catch(() => {
      this.inboxFeedback = '设置下一件事失败，请重试。';
    });
  }

  private startEditing(task: InboxTask): void {
    this.editingTaskId = task.id;
    this.editingTitle = task.title;
    this.editingMinutes = task.plannedMinutes.toString();
    this.inboxFeedback = '';
  }

  private saveEditing(): void {
    const title = validateTaskTitle(this.editingTitle);
    const minutes = validatePlannedMinutes(this.editingMinutes);
    if (!title.isValid || minutes === undefined) {
      this.inboxFeedback = '请输入任务内容和正整数分钟数';
      return;
    }
    appRepository.updateInboxTask(this.editingTaskId, title.taskTitle, minutes).then(() => {
      this.editingTaskId = 0;
      this.inboxFeedback = '';
      this.loadInbox();
    }).catch(() => this.inboxFeedback = '保存任务失败，请重试');
  }

  private moveTask(task: InboxTask, offset: number): void {
    const tasks = sortInboxTasks(this.inboxTasks, 'manual');
    const index = tasks.findIndex((item: InboxTask) => item.id === task.id);
    const target = index + offset;
    if (index < 0 || target < 0 || target >= tasks.length) return;
    const moved = tasks[index];
    tasks[index] = tasks[target];
    tasks[target] = moved;
    appRepository.updateManualOrder(tasks).then(() => this.loadInbox())
      .catch(() => this.inboxFeedback = '保存排序失败，请重试');
  }

  private visibleInboxTasks(): InboxTask[] {
    return sortInboxTasks(filterInboxTasks(this.inboxTasks, this.inboxSearch), this.inboxSortMode);
  }

  private loadTodayReview(): void {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const tomorrowStart = new Date(todayStart.getTime());
    tomorrowStart.setDate(tomorrowStart.getDate() + 1);
    appRepository.listTodayRecords(todayStart.getTime(), tomorrowStart.getTime()).then((records) => {
      this.review = calculateTodayReview(records);
      this.reviewFeedback = '';
    }).catch(() => {
      this.reviewFeedback = '读取今日回顾失败，请重试。';
    });
  }

  @Builder
  private nowTab(): void {
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
          .onClick(() => this.selectDuration(5))
        Button('10 分钟')
          .id('duration-10')
          .layoutWeight(1)
          .backgroundColor(this.selectedMinutes === 10 ? '#0A59F7' : '#E8EDF5')
          .fontColor(this.selectedMinutes === 10 ? '#FFFFFF' : '#1F2937')
          .onClick(() => this.selectDuration(10))
        Button('25 分钟')
          .id('duration-25')
          .layoutWeight(1)
          .backgroundColor(this.selectedMinutes === 25 ? '#0A59F7' : '#E8EDF5')
          .fontColor(this.selectedMinutes === 25 ? '#FFFFFF' : '#1F2937')
          .onClick(() => this.selectDuration(25))
      }
      .width('100%')

      Button('开始')
        .id('start-button')
        .width('100%')
        .height(48)
        .backgroundColor('#0A59F7')
        .fontColor('#FFFFFF')
        .onClick(() => this.startTask())

      if (this.feedback.length > 0) {
        Text(this.feedback)
          .id('home-feedback')
          .fontSize(15)
          .fontColor('#C62828')
          .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24 })
  }

  @Builder
  private inboxTab(): void {
    Column({ space: 16 }) {
      Text('清空脑袋')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      Text('先记下来，再决定下一件事。')
        .fontSize(16)
        .fontColor('#5F6B7A')
        .width('100%')
      Row({ space: 8 }) {
        TextInput({ placeholder: '输入想到的任务', text: this.inboxDraft })
          .id('inbox-input')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F3F5F8')
          .onChange((value: string) => {
            this.inboxDraft = value;
            this.inboxFeedback = '';
          })
        Button('添加')
          .id('add-inbox-button')
          .height(48)
          .backgroundColor('#0A59F7')
          .fontColor('#FFFFFF')
          .onClick(() => this.addInboxTask())
      }
      .width('100%')

      TextInput({ placeholder: '搜索任务', text: this.inboxSearch })
        .id('inbox-search')
        .width('100%')
        .height(44)
        .backgroundColor('#F3F5F8')
        .onChange((value: string) => this.inboxSearch = value)

      Row({ space: 8 }) {
        Button('最近添加').layoutWeight(1).backgroundColor(this.inboxSortMode === 'newest' ? '#0A59F7' : '#E8EDF5').fontColor(this.inboxSortMode === 'newest' ? '#FFFFFF' : '#1F2937').onClick(() => this.inboxSortMode = 'newest')
        Button('最早添加').layoutWeight(1).backgroundColor(this.inboxSortMode === 'oldest' ? '#0A59F7' : '#E8EDF5').fontColor(this.inboxSortMode === 'oldest' ? '#FFFFFF' : '#1F2937').onClick(() => this.inboxSortMode = 'oldest')
        Button('名称').layoutWeight(1).backgroundColor(this.inboxSortMode === 'title' ? '#0A59F7' : '#E8EDF5').fontColor(this.inboxSortMode === 'title' ? '#FFFFFF' : '#1F2937').onClick(() => this.inboxSortMode = 'title')
        Button('手动').layoutWeight(1).backgroundColor(this.inboxSortMode === 'manual' ? '#0A59F7' : '#E8EDF5').fontColor(this.inboxSortMode === 'manual' ? '#FFFFFF' : '#1F2937').onClick(() => this.inboxSortMode = 'manual')
      }.width('100%')

      if (this.inboxFeedback.length > 0) {
        Text(this.inboxFeedback)
          .id('inbox-feedback')
          .fontSize(15)
          .fontColor('#C62828')
          .width('100%')
      }

      if (this.visibleInboxTasks().length === 0) {
        Text('还没有记录任务。')
          .fontSize(16)
          .fontColor('#5F6B7A')
          .width('100%')
          .margin({ top: 24 })
      } else {
        List({ space: 10 }) {
          ForEach(this.visibleInboxTasks(), (task: InboxTask) => {
            ListItem() {
              Column({ space: 10 }) {
                Text(task.title)
                  .fontSize(17)
                  .fontWeight(FontWeight.Medium)
                  .width('100%')
                Text(`${task.plannedMinutes} 分钟`)
                  .fontSize(14)
                  .fontColor('#5F6B7A')
                if (this.editingTaskId === task.id) {
                  TextInput({ placeholder: '任务名称', text: this.editingTitle }).height(44).backgroundColor('#FFFFFF').onChange((value: string) => this.editingTitle = value)
                  Row({ space: 8 }) {
                    Button('5').onClick(() => this.editingMinutes = '5')
                    Button('10').onClick(() => this.editingMinutes = '10')
                    Button('25').onClick(() => this.editingMinutes = '25')
                    TextInput({ placeholder: '自定义分钟', text: this.editingMinutes }).layoutWeight(1).height(36).backgroundColor('#FFFFFF').onChange((value: string) => this.editingMinutes = value)
                  }.width('100%')
                  Row({ space: 8 }) {
                    Button('保存').backgroundColor('#0A59F7').fontColor('#FFFFFF').onClick(() => this.saveEditing())
                    Button('取消').onClick(() => this.editingTaskId = 0)
                  }
                }
                Row({ space: 8 }) {
                  Button('设为下一件事')
                    .id(`choose-inbox-${task.id}`)
                    .layoutWeight(1)
                    .backgroundColor('#E8EDF5')
                    .fontColor('#1F2937')
                    .onClick(() => this.chooseNextTask(task))
                  Button('编辑').id(`edit-inbox-${task.id}`).onClick(() => this.startEditing(task))
                  if (this.inboxSortMode === 'manual') {
                    Button('上移').enabled(this.inboxSearch.trim().length === 0 && this.visibleInboxTasks().findIndex((item: InboxTask) => item.id === task.id) > 0).onClick(() => this.moveTask(task, -1))
                    Button('下移').enabled(this.inboxSearch.trim().length === 0 && this.visibleInboxTasks().findIndex((item: InboxTask) => item.id === task.id) < this.visibleInboxTasks().length - 1).onClick(() => this.moveTask(task, 1))
                  }
                  Button('删除')
                    .id(`delete-inbox-${task.id}`)
                    .backgroundColor('#FDECEC')
                    .fontColor('#C62828')
                    .onClick(() => this.deleteInboxTask(task.id))
                }
                .width('100%')
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#F8FAFC')
              .borderRadius(6)
            }
          }, (task: InboxTask) => task.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 12 })
  }

  @Builder
  private reviewTab(): void {
    Column({ space: 16 }) {
      Text('今日回顾')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      Text('所有结束的专注都会计入今天。')
        .fontSize(16)
        .fontColor('#5F6B7A')
        .width('100%')
      Row({ space: 12 }) {
        Column({ space: 6 }) {
          Text(this.review.sessionCount.toString())
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
          Text('专注次数')
            .fontSize(14)
            .fontColor('#5F6B7A')
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor('#F3F5F8')
        .borderRadius(6)
        Column({ space: 6 }) {
          Text(this.review.actualMinutes.toString())
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
          Text('实际分钟')
            .fontSize(14)
            .fontColor('#5F6B7A')
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor('#FFF3E8')
        .borderRadius(6)
      }
      .width('100%')
      Row({ space: 12 }) {
        Column({ space: 6 }) {
          Text(this.review.completedCount.toString())
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
          Text('完成')
            .fontSize(14)
            .fontColor('#5F6B7A')
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor('#EAF7EF')
        .borderRadius(6)
        Column({ space: 6 }) {
          Text(this.review.unfinishedCount.toString())
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
          Text('未完成')
            .fontSize(14)
            .fontColor('#5F6B7A')
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor('#FDECEC')
        .borderRadius(6)
      }
      .width('100%')
      if (this.reviewFeedback.length > 0) {
        Text(this.reviewFeedback)
          .id('review-feedback')
          .fontSize(15)
          .fontColor('#C62828')
          .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24, top: 24 })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.selectedTab }) {
      TabContent() {
        this.nowTab();
      }
      .tabBar('现在')

      TabContent() {
        this.inboxTab();
      }
      .tabBar('清空脑袋')

      TabContent() {
        this.reviewTab();
      }
      .tabBar('今日回顾')
    }
    .width('100%')
    .height('100%')
    .onChange((index: number) => {
      this.selectedTab = index;
      if (index === 1) {
        this.loadInbox();
      }
      if (index === 2) {
        this.loadTodayReview();
      }
    })
  }
}
