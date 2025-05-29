import { Post, Dream } from '../../model/CommonTypes';
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
import { MyLoadingProgress } from '../../components/LoadingProgress';

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

// 路由参数接口
interface RouteParams {
  postId: number;
  title?: string;
  content?: string;
  imageUrls?: string[];
  dreamId?: number;
}

// 上传图片参数接口
interface UploadImageParams {
  base64: string;
  type?: string;
}

// 上传图片响应接口
interface UploadImageResponse {
  url: string;
  success: boolean;
  message?: string;
}

// 帖子更新数据接口
interface PostUpdateData {
  userId: number;
  title: string;
  content: string;
  dreamId?: number;
  imageUrls: string[];
  status: number;
}

// 常量定义
const FONT_SIZE_SMALL: number = 14;
const FONT_SIZE_NORMAL: number = 16;
const FONT_SIZE_LARGE: number = 20;
const MARGIN_SMALL: number = 4;
const MARGIN_NORMAL: number = 8;
const MARGIN_MEDIUM: number = 12;
const MARGIN_LARGE: number = 16;
const RADIUS_SMALL: number = 4;
const RADIUS_NORMAL: number = 8;
const RADIUS_LARGE: number = 16;

@Entry
@Component
export struct PostEditPage {
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
  
  @State originalImageUrls: string[] = []; // 原始图片列表，用于比较
  @State selectedImages: string[] = []; // 编辑过程中选择的新图片
  @State removedImageUrls: string[] = []; // 被移除的原始图片
  @State currentImageUrls: string[] = []; // 当前显示的所有图片（原始+新选择）
  @State isSubmitting: boolean = false;
  @State isLoading: boolean = true;
  @State showDreamSelector: boolean = false;
  @State userDreams: Dream[] = [];
  @State isLoadingDreams: boolean = false;
  @State selectedDreamId: number | undefined = undefined; // 添加selectedDreamId属性
  private userSession: UserSession = UserSession.getInstance();

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouteParams;
    console.info('PostEditPage路由参数:', JSON.stringify(params));
    
    if (params && params.postId) {
      this.post.id = params.postId;
      
      // 如果路由传递了基本数据，先使用这些数据
      if (params.title) this.post.title = params.title;
      if (params.content) this.post.content = params.content;
      if (params.dreamId) this.post.dreamId = params.dreamId;
      if (params.imageUrls && Array.isArray(params.imageUrls)) {
        this.originalImageUrls = [];
        for (let i = 0; i < params.imageUrls.length; i++) {
          this.originalImageUrls.push(params.imageUrls[i]);
        }
        this.currentImageUrls = [];
        for (let i = 0; i < params.imageUrls.length; i++) {
          this.currentImageUrls.push(params.imageUrls[i]);
        }
      }
      
      // 从会话获取当前用户ID
      if (this.userSession && this.userSession.isLoggedIn()) {
        const userInfo = this.userSession.getCurrentUser();
        if (userInfo && userInfo.id) {
          this.post.userId = userInfo.id;
        }
      }
      
      // 即使已有基础数据，仍然从服务器获取最新数据
      this.loadPostDetails();
      
      // 获取用户的梦想列表，用于关联梦想
      this.loadUserDreams();
    } else {
      promptAction.showToast({
        message: '无效的帖子ID',
        duration: 2000
      });
      router.back();
    }
  }

  /**
   * 加载帖子详情
   */
  async loadPostDetails() {
    try {
      this.isLoading = true;
      
      // 调用API获取帖子详情
      const postDetails = await ApiService.getPostById(this.post.id);
      console.info('获取帖子详情成功:', JSON.stringify(postDetails));
      
      if (postDetails) {
        // 更新帖子信息
        let updatedPost: Post = {
          id: this.post.id, // 保证ID不变
          userId: this.post.userId,
          title: postDetails.title || this.post.title,
          content: postDetails.content || this.post.content,
          likeCount: postDetails.likeCount || this.post.likeCount,
          commentCount: postDetails.commentCount || this.post.commentCount,
          createdAt: postDetails.createdAt || this.post.createdAt,
          updatedAt: postDetails.updatedAt || this.post.updatedAt,
          images: postDetails.images || this.post.images,
          dreamId: postDetails.dreamId || this.post.dreamId,
          author: postDetails.author || this.post.author
        };
        this.post = updatedPost;
        
        // 更新图片列表
        if (postDetails.imageUrls && Array.isArray(postDetails.imageUrls)) {
          this.originalImageUrls = [];
          for (let i = 0; i < postDetails.imageUrls.length; i++) {
            this.originalImageUrls.push(postDetails.imageUrls[i]);
          }
          
          this.currentImageUrls = [];
          for (let i = 0; i < postDetails.imageUrls.length; i++) {
            this.currentImageUrls.push(postDetails.imageUrls[i]);
          }
        }
        
        // 检查当前用户是否有权限编辑该帖子
        const currentUserId = this.userSession.getUserId();
        if (!currentUserId || (postDetails.userId !== currentUserId && postDetails.author?.id !== currentUserId)) {
          promptAction.showToast({
            message: '无权限编辑该帖子',
            duration: 2000
          });
          router.back();
        }
      } else {
        promptAction.showToast({
          message: '获取帖子详情失败',
          duration: 2000
        });
        router.back();
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      promptAction.showToast({
        message: `加载失败: ${errorMsg}`,
        duration: 2000
      });
      console.error('加载帖子详情失败:', error);
      router.back();
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 加载用户的梦想列表
   */
  async loadUserDreams() {
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
      const errorMsg = error instanceof Error ? error.message : String(error);
      promptAction.showToast({
        message: `加载梦想列表失败: ${errorMsg}`,
        duration: 2000
      });
      console.error('加载梦想列表失败:', error);
    } finally {
      this.isLoadingDreams = false;
    }
  }

  /**
   * 挑选图片
   */
  async pickImages() {
    try {
      // 创建图片选择器实例
      let photoPicker = new picker.PhotoViewPicker();
      // 设置选择参数
      let photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 9 - this.originalImageUrls.length + this.removedImageUrls.length;
      
      // 使用Promise方式调用
      photoPicker.select(photoSelectOptions)
        .then((photos) => {
          if (photos && photos.photoUris && photos.photoUris.length > 0) {
            // 添加新选择的图片
            const newSelectedImages: string[] = [];
            for (let i = 0; i < this.selectedImages.length; i++) {
              newSelectedImages.push(this.selectedImages[i]);
            }
            for (let i = 0; i < photos.photoUris.length; i++) {
              newSelectedImages.push(photos.photoUris[i]);
            }
            this.selectedImages = newSelectedImages;
            
            // 更新当前显示的图片列表
            this.updateCurrentImageUrls();
          }
        })
        .catch((err: Error) => {
          console.error(`选择图片失败: ${err.message}`);
          promptAction.showToast({
            message: `选择图片失败: ${err.message}`, 
            duration: 2000 
          });
        });
    } catch (error) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      console.error(`选择图片失败: ${err.message}`);
      promptAction.showToast({
        message: `选择图片失败: ${err.message}`,
        duration: 2000
      });
    }
  }
  
  /**
   * 删除图片
   * @param index 图片在当前列表中的索引
   */
  removeImage(index: number) {
    // 获取要删除的图片URL
    const imageToRemove = this.currentImageUrls[index];
    
    // 检查是否为原始图片
    const originalIndex = this.originalImageUrls.indexOf(imageToRemove);
    if (originalIndex !== -1) {
      // 添加到已移除的原始图片列表
      this.removedImageUrls.push(imageToRemove);
    } else {
      // 从新选择的图片中移除
      const newIndex = this.selectedImages.indexOf(imageToRemove);
      if (newIndex !== -1) {
        const newImages: string[] = [];
        for (let i = 0; i < this.selectedImages.length; i++) {
          if (i !== newIndex) {
            newImages.push(this.selectedImages[i]);
          }
        }
        this.selectedImages = newImages;
      }
    }
    
    // 更新当前显示的图片列表
    this.updateCurrentImageUrls();
  }
  
  /**
   * 更新当前显示的图片列表
   */
  updateCurrentImageUrls() {
    // 获取保留的原始图片
    const remainingOriginalImages: string[] = [];
    for (let i = 0; i < this.originalImageUrls.length; i++) {
      const url = this.originalImageUrls[i];
      if (!this.removedImageUrls.includes(url)) {
        remainingOriginalImages.push(url);
      }
    }
    
    // 合并原始图片和新选择的图片
    const mergedImages: string[] = [];
    for (let i = 0; i < remainingOriginalImages.length; i++) {
      mergedImages.push(remainingOriginalImages[i]);
    }
    for (let i = 0; i < this.selectedImages.length; i++) {
      mergedImages.push(this.selectedImages[i]);
    }
    this.currentImageUrls = mergedImages;
    
    // 确保最多9张图片
    if (this.currentImageUrls.length > 9) {
      const limitedImages: string[] = [];
      for (let i = 0; i < 9; i++) {
        limitedImages.push(this.currentImageUrls[i]);
      }
      this.currentImageUrls = limitedImages;
    }
  }
  
  /**
   * 上传图片到服务器
   * @param imageUris 图片URI列表
   * @returns 上传后的图片URL列表
   */
  private async uploadImages(imageUris: string[]): Promise<string[]> {
    try {
      const uploadPromises: Promise<string>[] = [];
      
      // 处理每个图片
      for (let i = 0; i < imageUris.length; i++) {
        const uri = imageUris[i];
        // 转换为Base64
        const base64 = await this.convertImageToBase64(uri);
        if (base64) {
          // 使用ApiService中定义的接口类型
          const uploadParams: ApiService.UploadImageParams = {
            base64Image: base64,
            fileName: `image_${Date.now()}.jpg`
          };
          
          const uploadPromise = ApiService.uploadImage(uploadParams)
            .then((result) => {
              // 正确使用返回的URL
              return result.url;
            })
            .catch((error: Error) => {
              console.error(`上传图片失败: ${error.message}`);
              return '';
            });
          
          uploadPromises.push(uploadPromise);
        }
      }
      
      // 等待所有上传完成
      const results = await Promise.all(uploadPromises);
      // 过滤掉空字符串
      return results.filter(url => url !== '');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(`上传图片过程中发生错误: ${err.message}`);
      return [];
    }
  }

  /**
   * 提交修改
   */
  async submitEdit() {
    try {
      if (!this.post.title || this.post.title.trim() === '') {
        promptAction.showToast({
          message: '标题不能为空',
          duration: 2000
        });
        return;
      }
      
      if (!this.post.content || this.post.content.trim() === '') {
        promptAction.showToast({
          message: '内容不能为空',
          duration: 2000
        });
        return;
      }
      
      this.isSubmitting = true;
      console.info(`开始提交帖子更新，标题： ${this.post.title}`);
      
      // 处理图片：结合原始保留的图片和新选择的图片
      let finalImageUrls: string[] = [];
      
      // 添加保留的原始图片
      for (let i = 0; i < this.originalImageUrls.length; i++) {
        const url = this.originalImageUrls[i];
        if (!this.removedImageUrls.includes(url)) {
          finalImageUrls.push(url);
        }
      }
      
      // 处理新选择的图片
      if (this.selectedImages.length > 0) {
        // 上传新图片
        const uploadedUrls = await this.uploadImages(this.selectedImages);
        if (uploadedUrls && uploadedUrls.length > 0) {
          // 使用循环逐个添加，而非展开运算符
          for (let i = 0; i < uploadedUrls.length; i++) {
            finalImageUrls.push(uploadedUrls[i]);
          }
        }
      }
      
      console.info(`图片处理完成，最终图片数量: ${finalImageUrls.length}`);
      
      // 准备更新数据，使用ApiService中的RequestData类型
      const updateData: ApiService.RequestData = {
        userId: this.post.userId,
        title: this.post.title,
        content: this.post.content,
        dreamId: this.selectedDreamId || this.post.dreamId,
        imageUrls: finalImageUrls,
        status: 1 // 确保状态字段设置为有效值
      };
      
      console.info(`准备提交更新数据: ${JSON.stringify(updateData)}`);
      
      // 调用API更新帖子
      const updatedPost = await ApiService.updatePost(this.post.id, updateData);
      
      promptAction.showToast({
        message: '更新成功',
        duration: 2000
      });
      
      // 返回上一页，并传递更新后的数据
      router.back({
        url: 'pages/community/PostDetailPage',
        params: {
          postId: this.post.id,
          updated: true
        }
      });
      
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      promptAction.showToast({
        message: `更新失败: ${errorMsg}`,
        duration: 2000
      });
      console.error(`更新失败: ${errorMsg}`);
    } finally {
      this.isSubmitting = false;
    }
  }
  
  /**
   * 图片转Base64
   */
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
    Stack() {
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
          
          Text('编辑动态')
            .fontSize(FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .margin({ left: MARGIN_LARGE })
          
          Blank()
          
          Button('保存') 
            .fontSize(FONT_SIZE_NORMAL)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(this.isSubmitting || this.isLoading ? '#999999' : $r('app.color.primary_color'))
            .height(40)
            .borderRadius(RADIUS_NORMAL)
            .enabled(!this.isSubmitting && !this.isLoading)
            .onClick(() => {
              this.submitEdit();
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: MARGIN_LARGE, right: MARGIN_LARGE })
        .alignItems(VerticalAlign.Center)
        
        if (this.isLoading) {
          // 加载中
          Column() {
            MyLoadingProgress()
              .width(50)
              .height(50)
            
            Text('加载中...')
              .fontSize(FONT_SIZE_NORMAL)
              .margin({ top: MARGIN_LARGE })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          // 内容区域
          Scroll() {
            Column() {
              // 标题输入
              TextInput({ placeholder: '标题（选填）', text: this.post.title })
                .fontSize(FONT_SIZE_NORMAL)
                .height(50)
                .backgroundColor(Color.Transparent)
                .placeholderFont({ size: FONT_SIZE_NORMAL })
                .width('100%')
                .onChange((value: string) => {
                  this.post.title = value;
                })
              
              // 内容输入
              TextArea({ placeholder: '分享你的梦想与生活...', text: this.post.content })
                .fontSize(FONT_SIZE_NORMAL)
                .placeholderFont({ size: FONT_SIZE_NORMAL })
                .backgroundColor(Color.Transparent)
                .height(200)
                .width('100%')
                .onChange((value: string) => {
                  this.post.content = value;
                })
              
              // 图片展示区
              if (this.currentImageUrls.length > 0) {
                Grid() {
                  ForEach(this.currentImageUrls, (image: string, index: number) => {
                    GridItem() {
                      Stack({ alignContent: Alignment.TopEnd }) {
                        Image(image)
                          .width('100%')
                          .height('100%')
                          .borderRadius(RADIUS_SMALL)
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
                .columnsTemplate(this.currentImageUrls.length === 1 ? '1fr' : 
                              this.currentImageUrls.length === 2 ? '1fr 1fr' : '1fr 1fr 1fr')
                .rowsTemplate(this.currentImageUrls.length <= 3 ? '1fr' : 
                            this.currentImageUrls.length <= 6 ? '1fr 1fr' : '1fr 1fr 1fr')
                .columnsGap(MARGIN_SMALL)
                .rowsGap(MARGIN_SMALL)
                .height(this.currentImageUrls.length <= 3 ? 100 : 
                      this.currentImageUrls.length <= 6 ? 200 : 300)
                .width('100%')
                .margin({ top: MARGIN_NORMAL })
              }
              
              // 关联梦想卡片
              if (this.post.dreamId) {
                Row() {
                  Text('关联梦想：')
                    .fontSize(FONT_SIZE_SMALL)
                    .fontColor('#999999')
                  
                  Text(this.userDreams.find(d => d.id === this.post.dreamId)?.title || '')
                    .fontSize(FONT_SIZE_SMALL)
                    .fontColor($r('app.color.primary_color'))
                    .fontWeight(FontWeight.Medium)
                  
                  Blank()
                  
                  Button({ type: ButtonType.Circle }) {
                    Image(AppIcons.close)
                      .width(16)
                      .height(16)
                      .fillColor('#999999')
                  }
                  .width(24)
                  .height(24)
                  .backgroundColor('#F5F5F5')
                  .onClick(() => {
                    this.post.dreamId = undefined;
                  })
                }
                .width('100%')
                .padding(MARGIN_MEDIUM)
                .borderRadius(RADIUS_NORMAL)
                .backgroundColor('#F5F5F5')
                .margin({ top: MARGIN_NORMAL })
              }
            }
            .width('100%')
            .padding({ 
              left: MARGIN_LARGE, 
              right: MARGIN_LARGE,
              bottom: MARGIN_LARGE
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
                  .fontSize(FONT_SIZE_SMALL)
                  .fontColor('#666666')
                  .margin({ left: 4 })
              }
              .enabled(this.currentImageUrls.length < 9)
              .opacity(this.currentImageUrls.length < 9 ? 1.0 : 0.5)
              .onClick(() => {
                if (this.currentImageUrls.length < 9) {
                  this.pickImages();
                } else {
                  promptAction.showToast({
                    message: '最多只能上传9张图片',
                    duration: 2000
                  });
                }
              })
              
              Divider()
                .vertical(true)
                .height(24)
                .width(1)
                .color('#E0E0E0')
                .margin({ left: MARGIN_LARGE, right: MARGIN_LARGE })
              
              Row() {
                Image(AppIcons.tag)
                  .width(24)
                  .height(24)
                  .fillColor('#666666')
                Text('关联梦想')
                  .fontSize(FONT_SIZE_SMALL)
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
            .padding({ left: MARGIN_LARGE, right: MARGIN_LARGE })
          }
          .width('100%')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      
      // 梦想选择对话框
      if (this.showDreamSelector) {
        Column() {
          // 对话框标题
          Row() {
            Text('选择关联的梦想')
              .fontSize(FONT_SIZE_LARGE)
              .fontWeight(FontWeight.Bold)
            
            Image(AppIcons.close)
              .width(24)
              .height(24)
              .fillColor('#333333')
              .onClick(() => {
                this.showDreamSelector = false;
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ 
            top: MARGIN_LARGE, 
            bottom: MARGIN_NORMAL,
            left: MARGIN_LARGE,
            right: MARGIN_LARGE
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
                  MyLoadingProgress()
                    .width(20)
                    .height(20)
                    .margin({ right: MARGIN_SMALL })
                  Text('加载中...')
                    .fontSize(FONT_SIZE_SMALL)
                    .fontColor('#999999')
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding({ top: MARGIN_LARGE, bottom: MARGIN_LARGE })
              }
            } else if (this.userDreams.length === 0) {
              ListItem() {
                Text('暂无公开的梦想可供关联')
                  .fontSize(FONT_SIZE_SMALL)
                  .fontColor('#999999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: MARGIN_LARGE, bottom: MARGIN_LARGE })
              }
            } else {
              ForEach(this.userDreams, (dream: Dream) => {
                ListItem() {
                  Row() {
                    Image(dream.imageUrl || '')
                      .width(40)
                      .height(40)
                      .borderRadius(4)
                      .margin({ right: MARGIN_MEDIUM })
                    
                    Column() {
                      Text(dream.title)
                        .fontSize(FONT_SIZE_NORMAL)
                        .fontWeight(FontWeight.Medium)
                      
                      Text(`完成率: ${dream.completionRate}%`)
                        .fontSize(FONT_SIZE_SMALL)
                        .fontColor('#999999')
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
                  .padding(MARGIN_MEDIUM)
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
            .borderRadius(RADIUS_NORMAL)
            .margin({ top: MARGIN_MEDIUM, bottom: MARGIN_LARGE })
            .onClick(() => {
              this.showDreamSelector = false;
            })
        }
        .width('100%')
        .height('70%')
        .backgroundColor(Color.White)
        .borderRadius({
          topLeft: RADIUS_LARGE,
          topRight: RADIUS_LARGE
        })
        .position({ x: 0, y: '30%' })
      }
      
      // 提交中的遮罩层
      if (this.isSubmitting) {
        Column() {
          MyLoadingProgress({ color: Color.White, progressSize: 50 })
          
          Text('正在保存...')
            .fontSize(FONT_SIZE_NORMAL)
            .fontColor(Color.White)
            .margin({ top: MARGIN_LARGE })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
} 