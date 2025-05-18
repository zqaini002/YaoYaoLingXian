import { CommonConstants, Task, PageResponse } from '../../model/CommonTypes';
import { AppIcons } from '../../utils/IconUtils';
import * as ApiService from '../../services/ApiService';
import router from '@ohos.router';

// 定义不带Entry装饰器的任务推荐页面组件
@Component
struct RecommendTasksPageContent {
  @State tasks: Task[] = [];
  @State isLoading: boolean = true;
  @State dataError: string | null = null;
  @State userId: number = 2; // 默认用户ID
  
  aboutToAppear() {
    this.loadData();
  }
  
  async loadData() {
    try {
      this.isLoading = true;
      
      // 获取推荐任务（包括今日任务和即将到期任务）
      const todayTasks = await ApiService.getTodayTasks(this.userId, 0, 50);
      const upcomingTasks = await ApiService.getUpcomingTasks(this.userId, 7, 0, 50);
      
      // 合并两个列表并去重
      let allTasks: Task[] = [...todayTasks.content];
      
      // 添加未包含的即将到期任务
      upcomingTasks.content.forEach(task => {
        if (!allTasks.some(t => t.id === task.id)) {
          task.isUpcomingTask = true;
          allTasks.push(task);
        }
      });
      
      // 按优先级和截止日期排序
      allTasks.sort((a, b) => {
        // 先按状态排序（进行中 > 待开始 > 已完成）
        if (a.status !== b.status) {
          return a.status === 1 ? -1 : b.status === 1 ? 1 : 
                 a.status === 0 ? -1 : b.status === 0 ? 1 : 0;
        }
        
        // 再按优先级排序
        if (a.priority !== b.priority) {
          return a.priority - b.priority;
        }
        
        // 最后按截止日期排序
        const dateA = a.dueDate ? new Date(a.dueDate) : new Date(9999, 11, 31);
        const dateB = b.dueDate ? new Date(b.dueDate) : new Date(9999, 11, 31);
        return dateA.getTime() - dateB.getTime();
      });
      
      this.tasks = allTasks;
    } catch (error) {
      this.dataError = `加载失败: ${error}`;
      console.error('加载推荐任务失败', error);
    } finally {
      this.isLoading = false;
    }
  }
  
  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .onClick(() => {
            router.back();
          })
        
        Text('任务推荐')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      
      // 内容区域
      if (this.isLoading) {
        // 加载中状态
        LoadingProgress()
          .height(100)
          .width(100)
          .color(CommonConstants.COLOR_PRIMARY)
      } else if (this.dataError) {
        // 错误状态
        Column({ space: 16 }) {
          Image($r('app.media.empty'))
            .width(100)
            .height(100)
            .opacity(0.6)
          
          Text(this.dataError)
            .fontSize(16)
            .fontColor('#999999')
          
          Button('重试')
            .onClick(() => this.loadData())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.tasks.length === 0) {
        // 空状态
        Column({ space: 16 }) {
          Image($r('app.media.empty'))
            .width(100)
            .height(100)
            .opacity(0.6)
          
          Text('暂无推荐任务')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 任务列表
        List() {
          ForEach(this.tasks, (task: Task) => {
            ListItem() {
              Row() {
                // 任务状态选择框
                Checkbox()
                  .select(task.status === 2)
                  .onChange((isChecked) => {
                    this.updateTaskStatus(task.id, isChecked ? 2 : 0);
                  })
                  .margin({ right: 10 })
                
                // 任务内容
                Column({ space: 4 }) {
                  // 任务标题
                  Text(task.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(task.status === 2 ? '#999999' : '#333333')
                    .decoration(task.status === 2 ? { type: TextDecorationType.LineThrough } : { type: TextDecorationType.None })
                  
                  // 任务描述
                  if (task.description) {
                    Text(task.description)
                      .fontSize(14)
                      .fontColor('#666666')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  
                  // 任务信息
                  Row({ space: 8 }) {
                    // 来源梦想
                    Text(task.dreamTitle || '')
                      .fontSize(13)
                      .fontColor(CommonConstants.COLOR_PRIMARY)
                    
                    // 截止时间
                    if (task.dueDate) {
                      Row({ space: 2 }) {
                        Image($r('app.media.ic_calendar'))
                          .width(16)
                          .height(16)
                          .fillColor('#999999')
                        
                        Text(`${task.isOverdue ? '已逾期' : task.isTodayTask ? '今天' : task.dueDate}`)
                          .fontSize(13)
                          .fontColor(task.isOverdue ? '#FF5252' : '#999999')
                      }
                    }
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                
                // 优先级标识（仅显示高优先级）
                if (task.priority <= 2) {
                  Text(task.priority === 1 ? '紧急' : '重要')
                    .fontSize(12)
                    .fontColor('#FFFFFF')
                    .backgroundColor(task.priority === 1 ? '#FF5252' : '#FF9800')
                    .borderRadius(4)
                    .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                }
              }
              .width('100%')
              .padding(15)
              .borderRadius(8)
              .backgroundColor('#F5F5F5')
              .margin({ bottom: 10 })
            }
          })
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
  
  // 更新任务状态
  async updateTaskStatus(taskId: number, status: number) {
    try {
      await ApiService.updateTaskStatus(taskId, status);
      // 更新本地数据
      const index = this.tasks.findIndex(task => task.id === taskId);
      if (index !== -1) {
        this.tasks[index].status = status;
        if (status === 2) {
          this.tasks[index].completedAt = new Date().toISOString();
        } else {
          this.tasks[index].completedAt = null;
        }
      }
    } catch (error) {
      console.error('更新任务状态失败', error);
    }
  }
}

// 入口页面
@Entry
@Component
export default struct RecommendTasksPage {
  build() {
    Column() {
      RecommendTasksPageContent()
    }
    .width('100%')
    .height('100%')
  }
} 