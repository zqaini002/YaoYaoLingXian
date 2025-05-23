/**
 * 首页
 */

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { TabBar } from '../components/TabBar';
import { HomePage } from './home/HomePage';
import { DreamPage } from './dream/DreamPage';
import { TaskPage } from './task/TaskPage';
import { CommunityPage } from './community/CommunityPage';
import { MinePage } from './personal/MinePage';
import { UserSession } from '../utils/auth/UserSession';

// 定义错误类型
interface SessionError {
  message: string;
  code?: number;
}

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;
  @State isUserLoggedIn: boolean = false;
  @State isInitializing: boolean = true;
  private userSession: UserSession = UserSession.getInstance();

  aboutToAppear() {
    console.info('Index页面: aboutToAppear开始执行');
    this.initAndCheckLogin();
  }

  // 初始化并检查登录状态
  private async initAndCheckLogin() {
    try {
      console.info('Index页面: 开始检查登录状态');
      // 1. 先检查用户会话是否已初始化
      if (!this.userSession.isInitialized()) {
        console.info('Index页面: 会话未初始化，进行初始化');
        try {
          // 使用await等待初始化完成
          await this.userSession.init();
          console.info('Index页面: 会话初始化完成');
        } catch (error) {
          console.error('Index页面: 初始化用户会话失败:', error);
          // 初始化失败，跳转到登录页面
          this.navigateToLogin('会话初始化失败，请重新登录');
          return;
        }
      }

      // 2. 检查用户是否已登录
      console.info('Index页面: 检查是否已登录');
      if (this.userSession.isLoggedIn()) {
        console.info('Index页面: 用户已登录，显示首页');
        // 已登录，允许访问首页
        this.isUserLoggedIn = true;
        this.isInitializing = false;
      } else {
        console.info('Index页面: 用户未登录，跳转到登录页');
        // 未登录，跳转到登录页
        this.navigateToLogin('请先登录');
      }
    } catch (error) {
      console.error('Index页面: 检查登录状态出错:', error);
      // 出错时跳转到登录页面
      this.navigateToLogin('系统出错，请重新登录');
    }
  }

  // 跳转到登录页
  private navigateToLogin(message: string) {
    console.info(`Index页面: 跳转到登录页，提示: ${message}`);
    promptAction.showToast({
      message: message,
      duration: 2000
    });
    
    router.replaceUrl({
      url: 'pages/auth/LoginPage'
    });
  }

  build() {
    if (this.isInitializing) {
      // 显示加载状态
      Column() {
        LoadingProgress()
          .width(50)
          .height(50) 
        Text('加载中...')
          .fontSize(16)
          .margin({ top: 20 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else if (this.isUserLoggedIn) {
      // 只有登录成功后才显示主内容
    Column() {
      // 主内容区域 - 使用Flex布局控制空间
      Flex({ direction: FlexDirection.Column }) {
        Swiper() {
          HomePage()
          DreamPage()
          TaskPage()
          CommunityPage()
          MinePage()
        }
        .index(this.selectedIndex)
        .indicator(false)
        .loop(false)
        .duration(300)
        .onChange((index: number) => {
          this.selectedIndex = index;
        })
        .width('100%')
        .flexGrow(1)
      }
      .width('100%')
      .height('calc(100% - 60px)') // 减去导航栏高度

      // 底部导航栏
        TabBar({ selectedIndex: this.selectedIndex })
        .height(40)
          .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    }
  }
}