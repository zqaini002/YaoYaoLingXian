import util from '@ohos.util';
import router from '@ohos.router';
import * as ApiService from '../../services/ApiService';
import { processImageUrl } from '../../services/ApiService'; // 导入processImageUrl函数
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
import request from '@ohos.request';
import fileIo from '@ohos.fileio';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import UIAbility from '@ohos.app.ability.UIAbility';
import featureAbility from '@ohos.ability.featureAbility'
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { UploadImageParams, deleteDream } from '../../services/ApiService';
import { UserSession } from '../../utils/auth/UserSession';

import type { UIContext } from '@kit.ArkUI';
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

// 上传图片数据接口
interface UploadImageData {
  base64Image: string;
  fileName: string;
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

// 自定义表单数据类型
interface ImageFormData {
  name: string;
  filename: string;
  contentType: string;
  uri: string;
}

// 自定义表单数据项
interface FormDataItem {
  name: string;
  value: string | ArrayBuffer | string[];
  filename?: string;
  contentType?: string;
}

// HTTP请求配置
interface HttpRequestOptions {
  method: http.RequestMethod;
  header?: Record<string, string>;
  connectTimeout?: number;
  readTimeout?: number;
  expectDataType?: http.HttpDataType;
  extraData?: string | Object | ArrayBuffer | FormDataItem[];
  usingCache?: boolean;
}

// 文件表单选项
interface FileOptions {
  filename: string;
  contentType: string;
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

// 请求配置类型
interface UploadConfig {
  url: string;
  header: Record<string, string>;
  method: string;
  files: Array<UploadFile>;
  data: Array<UploadFormData>;
}

// 上传文件类型
interface UploadFile {
  filename: string;
  name: string;
  uri: string;
  type: string;
}

// 上传表单数据类型
interface UploadFormData {
  name: string;
  value: string;
}

// 修改错误信息提取函数
function getErrorMessage(error: Object | string | null | undefined): string {
  let errorMessage = '未知错误';
  if (error === null || error === undefined) {
    return errorMessage;
  }
  
  if (typeof error === 'string') {
    return error;
  }
  
  if (typeof error === 'object') {
    // 检查是否有message属性，不使用in操作符
    const errorObj = error as Record<string, string>;
    if (errorObj.message !== undefined) {
      return String(errorObj.message);
    }
  }
  
  return String(error);
}

// 定义文件上传参数接口
interface UploadFileOption {
  filename: string;
  name: string;
  uri: string;
  contentType: string;
}

// 定义上传响应接口
interface UploadResponse {
  code: number;
  message: string;
  data?: UploadResponseData;
}

// 上传响应数据接口
interface UploadResponseData {
  url?: string;
  filename?: string;
}

interface FetchOptions {
  fetchColumns: Array<string>;
  predicates: dataSharePredicates.DataSharePredicates;
}

// 添加RequestOptions接口定义
interface RequestOptions {
  deliveryMode: number;  // 使用number替代枚举类型
}

// 添加MediaAssetDataHandler接口定义
interface MediaAssetDataHandlerInterface<T> {
  onDataPrepared(data: T): void;
}

@Entry
@Component
export struct DreamEditPage {
  @State dream: Dream = {
    id: 0,
    userId: 0, // 修改为0，从用户会话中获取
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
  
  private userSession: UserSession = UserSession.getInstance();
  
  aboutToAppear() {
    try {
      // 从用户会话获取用户ID
      if (this.userSession && this.userSession.isLoggedIn()) {
        const userInfo = this.userSession.getCurrentUser();
        if (userInfo && userInfo.id) {
          this.dream.userId = userInfo.id;
          console.info(`DreamEditPage: 从用户会话获取到用户ID ${this.dream.userId}`);
        } else {
          console.error('DreamEditPage: 用户已登录但无法获取用户ID');
          const toastOpts: ToastOptions = { message: '获取用户信息失败，请重新登录' };
          promptAction.showToast(toastOpts);
        }
      } else {
        console.error('DreamEditPage: 用户未登录或会话未初始化');
        const toastOpts: ToastOptions = { message: '用户未登录，请先登录' };
        promptAction.showToast(toastOpts);
        // 跳转到登录页面
        router.replaceUrl({
          url: 'pages/auth/LoginPage'
        });
        return;
      }
      
      // 初始化默认图片 - 设置一个固定的占位图URL
      if (!this.dream.imageUrl || this.dream.imageUrl.trim() === '') {
        this.dream.imageUrl = 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d'; // 使用占位图
      } else {
        // 确保已有的图片URL被正确处理
        this.dream.imageUrl = processImageUrl(this.dream.imageUrl);
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
      // 提取错误信息
      let errorMessage = '';
      if (error) {
        if (typeof error === 'object' && error.message) {
          errorMessage = String(error.message);
        } else {
          errorMessage = String(error);
        }
      }
      
      console.error(`初始化页面出错: ${errorMessage}`);
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
      const dreamDetail: Dream = await ApiService.getDreamById(dreamId);
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
      // 提取错误信息
      let errorMessage = '';
      if (error instanceof Error) {
        errorMessage = error.message;
      } else if (error !== null && error !== undefined) {
        errorMessage = String(error);
      }
      
      console.error(`获取梦想详情失败: ${errorMessage}`);
      this.errorMessage = `获取梦想详情失败: ${errorMessage}`;
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
        // 提取错误信息
        let errorMsg = '';
        if (error) {
          if (typeof error === 'object' && error.message) {
            errorMsg = String(error.message);
          } else {
            errorMsg = String(error);
          }
        }
        
        console.error('API错误：', errorMsg);
        
        // 解析错误信息，默认为服务器处理请求时出错
        errorMsg = '服务器处理请求时出错';
        
        // 检查是否包含特定的错误信息
        if (error) {
          const errorText = typeof error === 'object' && error.message ? 
            String(error.message) : String(error);
          
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
      // 提取错误信息
      let errorMessage = '';
      if (error) {
        if (typeof error === 'object' && error.message) {
          errorMessage = String(error.message);
        } else {
          errorMessage = String(error);
        }
      }
      
      console.error('提交梦想表单失败：', errorMessage);
      this.errorMessage = errorMessage;
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
      // 提取错误信息
      let errorMessage = '';
      if (error) {
        if (typeof error === 'object' && error.message) {
          errorMessage = String(error.message);
        } else {
          errorMessage = String(error);
        }
      }
      
      console.error(`显示日期选择器失败: ${errorMessage}`);
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
      
      try {
        // 使用await替代Promise链
        const photos = await photoPicker.select(photoSelectOptions);
        
          if (photos && photos.photoUris && photos.photoUris.length > 0) {
            this.selectedLocalImage = photos.photoUris[0];
          console.info(`选择的图片URI: ${this.selectedLocalImage}`);
          
          // 保持原始完整路径，包括file://前缀
          // 鸿蒙OS需要完整URI来访问媒体文件
          let filePath = this.selectedLocalImage;
          console.info(`使用完整的文件URI: ${filePath}`);
          
          // 使用完整URI路径
          this.uploadImage(filePath);
        }
      } catch (err) {
        console.error('选择图片失败', err);
        const toastOpts: ToastOptions = { message: '选择图片失败' };
        promptAction.showToast(toastOpts);
      }
    } catch (err) {
      // 处理选择器创建过程中的错误
      console.error('选择图片器错误', err);
      const toastOpts: ToastOptions = { message: '选择图片时出错' };
      promptAction.showToast(toastOpts);
    }
  }
  
  // 上传图片到服务器
  async uploadImage(imageUri: string): Promise<string | null> {
    try {
      this.isUploadingImage = true;
      const toastOpts: ToastOptions = { message: '开始上传图片...' };
      promptAction.showToast(toastOpts);
      console.info(`准备上传图片: ${imageUri}`);
      
      // 检查URI格式
      if (!imageUri.startsWith('file://')) {
        console.error('无效的文件URI格式，必须以file://开头');
        const toastOpts: ToastOptions = { message: '无效的文件路径' };
        promptAction.showToast(toastOpts);
        this.isUploadingImage = false;
        return null;
      }
      
      try {
        // 使用convertImageToBase64方法处理图片
        let base64String = await this.convertImageToBase64(imageUri);
        if (base64String) {
          console.info('图片转Base64成功，长度: ' + base64String.length);
          
          // 上传Base64字符串到服务器
          try {
            // 修改类型定义，使用与ApiService一致的接口名
            const uploadData: UploadImageParams = {
              base64Image: base64String,
              fileName: imageUri.substring(imageUri.lastIndexOf('/') + 1)
            };
            
            // 调用API上传图片
            const response = await ApiService.uploadImage(uploadData);
            console.info('图片上传成功，服务器返回数据：', JSON.stringify(response));
            
            // 更新梦想对象的imageUrl
            if (response && response.url) {
              this.dream.imageUrl = response.url;
              const toastOpts: ToastOptions = { message: '图片上传成功！' };
              promptAction.showToast(toastOpts);
            } else {
              console.error('服务器返回的图片URL为空');
              const toastOpts: ToastOptions = { message: '图片上传失败：服务器返回的URL为空' };
              promptAction.showToast(toastOpts);
            }
          } catch (error) {
            console.error('图片上传到服务器失败:', error);
            const toastOpts: ToastOptions = { message: '图片上传到服务器失败' };
            promptAction.showToast(toastOpts);
          }
          
          // 返回Base64字符串，方便后续处理
          return base64String;
        } else {
          console.error('图片转Base64失败');
          const toastOpts: ToastOptions = { message: '图片转Base64失败' };
          promptAction.showToast(toastOpts);
          return null;
        }
      } catch (error) {
        console.error('读取文件内容失败', error);
        const toastOpts: ToastOptions = { message: '读取文件内容失败' };
        promptAction.showToast(toastOpts);
        return null;
      }
    } catch (error) {
      console.error('上传图片过程中出错', error);
      
      // 提取错误信息
      const errorMessage = getErrorMessage(error);
      
      const toastOpts: ToastOptions = { message: `上传过程中出错: ${errorMessage}` };
      promptAction.showToast(toastOpts);
      return null;
    } finally {
      // 无论成功失败，最终都要重置上传状态
      this.isUploadingImage = false;
    }
  }
  
  // 将图片转换为Base64
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
        } catch (error) {
          console.error('直接文件路径读取失败，尝试使用photoAccessHelper', error);
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
      
      // 异步返回Promise
      return new Promise<string | null>((resolve, reject) => {
        // 定义数据处理器
        class MediaDataHandler implements MediaAssetDataHandlerInterface<ArrayBuffer> {
          onDataPrepared(data: ArrayBuffer): void {
            if (data === undefined) {
              console.error('获取图片数据失败');
              resolve(null);
              return;
            }
            
            try {
              // 转换为Base64
              const uint8Array = new Uint8Array(data);
              const base64Helper: util.Base64Helper = new util.Base64Helper();
              const base64 = base64Helper.encodeToStringSync(uint8Array);
              resolve(base64);
            } catch (error) {
              console.error('Base64转换失败:', error);
              resolve(null);
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
                    resolve(null);
                  });
              } else {
                console.error('未找到图片资源');
                resolve(null);
              }
            } else {
              console.error('未找到匹配的图片资源');
              resolve(null);
            }
          })
          .catch((error: Error) => {
            console.error('获取资源失败:', error);
            resolve(null);
          });
      });
    } catch (error) {
      console.error('图片处理过程中发生错误:', error);
      return null;
    }
  }
  
  // 从URI中获取文件ID - 修正正则表达式以正确提取ID
  private getFileIdFromUri(uri: string): string | null {
    try {
      // 匹配形如 file://media/Photo/1/IMG_1747504493_000/xxx.png 的URI
      const regex = /file:\/\/media\/Photo\/(\d+)\/([^\/]+)/;
      const match = uri.match(regex);
      if (match && match.length >= 2) {
        return match[1]; // 返回ID部分 (1)
      }
      return null;
    } catch (error) {
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      console.error(`解析URI失败: ${errorMsg}`);
      return null;
    }
  }
  
  // ArrayBuffer转Base64工具函数
  private arrayBufferToBase64(buffer: Uint8Array): string {
    // 创建Base64Helper实例后再调用方法
    const base64Helper: util.Base64Helper = new util.Base64Helper();
    return base64Helper.encodeToStringSync(buffer);
  }

  /**
   * 删除当前梦想
   */
  private deleteDreamItem() {
    if (!this.dream.id) {
      console.error('无法删除梦想：梦想ID不存在');
      const toastOpts: ToastOptions = { message: '无法删除梦想' };
      promptAction.showToast(toastOpts);
      return;
    }

    promptAction_1.showDialog({
      title: '确认删除',
      message: '确定要删除这个梦想吗？删除后将无法恢复。',
      buttons: [
        {
          text: '取消',
          color: CommonConstants.COLOR_TEXT_SECONDARY
        },
        {
          text: '删除',
          color: '#FF0000'
        }
      ]
    })
    .then((result) => {
      if (result.index === 1) { // 用户点击了"删除"按钮
        this.isLoading = true;
        // 类型安全：确保id是number类型
        const dreamId: number = this.dream.id || 0; // 使用空值合并
        deleteDream(dreamId)
          .then(() => {
            const toastOpts: ToastOptions = { message: '梦想已成功删除' };
            promptAction.showToast(toastOpts);
            // 返回上一页
            router.back();
          })
          .catch((err: Error | string | Object) => {
            const errorMsg = err instanceof Error ? err.message : String(err);
            console.error(`删除梦想失败: ${errorMsg}`);
            const toastOpts: ToastOptions = { message: `删除失败: ${errorMsg}` };
            promptAction.showToast(toastOpts);
          })
          .finally(() => {
            this.isLoading = false;
          });
      }
    })
    .catch((err: Error | string | Object) => {
      console.error(`显示对话框失败: ${err}`);
    });
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
                Image(processImageUrl(this.dream.imageUrl))
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
            Row() {
              // 保存/创建按钮
              Button() {
                Text(this.isEditing ? '保存修改' : '创建梦想')
                  .fontSize(16)
                  .fontColor('#FFFFFF')
              }
              .width(this.dream.id ? '45%' : '100%')
              .height(50)
              .backgroundColor(this.isSubmitting ? '#999999' : '#2196F3')
              .borderRadius(8)
              .enabled(!this.isSubmitting)
              .opacity(this.isSubmitting ? 0.5 : 1)
              .onClick(() => this.submitForm())
              
              if (this.dream.id) {
                // 间隔
                Divider()
                  .width(16)
                  .color('#00000000')
                
                // 删除按钮
                Button() {
                  Text('删除梦想')
                    .fontSize(16)
                    .fontColor('#FFFFFF')
                }
                .width('45%')
                .height(50)
                .backgroundColor('#FF4757')
                .borderRadius(8)
                .enabled(!this.isSubmitting)
                .onClick(() => this.deleteDreamItem())
              }
            }
            .width('100%')
            .justifyContent(this.dream.id ? FlexAlign.SpaceBetween : FlexAlign.Center)
            .margin({ top: 24, bottom: 24 })
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