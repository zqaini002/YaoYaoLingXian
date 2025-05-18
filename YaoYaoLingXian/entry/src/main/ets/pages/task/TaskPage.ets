import { CommonConstants, Task, PageResponse } from '../../model/CommonTypes';
import { AppIcons } from '../../utils/IconUtils';
import prompt from '@ohos.promptAction';
import { getAllTasks, getTasksByStatus, updateTaskStatus, getTodayTasks, getUpcomingTasks, searchTasks } from '../../services/TaskService';
import router from '@ohos.router';

@Component
export struct TaskPage {
  @State selectedTab: number = 0;
  @State tabs: string[] = ['全部', '今日', '即将到期', '待开始', '进行中', '已完成', '已延期'];
  @State tasks: Task[] = [];
  @State isLoading: boolean = false;
  @State userId: number = 2; // 假设当前用户ID为2，实际应用中应该从登录状态获取
  @State refreshing: boolean = false;
  @State currentPage: number = 0;
  @State pageSize: number = 20;
  @State hasMoreData: boolean = true;
  @State searchKeyword: string = "";
  @State isSearchMode: boolean = false;
  @State upcomingDays: number = 7; // 默认展示7天内即将到期的任务
  
  aboutToAppear() {
    this.loadTasks();
  }
  
  async loadTasks() {
    this.isLoading = true;
    try {
      // 如果是搜索模式，执行搜索
      if (this.isSearchMode && this.searchKeyword.trim().length > 0) {
        const response = await searchTasks(this.userId, this.searchKeyword, this.currentPage, this.pageSize);
        if (response && response.content) {
          if (this.currentPage === 0) {
            this.tasks = response.content;
          } else {
            // 不使用slice和展开运算符，直接创建新数组
            const newTasks: Task[] = [];
            for (let i = 0; i < this.tasks.length; i++) {
              newTasks[i] = this.tasks[i];
            }
            for (let i = 0; i < response.content.length; i++) {
              newTasks.push(response.content[i]);
            }
            this.tasks = newTasks;
          }
          this.hasMoreData = !response.last;
        }
        this.isLoading = false;
        return;
      }
      
      // 不是搜索模式，根据标签加载不同类型的任务
      switch (this.selectedTab) {
        case 0: // 全部任务
          const allResponse = await getAllTasks(this.userId, this.currentPage, this.pageSize);
          if (allResponse && allResponse.content) {
            if (this.currentPage === 0) {
              this.tasks = allResponse.content;
            } else {
              // 不使用slice和展开运算符，直接创建新数组
              const newTasks: Task[] = [];
              for (let i = 0; i < this.tasks.length; i++) {
                newTasks[i] = this.tasks[i];
              }
              for (let i = 0; i < allResponse.content.length; i++) {
                newTasks.push(allResponse.content[i]);
              }
              this.tasks = newTasks;
            }
            this.hasMoreData = !allResponse.last;
          }
          break;
          
        case 1: // 今日任务
          const todayResponse = await getTodayTasks(this.userId, this.currentPage, this.pageSize);
          if (todayResponse && todayResponse.content) {
            if (this.currentPage === 0) {
              // 不使用map和对象展开，直接创建新对象
              const tasksWithToday: Task[] = [];
              for (let i = 0; i < todayResponse.content.length; i++) {
                const task = todayResponse.content[i];
                const taskWithToday: Task = {
                  id: task.id,
                  title: task.title,
                  description: task.description,
                  status: task.status,
                  priority: task.priority,
                  dreamId: task.dreamId,
                  dreamTitle: task.dreamTitle,
                  userId: task.userId,
                  startDate: task.startDate,
                  dueDate: task.dueDate,
                  completedAt: task.completedAt,
                  reminderTime: task.reminderTime,
                  parentTaskId: task.parentTaskId,
                  createdAt: task.createdAt,
                  updatedAt: task.updatedAt,
                  isTodayTask: true,
                  isOverdue: task.isOverdue,
                  isUpcomingTask: task.isUpcomingTask
                };
                tasksWithToday.push(taskWithToday);
              }
              this.tasks = tasksWithToday;
            } else {
              // 不使用slice和展开运算符，直接创建新数组
              const newTasks: Task[] = [];
              for (let i = 0; i < this.tasks.length; i++) {
                newTasks[i] = this.tasks[i];
              }
              for (let i = 0; i < todayResponse.content.length; i++) {
                const task = todayResponse.content[i];
                const taskWithToday: Task = {
                  id: task.id,
                  title: task.title,
                  description: task.description,
                  status: task.status,
                  priority: task.priority,
                  dreamId: task.dreamId,
                  dreamTitle: task.dreamTitle,
                  userId: task.userId,
                  startDate: task.startDate,
                  dueDate: task.dueDate,
                  completedAt: task.completedAt,
                  reminderTime: task.reminderTime,
                  parentTaskId: task.parentTaskId,
                  createdAt: task.createdAt,
                  updatedAt: task.updatedAt,
                  isTodayTask: true,
                  isOverdue: task.isOverdue,
                  isUpcomingTask: task.isUpcomingTask
                };
                newTasks.push(taskWithToday);
              }
              this.tasks = newTasks;
            }
            this.hasMoreData = !todayResponse.last;
          }
          break;
          
        case 2: // 即将到期任务
          const upcomingResponse = await getUpcomingTasks(this.userId, this.upcomingDays, this.currentPage, this.pageSize);
          if (upcomingResponse && upcomingResponse.content) {
            if (this.currentPage === 0) {
              // 不使用map和对象展开，直接创建新对象
              const tasksWithUpcoming: Task[] = [];
              for (let i = 0; i < upcomingResponse.content.length; i++) {
                const task = upcomingResponse.content[i];
                const taskWithUpcoming: Task = {
                  id: task.id,
                  title: task.title,
                  description: task.description,
                  status: task.status,
                  priority: task.priority,
                  dreamId: task.dreamId,
                  dreamTitle: task.dreamTitle,
                  userId: task.userId,
                  startDate: task.startDate,
                  dueDate: task.dueDate,
                  completedAt: task.completedAt,
                  reminderTime: task.reminderTime,
                  parentTaskId: task.parentTaskId,
                  createdAt: task.createdAt,
                  updatedAt: task.updatedAt,
                  isTodayTask: task.isTodayTask,
                  isOverdue: task.isOverdue,
                  isUpcomingTask: true
                };
                tasksWithUpcoming.push(taskWithUpcoming);
              }
              this.tasks = tasksWithUpcoming;
            } else {
              // 不使用slice和展开运算符，直接创建新数组
              const newTasks: Task[] = [];
              for (let i = 0; i < this.tasks.length; i++) {
                newTasks[i] = this.tasks[i];
              }
              for (let i = 0; i < upcomingResponse.content.length; i++) {
                const task = upcomingResponse.content[i];
                const taskWithUpcoming: Task = {
                  id: task.id,
                  title: task.title,
                  description: task.description,
                  status: task.status,
                  priority: task.priority,
                  dreamId: task.dreamId,
                  dreamTitle: task.dreamTitle,
                  userId: task.userId,
                  startDate: task.startDate,
                  dueDate: task.dueDate,
                  completedAt: task.completedAt,
                  reminderTime: task.reminderTime,
                  parentTaskId: task.parentTaskId,
                  createdAt: task.createdAt,
                  updatedAt: task.updatedAt,
                  isTodayTask: task.isTodayTask,
                  isOverdue: task.isOverdue,
                  isUpcomingTask: true
                };
                newTasks.push(taskWithUpcoming);
              }
              this.tasks = newTasks;
            }
            this.hasMoreData = !upcomingResponse.last;
          }
          break;
          
        default: // 按状态筛选 (3-待开始, 4-进行中, 5-已完成, 6-已延期)
          const status = this.selectedTab - 3;
          const response = await getTasksByStatus(this.userId, status);
          if (response) {
            this.tasks = response;
            this.hasMoreData = false;
          }
          break;
      }
    } catch (error) {
      console.error(`加载任务失败: ${error}`);
      prompt.showToast({
        message: '加载任务失败，请稍后重试',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
      this.refreshing = false;
    }
  }
  
  async onRefresh() {
    this.refreshing = true;
    this.currentPage = 0;
    await this.loadTasks();
    this.refreshing = false;
  }
  
  async loadMoreData() {
    if (this.hasMoreData && !this.isLoading && (this.selectedTab <= 2 || this.isSearchMode)) {
      this.currentPage++;
      await this.loadTasks();
    }
  }
  
  async updateStatus(task: Task, newStatus: number) {
    try {
      const updatedTask = await updateTaskStatus(task.id, newStatus);
      if (updatedTask) {
        // 更新本地任务列表
        const index = this.tasks.findIndex(t => t.id === task.id);
        if (index !== -1) {
          // 不使用slice创建新数组，直接手动复制
          const newTasks: Task[] = [];
          for (let i = 0; i < this.tasks.length; i++) {
            if (i === index) {
              newTasks.push(updatedTask);
            } else {
              newTasks.push(this.tasks[i]);
            }
          }
          this.tasks = newTasks;
        }
        
        prompt.showToast({
          message: '任务状态已更新',
          duration: 2000
        });
      }
    } catch (error) {
      console.error(`更新任务状态失败: ${error}`);
      prompt.showToast({
        message: '更新任务状态失败，请稍后重试',
        duration: 2000
      });
    }
  }
  
  goToAddTask() {
    router.pushUrl({
      url: 'pages/task/TaskEditPage',
      params: {
        isEdit: false,
        userId: this.userId
      }
    });
  }
  
  goToEditTask(task: Task) {
    router.pushUrl({
      url: 'pages/task/TaskEditPage',
      params: {
        isEdit: true,
        taskId: task.id,
        task: task
      }
    });
  }
  
  async handleSearch() {
    if (this.searchKeyword.trim().length > 0) {
      this.isSearchMode = true;
      this.currentPage = 0;
      await this.loadTasks();
    }
  }
  
  clearSearch() {
    this.searchKeyword = "";
    this.isSearchMode = false;
    this.currentPage = 0;
    this.loadTasks();
  }

  getPriorityColor(priority: number): Resource {
    switch (priority) {
      case 1:
        return $r('app.color.priority_highest');
      case 2:
        return $r('app.color.priority_high');
      case 3:
        return $r('app.color.priority_medium');
      case 4:
        return $r('app.color.priority_low');
      case 5:
        return $r('app.color.priority_lowest');
      default:
        return $r('app.color.priority_medium');
    }
  }

  getStatusText(status: number): string {
    switch (status) {
      case 0:
        return '待开始';
      case 1:
        return '进行中';
      case 2:
        return '已完成';
      case 3:
        return '已延期';
      default:
        return '未知';
    }
  }

  getStatusColor(status: number): Resource {
    switch (status) {
      case 0:
        return $r('app.color.pending_color');
      case 1:
        return $r('app.color.progress_color');
      case 2:
        return $r('app.color.completed_color');
      case 3:
        return $r('app.color.overdue_color');
      default:
        return $r('app.color.text_primary');
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部标题和搜索栏
        Column() {
        Row() {
          Text('我的任务')
            .fontSize(CommonConstants.FONT_SIZE_XXLARGE)
            .fontWeight(FontWeight.Bold)
          
          Image(AppIcons.add)
            .width(24)
            .height(24)
            .fillColor($r('app.color.text_primary'))
              .onClick(() => this.goToAddTask())
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          
          // 搜索栏
          Row() {
            Row() {
              Image(AppIcons.search)
                .width(20)
                .height(20)
                .fillColor($r('app.color.text_secondary'))
                .margin({ right: CommonConstants.MARGIN_SMALL })
              
              TextInput({ placeholder: '搜索任务', text: this.searchKeyword })
                .width('100%')
                .height(40)
                .backgroundColor(Color.Transparent)
                .placeholderColor($r('app.color.text_placeholder'))
                .onChange((value: string) => {
                  this.searchKeyword = value;
                })
                .onSubmit(() => this.handleSearch())
            }
            .width('85%')
            .height(40)
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .backgroundColor($r('app.color.input_background'))
            .padding({ left: CommonConstants.MARGIN_NORMAL, right: CommonConstants.MARGIN_NORMAL })
            
            // 搜索或取消按钮
            if (this.isSearchMode) {
              Text('取消')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.primary_color'))
                .onClick(() => this.clearSearch())
            } else {
              Image(AppIcons.search)
                .width(24)
                .height(24)
                .fillColor($r('app.color.primary_color'))
                .onClick(() => this.handleSearch())
            }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
          .margin({ top: CommonConstants.MARGIN_NORMAL })
        }
        .padding({ 
          top: CommonConstants.MARGIN_LARGE, 
          bottom: CommonConstants.MARGIN_MEDIUM,
          left: CommonConstants.MARGIN_LARGE,
          right: CommonConstants.MARGIN_LARGE
        })
        
        // 任务状态Tab
        if (!this.isSearchMode) {
        Tabs({ barPosition: BarPosition.Start, index: this.selectedTab }) {
          ForEach(this.tabs, (tabName: string, index: number) => {
            TabContent() {
              this.taskList(index)
            }
            .tabBar(this.TabBuilder(tabName, index))
          })
        }
        .barMode(BarMode.Scrollable)
        .barWidth('100%')
        .barHeight(48)
        .animationDuration(300)
        .onChange((index: number) => {
            if (this.selectedTab !== index) {
          this.selectedTab = index;
              this.currentPage = 0;
              this.loadTasks();
            }
        })
        .layoutWeight(1)
        } else {
          // 搜索结果显示
          Column() {
            Text(`"${this.searchKeyword}" 的搜索结果`)
              .fontSize(CommonConstants.FONT_SIZE_MEDIUM)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: CommonConstants.MARGIN_NORMAL })
            
            this.taskList(-1) // 使用特殊索引表示搜索模式
          }
          .layoutWeight(1)
          .width('100%')
          .padding({ left: CommonConstants.MARGIN_LARGE, right: CommonConstants.MARGIN_LARGE })
        }
      }
      .width('100%')
      .height('100%')
      
      // 添加悬浮的新增任务按钮
      Button() {
        Row() {
          Image(AppIcons.add)
            .width(24)
            .height(24)
            .fillColor(Color.White)
          
          Text('新增任务')
            .fontColor(Color.White)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 8 })
        }
      }
      .type(ButtonType.Capsule)
      .backgroundColor($r('app.color.primary_color'))
      .width(140)
      .height(48)
      .margin(16)
      .onClick(() => this.goToAddTask())
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TabBuilder(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(CommonConstants.FONT_SIZE_NORMAL)
        .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.selectedTab === index ? $r('app.color.primary_color') : $r('app.color.text_primary'))
        .margin({ top: CommonConstants.MARGIN_SMALL, bottom: CommonConstants.MARGIN_SMALL })
      
      Divider()
        .width('60%')
        .height(2)
        .backgroundColor(this.selectedTab === index ? $r('app.color.primary_color') : 'transparent')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  taskList(tabIndex: number) {
    Refresh({ refreshing: this.refreshing, offset: 80, friction: 66 }) {
      List({ space: CommonConstants.MARGIN_NORMAL }) {
        if (this.isLoading && this.tasks.length === 0) {
          ListItem() {
            Column() {
              LoadingProgress()
                .width(30)
                .height(30)
                .color($r('app.color.primary_color'))
              Text('加载中...')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: CommonConstants.MARGIN_NORMAL })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .height(200)
          }
        } else if (this.tasks.length === 0) {
          ListItem() {
      Column() {
              Image($r('app.media.ic_empty_task'))
                .width(120)
                .height(120)
                .objectFit(ImageFit.Contain)
              Text(this.isSearchMode ? '未找到相关任务' : '暂无任务')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: CommonConstants.MARGIN_LARGE })
              Button('添加任务')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontColor(Color.White)
                .backgroundColor($r('app.color.primary_color'))
                .borderRadius(CommonConstants.RADIUS_NORMAL)
                .margin({ top: CommonConstants.MARGIN_XLARGE })
                .onClick(() => this.goToAddTask())
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .height(400)
          }
          } else {
          ForEach(this.tasks, (task: Task) => {
            this.buildTaskItem(task)
          })
          
          if (this.hasMoreData && (this.selectedTab <= 2 || this.isSearchMode)) {
            ListItem() {
              Row() {
                if (this.isLoading) {
                  LoadingProgress()
                    .width(20)
                    .height(20)
                    .color($r('app.color.primary_color'))
                    .margin({ right: CommonConstants.MARGIN_SMALL })
                }
                Text('加载更多...')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .height(40)
            }
            .onClick(() => this.loadMoreData())
          }
        }
      }
      .width('100%')
      .padding({ left: CommonConstants.MARGIN_LARGE, right: CommonConstants.MARGIN_LARGE })
      .listDirection(Axis.Vertical)
      .edgeEffect(EdgeEffect.Spring)
      .onReachEnd(() => {
        if (this.hasMoreData && !this.isLoading && (this.selectedTab <= 2 || this.isSearchMode)) {
          this.loadMoreData();
        }
      })
    }
    .onRefreshing(() => {
      this.onRefresh();
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildTaskItem(task: Task) {
    ListItem() {
          Column() {
            Row() {
              // 优先级标记
              Circle({ width: 16, height: 16 })
                .fill(this.getPriorityColor(task.priority))
                .margin({ right: CommonConstants.MARGIN_NORMAL })
              
              // 任务信息
              Column() {
                Row() {
                  Text(task.title)
                    .fontSize(CommonConstants.FONT_SIZE_MEDIUM)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(task.status === 2 ? $r('app.color.text_secondary') : $r('app.color.text_primary'))
                    .decoration(task.status === 2 ? { type: TextDecorationType.LineThrough, color: $r('app.color.text_secondary') } : null)
                    .layoutWeight(1)
                  
              // 显示任务状态和提醒标记
              Row() {
                if (task.reminderTime) {
                  Image(AppIcons.notification)
                    .width(16)
                    .height(16)
                    .fillColor($r('app.color.primary_color'))
                    .margin({ right: CommonConstants.MARGIN_SMALL })
                }
                
                if (task.isTodayTask) {
                  Text('今日')
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.primary_color'))
                    .fontWeight(FontWeight.Medium)
                    .borderRadius(CommonConstants.RADIUS_SMALL)
                    .backgroundColor($r('app.color.background_color'))
                    .padding({
                      left: CommonConstants.MARGIN_SMALL,
                      right: CommonConstants.MARGIN_SMALL,
                      top: 2,
                      bottom: 2
                    })
                    .margin({ right: CommonConstants.MARGIN_SMALL })
                }
                
                if (task.isOverdue) {
                  Text('已逾期')
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.overdue_color'))
                    .fontWeight(FontWeight.Medium)
                    .borderRadius(CommonConstants.RADIUS_SMALL)
                    .backgroundColor($r('app.color.background_color'))
                    .padding({
                      left: CommonConstants.MARGIN_SMALL,
                      right: CommonConstants.MARGIN_SMALL,
                      top: 2,
                      bottom: 2
                    })
                    .margin({ right: CommonConstants.MARGIN_SMALL })
                }
                  
                  Text(this.getStatusText(task.status))
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor(this.getStatusColor(task.status))
                    .fontWeight(FontWeight.Medium)
                    .borderRadius(CommonConstants.RADIUS_SMALL)
                    .backgroundColor(Color.Transparent)
                    .padding({
                      left: CommonConstants.MARGIN_NORMAL,
                      right: CommonConstants.MARGIN_NORMAL,
                      top: 2,
                      bottom: 2
                    })
                    .border({
                      width: 1,
                      color: this.getStatusColor(task.status),
                      style: BorderStyle.Solid,
                      radius: CommonConstants.RADIUS_SMALL
                    })
              }
                }
                .width('100%')
                
                Text(task.description)
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor(task.status === 2 ? $r('app.color.text_tertiary') : $r('app.color.text_secondary'))
                  .margin({ top: 2 })
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                
                Row() {
              if (task.dreamTitle) {
                  Text(task.dreamTitle)
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_tertiary'))
                    .backgroundColor($r('app.color.tag_background'))
                    .borderRadius(CommonConstants.RADIUS_SMALL)
                    .padding({
                      left: CommonConstants.MARGIN_NORMAL,
                      right: CommonConstants.MARGIN_NORMAL,
                      top: 2,
                      bottom: 2
                    })
                    .margin({ right: CommonConstants.MARGIN_NORMAL })
              }
              
              Row() {
                Image(AppIcons.calendar)
                  .width(14)
                  .height(14)
                  .fillColor($r('app.color.text_tertiary'))
                  .margin({ right: 4 })
                
                Text(`截止: ${task.dueDate}`)
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor(task.status === 3 ? $r('app.color.overdue_color') : $r('app.color.text_tertiary'))
              }
                }
                .margin({ top: CommonConstants.MARGIN_SMALL })
                .width('100%')
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              
              // 右侧操作区
              if (task.status !== 2) {
                Toggle({ type: ToggleType.Checkbox, isOn: false })
                  .width(20)
                  .height(20)
                  .onChange((isOn: boolean) => {
                    if (isOn) {
                  this.updateStatus(task, 2);
                    }
                  })
              }
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
        
        // 操作按钮
        Row() {
          // 记录进度按钮
          Button({ type: ButtonType.Capsule }) {
            Row() {
              Image(AppIcons.edit)
                .width(16)
                .height(16)
                .fillColor($r('app.color.primary_color'))
                .margin({ right: 4 })
              
              Text('记录进度')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.primary_color'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
          }
          .height(32)
          .width(100) 
          .backgroundColor($r('app.color.background_color'))
          .padding(0)
          .margin(0)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/task/TaskProgressPage',
              params: {
                taskId: task.id
              }
            })
          })
          
          Blank()
            .layoutWeight(1)
          
          // 编辑按钮
          Button({ type: ButtonType.Capsule }) {
            Row() {
              Image(AppIcons.edit)
                .width(16)
                .height(16)
                .fillColor($r('app.color.primary_color'))
                .margin({ right: 4 })
              
              Text('编辑')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.primary_color'))
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
          }
          .height(32)
          .width(80)
          .backgroundColor(Color.White)
          .borderWidth(1)
          .borderColor($r('app.color.primary_color'))
          .padding(0)
          .margin(0)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/task/TaskEditPage',
              params: {
                isEdit: true,
                task: task
              }
            })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 8 })
          }
          .width('100%')
          .padding(CommonConstants.MARGIN_MEDIUM)
          .borderRadius(CommonConstants.RADIUS_NORMAL)
          .backgroundColor($r('app.color.card_background'))
      .onClick(() => {
        // 点击整个卡片时也跳转到编辑页面
        router.pushUrl({
          url: 'pages/task/TaskEditPage',
          params: {
            isEdit: true,
            task: task
          }
        })
      })
    }
    .margin({ bottom: CommonConstants.MARGIN_NORMAL })
  }
} 