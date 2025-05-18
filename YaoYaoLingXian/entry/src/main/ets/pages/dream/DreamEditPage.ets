import router from '@ohos.router';
import * as ApiService from '../../services/ApiService';
import { Dream } from '../../model/CommonTypes';
import { AppIcons } from '../../utils/IconUtils';
import { promptAction } from '../../utils/PromptUtils';
import { CommonConstants } from '../../constants/CommonConstants';
import promptAction_1 from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import image from '@ohos.multimedia.image';
import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import { BASE_URL } from '../../services/ApiService';

/**
 * 接口定义部分
 */
// 错误类型
interface ErrorInfo {
  message: string;
}

// HTTP请求头部类型
type HttpHeader = Record<string, string>;

// 文件信息类型
type FileInfo = Record<string, string>;

// 提示框参数
interface ToastOptions {
  message: string;
  duration?: number;
}

// 图片选择结果
interface PhotoSelectResult {
  photoUris: string[];
  isOriginal?: boolean;
}

// 对齐官方API的HTTP响应类型
interface HttpResponse {
  responseCode: number;
  result?: string | Object | ArrayBuffer;
  header?: Object;
  cookies?: string[]; // 更新为字符串数组以与官方API匹配
}

// API响应数据结构
interface ApiResponse {
  code: number;
  message: string;
  data: ImageResponseData;
}

// 图片响应数据
interface ImageResponseData {
  url: string;
  filename: string;
}

/**
 * 定义http.MultiFormData类型以匹配API要求
 */
interface MultiFormData {
  name: string; // 表单项名称
  contentType: string; // 内容类型
  filePath?: string; // 文件路径
  data?: string | ArrayBuffer; // 数据
  remoteFileName?: string; // 服务器端文件名
}

// HTTP请求配置
interface HttpRequestConfig {
  method: http.RequestMethod;
  header: HttpHeader;
  connectTimeout: number;
  readTimeout: number;
  multiFormDataList?: MultiFormData[];
}

/**
 * 路由参数接口
 */
interface DreamRouterParams {
  dreamId?: number;
}

/**
 * 选择器选项接口
 */
interface SelectOption {
  value: string;
}

/**
 * 日期类型接口，替代标准库的Date
 */
interface SimpleDate {
  year: number;
  month: number;
  day: number;
}

/**
 * 使用自定义日期类来替代标准库Date类型
 */
class CustomDate {
  private date: SimpleDate;
  
  constructor(year?: number, month?: number, day?: number) {
    if (year !== undefined && month !== undefined && day !== undefined) {
      this.date = { year, month, day };
    } else {
      const now = new Date();
      this.date = {
        year: now.getFullYear(),
        month: now.getMonth() + 1, // 月份从1开始
        day: now.getDate()
      };
    }
  }
  
  // 获取年份
  getFullYear(): number {
    return this.date.year;
  }
  
  // 获取月份(1-12)
  getMonth(): number {
    return this.date.month;
  }
  
  // 获取日期
  getDate(): number {
    return this.date.day;
  }
  
  // 设置日期
  setDate(day: number): void {
    this.date.day = day;
  }
  
  // 转为字符串形式 YYYY-MM-DD
  toString(): string {
    return `${this.date.year}-${String(this.date.month).padStart(2, '0')}-${String(this.date.day).padStart(2, '0')}`;
  }
  
  // 创建日期之后n天的日期
  static afterDays(days: number): CustomDate {
    const newDate = new CustomDate();
    const tempDate = new Date();
    tempDate.setDate(tempDate.getDate() + days);
    newDate.date.year = tempDate.getFullYear();
    newDate.date.month = tempDate.getMonth() + 1;
    newDate.date.day = tempDate.getDate();
    return newDate;
  }
  
  // 解析日期字符串 YYYY-MM-DD
  static fromString(dateStr: string): CustomDate | null {
    try {
      const parts = dateStr.split('-');
      if (parts.length !== 3) return null;
      
      const year = parseInt(parts[0], 10);
      const month = parseInt(parts[1], 10);
      const day = parseInt(parts[2], 10);
      
      if (isNaN(year) || isNaN(month) || isNaN(day)) return null;
      
      return new CustomDate(year, month, day);
    } catch (e) {
      return null;
    }
  }
}

@Entry
@Component
export struct DreamEditPage {
  @State dream: Dream = {
    id: 0,
    userId: 2, // 默认用户ID为2
    title: '',
    description: '',
    category: '学习',
    priority: 3,
    status: 1, // 默认进行中
    completionRate: 0,
    deadline: '', // 初始化为空字符串，将在aboutToAppear中设置
    imageUrl: '', // 初始化为空字符串，将在aboutToAppear中设置
    isPublic: 1, // 默认公开
    expectedDays: 30, // 默认30天
    tags: [] // 初始化为空数组
  };
  
  @State isEditing: boolean = false;
  @State isSubmitting: boolean = false;
  @State isLoading: boolean = false;
  @State categoryOptions: string[] = ['学习', '健康', '旅行', '创作', '艺术', '职业', '生活技能'];
  @State priorityOptions: number[] = [1, 2, 3, 4, 5];
  @State priorityLabels: string[] = CommonConstants.DREAM_PRIORITY_LABELS;
  @State showDatePicker: boolean = false;
  @State selectedDate: CustomDate = new CustomDate();
  @State errorMessage: string = '';
  @State isUploadingImage: boolean = false; // 图片上传状态
  @State selectedLocalImage: string = ''; // 已选本地图片路径
  
  aboutToAppear() {
    try {
      // 初始化默认图片 - 设置一个固定的占位图URL
      if (!this.dream.imageUrl || this.dream.imageUrl.trim() === '') {
        this.dream.imageUrl = 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d'; // 使用占位图
      }
      
      // 设置默认截止日期
      this.selectedDate = CustomDate.afterDays(30);
      if (!this.dream.deadline || this.dream.deadline.trim() === '') {
        this.dream.deadline = this.selectedDate.toString();
      }
      
      // 检查是否有传入的梦想数据（编辑模式）
      const params = router.getParams() as DreamRouterParams;
      if (params && params.dreamId) {
        // 编辑模式，获取梦想详情
        this.isEditing = true;
        this.fetchDreamDetail(params.dreamId);
      }
    } catch (error) {
      console.error(`初始化页面出错: ${error instanceof Error ? error.message : String(error)}`);
      this.errorMessage = '页面初始化失败，请返回重试。';
      const toastOpts: ToastOptions = { message: this.errorMessage };
      promptAction.showToast(toastOpts);
    }
  }
  
  /**
   * 获取梦想详情信息
   */
  private async fetchDreamDetail(dreamId: number) {
    try {
      this.isLoading = true;
      console.info(`获取梦想详情，ID: ${dreamId}`);
      const dreamDetail = await ApiService.getDreamById(dreamId);
      console.info(`获取到梦想详情: ${JSON.stringify(dreamDetail)}`);
      
      // 将后端返回的数据填充到表单
      this.dream = dreamDetail;
      
      // 确保tags字段始终存在且为数组
      this.dream.tags = this.dream.tags || [];

      // 处理日期字符串转CustomDate对象（假设格式为YYYY-MM-DD）
      if (dreamDetail.deadline && typeof dreamDetail.deadline === 'string') {
        const customDate = CustomDate.fromString(dreamDetail.deadline);
        if (customDate) {
          this.selectedDate = customDate;
          console.info(`解析日期成功: ${this.selectedDate.toString()}`);
        } else {
          console.warn(`日期解析失败，使用当前日期: ${dreamDetail.deadline}`);
          this.selectedDate = new CustomDate(); // 如果解析失败，使用当前日期
        }
      } else {
        console.info(`未提供deadline或格式不是字符串，使用当前日期`);
        this.selectedDate = new CustomDate(); // 如果没有提供deadline，使用当前日期
      }
    } catch (error) {
      console.error(`获取梦想详情失败: ${error instanceof Error ? error.message : String(error)}`);
      this.errorMessage = `获取梦想详情失败: ${error instanceof Error ? error.message : String(error)}`;
      const toastOpts: ToastOptions = { message: this.errorMessage };
      promptAction.showToast(toastOpts);
    } finally {
      this.isLoading = false;
    }
  }
  
  // 获取当前日期之后n天的日期
  getDateAfterDays(days: number): CustomDate {
    return CustomDate.afterDays(days);
  }
  
  // 格式化日期为YYYY-MM-DD
  formatDate(date: CustomDate): string {
    return date.toString();
  }
  
  // 验证表单
  validateForm(): boolean {
    if (!this.dream.title.trim()) {
      this.errorMessage = '请输入梦想标题';
      return false;
    }
    
    if (!this.dream.description.trim()) {
      this.errorMessage = '请输入梦想描述';
      return false;
    }
    
    return true;
  }
  
  // 提交表单
  private async submitForm() {
    try {
      // 设置加载状态
      this.isLoading = true;
      this.errorMessage = '';

      // 验证表单字段
      if (!this.dream.title || this.dream.title.trim() === '') {
        this.errorMessage = '梦想标题不能为空';
        this.isLoading = false;
        return;
      }

      // 设置截止日期
      this.dream.deadline = this.selectedDate.toString();

      // 确保数值字段为数字类型
      this.dream.priority = parseInt(String(this.dream.priority || 1), 10);
      this.dream.status = parseInt(String(this.dream.status || 0), 10);
      this.dream.completionRate = parseInt(String(this.dream.completionRate || 0), 10);
      this.dream.expectedDays = parseInt(String(this.dream.expectedDays || 1), 10);
      this.dream.isPublic = parseInt(String(this.dream.isPublic || 0), 10);

      // 确保有图片路径
      if (!this.dream.imageUrl || this.dream.imageUrl.trim() === '') {
        this.dream.imageUrl = 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d'; // 使用占位图
      }
      
      // 确保tags字段初始化为空数组
      this.dream.tags = this.dream.tags || [];

      // 记录提交的数据，便于调试
      console.info('提交梦想数据：', JSON.stringify(this.dream));

      try {
        // 根据是否有ID决定创建还是更新
        if (this.dream.id) {
          // 更新已有梦想
          const updatedDream = await ApiService.updateDream(this.dream.id, this.dream);
          console.info('梦想更新成功：', JSON.stringify(updatedDream));
          const toastOpts: ToastOptions = { message: '梦想已成功更新！' };
          promptAction.showToast(toastOpts);
          // 返回上一页
          router.back();
        } else {
          // 创建新梦想
          const newDream = await ApiService.createDream(this.dream);
          console.info('梦想创建成功：', JSON.stringify(newDream));
          const toastOpts: ToastOptions = { message: '梦想已成功创建！' };
          promptAction.showToast(toastOpts);
          // 返回上一页
          router.back();
        }
      } catch (error) {
        // 处理API错误
        console.error('API错误：', error instanceof Error ? error.message : String(error));
        
        // 解析错误信息
        let errorMsg = '服务器处理请求时出错';
        
        // 检查是否包含特定的错误信息
        if (error instanceof Error) {
          const errorText = error.message || '';
          
          if (errorText.includes('NullPointerException') || errorText.includes('dreamTags')) {
            errorMsg = '服务器在处理标签时出错，请联系管理员修复后端dreamTags问题';
          } else if (errorText.includes('500')) {
            errorMsg = '服务器内部错误，请稍后再试';
          } else if (errorText.includes('timeout') || errorText.includes('超时')) {
            errorMsg = '请求超时，请检查网络连接';
          }
        }
        
        this.errorMessage = errorMsg;
        const toastOpts: ToastOptions = { message: errorMsg };
        promptAction.showToast(toastOpts);
      }
    } catch (error) {
      // 处理其他错误
      console.error('提交梦想表单失败：', error instanceof Error ? error.message : String(error));
      this.errorMessage = error instanceof Error ? error.message : String(error);
      const toastOpts: ToastOptions = { message: '操作失败：' + this.errorMessage };
      promptAction.showToast(toastOpts);
    } finally {
      // 取消加载状态
      this.isLoading = false;
    }
  }

  // 处理日期选择
  handleDateSelect() {
    try {
      // 生成未来60天的日期选项
      const dateOptions = this.generateDateOptions();
      
      // 设置默认选中当前日期
      this.dream.deadline = this.selectedDate.toString();
      
      // 显示选择器
      this.showDatePicker = true;
    } catch (error) {
      console.error(`显示日期选择器失败: ${error instanceof Error ? error.message : String(error)}`);
      const toastOpts: ToastOptions = { message: '无法打开日期选择器' };
      promptAction.showToast(toastOpts);
    }
  }
  
  // 生成日期字符串选项，未来60天的日期
  private generateDateStrings(): string[] {
    const options: string[] = [];
    
    for (let i = 0; i < 60; i++) {
      const date = CustomDate.afterDays(i);
      options.push(date.toString());
    }
    
    return options;
  }
  
  // 生成日期选项，未来60天的日期
  private generateDateOptions(): SelectOption[] {
    const options: SelectOption[] = [];
    const today = new CustomDate();
    
    for (let i = 0; i < 60; i++) {
      const date = CustomDate.afterDays(i);
      options.push({ value: date.toString() });
    }
    
    return options;
  }

  // 从本地选择图片
  async pickLocalImage(): Promise<void> {
    try {
      // 创建图片选择器实例
      let photoPicker = new picker.PhotoViewPicker();
      // 设置选择参数
      let photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      
      photoPicker.select(photoSelectOptions)
        .then((photos) => {
          if (photos && photos.photoUris && photos.photoUris.length > 0) {
            this.selectedLocalImage = photos.photoUris[0];
            this.uploadImage(this.selectedLocalImage);
          }
        })
        .catch(() => {
          // 不直接引用错误参数，避免隐式类型问题
          const toastOpts: ToastOptions = { message: '选择图片失败' };
          promptAction.showToast(toastOpts);
          console.error('选择图片失败');
        });
    } catch (_) {
      // 不直接引用错误参数，避免隐式类型问题
      const toastOpts: ToastOptions = { message: '选择图片时出错' };
      promptAction.showToast(toastOpts);
      console.error('选择图片器错误');
    }
  }
  
  // 上传图片到服务器
  async uploadImage(imageUri: string): Promise<void> {
    try {
      this.isUploadingImage = true;
      const toastOpts: ToastOptions = { message: '开始上传图片...' };
      promptAction.showToast(toastOpts);
        
      // HTTP请求头
      const headers: HttpHeader = {
        'Content-Type': 'multipart/form-data',
      };
      
      // 文件信息 - 使用MultiFormData对象正确配置
      // 明确定义multiFormDataList的类型
      const multiFormData: MultiFormData[] = [
        {
          name: 'file',
          contentType: 'image/jpeg',
          filePath: imageUri,
          remoteFileName: 'dream_image.jpg'
        }
      ];
      
      // 创建符合http.HttpRequestOptions的请求选项
      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: headers,
        connectTimeout: 60000,
        readTimeout: 60000,
        multiFormDataList: multiFormData
      };
      
      // 发送请求
      let httpRequest = http.createHttp();
      httpRequest.request(
        `${BASE_URL}/files/upload`,
        requestOptions
      ).then((response) => {
        this.isUploadingImage = false;
        if (response.responseCode === 200) {
          // 确保result先转为字符串
          const resultText = response.result.toString();
          // 使用类型断言将解析后的JSON对象转为ApiResponse类型
          const responseData = JSON.parse(resultText) as ApiResponse;
          
          if (responseData.code === 200) {
            this.dream.imageUrl = responseData.data.url;
            const toastOpts: ToastOptions = { message: '图片上传成功' };
            promptAction.showToast(toastOpts);
          } else {
            const toastOpts: ToastOptions = { message: '图片上传失败: ' + responseData.message };
            promptAction.showToast(toastOpts);
          }
        } else {
          const toastOpts: ToastOptions = { message: '上传失败，请重试' };
          promptAction.showToast(toastOpts);
        }
      }).catch(() => {
        this.isUploadingImage = false;
        // 不直接引用错误参数，避免隐式类型问题
        const toastOpts: ToastOptions = { message: '网络错误，上传失败' };
        promptAction.showToast(toastOpts);
        console.error('上传失败');
      }).finally(() => {
        httpRequest.destroy();
      });
    } catch (_) {
      this.isUploadingImage = false;
      // 不直接引用错误参数，避免隐式类型问题
      const toastOpts: ToastOptions = { message: '上传过程中出错' };
      promptAction.showToast(toastOpts);
      console.error('上传图片过程中出错');
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
        
        Text(this.isEditing ? '编辑梦想' : '创建梦想')
          .fontSize(CommonConstants.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .margin({ left: CommonConstants.MARGIN_LARGE })
      }
      .width('100%')
      .height(56)
      .padding({ left: CommonConstants.MARGIN_LARGE, right: CommonConstants.MARGIN_LARGE })
      .alignItems(VerticalAlign.Center)
      
      // 加载状态
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .color($r('app.color.primary_color'))
            .width(50)
            .height(50)
          
          Text('加载中...')
            .fontSize(CommonConstants.FONT_SIZE_NORMAL)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: CommonConstants.MARGIN_NORMAL })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 表单内容
        Scroll() {
          Column() {
            // 错误提示
            if (this.errorMessage) {
              Text(this.errorMessage)
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.error'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .margin({ top: CommonConstants.MARGIN_NORMAL, bottom: CommonConstants.MARGIN_NORMAL })
                .backgroundColor($r('app.color.error_background'))
                .padding(CommonConstants.MARGIN_NORMAL)
                .borderRadius(CommonConstants.RADIUS_SMALL)
            }
            
            // 梦想标题
            Column() {
              Text('梦想标题')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: CommonConstants.MARGIN_SMALL })
              
              TextInput({ placeholder: '请输入梦想标题', text: this.dream.title })
                .width('100%')
                .height(48)
                .borderRadius(CommonConstants.RADIUS_NORMAL)
                .backgroundColor($r('app.color.input_background'))
                .padding(CommonConstants.MARGIN_NORMAL)
                .placeholderColor($r('app.color.text_placeholder'))
                .onChange((value: string) => {
                  this.dream.title = value;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ top: CommonConstants.MARGIN_LARGE })
            
            // 梦想封面图片 - 修改后的UI
            Column() {
              Text('封面图片')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: CommonConstants.MARGIN_SMALL, top: CommonConstants.MARGIN_LARGE })
              
              Row() {
                Image(this.dream.imageUrl)
                  .width(100)
                  .height(100)
                  .borderRadius(CommonConstants.RADIUS_NORMAL)
                  .objectFit(ImageFit.Cover)
                
                Column() {
                  Button('本地上传图片')
                    .margin({ left: CommonConstants.MARGIN_LARGE })
                    .backgroundColor($r('app.color.primary_color'))
                    .borderRadius(CommonConstants.RADIUS_NORMAL)
                    .enabled(!this.isUploadingImage)
                    .opacity(this.isUploadingImage ? 0.5 : 1)
                    .onClick(() => {
                      this.pickLocalImage();
                    })
                }
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              
              // 图片上传中显示进度
              if (this.isUploadingImage) {
                Row() {
                  LoadingProgress()
                    .color($r('app.color.primary_color'))
                    .width(24)
                    .height(24)
                  
                  Text('图片上传中...')
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ left: CommonConstants.MARGIN_SMALL })
                }
                .margin({ top: CommonConstants.MARGIN_NORMAL })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 梦想描述
            Column() {
              Text('梦想描述')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: CommonConstants.MARGIN_SMALL, top: CommonConstants.MARGIN_LARGE })
              
              TextArea({ placeholder: '请输入梦想详细描述', text: this.dream.description })
                .width('100%')
                .height(120)
                .borderRadius(CommonConstants.RADIUS_NORMAL)
                .backgroundColor($r('app.color.input_background'))
                .padding(CommonConstants.MARGIN_NORMAL)
                .placeholderColor($r('app.color.text_placeholder'))
                .onChange((value: string) => {
                  this.dream.description = value;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 分类选择
            Column() {
              Text('梦想分类')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: CommonConstants.MARGIN_SMALL, top: CommonConstants.MARGIN_LARGE })
              
              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                ForEach(this.categoryOptions, (category: string) => {
                  Text(category)
                    .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                    .fontColor(this.dream.category === category ? 
                      Color.White : $r('app.color.text_primary'))
                    .backgroundColor(this.dream.category === category ? 
                      $r('app.color.primary_color') : $r('app.color.category_background'))
                    .borderRadius(CommonConstants.RADIUS_NORMAL)
                    .padding({
                      left: CommonConstants.MARGIN_LARGE,
                      right: CommonConstants.MARGIN_LARGE,
                      top: CommonConstants.MARGIN_NORMAL,
                      bottom: CommonConstants.MARGIN_NORMAL
                    })
                    .margin({ right: CommonConstants.MARGIN_NORMAL, bottom: CommonConstants.MARGIN_NORMAL })
                    .onClick(() => {
                      this.dream.category = category;
                    })
                })
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 优先级选择
            Column() {
              Text('优先级')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: CommonConstants.MARGIN_SMALL, top: CommonConstants.MARGIN_LARGE })
              
              Row() {
                ForEach(this.priorityOptions, (priority: number, index: number) => {
                  Column() {
                    Text(`${priority}`)
                      .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                      .fontColor(this.dream.priority === priority ? 
                        Color.White : $r('app.color.text_primary'))
                      .backgroundColor(this.dream.priority === priority ? 
                        $r('app.color.primary_color') : $r('app.color.category_background'))
                      .borderRadius(CommonConstants.RADIUS_LARGE)
                      .width(36)
                      .height(36)
                      .textAlign(TextAlign.Center)
                      .margin({ bottom: CommonConstants.MARGIN_SMALL })
                    
                    Text(this.priorityLabels[index])
                      .fontSize(CommonConstants.FONT_SIZE_SMALL)
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .onClick(() => {
                    this.dream.priority = priority;
                  })
                  .margin({ right: CommonConstants.MARGIN_LARGE })
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 截止日期
            Column() {
              Text('截止日期')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: CommonConstants.MARGIN_SMALL, top: CommonConstants.MARGIN_LARGE })
              
              Row() {
                Text(this.dream.deadline)
                  .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                  .fontColor($r('app.color.text_primary'))
                
                Image(AppIcons.calendar)
                  .width(24)
                  .height(24)
                  .fillColor($r('app.color.text_primary'))
                  .margin({ left: CommonConstants.MARGIN_LARGE })
              }
              .width('100%')
              .height(48)
              .borderRadius(CommonConstants.RADIUS_NORMAL)
              .backgroundColor($r('app.color.input_background'))
              .padding(CommonConstants.MARGIN_NORMAL)
              .justifyContent(FlexAlign.SpaceBetween)
              .onClick(() => {
                this.handleDateSelect();
              })
              
              // 日期选择器
              if (this.showDatePicker) {
                Column() {
                  Text('选择截止日期')
                    .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: CommonConstants.MARGIN_NORMAL })
                  
                  // 使用文本选择器替代Select
                  TextPicker({
                    range: this.generateDateStrings(),
                    selected: 0,
                    value: this.dream.deadline
                  })
                    .onChange((value: string | string[], index: number | number[]) => {
                      // 确保value是字符串类型
                      const selectedValue = typeof value === 'string' ? value : (Array.isArray(value) && value.length > 0 ? value[0] : this.dream.deadline);
                      
                      this.dream.deadline = selectedValue;
                      const date = CustomDate.fromString(selectedValue);
                      if (date) {
                        this.selectedDate = date;
                      }
                    })
                    .width('100%')
                  
                  Button('确定')
                    .margin({ top: CommonConstants.MARGIN_NORMAL })
                    .onClick(() => {
                      this.showDatePicker = false;
                    })
                }
                .width('100%')
                .backgroundColor(Color.White)
                .borderRadius(CommonConstants.RADIUS_NORMAL)
                .padding(CommonConstants.MARGIN_LARGE)
                .margin({ top: CommonConstants.MARGIN_NORMAL })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 预计天数
            Column() {
              Text('预计完成天数')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: CommonConstants.MARGIN_SMALL, top: CommonConstants.MARGIN_LARGE })
              
              TextInput({ placeholder: '预计需要的天数', text: this.dream.expectedDays ? this.dream.expectedDays.toString() : '' })
                .width('100%')
                .height(48)
                .borderRadius(CommonConstants.RADIUS_NORMAL)
                .backgroundColor($r('app.color.input_background'))
                .padding(CommonConstants.MARGIN_NORMAL)
                .placeholderColor($r('app.color.text_placeholder'))
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.dream.expectedDays = parseInt(value) || 0;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 是否公开
            Column() {
              Text('是否公开')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: CommonConstants.MARGIN_SMALL, top: CommonConstants.MARGIN_LARGE })
              
              Row() {
                Text('公开此梦想')
                  .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                  .fontColor($r('app.color.text_primary'))
                
                Toggle({ type: ToggleType.Switch, isOn: this.dream.isPublic === 1 })
                  .onChange((isOn: boolean) => {
                    this.dream.isPublic = isOn ? 1 : 0;
                  })
              }
              .width('100%')
              .height(48)
              .borderRadius(CommonConstants.RADIUS_NORMAL)
              .backgroundColor($r('app.color.input_background'))
              .padding(CommonConstants.MARGIN_NORMAL)
              .justifyContent(FlexAlign.SpaceBetween)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            
            // 提交按钮
            Button(this.isEditing ? '保存修改' : '创建梦想')
              .width('100%')
              .height(50)
              .backgroundColor($r('app.color.primary_color'))
              .borderRadius(CommonConstants.RADIUS_NORMAL)
              .fontSize(CommonConstants.FONT_SIZE_NORMAL)
              .fontWeight(FontWeight.Bold)
              .margin({ top: CommonConstants.MARGIN_XLARGE, bottom: CommonConstants.MARGIN_XLARGE })
              .onClick(() => {
                this.submitForm();
              })
              .enabled(!this.isSubmitting)
              .opacity(this.isSubmitting ? 0.5 : 1)
          }
          .width('100%')
          .padding({ left: CommonConstants.MARGIN_LARGE, right: CommonConstants.MARGIN_LARGE })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
} 