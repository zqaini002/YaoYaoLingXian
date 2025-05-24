import { CommonConstants, Dream, Task, DreamStats, HomePageData } from '../../model/CommonTypes';
import { AppIcons } from '../../utils/IconUtils';
import { CommonIcon } from '../../components/CommonIcon';
import { SystemIcon } from '../../components/SystemIcon';
import { getTimeOfDay, TimeUtils } from '../../utils/TimeUtils';
import * as ApiService from '../../services/ApiService';
import router from '@ohos.router';
import { UserSession } from '../../utils/auth/UserSession';

@Component
export struct HomePage {
  @State greeting: string = TimeUtils.getGreetingByTime();
  @State username: string = '梦想家';
  @State nickname: string = '梦想家';
  @State signature: string = '每天进步一点点，离梦想更近一点点。';
  
  // 统计数据
  @State totalDreams: number = 0;
  @State activeDreams: number = 0;
  @State completedDreams: number = 0;
  
  // 任务数据
  @State todayTasks: Task[] = [];
  @State upcomingTasks: Task[] = [];
  
  // 加载状态
  @State isLoading: boolean = true;
  @State dataError: string | null = null;
  @State lastUpdated: number = 0; // 最后更新时间戳
  
  // 图表数据
  private chartData: number[] = [30, 40, 30];
  private chartColors: string[] = [CommonConstants.COLOR_PRIMARY, CommonConstants.COLOR_SECONDARY, '#FFD166'];
  private chartLabels: string[] = ['进行中', '已完成', '未开始'];

  @State dreamStats: DreamStats = {
    userId: 0,
    totalDreams: 0,
    inProgressDreams: 0,
    completedDreams: 0,
    abandonedDreams: 0,
    dreamCompletionRate: 0,
    totalTasks: 0,
    completedTasks: 0,
    taskCompletionRate: 0
  };
  @State recentDreams: Dream[] = [];
  @State loading: boolean = true;
  @State dailyQuote: string = '每天进步一点点，离梦想更近一点点。';
  @State userId: number = 0; // 用户ID
  
  private dailyQuotes: string[] = [
    '每天进步一点点，离梦想更近一点点。',
    '坚持，是为梦想而努力的态度。',
    '不是因为有希望才去坚持，而是坚持了才会有希望。',
    '梦想不会逃跑，会逃跑的是那些缺乏毅力的人。',
    '成功的路上，不怕走得慢，就怕一直停。',
    '只要有梦想，就敢于去追求。',
    '每一个成功者都有一个开始，勇于开始，才能找到成功的路。'
  ];

  private userSession: UserSession = UserSession.getInstance();

  aboutToAppear() {
    this.initializeData();
    this.loadData();
  }
  
  // 初始化数据
  initializeData() {
    // 从UserSession获取当前登录用户的ID
    this.userId = this.userSession.getUserId();
    console.info(`初始化首页数据，获取用户ID: ${this.userId}`);
    
    // 获取用户信息
    const userInfo = this.userSession.getCurrentUser();
    if (userInfo) {
      this.username = userInfo.username;
      this.nickname = userInfo.nickname || this.username;
      this.signature = userInfo.signature || this.dailyQuote;
      console.info(`已从会话获取用户信息: 昵称=${this.nickname}, 签名=${this.signature}`);
    }
    
    // 随机选择一条每日励志语
    const randomQuoteIndex = Math.floor(Math.random() * this.dailyQuotes.length);
    this.dailyQuote = this.dailyQuotes[randomQuoteIndex];
    
    // 获取问候语
    this.greeting = TimeUtils.getGreetingByTime();
  }

  async loadData() {
    try {
      this.loading = true;
      this.dataError = null; // 重置错误状态
      this.lastUpdated = Date.now(); // 记录更新时间
      console.info('开始加载首页数据...');
      
      // 获取首页数据
      const homeData = await ApiService.getHomePageData(this.userId);
      console.info(`首页数据响应: ${JSON.stringify(homeData)}`);
      
      // 检查数据是否有效
      if (homeData) {
        console.info('成功获取首页数据，开始处理...');
        
        // 获取用户信息
        if (homeData.username) {
          this.username = homeData.username;
        }
        if (homeData.nickname) {
          this.nickname = homeData.nickname;
        }
        if (homeData.signature) {
          this.signature = homeData.signature;
        }
        console.info(`用户信息: 昵称=${this.nickname}, 签名=${this.signature}`);
        
        // 处理梦想统计
        if (homeData.dreamStats) {
          this.dreamStats = homeData.dreamStats;
          console.info(`梦想统计: ${JSON.stringify(this.dreamStats)}`);
          
          // 如果梦想完成率为0但有已完成任务，则使用任务完成率
          if (this.dreamStats.dreamCompletionRate === 0 && this.dreamStats.completedTasks > 0) {
            console.info('梦想完成率为0但存在已完成任务，使用任务完成率表示整体进度');
          }
        } else {
          console.warn('返回的数据中没有dreamStats字段');
        }
        
        // 处理今日任务
        if (homeData.todayTasks) {
          if (homeData.todayTasks.content && Array.isArray(homeData.todayTasks.content)) {
            this.todayTasks = homeData.todayTasks.content;
            console.info(`今日任务数量: ${this.todayTasks.length}`);
            
            // 如果今日任务为空，使用最近到期的任务作为推荐任务
            if (this.todayTasks.length === 0 && homeData.upcomingTasks && 
                homeData.upcomingTasks.content && homeData.upcomingTasks.content.length > 0) {
              console.info('今日任务为空，使用即将到期的任务作为推荐任务');
              // 获取前3个即将到期的任务作为今日推荐
              this.todayTasks = homeData.upcomingTasks.content.slice(0, 3);
              // 标记为今日任务
              this.todayTasks.forEach(task => {
                task.isTodayTask = true;
              });
              console.info(`已添加${this.todayTasks.length}个推荐任务`);
            }
          } else {
            console.info('返回的todayTasks没有content数组或为空');
            
            // 如果今日任务数据结构异常，尝试从upcomingTasks获取推荐
            if (homeData.upcomingTasks && homeData.upcomingTasks.content && 
                homeData.upcomingTasks.content.length > 0) {
              console.info('使用即将到期的任务作为推荐任务');
              this.todayTasks = homeData.upcomingTasks.content.slice(0, 3);
              // 标记为今日任务
              this.todayTasks.forEach(task => {
                task.isTodayTask = true;
              });
              console.info(`已添加${this.todayTasks.length}个推荐任务`);
            } else {
              this.todayTasks = []; // 设置为空数组而不是undefined
            }
          }
        } else {
          console.warn('返回的数据中没有todayTasks字段');
          
          // 如果没有todayTasks字段，尝试从upcomingTasks获取推荐
          if (homeData.upcomingTasks && homeData.upcomingTasks.content && 
              homeData.upcomingTasks.content.length > 0) {
            console.info('使用即将到期的任务作为推荐任务');
            this.todayTasks = homeData.upcomingTasks.content.slice(0, 3);
            // 标记为今日任务
            this.todayTasks.forEach(task => {
              task.isTodayTask = true;
            });
            console.info(`已添加${this.todayTasks.length}个推荐任务`);
          } else {
            this.todayTasks = []; // 设置为空数组而不是undefined
          }
        }
        
        // 处理最近更新的梦想
        if (homeData.recentDreams) {
          this.recentDreams = homeData.recentDreams;
          console.info(`梦想数量: ${this.recentDreams.length}`);
        } else {
          console.warn('返回的数据中没有recentDreams字段');
          this.recentDreams = []; // 设置为空数组而不是undefined
        }
      } else {
        console.warn('无法获取首页数据或数据为空');
        // 如果无法获取完整首页数据，则尝试单独获取各部分数据
        await this.fetchSeparateData();
      }
    } catch (error) {
      let errorMessage: string;
      if (error instanceof Error) {
        errorMessage = error.message;
      } else {
        errorMessage = String(error);
      }
      
      console.error(`加载首页数据失败: ${errorMessage}`);
      // 显示更详细的错误信息
      this.dataError = `数据加载失败: ${errorMessage}`;
      
      // 尝试单独获取各部分数据作为备选方案
      await this.fetchSeparateData();
    } finally {
      this.loading = false;
      console.info(`首页数据加载完成，时间: ${new Date().toLocaleTimeString()}`);
    }
  }
  
  // 单独获取各部分数据的方法
  async fetchSeparateData() {
    console.info('尝试单独获取各部分数据...');
    let hasAnyData = false;
    
    try {
        // 获取梦想统计数据
      const stats = await ApiService.getDreamStats(this.userId);
      console.info(`梦想统计获取成功，数据: ${JSON.stringify(stats)}`);
      
      if (stats) {
        this.dreamStats = stats;
        console.info(`梦想统计数据已更新: 总梦想数=${stats.totalDreams}, 已完成=${stats.completedDreams}, 进行中=${stats.inProgressDreams}`);
        hasAnyData = true;
      }
    } catch (error) {
      let errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(`获取梦想统计数据错误: ${errorMessage}`);
      // 保留默认值或使用当前UI显示值，不要把this.dreamStats设为undefined
      console.info('使用默认的梦想统计数据');
      // 确保dreamStats不为undefined
      if (!this.dreamStats) {
        this.dreamStats = {
          userId: this.userId,
          totalDreams: 0,
          inProgressDreams: 0,
          completedDreams: 0,
          abandonedDreams: 0,
          dreamCompletionRate: 0,
          totalTasks: 0,
          completedTasks: 0,
          taskCompletionRate: 0
        };
      }
    }
        
    try {
      // 获取今日任务
      const tasks = await ApiService.getTodayTasks(this.userId);
      console.info(`今日任务响应: ${JSON.stringify(tasks)}`);
      
      if (tasks && tasks.content && tasks.content.length > 0) {
        this.todayTasks = tasks.content;
        console.info(`今日任务数据已更新，数量: ${this.todayTasks.length}`);
        hasAnyData = true;
      } else {
        console.info('今日任务为空，尝试获取即将到期的任务作为推荐');
        
        // 直接尝试获取即将到期的任务作为推荐，无需等待检查今日任务是否为空
        try {
          const upcomingTasks = await ApiService.getUpcomingTasks(this.userId, 7);
          console.info(`即将到期任务响应: ${JSON.stringify(upcomingTasks)}`);
          
          if (upcomingTasks && upcomingTasks.content && upcomingTasks.content.length > 0) {
            console.info('使用即将到期的任务作为推荐任务');
            // 获取前3个即将到期的任务作为今日推荐
            this.todayTasks = upcomingTasks.content.slice(0, 3);
            // 标记为今日任务
            this.todayTasks.forEach(task => {
              task.isTodayTask = true;
            });
            console.info(`已添加${this.todayTasks.length}个推荐任务`);
            hasAnyData = true;
          } else {
            console.info('没有找到即将到期的任务');
            this.todayTasks = []; // 确保是空数组而不是undefined
          }
        } catch (upcomingError) {
          console.error(`获取即将到期任务错误: ${upcomingError instanceof Error ? upcomingError.message : String(upcomingError)}`);
          this.todayTasks = []; // 确保是空数组而不是undefined
        }
      }
    } catch (error) {
      let errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(`获取今日任务错误: ${errorMessage}`);
      
      // 当获取今日任务失败时，直接尝试获取即将到期的任务
      try {
        const upcomingTasks = await ApiService.getUpcomingTasks(this.userId, 7);
        console.info(`获取今日任务失败，尝试获取即将到期任务: ${JSON.stringify(upcomingTasks)}`);
        
        if (upcomingTasks && upcomingTasks.content && upcomingTasks.content.length > 0) {
          this.todayTasks = upcomingTasks.content.slice(0, 3);
          this.todayTasks.forEach(task => {
            task.isTodayTask = true;
          });
          console.info(`已添加${this.todayTasks.length}个推荐任务作为备选`);
          hasAnyData = true;
        } else {
          this.todayTasks = []; // 确保是空数组而不是undefined
        }
      } catch (upcomingError) {
        console.error(`获取即将到期任务备选方案也失败: ${upcomingError instanceof Error ? upcomingError.message : String(upcomingError)}`);
        this.todayTasks = []; // 确保是空数组而不是undefined
      }
    }
    
    try {
      // 获取梦想列表并筛选最近更新的
      const dreams = await ApiService.getDreamsByUserId(this.userId);
      console.info(`梦想列表响应: ${JSON.stringify(dreams)}`);
      
      if (dreams && dreams.length > 0) {
        // 使用sortDreams方法排序
        this.recentDreams = this.sortDreams(dreams).slice(0, 5); // 只取前5个
        console.info(`梦想数据已更新，数量: ${this.recentDreams.length}`);
        hasAnyData = true;
      } else {
        this.recentDreams = []; // 确保是空数组而不是undefined
      }
    } catch (error) {
      let errorMessage: string = error instanceof Error ? error.message : String(error);
      console.error(`获取梦想列表错误: ${errorMessage}`);
      this.recentDreams = []; // 确保是空数组而不是undefined
    }
    
    if (!hasAnyData && !this.dataError) {
      this.dataError = '无法获取任何数据，请检查网络连接或稍后重试';
    }
  }
  
  // 刷新数据
  refreshData() {
    this.loadData();
  }
  
  // 更新任务状态
  async updateTaskStatus(taskId: number, status: number) {
    try {
      await ApiService.updateTaskStatus(taskId, status);
      // 刷新数据
      this.refreshData();
    } catch (error) {
      console.error('更新任务状态失败', error);
      // 本地更新UI（乐观更新）
      const taskIndex = this.todayTasks.findIndex(task => task.id === taskId);
      if (taskIndex !== -1) {
        this.todayTasks[taskIndex].status = status;
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 内容区域
    Scroll() {
      Column() {
          // 顶部区域
          Stack({ alignContent: Alignment.Center }) {
            // 背景图片
            Image($r('app.media.home_background'))
              .width('100%')
              .height(180)
              .objectFit(ImageFit.Cover)

            // 标题区内容
            Column({ space: 8 }) {
              // 问候语
              Text(getTimeOfDay())
                .fontSize(16)
                .fontWeight(FontWeight.Regular)
                .fontColor('#333333')
                .opacity(0.85)
                .padding({ top: 8 })

              // 问候用户昵称
              Text(`${this.nickname || '梦想家'}`)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
              
              // 用户个性签名或每日励志名言
              Text(this.signature || this.dailyQuote)
                .fontSize(14)
                .fontColor('#333333')
                .opacity(0.75)
                .width('85%')
                .textAlign(TextAlign.Center)
                .padding({ top: 6, bottom: 6 })
            }
            .width('100%')
            .padding({ top: 5 })
          }
          .height(180)
          .width('100%')
          
          // 内容区域
          Column({ space: 15 }) {
            // 梦想统计卡片
            Column() {
              Text('梦想统计')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .padding({ left: 5, bottom: 5 })
              
              Row({ space: 10 }) {
                // 待完成
            Column() {
              Text(this.dreamStats.inProgressDreams.toString())
                    .fontSize(22)
                .fontWeight(FontWeight.Bold)
                    .fontColor('#4D8CFE')
              Text('进行中')
                    .fontSize(14)
                    .fontColor('#666666')
            }
                .backgroundColor('#E3F2FD')
                .borderRadius(12)
                .width('30%')
                .height(70)
                .justifyContent(FlexAlign.Center)

                // 已完成
            Column() {
              Text(this.dreamStats.completedDreams.toString())
                    .fontSize(22)
                .fontWeight(FontWeight.Bold)
                    .fontColor('#4CAF50')
              Text('已完成')
                    .fontSize(14)
                    .fontColor('#666666')
                }
                .backgroundColor('#E8F5E9')
                .borderRadius(12)
                .width('30%')
                .height(70)
                .justifyContent(FlexAlign.Center)
                
                // 总数
                Column() {
                  Text(this.dreamStats.totalDreams.toString())
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#9C27B0')
                  Text('总梦想')
                    .fontSize(14)
                    .fontColor('#666666')
                }
                .backgroundColor('#F3E5F5')
                .borderRadius(12)
                .width('30%')
                .height(70)
                .justifyContent(FlexAlign.Center)
          }
          .width('100%')
              .padding({ bottom: 10 })

              // 完成率
              Column({ space: 5 }) {
          Row() {
            Text('完成率:')
                    .fontSize(14)
                    .fontColor('#666666')
                  Text(`${this.dreamStats.taskCompletionRate}%`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(CommonConstants.COLOR_PRIMARY)
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                
                // 动画进度条
                Stack() {
                  Progress({ value: 0, total: 100 })
                    .color('#E3F2FD')
                    .height(10)
                    .width('100%')
                    
            Progress({ value: this.dreamStats.taskCompletionRate, total: 100 })
              .color($r('app.color.primary_color'))
              .height(10)
                    .width('100%')
                    .animation({
                      duration: 1000,
                      curve: Curve.EaseOut,
                      iterations: 1,
                      playMode: PlayMode.Normal
                    })
                }
          }
          .width('100%')
        }
        .width('100%')
            .padding(15)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)

            // 今日推荐任务
            Column() {
        Row() {
          Text('任务推荐')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
            
          Text('查看全部')
                  .fontSize(14)
                  .fontColor(CommonConstants.COLOR_PRIMARY)
                  .onClick(() => {
                    // 跳转到任务推荐页面
                    router.pushUrl({
                      url: 'pages/task/RecommendTasksPage'
                    });
                  })
        }
        .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .padding({ bottom: 10 })
              
              if (this.loading) {
                // 加载中
                LoadingProgress()
                  .height(100)
                  .width(100)
                  .color(CommonConstants.COLOR_PRIMARY)
              } else if (this.dataError) {
                // 显示错误提示
                Column({ space: 8 }) {
                  Image($r('app.media.empty'))
                    .width(80)
                    .height(80)
                    .opacity(0.6)
                  Text(this.dataError)
                    .fontSize(14)
                    .fontColor('#999999')
                }
                .height(150)
                .width('100%')
                .justifyContent(FlexAlign.Center)
              } else if (this.todayTasks.length === 0) {
                // 无任务时显示空状态
                Column({ space: 8 }) {
                  Image($r('app.media.empty'))
                    .width(80)
                    .height(80)
                    .opacity(0.6)
                  Text('暂无推荐任务')
                    .fontSize(14)
                    .fontColor('#999999')
                }
                .height(150)
                .width('100%')
                .justifyContent(FlexAlign.Center)
              } else {
                // 任务列表
                ForEach(this.todayTasks, (task: Task) => {
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
                      
                      // 任务信息
                      Row({ space: 8 }) {
                        // 来源梦想
                        Text(task.dreamTitle || '')
                          .fontSize(13)
                          .fontColor(CommonConstants.COLOR_PRIMARY)
                        
                        // 截止时间
                        if (task.dueDate) {
                          Row({ space: 2 }) {
                            CommonIcon({
                              name: 'calendar',
                              color: '#999999',
                              iconSize: 16
                            })
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
                  .padding(10)
                  .borderRadius(8)
                  .backgroundColor('#F5F5F5')
                  .margin({ bottom: 10 })
                })
              }
            }
            .width('100%')
            .padding(15)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            
            // 最近更新的梦想
            Column() {
              Text('最近更新的梦想')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .padding({ bottom: 10 })
                  
              if (this.loading) {
                // 加载中
                LoadingProgress()
                  .height(100)
                  .width(100)
                  .color(CommonConstants.COLOR_PRIMARY)
              } else if (this.dataError) {
                // 显示错误提示
                Column({ space: 8 }) {
                  Image($r('app.media.empty'))
                    .width(80)
                    .height(80)
                    .opacity(0.6)
                  Text(this.dataError)
                    .fontSize(14)
                    .fontColor('#999999')
                }
                .height(150)
                .width('100%')
                .justifyContent(FlexAlign.Center)
              } else if (this.recentDreams.length === 0) {
                // 无梦想时显示空状态
                Column({ space: 8 }) {
                  Image($r('app.media.empty'))
                    .width(80)
                    .height(80)
                    .opacity(0.6)
                  Text('暂无梦想记录')
                    .fontSize(14)
                    .fontColor('#999999')
                }
                .height(150)
                .width('100%')
                .justifyContent(FlexAlign.Center)
              } else {
                // 梦想列表
                ForEach(this.recentDreams, (dream: Dream) => {
                  Stack({ alignContent: Alignment.BottomStart }) {
                    // 背景图
                    Image(dream.imageUrl)
                      .width('100%')
                      .height(160)
                      .borderRadius(12)
                      .objectFit(ImageFit.Cover)
              
                    // 文字遮罩层
              Column() {
                      Row() {
                        // 分类标签
                        Text(dream.category)
                          .fontSize(12)
                          .backgroundColor($r('app.color.primary_color'))
                          .fontColor('#FFFFFF')
                          .borderRadius(4)
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        
                        Blank()
                        
                        // 状态标签
                        Text(dream.status === 1 ? '进行中' : (dream.status === 2 ? '已完成' : '已放弃'))
                          .fontSize(12)
                          .backgroundColor(dream.status === 1 ? '#4CAF50' : (dream.status === 2 ? '#2196F3' : '#9E9E9E'))
                          .fontColor('#FFFFFF')
                          .borderRadius(4)
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      }
                  .width('100%')
                  
                      // 标题
                      Text(dream.title)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#FFFFFF')
                        .margin({ top: 5 })
                      
                      // 完成率
                      Row({ space: 5 }) {
                        Text(`完成率: ${dream.completionRate}%`)
                          .fontSize(12)
                          .fontColor('#FFFFFF')
                        
                        Progress({ value: dream.completionRate, total: 100 })
                          .color('#FFFFFF')
                          .opacity(0.8)
                          .height(6)
                          .width(80)
                      }
                      .margin({ top: 5 })
                    }
                    .width('100%')
                    .padding(10)
                    .linearGradient({
                      angle: 180,
                      colors: [
                        [0x00000000, 0.0],
                        [0x99000000, 0.7],
                        [0xDD000000, 1.0]
                      ]
                    })
                    .borderRadius(12)
                  }
                  .width('100%')
                  .height(160)
                  .margin({ bottom: 10 })
                  .onClick(() => {
                    // 跳转到梦想详情页，并同时查看该梦想的任务情况
                    console.info(`查看梦想详情，梦想ID: ${dream.id}, 标题: ${dream.title}`);
                    router.pushUrl({
                      url: 'pages/dream/DreamDetailPage',
                      params: {
                        dreamId: dream.id,
                        showTasks: true, // 标记需要显示任务选项卡
                        source: 'home' // 标记来源为首页
                      }
                    });
                  })
                })
              }
            }
            .width('100%')
            .padding(15)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            
            // 底部间距
            Blank()
              .height(80)
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 0, bottom: 0 })
        }
        .width('100%')
      }
      .width('100%')
    .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      
      // 顶部刷新指示器
      if (this.loading) {
        Row() {
          LoadingProgress()
            .width(30)
            .height(30)
            .color(CommonConstants.COLOR_PRIMARY)
          Text('正在刷新...')
            .fontSize(14)
            .fontColor(CommonConstants.COLOR_PRIMARY)
            .margin({ left: 10 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
        .padding(10)
        .position({ y: 0 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  // API响应处理
  private processHomeData(homeData: HomePageData): void {
    if (homeData) {
      if (homeData.dreamStats) {
        this.dreamStats = homeData.dreamStats;
        
        // 如果梦想完成率为0但有已完成任务，则使用任务完成率
        if (this.dreamStats.dreamCompletionRate === 0 && this.dreamStats.completedTasks > 0) {
          console.info('梦想完成率为0但存在已完成任务，使用任务完成率表示整体进度');
        }
      }
      if (homeData.todayTasks && homeData.todayTasks.content) {
        this.todayTasks = homeData.todayTasks.content;
      }
      if (homeData.upcomingTasks && homeData.upcomingTasks.content) {
        this.upcomingTasks = homeData.upcomingTasks.content;
      }
      if (homeData.recentDreams) {
        this.recentDreams = homeData.recentDreams;
      }
    }
  }

  // 整理梦想列表数据，按照更新时间排序
  sortDreams(dreams: Dream[]): Dream[] {
    // 创建副本，避免修改原始数据
    const sorted = [...dreams];
    
    // 按更新时间排序，如果没有则使用createAt
    sorted.sort((a, b) => {
      const aTime = a.updatedAt || a.createdAt || '';
      const bTime = b.updatedAt || b.createdAt || '';
      
      // 降序排序（最新的排在前面）
      return bTime.localeCompare(aTime);
    });
    
    return sorted;
  }
} 