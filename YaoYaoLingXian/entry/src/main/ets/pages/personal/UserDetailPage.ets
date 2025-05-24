import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { getUserById, followUser, unfollowUser, isFollowingUser } from '../../services/ApiService';
import type { UserInfo } from '../../model/CommonTypes';
import { UserSession } from '../../utils/auth/UserSession';

// 定义路由参数接口
interface RouteParams {
  userId?: number;
}

/**
 * 用户详情页面
 */
@Entry
@Component
struct UserDetailPage {
  @State userInfo: UserInfo | null = null;
  @State isLoading: boolean = true;
  @State isFollowing: boolean = false;
  @State currentUserId: number = 0;
  @State targetUserId: number = 0;
  @State isCurrentUser: boolean = false;

  aboutToAppear() {
    // 获取路由参数 - 目标用户ID
    const params = router.getParams() as RouteParams;
    // 类型安全的访问方式
    if (params && params.userId !== undefined) {
      this.targetUserId = params.userId;
    }
    
    // 获取当前登录用户ID
    const userSession = UserSession.getInstance();
    if (userSession.isLoggedIn()) {
      this.currentUserId = userSession.getUserId();
      // 检查是否是查看自己的资料
      this.isCurrentUser = this.currentUserId === this.targetUserId;
    }

    // 加载用户信息和关注状态
    this.loadUserInfo();
  }

  async loadUserInfo() {
    this.isLoading = true;
    try {
      // 获取用户信息
      this.userInfo = await getUserById(this.targetUserId);
      
      // 如果不是查看自己的资料，检查关注状态
      if (!this.isCurrentUser) {
        this.isFollowing = await isFollowingUser(this.currentUserId, this.targetUserId);
      }
    } catch (error) {
      console.error(`加载用户信息失败: ${error instanceof Error ? error.message : String(error)}`);
      // 使用合法的ArkTS API格式
      promptAction.showToast({
        message: '加载用户信息失败',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  async handleFollowAction() {
    if (this.isCurrentUser) return;
    
    try {
      if (this.isFollowing) {
        // 取消关注
        await unfollowUser(this.currentUserId, this.targetUserId);
        this.isFollowing = false;
        // 使用合法的ArkTS API格式
        promptAction.showToast({
          message: '已取消关注',
          duration: 2000
        });
      } else {
        // 关注
        await followUser(this.currentUserId, this.targetUserId);
        this.isFollowing = true;
        // 使用合法的ArkTS API格式
        promptAction.showToast({
          message: '关注成功',
          duration: 2000
        });
      }
    } catch (error) {
      console.error(`关注操作失败: ${error instanceof Error ? error.message : String(error)}`);
      // 使用合法的ArkTS API格式
      promptAction.showToast({
        message: '操作失败，请重试',
        duration: 2000
      });
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.back_icon'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .onClick(() => {
            router.back();
          })

        Text('用户资料')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      if (this.isLoading) {
        // 加载中状态
        LoadingProgress()
          .width(48)
          .height(48)
          .margin({ top: 100 })
      } else if (this.userInfo) {
        // 用户信息
        Column() {
          // 用户头像和基本信息
          Column() {
            Image(this.userInfo.avatar ? this.userInfo.avatar : $r('app.media.default_avatar'))
              .width(80)
              .height(80)
              .borderRadius(40)
              .margin({ top: 20, bottom: 16 })

            Text(this.userInfo.nickname ? this.userInfo.nickname : this.userInfo.username)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 8 })

            Text(`@${this.userInfo.username}`)
              .fontSize(14)
              .fontColor('#666')
              .margin({ bottom: 16 })

            if (this.userInfo.signature) {
              Text(this.userInfo.signature)
                .fontSize(16)
                .margin({ bottom: 16 })
                .textAlign(TextAlign.Center)
                .padding({ left: 32, right: 32 })
            }

            // 关注按钮 - 不显示给自己
            if (!this.isCurrentUser) {
              Button(this.isFollowing ? '已关注' : '关注')
                .width(100)
                .height(36)
                .fontSize(14)
                .fontColor(this.isFollowing ? '#666' : '#fff')
                .backgroundColor(this.isFollowing ? '#e0e0e0' : '#4D8CFE')
                .margin({ top: 16, bottom: 20 })
                .borderRadius(18)
                .onClick(() => this.handleFollowAction())
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)

          // 用户统计信息
          Row() {
            Column() {
              // 安全地访问dreamsCount属性
              Text(this.userInfo.dreamsCount !== undefined ? this.userInfo.dreamsCount.toString() : '0')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
              Text('梦想')
                .fontSize(14)
                .fontColor('#666')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            
            Column() {
              // 安全地访问completedDreamsCount属性
              Text(this.userInfo.completedDreamsCount !== undefined ? this.userInfo.completedDreamsCount.toString() : '0')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
              Text('已实现')
                .fontSize(14)
                .fontColor('#666')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            
            Column() {
              // 安全地访问followersCount属性
              Text(this.userInfo.followersCount !== undefined ? this.userInfo.followersCount.toString() : '0')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
              Text('粉丝')
                .fontSize(14)
                .fontColor('#666')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            
            Column() {
              // 安全地访问followingCount属性
              Text(this.userInfo.followingCount !== undefined ? this.userInfo.followingCount.toString() : '0')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
              Text('关注')
                .fontSize(14)
                .fontColor('#666')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding({ top: 16, bottom: 16 })
          .backgroundColor('#f5f5f5')
          
          // 用户梦想展示区 - 可以根据需求添加更多内容
          Column() {
            Text('Ta的梦想')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 16, bottom: 16 })
              .alignSelf(ItemAlign.Start)
              .padding({ left: 16 })
              
            // 这里可以添加用户梦想列表，类似于首页的梦想卡片展示
            // 为了简化，这里只添加一个占位提示
            Text('还没有公开的梦想哦~')
              .fontSize(14)
              .fontColor('#999')
              .margin({ top: 40, bottom: 40 })
          }
          .width('100%')
        }
        .width('100%')
      } else {
        // 加载失败状态
        Column() {
          Image($r('app.media.error_icon'))
            .width(64)
            .height(64)
            .opacity(0.6)
            .margin({ top: 100, bottom: 16 })
            
          Text('无法加载用户信息')
            .fontSize(16)
            .fontColor('#999')
            
          Button('重试')
            .width(80)
            .height(36)
            .fontSize(14)
            .margin({ top: 16 })
            .onClick(() => this.loadUserInfo())
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }
} 