import { CommonConstants, User, DreamStats, ApiResponse, UserInfo } from '../../model/CommonTypes';
import { AppIcons } from '../../utils/IconUtils';
import http from '@ohos.net.http';
import * as ApiService from '../../services/ApiService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { UserSession } from '../../utils/auth/UserSession';

// 定义路由参数接口
interface RouteParams {
  userId?: number;
}

@Component
export struct MinePage {
  @State userInfo: UserInfo = {
    id: 0,
    username: '',
    nickname: '',
    avatar: '',
    followersCount: 0,
    followingCount: 0
  };

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

  @State menuItems: string[] = ['我的动态', '进度记录', '收藏资源', '消息通知', '设置', '帮助与反馈'];
  @State menuIcons: Array<Resource> = [$r('app.media.ic_dynamic'), $r('app.media.ic_progress'), $r('app.media.ic_favorite'), $r('app.media.ic_message'), $r('app.media.ic_setting'), $r('app.media.ic_help')];
  @State menuRoutes: string[] = ['myPosts', 'progress', 'favorites', 'notifications', 'settings', 'help'];
  @State loading: boolean = false;
  @State dataError: string = '';
  private userSession: UserSession = UserSession.getInstance();

  aboutToAppear() {
    // 获取当前用户ID
    const userId = this.userSession.getUserId();
    this.fetchUserInfo(userId);
    this.fetchDreamStats(userId);
  }

  // 获取用户信息
  async fetchUserInfo(userId: number) {
    try {
      this.loading = true;
      console.info(`开始获取用户信息, userId: ${userId}`);
      
      // 使用ApiService获取用户信息
      const userInfo = await ApiService.getUserById(userId);
      
      if (userInfo) {
        this.userInfo = userInfo;
        console.info(`成功获取用户信息: ${JSON.stringify(userInfo)}`);
      } else {
        this.dataError = '获取用户信息失败: 返回数据为空';
        console.error(this.dataError);
      }
    } catch (error) {
      this.dataError = `加载用户数据出错: ${(error as Error).message}`;
      console.error(`获取用户数据错误: ${(error as Error).message}`);
    } finally {
      this.loading = false;
    }
  }

  // 获取梦想统计数据
  async fetchDreamStats(userId: number) {
    try {
      console.info(`开始获取梦想统计数据, userId: ${userId}`);
      
      // 使用ApiService中的方法获取梦想统计数据
      const stats = await ApiService.getDreamStats(userId);
      
      if (stats) {
        this.dreamStats = stats;
        console.info(`成功获取梦想统计数据: ${JSON.stringify(stats)}`);
      } else {
        console.error('获取梦想统计数据失败: 返回数据为空');
      }
    } catch (error) {
      console.error(`获取梦想统计数据错误: ${(error as Error).message}`);
      // 保持现有的默认值，不做修改
    } finally {
      // 确保没有undefined的统计数据显示到UI
      if (!this.dreamStats) {
        console.info('恢复默认的梦想统计数据');
        this.dreamStats = {
          userId: userId,
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
  }

  // 退出登录处理函数
  async handleLogout() {
    try {
      // 显示确认对话框
      const result = await promptAction.showDialog({
        title: '退出登录',
        message: '确定要退出登录吗？',
        buttons: [
          {
            text: '取消',
            color: $r('app.color.text_primary')
          },
          {
            text: '确定',
            color: $r('app.color.logout_text')
          }
        ]
      });
      
      // 用户点击了确定按钮
      if (result.index === 1) {
        // 显示加载提示
        this.loading = true;
        
        try {
          // 调用退出登录API
          await this.userSession.logout();
          
          // 显示成功提示
          promptAction.showToast({
            message: '已成功退出登录',
            duration: 2000
          });
          
          // 跳转到登录页面
          setTimeout(() => {
            router.replaceUrl({
              url: 'pages/auth/LoginPage'
            });
          }, 500);
        } catch (error) {
          promptAction.showToast({
            message: `退出登录失败: ${error instanceof Error ? error.message : String(error)}`,
            duration: 3000
          });
        } finally {
          this.loading = false;
        }
      }
    } catch (error) {
      console.error(`显示退出确认框失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // 处理菜单项点击
  handleMenuItemClick(index: number) {
    console.info(`Navigate to ${this.menuRoutes[index]}`);
    
    // 根据不同的菜单项执行不同的路由跳转
    switch(this.menuRoutes[index]) {
      case 'myPosts':
        // 跳转到我的动态页面
        router.pushUrl({
          url: 'pages/personal/UserPostsPage',
          params: {
            userId: this.userInfo.id,
            username: this.userInfo.username,
            nickname: this.userInfo.nickname
          }
        });
        break;
      case 'progress':
      case 'favorites':
      case 'notifications':
      case 'settings':
      case 'help':
        // 其他页面暂未实现，显示提示
        promptAction.showToast({
          message: `${this.menuItems[index]}功能正在开发中`,
          duration: 2000
        });
        break;
    }
  }

  build() {
    Scroll() {
      Column() {
        // 个人资料卡片
        Stack({ alignContent: Alignment.Bottom }) {
          // 背景图
          Image('https://images.unsplash.com/photo-1483232539664-d89822fb5d3e')
            .width('100%')
            .height(200)
            .brightness(-0.2)
          
          // 用户信息
          Column() {
            Row() {
              // 头像
              Image(this.userInfo.avatar || 'https://img.zcool.cn/community/01a1955d145660a8012051cdb52526.png')
                .width(80)
                .height(80)
                .borderRadius(40)
                .borderWidth(3)
                .borderColor(Color.White)
                .margin({ right: CommonConstants.MARGIN_LARGE })
              
              // 用户名和签名
              Column() {
                Text(this.userInfo.nickname || '未设置昵称')
                  .fontSize(CommonConstants.FONT_SIZE_XLARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                
                Text(this.userInfo.signature || '这个人很懒，什么也没有留下')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor(Color.White)
                  .opacity(0.9)
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              
              // 编辑按钮
              Button('编辑资料')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.primary_color'))
                .backgroundColor(Color.White)
                .borderRadius(CommonConstants.RADIUS_SMALL)
                .height(32)
                .width(80)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            
            // 统计数据
            Row() {
              Column() {
                Text(this.dreamStats?.totalDreams?.toString() || '0')
                  .fontSize(CommonConstants.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                Text('梦想')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor(Color.White)
                  .opacity(0.9)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              
              Column() {
                Text(this.dreamStats?.completedDreams?.toString() || '0')
                  .fontSize(CommonConstants.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                Text('已实现')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor(Color.White)
                  .opacity(0.9)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              
              Column() {
                Text(this.userInfo?.followersCount?.toString() || '0')
                  .fontSize(CommonConstants.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                Text('粉丝')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor(Color.White)
                  .opacity(0.9)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/personal/FollowersPage',
                  params: {
                    userId: this.userInfo.id
                  }
                });
              })
              
              Column() {
                Text(this.userInfo?.followingCount?.toString() || '0')
                  .fontSize(CommonConstants.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                Text('关注')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor(Color.White)
                  .opacity(0.9)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/personal/FollowingsPage',
                  params: {
                    userId: this.userInfo.id
                  }
                });
              })
            }
            .width('100%')
            .margin({ top: CommonConstants.MARGIN_LARGE })
          }
          .width('100%')
          .padding(CommonConstants.MARGIN_LARGE)
        }
        .width('100%')
        .margin({ bottom: CommonConstants.MARGIN_LARGE })
        
        // 成就预览卡片
        Column() {
          Text('我的成就')
            .fontSize(CommonConstants.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: CommonConstants.MARGIN_MEDIUM })
            .alignSelf(ItemAlign.Start)
          
          Row() {
            // 初学者徽章
            Column() {
              Image(AppIcons.badge_beginner)
                .width(60)
                .height(60)
                .fillColor($r('app.color.text_primary'))
              Text('初学者')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            
            // 坚持者徽章
            Column() {
              Image(AppIcons.badge_consistent)
                .width(60)
                .height(60)
                .fillColor($r('app.color.text_primary'))
              Text('坚持者')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            
            // 探索者徽章
            Column() {
              Image(AppIcons.badge_explorer)
                .width(60)
                .height(60)
                .fillColor($r('app.color.text_primary'))
              Text('探索者')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            
            // 待解锁徽章
            Column() {
              Image(AppIcons.badge_locked)
                .width(60)
                .height(60)
                .fillColor($r('app.color.text_tertiary'))
              Text('待解锁')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_tertiary'))
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding({ top: CommonConstants.MARGIN_MEDIUM, bottom: CommonConstants.MARGIN_MEDIUM })
        }
        .width('100%')
        .padding(CommonConstants.MARGIN_LARGE)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(CommonConstants.RADIUS_NORMAL)
        .margin({ bottom: CommonConstants.MARGIN_LARGE })
        
        // 菜单列表
        Column() {
          List() {
            ForEach(this.menuItems, (item: string, index: number) => {
              ListItem() {
                Row() {
                  Image(this.menuIcons[index])
                    .width(24)
                    .height(24)
                    .fillColor($r('app.color.text_primary'))
                    .margin({ right: CommonConstants.MARGIN_LARGE })
                  
                  Text(item)
                    .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                    .layoutWeight(1)
                  
                  Text('>')
                    .width(16)
                    .height(16)
                    .fontSize(16)
                    .opacity(0.6)
                }
                .width('100%')
                .height(54)
                .alignItems(VerticalAlign.Center)
              }
              .onClick(() => {
                // 使用处理函数处理点击事件
                this.handleMenuItemClick(index);
              })
            })
          }
          .divider({
            strokeWidth: 0.5,
            color: $r('app.color.border_color'),
            startMargin: 56,
            endMargin: 16
          })
          .width('100%')
        }
        .width('100%')
        .padding(CommonConstants.MARGIN_LARGE)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(CommonConstants.RADIUS_NORMAL)
        .margin({ bottom: CommonConstants.MARGIN_LARGE })
        
        // 退出登录按钮
        Button('退出登录')
          .width('90%')
          .height(48)
          .fontSize(CommonConstants.FONT_SIZE_NORMAL)
          .fontColor($r('app.color.logout_text'))
          .backgroundColor($r('app.color.logout_background'))
          .borderRadius(CommonConstants.RADIUS_NORMAL)
          .margin({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_XLARGE })
          .onClick(() => this.handleLogout())
        
        // 版本信息
        Text('梦想生活规划师 v1.0.0')
          .fontSize(CommonConstants.FONT_SIZE_SMALL)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ bottom: CommonConstants.MARGIN_XLARGE })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }
} 