import router from '@ohos.router';
import prompt from '@ohos.promptAction';
import { CommonConstants } from '../../constants/CommonConstants';
import { Task } from '../../model/CommonTypes';
import { getTaskById, updateTaskStatus, getTaskProgress } from '../../services/TaskService';
import type { Progress } from '../../services/TaskService';
import { CommonIcon } from '../../components/CommonIcon';
import { MyLoadingProgress } from '../../components/LoadingProgress';
import { AppIcons } from '../../utils/IconUtils';

/**
 * 路由参数类型定义
 */
interface RouteParams {
  taskId: number;
  source?: string;
}

@Entry
@Component
struct TaskDetailPage {
  @State task: Task | null = null;
  @State isLoading: boolean = true;
  @State progress: Progress[] = [];
  @State isLoadingProgress: boolean = false;
  @State isUpdating: boolean = false;
  
  // 从路由参数获取任务ID
  private taskId: number = 0;
  private source: string = '';
  
  aboutToAppear() {
    const params = router.getParams() as RouteParams;
    this.taskId = params.taskId || 0;
    this.source = params.source || '';
    
    if (this.taskId) {
      this.loadTaskDetails();
    } else {
      this.isLoading = false;
      prompt.showToast({
        message: '无效的任务ID',
        duration: 2000
      });
    }
  }
  
  /**
   * 加载任务详情
   */
  async loadTaskDetails() {
    try {
      this.isLoading = true;
      // 获取任务详情
      this.task = await getTaskById(this.taskId);
      // 加载进度记录
      this.loadTaskProgress();
    } catch (error) {
      console.error(`加载任务详情失败: ${error instanceof Error ? error.message : String(error)}`);
      prompt.showToast({
        message: '加载任务详情失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 加载任务进度记录
   */
  async loadTaskProgress() {
    try {
      this.isLoadingProgress = true;
      // 获取任务进度记录
      this.progress = await getTaskProgress(this.taskId);
    } catch (error) {
      console.error(`加载进度记录失败: ${error instanceof Error ? error.message : String(error)}`);
      prompt.showToast({
        message: '加载进度记录失败',
        duration: 2000
      });
    } finally {
      this.isLoadingProgress = false;
    }
  }
  
  /**
   * 更新任务状态
   * 
   * @param status 新状态
   */
  async updateTaskStatus(status: number) {
    if (!this.task) return;
    
    try {
      this.isUpdating = true;
      // 更新任务状态
      const updatedTask = await updateTaskStatus(this.task.id, status);
      if (updatedTask) {
        this.task = updatedTask;
        prompt.showToast({
          message: '状态更新成功',
          duration: 2000
        });
      }
    } catch (error) {
      console.error(`更新任务状态失败: ${error instanceof Error ? error.message : String(error)}`);
      prompt.showToast({
        message: '更新任务状态失败',
        duration: 2000
      });
    } finally {
      this.isUpdating = false;
    }
  }
  
  /**
   * 获取任务状态文本
   * 
   * @param status 状态码
   * @returns 状态文本
   */
  getTaskStatusText(status: number): string {
    switch (status) {
      case 0: return '待开始';
      case 1: return '进行中';
      case 2: return '已完成';
      case 3: return '已延期';
      default: return '未知';
    }
  }
  
  /**
   * 获取任务状态颜色
   * 
   * @param status 状态码
   * @returns 状态颜色
   */
  getTaskStatusColor(status: number): string {
    switch (status) {
      case 0: return '#888888';
      case 1: return '#2196F3';
      case 2: return '#4CAF50';
      case 3: return '#F44336';
      default: return '#888888';
    }
  }
  
  /**
   * 获取优先级文本
   * 
   * @param priority 优先级
   * @returns 优先级文本
   */
  getPriorityText(priority: number): string {
    switch (priority) {
      case 1: return '最高';
      case 2: return '高';
      case 3: return '中';
      case 4: return '低';
      case 5: return '最低';
      default: return '中';
    }
  }
  
  /**
   * 获取优先级颜色
   * 
   * @param priority 优先级
   * @returns 优先级颜色
   */
  getPriorityColor(priority: number): string {
    switch (priority) {
      case 1: return '#F44336'; // 红色
      case 2: return '#FF9800'; // 橙色
      case 3: return '#2196F3'; // 蓝色
      case 4: return '#4CAF50'; // 绿色
      case 5: return '#9E9E9E'; // 灰色
      default: return '#2196F3'; // 默认蓝色
    }
  }
  
  /**
   * 格式化日期
   * 
   * @param dateString ISO格式日期字符串
   * @returns 格式化后的日期字符串
   */
  formatDate(dateString: string): string {
    if (!dateString) return '';
    const date = new Date(dateString);
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }
  
  build() {
    Column() {
      // 顶部导航栏
      Row() {
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
        .onClick(() => router.back())
        
        Text('任务详情')
          .fontSize(CommonConstants.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({
        left: CommonConstants.MARGIN_LARGE,
        right: CommonConstants.MARGIN_LARGE,
        top: CommonConstants.MARGIN_LARGE,
        bottom: CommonConstants.MARGIN_NORMAL
      })
      .alignItems(VerticalAlign.Center)
      
      // 内容区域
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
      } else if (this.task) {
        Scroll() {
          Column() {
            // 任务基本信息卡片
            Column() {
              // 任务标题和状态
              Row() {
                Text(this.task.title)
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .layoutWeight(1)
                
                Text(this.getTaskStatusText(this.task.status))
                  .fontSize(14)
                  .backgroundColor(this.getTaskStatusColor(this.task.status))
                  .fontColor('#FFFFFF')
                  .borderRadius(4)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              }
              .width('100%')
              .padding({ bottom: 12 })
              
              // 任务描述
              if (this.task.description) {
                Text(this.task.description)
                  .fontSize(16)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                  .margin({ bottom: 16 })
              }
              
              // 任务详细信息
              Column() {
                Row() {
                  if (this.task.startDate) {
                    Row() {
                      Image(AppIcons.calendar)
                        .width(16)
                        .height(16)
                        .fillColor($r('app.color.text_tertiary'))
                        .margin({ right: 4 })
                      
                      Text(`开始: ${this.task.startDate}`)
                        .fontSize(14)
                        .fontColor($r('app.color.text_tertiary'))
                    }
                    .margin({ right: 16 })
                  }
                  
                  if (this.task.dueDate) {
                    Row() {
                      Image(AppIcons.calendar)
                        .width(16)
                        .height(16)
                        .fillColor($r('app.color.text_tertiary'))
                        .margin({ right: 4 })
                      
                      Text(`截止: ${this.task.dueDate}`)
                        .fontSize(14)
                        .fontColor($r('app.color.text_tertiary'))
                    }
                  }
                }
                .margin({ bottom: 8 })
                
                Row() {
                  Row() {
                    Circle({ width: 12, height: 12 })
                      .fill(this.getPriorityColor(this.task.priority))
                      .margin({ right: 4 })
                    
                    Text(`优先级: ${this.getPriorityText(this.task.priority)}`)
                      .fontSize(14)
                      .fontColor($r('app.color.text_tertiary'))
                  }
                  .margin({ right: 16 })
                }
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              
              // 任务操作按钮
              Row() {
                Button('记录进度')
                  .fontSize(14)
                  .backgroundColor($r('app.color.primary_color'))
                  .fontColor(Color.White)
                  .width(120)
                  .height(36)
                  .onClick(() => {
                    if (this.task && this.task.id) {
                      router.pushUrl({
                        url: 'pages/task/TaskProgressPage',
                        params: {
                          taskId: this.task.id
                        }
                      });
                    }
                  })
                
                Blank().layoutWeight(1)
                
                Button(this.task && this.task.status === 2 ? '标记未完成' : '标记完成')
                  .fontSize(14)
                  .backgroundColor(this.task && this.task.status === 2 ? '#888888' : '#4CAF50')
                  .fontColor(Color.White)
                  .width(120)
                  .height(36)
                  .onClick(() => {
                    if (this.task) {
                      this.updateTaskStatus(this.task.status === 2 ? 1 : 2);
                    }
                  })
              }
              .width('100%')
              .margin({ top: 16 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ bottom: 16 })
            
            // 进度记录列表
            Column() {
              Row() {
                Text('进度记录')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              
              // 进度记录内容
              if (this.isLoadingProgress) {
                Column() {
                  MyLoadingProgress()
                  
                  Text('加载中...')
                    .fontSize(16)
                    .margin({ top: 16 })
                }
                .width('100%')
                .height(200)
                .justifyContent(FlexAlign.Center)
              } else if (this.progress.length === 0) {
                Column() {
                  Image(AppIcons.empty)
                    .width(80)
                    .height(80)
                    .fillColor('#CCCCCC')
                    .opacity(0.6)
                  
                  Text('暂无进度记录')
                    .fontSize(16)
                    .margin({ top: 16 })
                    .fontColor('#999999')
                }
                .width('100%')
                .height(200)
                .justifyContent(FlexAlign.Center)
              } else {
                // 按时间倒序排列进度记录
                ForEach(this.progress.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()), (item: Progress) => {
                  Column() {
                    // 记录时间
                    Row() {
                      Image(AppIcons.time)
                        .width(16)
                        .height(16)
                        .fillColor($r('app.color.text_tertiary'))
                        .margin({ right: 4 })
                      
                      Text(this.formatDate(item.createdAt))
                        .fontSize(14)
                        .fontColor($r('app.color.text_tertiary'))
                    }
                    .width('100%')
                    .margin({ bottom: 8 })
                    
                    // 记录内容
                    Text(item.description)
                      .fontSize(16)
                      .fontColor($r('app.color.text_secondary'))
                      .width('100%')
                      .margin({ bottom: 8 })
                    
                    // 图片展示（如果有）
                    if (item.images && item.images.length > 0) {
                      Column() {
                        Grid() {
                          ForEach(item.images.split(','), (imageUrl: string) => {
                            GridItem() {
                              Stack() {
                                Image(imageUrl)
                                  .width('100%')
                                  .height('100%')
                                  .objectFit(ImageFit.Cover)
                                  .borderRadius(4)
                              }
                              .width('100%')
                              .aspectRatio(1)
                              .onClick(() => {
                                // 点击查看大图
                              })
                            }
                          })
                        }
                        .columnsTemplate('1fr 1fr 1fr')
                        .columnsGap(8)
                        .rowsGap(8)
                        .width('100%')
                      }
                      .width('100%')
                    }
                    
                    Divider()
                      .color('#EEEEEE')
                      .width('100%')
                      .margin({ top: 12, bottom: 12 })
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(8)
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
        // 错误状态
        Column() {
          CommonIcon({
            name: 'error',
            color: '#CCCCCC',
            iconSize: 100
          })
          .opacity(0.6)
          
          Text('任务不存在或已被删除')
            .fontSize(16)
            .margin({ top: 16 })
            .fontColor('#999999')
        }
        .width('100%')
        .height('80%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
} 