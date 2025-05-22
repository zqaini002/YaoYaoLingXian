/**
 * 注册页面
 */

import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { UserSession } from '../../utils/auth/UserSession';
import { checkUsername, RegisterRequest } from '../../services/ApiService';

// 定义错误类型
interface RegisterError {
  message: string;
  code?: number;
}

@Entry
@Component
export struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State nickname: string = '';
  @State email: string = '';
  @State phone: string = '';
  
  @State isPasswordVisible: boolean = false;
  @State isConfirmPasswordVisible: boolean = false;
  @State isLoading: boolean = false;
  @State isCheckingUsername: boolean = false;
  
  // 错误状态
  @State usernameError: string = '';
  @State passwordError: string = '';
  @State confirmPasswordError: string = '';
  @State nicknameError: string = '';
  @State emailError: string = '';
  @State phoneError: string = '';
  
  aboutToAppear() {
    // 初始化用户会话
    UserSession.getInstance().init().catch((error: Error | string | Object) => {
      console.error('初始化用户会话失败:', error);
    });
  }
  
  // 验证用户名是否可用
  async checkUsernameAvailability(username: string) {
    if (!username || username.length < 3) {
      return;
    }
    
    try {
      this.isCheckingUsername = true;
      const response = await checkUsername(username);
      
      if (response.code === 200) {
        if (response.data === true) {
          this.usernameError = '';
        } else {
          this.usernameError = '用户名已被使用';
        }
      } else {
        console.error('检查用户名失败:', response.message);
      }
    } catch (error) {
      console.error('检查用户名出错:', error);
    } finally {
      this.isCheckingUsername = false;
    }
  }
  
  // 验证表单
  validateForm(): boolean {
    let isValid = true;
    
    // 验证用户名
    if (!this.username.trim()) {
      this.usernameError = '请输入用户名';
      isValid = false;
    } else if (this.username.length < 3) {
      this.usernameError = '用户名长度不能少于3位';
      isValid = false;
    } else if (this.usernameError) {
      // 如果已有错误消息（检查用户名可用性时设置的），说明用户名不可用
      isValid = false;
    }
    
    // 验证密码
    if (!this.password) {
      this.passwordError = '请输入密码';
      isValid = false;
    } else if (this.password.length < 6) {
      this.passwordError = '密码长度不能少于6位';
      isValid = false;
    } else {
      this.passwordError = '';
    }
    
    // 验证确认密码
    if (!this.confirmPassword) {
      this.confirmPasswordError = '请确认密码';
      isValid = false;
    } else if (this.confirmPassword !== this.password) {
      this.confirmPasswordError = '两次输入的密码不一致';
      isValid = false;
    } else {
      this.confirmPasswordError = '';
    }
    
    // 验证昵称
    if (!this.nickname.trim()) {
      this.nicknameError = '请输入昵称';
      isValid = false;
    } else {
      this.nicknameError = '';
    }
    
    // 验证邮箱（可选）
    if (this.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email)) {
      this.emailError = '邮箱格式不正确';
      isValid = false;
    } else {
      this.emailError = '';
    }
    
    // 验证手机号（可选）
    if (this.phone && !/^1[3-9]\d{9}$/.test(this.phone)) {
      this.phoneError = '手机号格式不正确';
      isValid = false;
    } else {
      this.phoneError = '';
    }
    
    return isValid;
  }
  
  // 处理注册
  async handleRegister() {
    if (!this.validateForm()) {
      return;
    }
    
    try {
      this.isLoading = true;
      
      // 调用注册API
      const result = await UserSession.getInstance().register(
        this.username,
        this.password,
        this.nickname,
        this.email || undefined,
        this.phone || undefined
      );
      
      if (result) {
        // 注册成功，显示提示
        promptAction.showToast({
          message: '注册成功',
          duration: 2000
        });
        
        // 跳转到首页
        setTimeout(() => {
          router.replaceUrl({
            url: 'pages/Index'
          });
        }, 1500);
      } else {
        // 注册失败，显示错误信息
        promptAction.showToast({
          message: '注册失败，请检查输入信息',
          duration: 3000
        });
      }
    } catch (error) {
      console.error('注册过程出错:', error);
      promptAction.showToast({
        message: '注册失败，请稍后重试',
        duration: 3000
      });
    } finally {
      this.isLoading = false;
    }
  }
  
  // 返回登录页
  navigateToLogin() {
    router.back();
  }
  
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景
      Column() {
        Image($r('app.media.register_bg'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .opacity(0.6)
      }
      .width('100%')
      .height('100%')
      
      // 头部返回按钮
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .margin({ left: 16, top: 16 })
          .onClick(() => {
            this.navigateToLogin();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .position({ x: 0, y: 0 })
      
      // 主内容
      Scroll() {
        Column() {
          // 标题
          Column({ space: 8 }) {
            Text('创建账号')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
              .margin({ top: 60 })
            
            Text('开始您的追梦之旅')
              .fontSize(16)
              .fontColor('#666')
              .margin({ bottom: 40 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          
          // 注册表单
          Column({ space: 16 }) {
            // 用户名
            Column({ space: 8 }) {
              Text('用户名')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#555')
              
              Row() {
                TextInput({ 
                  text: this.username, 
                  placeholder: '请输入用户名（至少3位）' 
                })
                  .height(50)
                  .backgroundColor(Color.White)
                  .width('100%')
                  .onChange((value) => {
                    this.username = value;
                    if (value.length >= 3) {
                      this.checkUsernameAvailability(value);
                    } else {
                      this.usernameError = value ? '用户名长度不能少于3位' : '请输入用户名';
                    }
                  })
                
                if (this.isCheckingUsername) {
                  LoadingProgress()
                    .color('#1976d2')
                    .width(24)
                    .height(24)
                    .margin({ right: 16 })
                }
              }
              .width('100%')
              .borderRadius(10)
              .backgroundColor(Color.White)
              
              if (this.usernameError) {
                Text(this.usernameError)
                  .fontSize(12)
                  .fontColor(Color.Red)
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 密码
            Column({ space: 8 }) {
              Text('密码')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#555')
              
              Row() {
                TextInput({ 
                  text: this.password, 
                  placeholder: '请输入密码（至少6位）'
                })
                  .height(50)
                  .backgroundColor(Color.White)
                  .onChange((value) => {
                    this.password = value;
                    if (value.length >= 6) {
                      this.passwordError = '';
                    } else {
                      this.passwordError = value ? '密码长度不能少于6位' : '请输入密码';
                    }
                    
                    // 同步检查确认密码
                    if (this.confirmPassword && this.confirmPassword !== value) {
                      this.confirmPasswordError = '两次输入的密码不一致';
                    } else if (this.confirmPassword) {
                      this.confirmPasswordError = '';
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
            
            // 确认密码
            Column({ space: 8 }) {
              Text('确认密码')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#555')
              
              Row() {
                TextInput({ 
                  text: this.confirmPassword, 
                  placeholder: '请再次输入密码'
                })
                  .height(50)
                  .backgroundColor(Color.White)
                  .onChange((value) => {
                    this.confirmPassword = value;
                    if (value !== this.password) {
                      this.confirmPasswordError = '两次输入的密码不一致';
                    } else {
                      this.confirmPasswordError = '';
                    }
                  })
                  .width('100%')
                  .type(this.isConfirmPasswordVisible ? InputType.Normal : InputType.Password)
                
                Image(this.isConfirmPasswordVisible ? $r('app.media.ic_eye_open') : $r('app.media.ic_eye_close'))
                  .width(24)
                  .height(24)
                  .margin({ right: 16 })
                  .onClick(() => {
                    this.isConfirmPasswordVisible = !this.isConfirmPasswordVisible;
                  })
              }
              .width('100%')
              .borderRadius(10)
              .backgroundColor(Color.White)
              
              if (this.confirmPasswordError) {
                Text(this.confirmPasswordError)
                  .fontSize(12)
                  .fontColor(Color.Red)
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 昵称
            Column({ space: 8 }) {
              Text('昵称')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#555')
              
              TextInput({ text: this.nickname, placeholder: '请输入您的昵称' })
                .height(50)
                .borderRadius(10)
                .backgroundColor(Color.White)
                .onChange((value) => {
                  this.nickname = value;
                  if (value) {
                    this.nicknameError = '';
                  } else {
                    this.nicknameError = '请输入昵称';
                  }
                })
              
              if (this.nicknameError) {
                Text(this.nicknameError)
                  .fontSize(12)
                  .fontColor(Color.Red)
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 可选信息
            Column({ space: 8 }) {
              Text('联系方式（可选）')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#555')
              
              // 邮箱
              TextInput({ text: this.email, placeholder: '邮箱（可选）' })
                .height(50)
                .borderRadius(10)
                .backgroundColor(Color.White)
                .margin({ top: 8 })
                .onChange((value) => {
                  this.email = value;
                  if (!value || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
                    this.emailError = '';
                  } else {
                    this.emailError = '邮箱格式不正确';
                  }
                })
              
              if (this.emailError) {
                Text(this.emailError)
                  .fontSize(12)
                  .fontColor(Color.Red)
                  .margin({ top: 4 })
              }
              
              // 手机号
              TextInput({ text: this.phone, placeholder: '手机号（可选）' })
                .height(50)
                .borderRadius(10)
                .backgroundColor(Color.White)
                .margin({ top: 8 })
                .onChange((value) => {
                  this.phone = value;
                  if (!value || /^1[3-9]\d{9}$/.test(value)) {
                    this.phoneError = '';
                  } else {
                    this.phoneError = '手机号格式不正确';
                  }
                })
              
              if (this.phoneError) {
                Text(this.phoneError)
                  .fontSize(12)
                  .fontColor(Color.Red)
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 8 })
            
            // 注册按钮
            Button('注册')
              .width('100%')
              .height(50)
              .borderRadius(10)
              .backgroundColor(this.isLoading ? '#7FB3E6' : '#1976d2')
              .fontColor(Color.White)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 24 })
              .enabled(!this.isLoading)
              .onClick(() => {
                this.handleRegister();
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
          
          // 登录提示
          Row() {
            Text('已有账号？')
              .fontSize(14)
              .fontColor('#666')
            
            Text('立即登录')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1976d2')
              .onClick(() => {
                this.navigateToLogin();
              })
          }
          .margin({ top: 24, bottom: 40 })
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