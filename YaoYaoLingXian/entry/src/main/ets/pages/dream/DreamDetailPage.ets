import router from '@ohos.router';
import { CommonConstants, Dream, Task } from '../../model/CommonTypes';
import * as ApiService from '../../services/ApiService';
import { AppIcons } from '../../utils/IconUtils';
import { CommonIcon } from '../../components/CommonIcon';
import { MyLoadingProgress } from '../../components/LoadingProgress';

// 定义路由参数接口
interface RouteParams {
  dreamId?: number;
  showTasks?: boolean;
  source?: string;
}

@Entry
@Component
struct DreamDetailPage {
  @State dream: Dream = {} as Dream;
  @State tasks: Task[] = [];
  @State isLoading: boolean = true;
  @State errorMessage: string | null = null;
  @State activeTab: number = 0; // 0: 详情, 1: 任务
  
  // 路由参数
  @State dreamId: number = 0;
  @State showTasks: boolean = false;
  @State source: string = '';
  
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouteParams;
    if (params && params.dreamId !== undefined) {
      this.dreamId = params.dreamId;
    }
    if (params && params.showTasks !== undefined) {
      this.showTasks = params.showTasks;
      if (this.showTasks) {
        this.activeTab = 1; // 默认显示任务选项卡
      }
    }
    if (params && params.source !== undefined) {
      this.source = params.source;
    }
    
    this.loadData();
  }
  
  async loadData() {
    try {
      this.isLoading = true;
      this.errorMessage = null;
      
      // 加载梦想详情
      this.dream = await ApiService.getDreamById(this.dreamId);
      console.info(`成功获取梦想详情, ID: ${this.dreamId}, 标题: ${this.dream.title}`);
      
      // 加载梦想相关任务
      await this.loadTasks();
    } catch (error) {
      console.error(`加载梦想详情失败: ${error instanceof Error ? error.message : String(error)}`);
      this.errorMessage = `加载数据失败: ${error instanceof Error ? error.message : String(error)}`;
    } finally {
      this.isLoading = false;
    }
  }
  
  // 加载梦想相关任务
  async loadTasks() {
    try {
      // 获取梦想下的任务列表
      const tasksResponse = await ApiService.getTasksByDreamId(this.dreamId);
      
      if (tasksResponse) {
        this.tasks = tasksResponse;
        console.info(`成功获取梦想任务列表, 数量: ${this.tasks.length}`);
        
        // 按状态排序：先显示进行中的任务
        this.tasks.sort((a, b) => {
          // 创建状态排序映射
          const statusOrder: Record<number, number> = {
            1: 0, // 进行中
            0: 1, // 待开始
            2: 2, // 已完成
            3: 3  // 已延期
          };
          
          const statusComparison = statusOrder[a.status] - statusOrder[b.status];
          if (statusComparison !== 0) return statusComparison;
          
          // 如果状态相同，按优先级排序（数字越小优先级越高）
          return a.priority - b.priority;
        });
        
        // 不再计算前端完成率，使用后端返回的值
      } else {
        console.warn(`获取梦想任务列表返回空值`);
        this.tasks = [];
      }
    } catch (error) {
      console.error(`加载梦想任务失败: ${error instanceof Error ? error.message : String(error)}`);
      // 不设置错误消息，保持任务列表为空
      this.tasks = [];
    }
  }
  
  // 更新任务状态
  async updateTaskStatus(taskId: number, status: number) {
    try {
      await ApiService.updateTaskStatus(taskId, status);
      
      // 更新完成率 - 重新获取梦想详情以获取正确的完成率
      this.dream = await ApiService.getDreamById(this.dreamId);
      
      // 刷新任务列表
      await this.loadTasks();
    } catch (error) {
      console.error(`更新任务状态失败: ${error instanceof Error ? error.message : String(error)}`);
      // 本地更新UI（乐观更新）
      const taskIndex = this.tasks.findIndex(task => task.id === taskId);
      if (taskIndex !== -1) {
        this.tasks[taskIndex].status = status;
      }
    }
  }
  
  getTaskStatusText(status: number): string {
    switch (status) {
      case 0: return '待开始';
      case 1: return '进行中';
      case 2: return '已完成';
      case 3: return '已延期';
      default: return '未知状态';
    }
  }
  
  getTaskStatusColor(status: number): string {
    switch (status) {
      case 0: return '#FF9800'; // 待开始：橙色
      case 1: return '#4CAF50'; // 进行中：绿色
      case 2: return '#2196F3'; // 已完成：蓝色
      case 3: return '#F44336'; // 已延期：红色
      default: return '#9E9E9E'; // 未知状态：灰色
    }
  }
  
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        // 返回按钮
        Button() {
          Row() {
            Image(AppIcons.back)
              .width(20)
              .height(20)
              .fillColor(Color.White)
              .margin({ right: 4 })
            
            Text('返回')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
          .alignItems(VerticalAlign.Center)
        }
        .backgroundColor($r('app.color.primary_color'))
        .borderRadius(CommonConstants.RADIUS_SMALL)
        .height(36)
        .padding({ left: 12, right: 12 })
        .border({
          width: 2,
          color: Color.White,
          style: BorderStyle.Solid
        })
        .shadow({
          radius: 6,
          color: 'rgba(0, 0, 0, 0.3)',
          offsetX: 2,
          offsetY: 2
        })
        .onClick(() => {
          router.back();
        })
        
        Text('梦想详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(CommonConstants.COLOR_PRIMARY)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      
      if (this.isLoading) {
        // 加载状态
        Column() {
          MyLoadingProgress()
          
          Text('加载中...')
            .fontSize(16)
            .margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage) {
        // 错误状态
        Column() {
          // 使用通用图标替代资源图标
          Image(AppIcons.error)
            .width(80)
            .height(80)
            .fillColor('#F44336')
          
          Text(this.errorMessage)
            .fontSize(16)
            .margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 页面内容
        Column() {
          // 梦想顶部卡片
          Stack({ alignContent: Alignment.BottomStart }) {
            Image(this.dream.imageUrl || '')
              .width('100%')
              .height(200)
              .objectFit(ImageFit.Cover)
            
            Column() {
              Row() {
                // 分类标签
                Text(this.dream.category || '')
                  .fontSize(14)
                  .backgroundColor(CommonConstants.COLOR_PRIMARY)
                  .fontColor('#FFFFFF')
                  .borderRadius(4)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                
                Blank()
                
                // 状态标签
                Text(this.dream.status === 1 ? '进行中' : 
                     (this.dream.status === 2 ? '已完成' : '已放弃'))
                  .fontSize(14)
                  .backgroundColor(this.dream.status === 1 ? '#4CAF50' : 
                                   (this.dream.status === 2 ? '#2196F3' : '#9E9E9E'))
                  .fontColor('#FFFFFF')
                  .borderRadius(4)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              }
              .width('100%')
              
              // 标题
              Text(this.dream.title || '')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .margin({ top: 8, bottom: 4 })
              
              // 完成率
              Row() {
                Text(`完成率: ${this.dream.completionRate}%`)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                
                Progress({ value: this.dream.completionRate || 0, total: 100 })
                  .color('#FFFFFF')
                  .height(6)
                  .width(100)
                  .margin({ left: 8 })
              }
            }
            .width('100%')
            .padding(16)
            .linearGradient({
              angle: 180,
              colors: [
                [0x00000000, 0.0],
                [0x99000000, 0.7],
                [0xDD000000, 1.0]
              ]
            })
          }
          .width('100%')
          
          // 选项卡
          Row() {
            Text('详情')
              .fontSize(16)
              .fontWeight(this.activeTab === 0 ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(this.activeTab === 0 ? CommonConstants.COLOR_PRIMARY : '#666666')
              .padding({ top: 12, bottom: 12, left: 24, right: 24 })
              .border({
                width: { bottom: this.activeTab === 0 ? 2 : 0 },
                color: CommonConstants.COLOR_PRIMARY
              })
              .onClick(() => {
                this.activeTab = 0;
              })
            
            Text('任务')
              .fontSize(16)
              .fontWeight(this.activeTab === 1 ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(this.activeTab === 1 ? CommonConstants.COLOR_PRIMARY : '#666666')
              .padding({ top: 12, bottom: 12, left: 24, right: 24 })
              .border({
                width: { bottom: this.activeTab === 1 ? 2 : 0 },
                color: CommonConstants.COLOR_PRIMARY
              })
              .onClick(() => {
                this.activeTab = 1;
              })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          
          // 内容区域
          if (this.activeTab === 0) {
            // 详情选项卡
            Scroll() {
              Column() {
                Column() {
                  // 描述
                  Row() {
                    Text('描述')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .width('30%')
                    
                    Text(this.dream.description || '无描述')
                      .fontSize(16)
                      .width('70%')
                  }
                  .width('100%')
                  .padding(16)
                  .justifyContent(FlexAlign.SpaceBetween)
                  
                  Divider().color('#EEEEEE').width('90%').margin({ left: '5%', right: '5%' })
                  
                  // 截止日期
                  Row() {
                    Text('截止日期')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .width('30%')
                    
                    Text(this.dream.deadline || '无截止日期')
                      .fontSize(16)
                      .width('70%')
                  }
                  .width('100%')
                  .padding(16)
                  .justifyContent(FlexAlign.SpaceBetween)
                  
                  Divider().color('#EEEEEE').width('90%').margin({ left: '5%', right: '5%' })
                  
                  // 优先级
                  Row() {
                    Text('优先级')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .width('30%')
                    
                    Text(this.dream.priority === 1 ? '最高' : 
                         (this.dream.priority === 2 ? '高' : 
                          (this.dream.priority === 3 ? '中' : 
                           (this.dream.priority === 4 ? '低' : '最低'))))
                      .fontSize(16)
                      .width('70%')
                  }
                  .width('100%')
                  .padding(16)
                  .justifyContent(FlexAlign.SpaceBetween)
                  
                  Divider().color('#EEEEEE').width('90%').margin({ left: '5%', right: '5%' })
                  
                  // 预计天数
                  Row() {
                    Text('预计天数')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .width('30%')
                    
                    Text(`${this.dream.expectedDays || 0}天`)
                      .fontSize(16)
                      .width('70%')
                  }
                  .width('100%')
                  .padding(16)
                }
                .width('100%')
                .margin({ top: 16 })
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
              }
              .width('100%')
              .padding(16)
            }
            .width('100%')
            .layoutWeight(1)
          } else {
            // 任务选项卡
            Scroll() {
              Column() {
                if (this.tasks.length === 0) {
                  // 无任务状态
                  Column() {
                    // 使用通用图标替代资源图标
                    CommonIcon({
                      name: 'empty',
                      color: '#CCCCCC',
                      iconSize: 100
                    })
                    .opacity(0.6)
                    
                    Text('暂无任务')
                      .fontSize(16)
                      .margin({ top: 16 })
                      .fontColor('#999999')
                  }
                  .width('100%')
                  .height(300)
                  .justifyContent(FlexAlign.Center)
                } else {
                  // 任务列表
                  ForEach(this.tasks, (task: Task) => {
                    Column() {
                      Row() {
                        // 任务状态选择框
                        Checkbox()
                          .select(task.status === 2)
                          .onChange((isChecked) => {
                            this.updateTaskStatus(task.id, isChecked ? 2 : 1);
                          })
                          .margin({ right: 16 })
                        
                        // 任务内容
                        Column() {
                          Text(task.title)
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                            .fontColor(task.status === 2 ? '#999999' : '#333333')
                            .decoration({ type: task.status === 2 ? TextDecorationType.LineThrough : TextDecorationType.None })
                          
                          Row() {
                            // 状态标签
                            Text(this.getTaskStatusText(task.status))
                              .fontSize(12)
                              .backgroundColor(this.getTaskStatusColor(task.status))
                              .fontColor('#FFFFFF')
                              .borderRadius(4)
                              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                              .margin({ right: 8, top: 4 })
                            
                            // 截止日期
                            if (task.dueDate) {
                              Text(`截止: ${task.dueDate}`)
                                .fontSize(12)
                                .fontColor('#666666')
                                .margin({ top: 4 })
                            }
                          }
                        }
                        .alignItems(HorizontalAlign.Start)
                        .layoutWeight(1)
                        
                        // 优先级指示器（仅显示高优先级）
                        if (task.priority <= 2) {
                          Text(task.priority === 1 ? '紧急' : '重要')
                            .fontSize(12)
                            .fontColor('#FFFFFF')
                            .backgroundColor(task.priority === 1 ? '#F44336' : '#FF9800')
                            .borderRadius(4)
                            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        }
                      }
                      .width('100%')
                      .padding({ top: 12, bottom: 12 })
                      
                      // 任务描述（如果有）
                      if (task.description) {
                        Text(task.description)
                          .fontSize(14)
                          .fontColor('#666666')
                          .width('100%')
                          .margin({ top: 4, bottom: 8, left: 40 })
                      }
                      
                      Divider().color('#EEEEEE').width('100%')
                    }
                    .width('100%')
                    .onClick(() => {
                      // 跳转到任务详情页
                      router.pushUrl({
                        url: 'pages/task/TaskDetailPage',
                        params: {
                          taskId: task.id
                        }
                      });
                    })
                  })
                }
              }
              .width('100%')
              .padding(16)
            }
            .width('100%')
            .layoutWeight(1)
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
} 