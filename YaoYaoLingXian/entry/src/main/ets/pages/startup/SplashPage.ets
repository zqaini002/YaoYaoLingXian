/**
 * 启动页面
 * 用于应用启动时检查登录状态并导航到相应页面
 */

import router from '@ohos.router';
import { UserSession } from '../../utils/auth/UserSession';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SplashPage {
  @State isLoading: boolean = true;
  private userSession: UserSession = UserSession.getInstance();
  
  aboutToAppear() {
    // 设置超时，确保不会无限等待
    const timeout = setTimeout(() => {
      // 如果3秒后还在加载，强制导航到登录页
      if (this.isLoading) {
        this.isLoading = false;
        this.navigateToLoginPage('系统响应超时，请重新登录');
      }
    }, 3000);
    
    // 检查登录状态
    this.checkLoginStatus().finally(() => {
      clearTimeout(timeout);
      this.isLoading = false;
    });
  }
  
  // 检查登录状态并导航
  private async checkLoginStatus() {
    try {
      console.info('启动页：开始检查登录状态');
      
      // 1. 检查用户会话是否已初始化
      if (!this.userSession.isInitialized()) {
        console.info('启动页：会话未初始化，进行初始化');
        try {
          await this.userSession.init();
          console.info('启动页：会话初始化完成');
        } catch (error) {
          console.error('启动页：初始化用户会话失败:', error);
          // 初始化失败，导航到登录页
          this.navigateToLoginPage('初始化失败，请重新登录');
          return;
        }
      }
      
      // 2. 检查用户是否已登录
      if (this.userSession.isLoggedIn()) {
        console.info('启动页：用户已登录，导航到首页');
        // 已登录，导航到首页
        this.navigateToHomePage();
      } else {
        console.info('启动页：用户未登录，导航到登录页');
        // 未登录，导航到登录页
        this.navigateToLoginPage();
      }
    } catch (error) {
      console.error('启动页：检查登录状态出错:', error);
      // 出错时导航到登录页
      this.navigateToLoginPage('检查登录状态出错，请重新登录');
    }
  }
  
  // 导航到首页
  private navigateToHomePage() {
    router.replaceUrl({
      url: 'pages/Index'
    });
  }
  
  // 导航到登录页
  private navigateToLoginPage(message?: string) {
    if (message) {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    }
    
    router.replaceUrl({
      url: 'pages/auth/LoginPage'
    });
  }
  
  build() {
    Column() {
      if (this.isLoading) {
        // 显示加载中的Logo和加载提示
        Column({ space: 20 }) {
          Image($r('app.media.app_icon'))
            .width(120)
            .height(120)
            .objectFit(ImageFit.Contain)
          
          LoadingProgress()
            .width(60)
            .height(60)
            .color('#1976d2')
          
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
      } else {
        // 这部分通常不会显示，因为页面会很快导航到其他页面
        Column() {
          Text('启动中...')
            .fontSize(18)
            .fontColor('#333333')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
  }
} 
 
 * 启动页面
 * 用于应用启动时检查登录状态并导航到相应页面
 */

import router from '@ohos.router';
import { UserSession } from '../../utils/auth/UserSession';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SplashPage {
  @State isLoading: boolean = true;
  private userSession: UserSession = UserSession.getInstance();
  
  aboutToAppear() {
    // 设置超时，确保不会无限等待
    const timeout = setTimeout(() => {
      // 如果3秒后还在加载，强制导航到登录页
      if (this.isLoading) {
        this.isLoading = false;
        this.navigateToLoginPage('系统响应超时，请重新登录');
      }
    }, 3000);
    
    // 检查登录状态
    this.checkLoginStatus().finally(() => {
      clearTimeout(timeout);
      this.isLoading = false;
    });
  }
  
  // 检查登录状态并导航
  private async checkLoginStatus() {
    try {
      console.info('启动页：开始检查登录状态');
      
      // 1. 检查用户会话是否已初始化
      if (!this.userSession.isInitialized()) {
        console.info('启动页：会话未初始化，进行初始化');
        try {
          await this.userSession.init();
          console.info('启动页：会话初始化完成');
        } catch (error) {
          console.error('启动页：初始化用户会话失败:', error);
          // 初始化失败，导航到登录页
          this.navigateToLoginPage('初始化失败，请重新登录');
          return;
        }
      }
      
      // 2. 检查用户是否已登录
      if (this.userSession.isLoggedIn()) {
        console.info('启动页：用户已登录，导航到首页');
        // 已登录，导航到首页
        this.navigateToHomePage();
      } else {
        console.info('启动页：用户未登录，导航到登录页');
        // 未登录，导航到登录页
        this.navigateToLoginPage();
      }
    } catch (error) {
      console.error('启动页：检查登录状态出错:', error);
      // 出错时导航到登录页
      this.navigateToLoginPage('检查登录状态出错，请重新登录');
    }
  }
  
  // 导航到首页
  private navigateToHomePage() {
    router.replaceUrl({
      url: 'pages/Index'
    });
  }
  
  // 导航到登录页
  private navigateToLoginPage(message?: string) {
    if (message) {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    }
    
    router.replaceUrl({
      url: 'pages/auth/LoginPage'
    });
  }
  
  build() {
    Column() {
      if (this.isLoading) {
        // 显示加载中的Logo和加载提示
        Column({ space: 20 }) {
          Image($r('app.media.app_icon'))
            .width(120)
            .height(120)
            .objectFit(ImageFit.Contain)
          
          LoadingProgress()
            .width(60)
            .height(60)
            .color('#1976d2')
          
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
      } else {
        // 这部分通常不会显示，因为页面会很快导航到其他页面
        Column() {
          Text('启动中...')
            .fontSize(18)
            .fontColor('#333333')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
  }
} 
 
 * 启动页面
 * 用于应用启动时检查登录状态并导航到相应页面
 */

import router from '@ohos.router';
import { UserSession } from '../../utils/auth/UserSession';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SplashPage {
  @State isLoading: boolean = true;
  private userSession: UserSession = UserSession.getInstance();
  
  aboutToAppear() {
    // 设置超时，确保不会无限等待
    const timeout = setTimeout(() => {
      // 如果3秒后还在加载，强制导航到登录页
      if (this.isLoading) {
        this.isLoading = false;
        this.navigateToLoginPage('系统响应超时，请重新登录');
      }
    }, 3000);
    
    // 检查登录状态
    this.checkLoginStatus().finally(() => {
      clearTimeout(timeout);
      this.isLoading = false;
    });
  }
  
  // 检查登录状态并导航
  private async checkLoginStatus() {
    try {
      console.info('启动页：开始检查登录状态');
      
      // 1. 检查用户会话是否已初始化
      if (!this.userSession.isInitialized()) {
        console.info('启动页：会话未初始化，进行初始化');
        try {
          await this.userSession.init();
          console.info('启动页：会话初始化完成');
        } catch (error) {
          console.error('启动页：初始化用户会话失败:', error);
          // 初始化失败，导航到登录页
          this.navigateToLoginPage('初始化失败，请重新登录');
          return;
        }
      }
      
      // 2. 检查用户是否已登录
      if (this.userSession.isLoggedIn()) {
        console.info('启动页：用户已登录，导航到首页');
        // 已登录，导航到首页
        this.navigateToHomePage();
      } else {
        console.info('启动页：用户未登录，导航到登录页');
        // 未登录，导航到登录页
        this.navigateToLoginPage();
      }
    } catch (error) {
      console.error('启动页：检查登录状态出错:', error);
      // 出错时导航到登录页
      this.navigateToLoginPage('检查登录状态出错，请重新登录');
    }
  }
  
  // 导航到首页
  private navigateToHomePage() {
    router.replaceUrl({
      url: 'pages/Index'
    });
  }
  
  // 导航到登录页
  private navigateToLoginPage(message?: string) {
    if (message) {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    }
    
    router.replaceUrl({
      url: 'pages/auth/LoginPage'
    });
  }
  
  build() {
    Column() {
      if (this.isLoading) {
        // 显示加载中的Logo和加载提示
        Column({ space: 20 }) {
          Image($r('app.media.app_icon'))
            .width(120)
            .height(120)
            .objectFit(ImageFit.Contain)
          
          LoadingProgress()
            .width(60)
            .height(60)
            .color('#1976d2')
          
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
      } else {
        // 这部分通常不会显示，因为页面会很快导航到其他页面
        Column() {
          Text('启动中...')
            .fontSize(18)
            .fontColor('#333333')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
  }
} 
 
 * 启动页面
 * 用于应用启动时检查登录状态并导航到相应页面
 */

import router from '@ohos.router';
import { UserSession } from '../../utils/auth/UserSession';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct SplashPage {
  @State isLoading: boolean = true;
  private userSession: UserSession = UserSession.getInstance();
  
  aboutToAppear() {
    // 设置超时，确保不会无限等待
    const timeout = setTimeout(() => {
      // 如果3秒后还在加载，强制导航到登录页
      if (this.isLoading) {
        this.isLoading = false;
        this.navigateToLoginPage('系统响应超时，请重新登录');
      }
    }, 3000);
    
    // 检查登录状态
    this.checkLoginStatus().finally(() => {
      clearTimeout(timeout);
      this.isLoading = false;
    });
  }
  
  // 检查登录状态并导航
  private async checkLoginStatus() {
    try {
      console.info('启动页：开始检查登录状态');
      
      // 1. 检查用户会话是否已初始化
      if (!this.userSession.isInitialized()) {
        console.info('启动页：会话未初始化，进行初始化');
        try {
          await this.userSession.init();
          console.info('启动页：会话初始化完成');
        } catch (error) {
          console.error('启动页：初始化用户会话失败:', error);
          // 初始化失败，导航到登录页
          this.navigateToLoginPage('初始化失败，请重新登录');
          return;
        }
      }
      
      // 2. 检查用户是否已登录
      if (this.userSession.isLoggedIn()) {
        console.info('启动页：用户已登录，导航到首页');
        // 已登录，导航到首页
        this.navigateToHomePage();
      } else {
        console.info('启动页：用户未登录，导航到登录页');
        // 未登录，导航到登录页
        this.navigateToLoginPage();
      }
    } catch (error) {
      console.error('启动页：检查登录状态出错:', error);
      // 出错时导航到登录页
      this.navigateToLoginPage('检查登录状态出错，请重新登录');
    }
  }
  
  // 导航到首页
  private navigateToHomePage() {
    router.replaceUrl({
      url: 'pages/Index'
    });
  }
  
  // 导航到登录页
  private navigateToLoginPage(message?: string) {
    if (message) {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    }
    
    router.replaceUrl({
      url: 'pages/auth/LoginPage'
    });
  }
  
  build() {
    Column() {
      if (this.isLoading) {
        // 显示加载中的Logo和加载提示
        Column({ space: 20 }) {
          Image($r('app.media.app_icon'))
            .width(120)
            .height(120)
            .objectFit(ImageFit.Contain)
          
          LoadingProgress()
            .width(60)
            .height(60)
            .color('#1976d2')
          
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
      } else {
        // 这部分通常不会显示，因为页面会很快导航到其他页面
        Column() {
          Text('启动中...')
            .fontSize(18)
            .fontColor('#333333')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
  }
} 
 