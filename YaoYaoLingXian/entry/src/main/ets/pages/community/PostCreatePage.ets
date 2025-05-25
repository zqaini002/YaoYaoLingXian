import { CommonConstants, Post, Dream } from '../../model/CommonTypes';
import { AppIcons } from '../../utils/IconUtils';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { UserSession } from '../../utils/auth/UserSession';
import * as ApiService from '../../services/ApiService';
import picker from '@ohos.file.picker';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import util from '@ohos.util';
import fileIo from '@ohos.fileio';

/**
 * 接口定义部分
 */

// 提示框参数
interface ToastOptions {
  message: string;
  duration?: number;
}

// 图片请求选项
interface RequestOptions {
  deliveryMode: number;
}

// 查询选项
interface FetchOptions {
  fetchColumns: string[];
  predicates: dataSharePredicates.DataSharePredicates;
}

// 媒体资源处理器接口
interface MediaAssetDataHandlerInterface<T> {
  onDataPrepared(data: T): void;
}

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
    images: ''
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
        const toastOpts: ToastOptions = { 
          message: '无法获取用户信息',
          duration: 2000
        };
        promptAction.showToast(toastOpts);
        return;
      }
      
      // 调用API获取用户的梦想列表
      const dreams = await ApiService.getDreamsByUserId(userId);
      // 过滤出公开的梦想供绑定选择
      this.userDreams = dreams.filter(dream => dream.isPublic === 1);
      
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      const toastOpts: ToastOptions = { 
        message: `加载梦想列表失败: ${errorMsg}`,
        duration: 2000
      };
      promptAction.showToast(toastOpts);
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
      
      // 使用Promise方式调用
      photoPicker.select(photoSelectOptions)
        .then((photos) => {
          if (photos && photos.photoUris && photos.photoUris.length > 0) {
        // 限制最多9张图片
            this.selectedImages = photos.photoUris.slice(0, 9);
          }
        })
        .catch((err: Error) => {
          console.error(`选择图片失败: ${err.message}`);
          const toastOpts: ToastOptions = { 
            message: `选择图片失败: ${err.message}`, 
            duration: 2000 
          };
          promptAction.showToast(toastOpts);
        });
    } catch (error) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      console.error(`选择图片失败: ${err.message}`);
      const toastOpts: ToastOptions = { 
        message: `选择图片失败: ${err.message}`,
        duration: 2000
      };
      promptAction.showToast(toastOpts);
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
        const toastOpts: ToastOptions = { 
          message: '请先登录后再发布',
          duration: 2000
        };
        promptAction.showToast(toastOpts);
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
        const toastOpts: ToastOptions = { 
          message: '内容不能为空',
          duration: 2000
        };
        promptAction.showToast(toastOpts);
        return;
      }
      
      this.isSubmitting = true;
      console.info('开始提交帖子，标题：', this.post.title || '无标题');
      
      // 确保设置了用户ID
      this.post.userId = this.userSession.getUserId() || 0;
      
      // 如果有选择图片，需要先上传图片
      let uploadedImages: string[] = [];
      if (this.selectedImages.length > 0) {
        console.info(`开始上传图片，数量: ${this.selectedImages.length}`);
        
        // 遍历上传图片
        for (const imageUri of this.selectedImages) {
          try {
            console.info(`处理图片: ${imageUri}`);
            let base64Data = await this.convertImageToBase64(imageUri);
            
            if (base64Data) {
              // 构造上传参数
              const uploadParams: ApiService.UploadImageParams = {
              fileName: imageUri.substring(imageUri.lastIndexOf('/') + 1),
                base64Image: base64Data
              };
              
              console.info('上传图片参数准备完成，开始上传...');
              const response = await ApiService.uploadImage(uploadParams);
            
            if (response && response.url) {
                console.info(`图片上传成功，URL: ${response.url}`);
              uploadedImages.push(response.url);
              } else {
                console.error('图片上传返回结果异常:', response);
              }
            }
          } catch (error) {
            const err: Error = error instanceof Error ? error : new Error(String(error));
            console.error(`上传图片失败: ${err.message}`);
            const toastOpts: ToastOptions = { 
              message: `图片上传失败: ${err.message}`,
              duration: 2000
            };
            promptAction.showToast(toastOpts);
          }
        }
      }
      
      console.info(`图片上传完成，成功上传${uploadedImages.length}张图片`);
      
      // 创建新的Post对象
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
        // 直接设置为空字符串，让ApiService处理转换
        images: ''
      };
      
      // 记录上传的图片URLs供日志查看
      console.info('上传的图片URLs:', JSON.stringify(uploadedImages));
      
      // 处理images字段 - 如果有上传图片，将数组转换为逗号分隔字符串
      if (uploadedImages.length > 0) {
        postData.images = uploadedImages.join(',');
      }
      
      console.info('准备提交帖子数据:', JSON.stringify(postData));
      
      // 调用API创建帖子
      const createdPost = await ApiService.createPost(postData);
      console.info('帖子创建成功:', createdPost);
      
      const toastOpts: ToastOptions = { 
        message: '发布成功',
        duration: 2000
      };
      promptAction.showToast(toastOpts);
      
      // 返回社区页面
      router.back();
      
    } catch (error) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      console.error(`发布失败: ${err.message}`);
      const toastOpts: ToastOptions = { 
        message: `发布失败: ${err.message}`,
        duration: 2000
      };
      promptAction.showToast(toastOpts);
    } finally {
      this.isSubmitting = false;
    }
  }
  
  // 图片转Base64
  private async convertImageToBase64(imageUri: string): Promise<string | null> {
    try {
      // 直接文件路径读取
      if (imageUri.startsWith('file://') && !imageUri.startsWith('file://media/')) {
        try {
          const realPath: string = imageUri.replace('file://', '');
          await fileIo.access(realPath);
          const fd: number = await fileIo.open(realPath, 0);
          const stat: fileIo.Stat = await fileIo.stat(realPath);
          const fileSize: number = stat.size;
          const buffer: ArrayBuffer = new ArrayBuffer(fileSize);
          await fileIo.read(fd, buffer);
          await fileIo.close(fd);
          const base64Helper: util.Base64Helper = new util.Base64Helper();
          return base64Helper.encodeToStringSync(new Uint8Array(buffer));
        } catch (err) {
          console.error('直接文件路径读取失败，尝试使用photoAccessHelper', err);
        }
      }
      
      // 使用photoAccessHelper正确的API
      const context = getContext(this);
      const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      
      // 构建查询条件
      let predicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('uri', imageUri);
      let fetchOptions: FetchOptions = {
        fetchColumns: [],
        predicates: predicates
      };
      
      // 返回Promise
      return new Promise<string | null>((resolve, reject) => {
        // 定义数据处理器
        class MediaDataHandler implements MediaAssetDataHandlerInterface<ArrayBuffer> {
          onDataPrepared(data: ArrayBuffer): void {
            if (data === undefined) {
              console.error('获取图片数据失败');
              reject(new Error('获取图片数据失败'));
              return;
            }
            
            try {
              // 转换为Base64
              const uint8Array = new Uint8Array(data);
              const base64Helper: util.Base64Helper = new util.Base64Helper();
              const base64 = base64Helper.encodeToStringSync(uint8Array);
              
              // 添加适当的数据URL前缀
              let contentType = 'image/jpeg'; // 默认为JPEG
              if (imageUri.toLowerCase().endsWith('.png')) {
                contentType = 'image/png';
              } else if (imageUri.toLowerCase().endsWith('.gif')) {
                contentType = 'image/gif';
              } else if (imageUri.toLowerCase().endsWith('.webp')) {
                contentType = 'image/webp';
              }
              
              // 添加数据URL前缀
              const base64WithPrefix = `data:${contentType};base64,${base64}`;
              resolve(base64WithPrefix);
            } catch (err) {
              console.error('Base64转换失败:', err);
              reject(err);
            }
          }
        }
        
        // 先获取资源
        phAccessHelper.getAssets(fetchOptions)
          .then(async (fetchResult) => {
            if (fetchResult.getCount() > 0) {
              const photoAsset = await fetchResult.getFirstObject();
              if (photoAsset) {
                // 配置请求选项
                const requestOptions: RequestOptions = {
                  deliveryMode: 1  // 使用数字1代表HIGH_QUALITY_MODE
                };
                
                // 请求图片数据
                const handler = new MediaDataHandler();
                photoAccessHelper.MediaAssetManager.requestImageData(context, photoAsset, requestOptions, handler)
                  .catch((err: Error) => {
                    console.error(`获取图片数据失败: ${err.name}, ${err.message}`);
                    reject(err);
                  });
              } else {
                console.error('未找到图片资源');
                reject(new Error('未找到图片资源'));
              }
            } else {
              console.error('未找到匹配的图片资源');
              reject(new Error('未找到匹配的图片资源'));
            }
          })
          .catch((error: Error) => {
            console.error('获取资源失败:', error);
            reject(error instanceof Error ? error : new Error(String(error)));
          });
      });
    } catch (error) {
      console.error('图片处理过程中发生错误:', error);
      throw error instanceof Error ? error : new Error(String(error));
    }
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