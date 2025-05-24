import { CommonConstants, Post, Dream } from '../../model/CommonTypes';
import { AppIcons } from '../../utils/IconUtils';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { UserSession } from '../../utils/auth/UserSession';
import * as ApiService from '../../services/ApiService';
import picker from '@ohos.file.picker';

@Entry
@Component
export struct PostCreatePage {
  @State post: Post = {
    id: 0,
    userId: 0,
    title: '',
    content: '',
    likeCount: 0,
    commentCount: 0,
    createdAt: '',
    updatedAt: '',
    images: []
  };
  
  @State selectedImages: string[] = [];
  @State isSubmitting: boolean = false;
  @State showDreamSelector: boolean = false;
  @State userDreams: Dream[] = [];
  @State isLoadingDreams: boolean = false;
  private userSession: UserSession = UserSession.getInstance();

  aboutToAppear() {
    // 从会话获取当前用户ID
    if (this.userSession && this.userSession.isLoggedIn()) {
      const userInfo = this.userSession.getCurrentUser();
      if (userInfo && userInfo.id) {
        this.post.userId = userInfo.id;
      }
    }
    // 获取用户的梦想列表
    this.loadUserDreams();
  }

  // 加载用户的梦想列表
  async loadUserDreams(): Promise<void> {
    try {
      this.isLoadingDreams = true;
      const userId = this.userSession.getUserId();
      if (!userId) {
        promptAction.showToast({
          message: '无法获取用户信息',
          duration: 2000
        });
        return;
      }
      
      // 调用API获取用户的梦想列表
      const dreams = await ApiService.getDreamsByUserId(userId);
      // 过滤出公开的梦想供绑定选择
      this.userDreams = dreams.filter(dream => dream.isPublic === 1);
      
    } catch (error) {
      promptAction.showToast({
        message: `加载梦想列表失败: ${error instanceof Error ? error.message : String(error)}`,
        duration: 2000
      });
    } finally {
      this.isLoadingDreams = false;
    }
  }

  // 挑选图片
  async pickImages(): Promise<void> {
    try {
      // 创建图片选择器实例
      let photoPicker = new picker.PhotoViewPicker();
      // 设置选择参数
      let photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 9;
      
      // 启动图片选择
      const photoSelectResult = await photoPicker.select(photoSelectOptions);
      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        // 限制最多9张图片
        this.selectedImages = photoSelectResult.photoUris.slice(0, 9);
      }
    } catch (error) {
      promptAction.showToast({
        message: `选择图片失败: ${error instanceof Error ? error.message : String(error)}`,
        duration: 2000
      });
    }
  }
  
  // 删除选择的图片
  removeImage(index: number): void {
    const newImages = this.selectedImages.slice();
    newImages.splice(index, 1);
    this.selectedImages = newImages;
  }
  
  // 提交帖子
  async submitPost(): Promise<void> {
    try {
      // 检查用户是否已登录
      if (!this.userSession.isLoggedIn()) {
        promptAction.showToast({
          message: '请先登录后再发布',
          duration: 2000
        });
        // 跳转到登录页面
        router.pushUrl({
          url: 'pages/user/LoginPage',
          params: {
            redirectUrl: 'pages/community/PostCreatePage'
          }
        });
        return;
      }

      // 表单验证
      if (!this.post.content.trim()) {
        promptAction.showToast({
          message: '内容不能为空',
          duration: 2000
        });
        return;
      }
      
      this.isSubmitting = true;
      
      // 确保设置了用户ID
      this.post.userId = this.userSession.getUserId() || 0;
      
      // 如果有选择图片，需要先上传图片
      let uploadedImages: string[] = [];
      if (this.selectedImages.length > 0) {
        // 遍历上传图片
        for (const imageUri of this.selectedImages) {
          try {
            const response = await ApiService.uploadImage({
              fileName: imageUri.substring(imageUri.lastIndexOf('/') + 1),
              base64Image: await this.convertImageToBase64(imageUri)
            });
            
            if (response && response.url) {
              uploadedImages.push(response.url);
            }
          } catch (error) {
            console.error(`上传图片失败: ${error instanceof Error ? error.message : String(error)}`);
          }
        }
      }
      
      // 创建新的Post对象而不是使用spread运算符
      const postData: Post = {
        id: this.post.id,
        userId: this.post.userId,
        title: this.post.title,
        content: this.post.content,
        likeCount: this.post.likeCount,
        commentCount: this.post.commentCount,
        createdAt: this.post.createdAt,
        updatedAt: this.post.updatedAt,
        dreamId: this.post.dreamId,
        images: uploadedImages
      };
      
      // 调用API创建帖子
      await ApiService.createPost(postData);
      
      promptAction.showToast({
        message: '发布成功',
        duration: 2000
      });
      
      // 返回社区页面
      router.back();
      
    } catch (error) {
      promptAction.showToast({
        message: `发布失败: ${error instanceof Error ? error.message : String(error)}`,
        duration: 2000
      });
    } finally {
      this.isSubmitting = false;
    }
  }
  
  // 图片转Base64
  private async convertImageToBase64(imageUri: string): Promise<string> {
    // 这里是模拟实现，实际项目中需要根据鸿蒙OS的图片处理API来实现
    // 返回一个假的Base64字符串，实际项目中需要替换为真实转换逻辑
    return "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3+iiigD//2Q==";
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .width(40)
        .height(40)
        .backgroundColor($r('app.color.primary_color'))
        .borderRadius(20)
        .onClick(() => {
          router.back();
        })
        
        Text('发布动态')
          .fontSize(CommonConstants.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .margin({ left: CommonConstants.MARGIN_LARGE })
        
        Blank()
        
        Button('发布') 
          .fontSize(CommonConstants.FONT_SIZE_NORMAL)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.isSubmitting ? $r('app.color.text_tertiary') : $r('app.color.primary_color'))
          .height(40)
          .borderRadius(CommonConstants.RADIUS_NORMAL)
          .enabled(!this.isSubmitting)
          .onClick(() => {
            this.submitPost();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: CommonConstants.MARGIN_LARGE, right: CommonConstants.MARGIN_LARGE })
      .alignItems(VerticalAlign.Center)
      
      // 内容区域
      Scroll() {
        Column() {
          // 标题输入
          TextInput({ placeholder: '标题（选填）', text: this.post.title })
            .fontSize(CommonConstants.FONT_SIZE_NORMAL)
            .height(50)
            .backgroundColor(Color.Transparent)
            .placeholderFont({ size: CommonConstants.FONT_SIZE_NORMAL })
            .width('100%')
            .onChange((value: string) => {
              this.post.title = value;
            })
          
          // 内容输入
          TextArea({ placeholder: '分享你的梦想与生活...', text: this.post.content })
            .fontSize(CommonConstants.FONT_SIZE_NORMAL)
            .placeholderFont({ size: CommonConstants.FONT_SIZE_NORMAL })
            .backgroundColor(Color.Transparent)
            .height(200)
            .width('100%')
            .onChange((value: string) => {
              this.post.content = value;
            })
          
          // 图片展示区
          if (this.selectedImages.length > 0) {
            Grid() {
              ForEach(this.selectedImages, (image: string, index: number) => {
                GridItem() {
                  Stack({ alignContent: Alignment.TopEnd }) {
                    Image(image)
                      .width('100%')
                      .height('100%')
                      .borderRadius(CommonConstants.RADIUS_SMALL)
                      .objectFit(ImageFit.Cover)
                    
                    Button({ type: ButtonType.Circle }) {
                      Image(AppIcons.delete)
                        .width(16)
                        .height(16)
                        .fillColor(Color.White)
                    }
                    .width(24)
                    .height(24)
                    .backgroundColor('#66000000')
                    .margin(4)
                    .onClick(() => {
                      this.removeImage(index);
                    })
                  }
                }
              })
            }
            .columnsTemplate(this.selectedImages.length === 1 ? '1fr' : 
                           this.selectedImages.length === 2 ? '1fr 1fr' : '1fr 1fr 1fr')
            .rowsTemplate(this.selectedImages.length <= 3 ? '1fr' : 
                         this.selectedImages.length <= 6 ? '1fr 1fr' : '1fr 1fr 1fr')
            .columnsGap(CommonConstants.MARGIN_SMALL)
            .rowsGap(CommonConstants.MARGIN_SMALL)
            .height(this.selectedImages.length <= 3 ? 100 : 
                   this.selectedImages.length <= 6 ? 200 : 300)
            .width('100%')
            .margin({ top: CommonConstants.MARGIN_NORMAL })
          }
          
          // 关联梦想卡片
          if (this.post.dreamId) {
            Row() {
              Text('关联梦想：')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_tertiary'))
              
              Text(this.userDreams.find(d => d.id === this.post.dreamId)?.title || '')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.primary_color'))
                .fontWeight(FontWeight.Medium)
              
              Blank()
              
              Button({ type: ButtonType.Circle }) {
                Image(AppIcons.close)
                  .width(16)
                  .height(16)
                  .fillColor($r('app.color.text_tertiary'))
              }
              .width(24)
              .height(24)
              .backgroundColor($r('app.color.background'))
              .onClick(() => {
                this.post.dreamId = undefined;
              })
            }
            .width('100%')
            .padding(CommonConstants.MARGIN_MEDIUM)
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .backgroundColor($r('app.color.background'))
            .margin({ top: CommonConstants.MARGIN_NORMAL })
          }
        }
        .width('100%')
        .padding({ 
          left: CommonConstants.MARGIN_LARGE, 
          right: CommonConstants.MARGIN_LARGE,
          bottom: CommonConstants.MARGIN_LARGE
        })
      }
      .width('100%')
      .layoutWeight(1)
      
      // 底部工具栏
      Column() {
        Divider()
          .width('100%')
          .height(1)
          .color('#E0E0E0')
          
        Row() {
          Row() {
            Image(AppIcons.image)
              .width(24)
              .height(24)
              .fillColor('#666666')
            Text('图片')
              .fontSize(CommonConstants.FONT_SIZE_SMALL)
              .fontColor('#666666')
              .margin({ left: 4 })
          }
          .onClick(() => {
            this.pickImages();
          })
          
          Divider()
            .vertical(true)
            .height(24)
            .width(1)
            .color('#E0E0E0')
            .margin({ left: CommonConstants.MARGIN_LARGE, right: CommonConstants.MARGIN_LARGE })
          
          Row() {
            Image(AppIcons.tag)
              .width(24)
              .height(24)
              .fillColor('#666666')
            Text('关联梦想')
              .fontSize(CommonConstants.FONT_SIZE_SMALL)
              .fontColor('#666666')
              .margin({ left: 4 })
          }
          .onClick(() => {
            this.showDreamSelector = true;
          })
        }
        .width('100%')
        .height(56)
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .padding({ left: CommonConstants.MARGIN_LARGE, right: CommonConstants.MARGIN_LARGE })
      }
      .width('100%')
      
      // 梦想选择对话框
      if (this.showDreamSelector) {
        Column() {
          // 对话框标题
          Row() {
            Text('选择关联的梦想')
              .fontSize(CommonConstants.FONT_SIZE_LARGE)
              .fontWeight(FontWeight.Bold)
            
            Image(AppIcons.close)
              .width(24)
              .height(24)
              .fillColor($r('app.color.text_primary'))
              .onClick(() => {
                this.showDreamSelector = false;
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ 
            top: CommonConstants.MARGIN_LARGE, 
            bottom: CommonConstants.MARGIN_NORMAL,
            left: CommonConstants.MARGIN_LARGE,
            right: CommonConstants.MARGIN_LARGE
          })
          
          Divider()
            .width('100%')
            .height(1)
            .color('#E0E0E0')
          
          // 梦想列表
          List() {
            if (this.isLoadingDreams) {
              ListItem() {
                Row() {
                  LoadingProgress()
                    .width(20)
                    .height(20)
                    .margin({ right: CommonConstants.MARGIN_SMALL })
                  Text('加载中...')
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_tertiary'))
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_LARGE })
              }
            } else if (this.userDreams.length === 0) {
              ListItem() {
                Text('暂无公开的梦想可供关联')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_tertiary'))
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_LARGE })
              }
            } else {
              ForEach(this.userDreams, (dream: Dream) => {
                ListItem() {
                  Row() {
                    Image(dream.imageUrl || '')
                      .width(40)
                      .height(40)
                      .borderRadius(4)
                      .margin({ right: CommonConstants.MARGIN_MEDIUM })
                    
                    Column() {
                      Text(dream.title)
                        .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                        .fontWeight(FontWeight.Medium)
                      
                      Text(`完成率: ${dream.completionRate}%`)
                        .fontSize(CommonConstants.FONT_SIZE_SMALL)
                        .fontColor($r('app.color.text_tertiary'))
                        .margin({ top: 4 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    
                    Radio({ value: String(dream.id || ''), group: 'dreams' })
                      .checked(this.post.dreamId === dream.id)
                      .onChange((isChecked: boolean) => {
                        if (isChecked && dream.id !== undefined) {
                          this.post.dreamId = dream.id;
                        }
                      })
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .padding(CommonConstants.MARGIN_MEDIUM)
                  .onClick(() => {
                    if (dream && dream.id !== undefined) {
                    this.post.dreamId = dream.id;
                    this.showDreamSelector = false;
                    }
                  })
                }
              })
            }
          }
          .width('100%')
          .layoutWeight(1)
          
          // 确认按钮
          Button('确定')
            .width('90%')
            .height(48)
            .backgroundColor($r('app.color.primary_color'))
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .margin({ top: CommonConstants.MARGIN_MEDIUM, bottom: CommonConstants.MARGIN_LARGE })
            .onClick(() => {
              this.showDreamSelector = false;
            })
        }
        .width('100%')
        .height('70%')
        .backgroundColor(Color.White)
        .borderRadius({
          topLeft: CommonConstants.RADIUS_LARGE,
          topRight: CommonConstants.RADIUS_LARGE
        })
        .position({ x: 0, y: '30%' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
} 