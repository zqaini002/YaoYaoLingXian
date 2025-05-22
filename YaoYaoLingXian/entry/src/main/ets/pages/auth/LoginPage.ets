/**
 * 登录页面
 */

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { UserSession } from '../../utils/auth/UserSession';

// 定义错误类型
interface LoginError {
  message: string;
  code?: number;
}

@Entry
@Component
export struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isPasswordVisible: boolean = false;
  @State isLoading: boolean = false;
  @State rememberMe: boolean = true;
  @State initComplete: boolean = false;
  
  // 校验状态
  @State usernameError: string = '';
  @State passwordError: string = '';

  private userSession: UserSession = UserSession.getInstance();
  
  aboutToAppear() {
    // 检查是否已经登录，如果已登录则直接跳转到首页
    if (this.userSession.isInitialized() && this.userSession.isLoggedIn()) {
      console.info('用户已登录，直接跳转到首页');
      this.navigateToHome();
      return;
    }
    
    // 初始化用户会话
    this.initUserSession();
  }

  // 初始化用户会话
  private async initUserSession() {
    try {
      this.isLoading = true;
      // 使用await确保初始化完成
      await this.userSession.init();
      
      // 初始化完成后，再次检查是否已登录
      if (this.userSession.isLoggedIn()) {
        console.info('初始化完成，用户已登录，跳转到首页');
        this.navigateToHome();
        return;
      }
      
      console.info('初始化完成，用户未登录，显示登录页面');
      this.initComplete = true;
    } catch (error) {
      console.error('初始化用户会话失败:', error);
      // 显示友好提示
      promptAction.showToast({
        message: '系统初始化失败，请重新启动应用',
        duration: 3000
      });
      
      // 即使初始化失败，仍然显示登录页，以便用户可以尝试登录
      this.initComplete = true;
    } finally {
      this.isLoading = false;
    }
  }
  
  // 跳转到首页
  private navigateToHome() {
    router.replaceUrl({
      url: 'pages/Index'
    });
  }
  
  // 校验表单
  validateForm(): boolean {
    let isValid = true;
    
    // 校验用户名
    if (!this.username.trim()) {
      this.usernameError = '请输入用户名';
      isValid = false;
    } else {
      this.usernameError = '';
    }
    
    // 校验密码
    if (!this.password) {
      this.passwordError = '请输入密码';
      isValid = false;
    } else if (this.password.length < 6) {
      this.passwordError = '密码长度不能少于6位';
      isValid = false;
    } else {
      this.passwordError = '';
    }
    
    return isValid;
  }
  
  // 处理登录
  async handleLogin() {
    if (!this.validateForm()) {
      return;
    }
    
    try {
      this.isLoading = true;
      
      // 如果用户会话尚未初始化，强制初始化
      if (!this.userSession.isInitialized()) {
        try {
          await this.userSession.init();
        } catch (initError) {
          console.error('登录时初始化会话失败:', initError);
          promptAction.showToast({
            message: '初始化失败，请重新启动应用',
            duration: 3000
          });
          return; // 初始化失败时，不继续登录
        }
      }
      
      // 调用登录API
      const result = await this.userSession.login(this.username, this.password);
      
      if (result) {
        // 登录成功，显示提示
        promptAction.showToast({
          message: '登录成功',
          duration: 2000
        });
        
        // 跳转到首页
        setTimeout(() => {
          this.navigateToHome();
        }, 1000);
      }
      // 登录失败的情况已在UserSession中处理，这里不需要额外处理
    } catch (error) {
      console.error('登录过程出错:', error);
      // 处理特殊类型的错误
      const errorStr = String(error);
      let errorMessage = '登录失败，请稍后重试';
      
      if (errorStr.includes('网络') || errorStr.includes('连接')) {
        errorMessage = '网络连接异常，请检查网络设置';
      } else if (errorStr.includes('服务器') || errorStr.includes('500')) {
        errorMessage = '服务器暂时不可用，请稍后再试';
      }
      
      promptAction.showToast({
        message: errorMessage,
        duration: 3000
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  // 跳转到注册页面
  navigateToRegister() {
    router.pushUrl({
      url: 'pages/auth/RegisterPage'
    });
  }
  
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景
      Column() {
        Image($r('app.media.login_bg'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .opacity(0.6)
      }
      .width('100%')
      .height('100%')
      
      // 主内容
      Scroll() {
        Column() {
          // 顶部图标和标题
          Column({ space: 16 }) {
            // Logo
            Column() {
              Text('梦')
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .width(80)
            .height(80)
            .backgroundColor('#1976d2')
            .borderRadius(20)
            .justifyContent(FlexAlign.Center)
            .margin({ top: 60, bottom: 16 })
            
            // 标题
            Text('欢迎回来')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
            
            // 副标题
            Text('登录您的账号继续追梦之旅')
              .fontSize(16)
              .fontColor('#666')
              .margin({ top: 8, bottom: 40 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          
          // 登录表单
          Column({ space: 20 }) {
            // 用户名输入
            Column({ space: 8 }) {
              Text('用户名/手机号')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#555')
              
              TextInput({ text: this.username, placeholder: '请输入用户名或手机号' })
                .height(50)
                .borderRadius(10)
                .backgroundColor(Color.White)
                .onChange((value) => {
                  this.username = value;
                  if (value) {
                    this.usernameError = '';
                  }
                })
              
              if (this.usernameError) {
                Text(this.usernameError)
                  .fontSize(12)
                  .fontColor(Color.Red)
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 密码输入
            Column({ space: 8 }) {
              Text('密码')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#555')
              
              Row() {
                TextInput({ 
                  text: this.password, 
                  placeholder: '请输入密码'
                })
                  .height(50)
                  .backgroundColor(Color.White)
                  .onChange((value) => {
                    this.password = value;
                    if (value.length >= 6) {
                      this.passwordError = '';
                    }
                  })
                  .width('100%')
                  .type(this.isPasswordVisible ? InputType.Normal : InputType.Password)
                
                Image(this.isPasswordVisible ? $r('app.media.ic_eye_open') : $r('app.media.ic_eye_close'))
                  .width(24)
                  .height(24)
                  .margin({ right: 16 })
                  .onClick(() => {
                    this.isPasswordVisible = !this.isPasswordVisible;
                  })
              }
              .width('100%')
              .borderRadius(10)
              .backgroundColor(Color.White)
              
              if (this.passwordError) {
                Text(this.passwordError)
                  .fontSize(12)
                  .fontColor(Color.Red)
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 记住我和忘记密码
            Row() {
              Row({ space: 8 }) {
                Checkbox()
                  .onChange((value) => {
                    this.rememberMe = value;
                  })
                  .select(this.rememberMe)
                  .size({ width: 20, height: 20 })
                
                Text('记住我')
                  .fontSize(14)
                  .fontColor('#666')
              }
              
              Text('忘记密码？')
                .fontSize(14)
                .fontColor('#1976d2')
                .onClick(() => {
                  promptAction.showToast({
                    message: '忘记密码功能开发中',
                    duration: 2000
                  });
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 8 })
            
            // 登录按钮
            Button('登录')
              .width('100%')
              .height(50)
              .borderRadius(10)
              .backgroundColor(this.isLoading ? '#7FB3E6' : '#1976d2')
              .fontColor(Color.White)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 16 })
              .enabled(!this.isLoading)
              .onClick(() => {
                this.handleLogin();
              })
            
            if (this.isLoading) {
              LoadingProgress()
                .color('#1976d2')
                .width(24)
                .height(24)
                .margin({ top: 12 })
            }
          }
          .width('90%')
          .padding(20)
          .borderRadius(16)
          .backgroundColor('rgba(255, 255, 255, 0.9)')
          
          // 其他登录方式
          Column() {
            Text('或使用以下方式登录')
              .fontSize(14)
              .fontColor('#888')
              .margin({ top: 30, bottom: 20 })
            
            Row({ space: 24 }) {
              // 微信登录按钮
              Stack() {
                Circle()
                  .width(50)
                  .height(50)
                  .backgroundColor(Color.White)
                  .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
                
                Image($r('app.media.ic_wechat'))
                  .width(28)
                  .height(28)
              }
              
              // 手机登录按钮
              Stack() {
                Circle()
                  .width(50)
                  .height(50)
                  .backgroundColor(Color.White)
                  .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
                
                Image($r('app.media.ic_mobile'))
                  .width(28)
                  .height(28)
              }
              
              // 邮箱登录按钮
              Stack() {
                Circle()
                  .width(50)
                  .height(50)
                  .backgroundColor(Color.White)
                  .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
                
                Image($r('app.media.ic_email'))
                  .width(28)
                  .height(28)
              }
            }
          }
          .margin({ top: 20, bottom: 20 })
          
          // 注册提示
          Row() {
            Text('还没有账号？')
              .fontSize(14)
              .fontColor('#666')
            
            Text('立即注册')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1976d2')
              .onClick(() => {
                this.navigateToRegister();
              })
          }
          .margin({ top: 20, bottom: 40 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
