/**
 * API服务类，用于封装对后端接口的调用
 */

import http from '@ohos.net.http';
import { RequestMethod, ApiResponse, PageResponse, Dream, Task, DreamStats, QueryParams, HomePageData, RequestParams, Post, Comment, LoginParams, RegisterParams, AuthResponse, UserInfo } from '../model/CommonTypes';

/**
 * 帖子API数据结构
 */
interface PostApiData {
  totalItems: number;
  totalPages: number;
  currentPage: number;
  posts: Post[];
}

/**
 * 帖子API专用响应格式
 */
interface PostApiResponse {
  code: number;
  message: string;
  data: PostApiData;
}

// API基础URL配置类型
class ApiConfig {
  // Android模拟器环境
  readonly ANDROID_EMULATOR: string = 'http://10.0.2.2:8080/api';
  // 真机环境，通过IP直接访问
  readonly DEVICE: string = 'http://192.168.31.75:8080/api';
  // 本地环境
  readonly LOCAL: string = 'http://localhost:8080/api';
  
  // 获取当前环境的URL
  getUrl(env: string): string {
    switch (env) {
      case 'ANDROID_EMULATOR':
        return this.ANDROID_EMULATOR;
      case 'DEVICE':
        return this.DEVICE;
      case 'LOCAL':
      default:
        return this.LOCAL;
    }
  }
}

// 创建API配置实例
const apiConfig = new ApiConfig();

// 当前使用的环境
// 根据实际开发环境修改，可选值: LOCAL, DEVICE, ANDROID_EMULATOR
const CURRENT_ENV = 'ANDROID_EMULATOR'; // 修改为当前开发环境
export const BASE_URL = apiConfig.getUrl(CURRENT_ENV);
console.info(`当前API环境: ${CURRENT_ENV}, 基础URL: ${BASE_URL}`);

/**
 * 处理图片URL，转换为当前环境可访问的URL
 * 
 * @param url 后端返回的URL
 * @returns 处理后可访问的URL
 */
export function processImageUrl(url: string): string {
  if (!url) return '';
  
  // 如果是相对路径（不包含http或https），则添加BASE_URL
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    return `${BASE_URL}/${url}`;
  }
  
  // 如果包含localhost，替换为当前环境URL
  if (url.includes('localhost')) {
    // 提取相对路径
    const urlParts = url.split('/api/');
    if (urlParts.length > 1) {
      return `${BASE_URL}/${urlParts[1]}`;
    }
  }
  
  return url;
}

// 请求超时时间
export const TIMEOUT = 30000; // 增加超时时间到30秒

// 状态码
enum StatusCode {
  SUCCESS = 200,
  CREATED = 201,
  NO_CONTENT = 204,
  BAD_REQUEST = 400,
  UNAUTHORIZED = 401,
  FORBIDDEN = 403,
  NOT_FOUND = 404,
  SERVER_ERROR = 500
}

/**
 * HTTP请求头接口
 */
export type HttpHeader = Record<string, string>;

/**
 * HTTP请求选项接口
 */
interface RequestOptions {
  method: http.RequestMethod;
  readTimeout: number;
  connectTimeout: number;
  extraData?: string | ArrayBuffer;
  header: Record<string, string>;
}

/**
 * 请求数据类型，支持各种基本类型的键值对
 */
export interface RequestData {
  // 基本信息字段
  id?: number;
  userId?: number;
  title?: string;
  description?: string;
  category?: string;
  content?: string;
  
  // 状态字段
  priority?: number;
  status?: number;
  type?: number;
  completionRate?: number;
  
  // 时间相关字段
  deadline?: string;
  createdAt?: string;
  updatedAt?: string;
  expectedDays?: number;
  
  // 其他属性
  imageUrl?: string;
  isPublic?: number;
  
  // 图片上传相关
  base64Image?: string;
  fileName?: string;
  fileContent?: string; // 文件Base64内容
  file?: string; // 文件路径或名称
  
  // 扩展字段，用于其他API
  dreamId?: number;
  taskId?: number;
  postId?: number;
  parentId?: number;
  keyword?: string;
  page?: number;
  size?: number;
  pageSize?: number;
  days?: number;
  tags?: string[];
  // 图片数组
  images?: string[];
  imageUrls?: string[];
  
  // 用户认证相关字段
  username?: string;
  password?: string;
  nickname?: string;
  email?: string;
  phone?: string;
}

/**
 * 任务查询参数接口
 */
interface TaskQueryParams extends QueryParams {
  page: number;
  size: number;
  days?: number;
}

/**
 * 空查询参数对象
 */
export const EmptyParams: QueryParams = {};

/**
 * 搜索查询参数
 */
export interface SearchParams extends QueryParams {
  userId: number;
  keyword: string;
}

/**
 * 发送HTTP请求的通用方法
 * 
 * @param method HTTP方法
 * @param endpoint API端点
 * @param params 请求参数
 * @param data 请求体数据
 * @returns 响应数据
 */
export async function request<T>(method: RequestMethod, endpoint: string, params: QueryParams = {}, data: RequestData = {}): Promise<T> {
  // 构建URL
  let url = `${BASE_URL}${endpoint}`;

  // 处理查询参数
  if (Object.keys(params).length > 0) {
    const queryParts: string[] = [];
    for (const key of Object.keys(params)) {
      const value = params[key];
      if (value !== undefined && value !== null) {
        queryParts.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`);
      }
    }
    if (queryParts.length > 0) {
      url += '?' + queryParts.join('&');
    }
  }

  // 创建HTTP请求
  const httpRequest = http.createHttp();
  
  try {
    console.info(`发送请求: ${method} ${url}`);
    
    // 配置请求选项
    const headers: HttpHeader = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    
    const options: RequestOptions = {
      method: method,
      readTimeout: TIMEOUT,
      connectTimeout: TIMEOUT,
      extraData: method !== RequestMethod.GET ? JSON.stringify(data) : undefined,
      header: headers
    };

    // 发送请求
    const response = await httpRequest.request(url, options);
    console.info(`收到响应: 状态码=${response.responseCode}, 结果类型=${typeof response.result}`);
    
    // 检查响应状态
    if (response.responseCode >= 200 && response.responseCode < 300) {
      // 解析响应数据
      if (response.responseCode === StatusCode.NO_CONTENT) {
        console.info('响应无内容');
        return null as T;
      }
      
      if (typeof response.result === 'string') {
        console.info(`解析字符串响应: ${response.result.substring(0, 100)}...`);
        return JSON.parse(response.result) as T;
      }
      
      // 使用标准的方式将 ArrayBuffer 转换为字符串
      if (response.result instanceof ArrayBuffer) {
        console.info('解析ArrayBuffer响应');
        const uint8Array = new Uint8Array(response.result);
        let resultStr = '';
        for (let i = 0; i < uint8Array.length; i++) {
          resultStr += String.fromCharCode(uint8Array[i]);
        }
        return JSON.parse(resultStr) as T;
      }
      
      // 处理其他情况
      console.info('解析其他类型响应');
      const resultObj = response.result as Object;
      return resultObj as T;
    } else {
      // 处理错误响应
      const errorMsg = `请求失败，状态码: ${response.responseCode}`;
      console.error(errorMsg);
      throw new Error(errorMsg);
    }
  } catch (error) {
    const errorMsg = `API请求错误: ${(error as Error).message}`;
    console.error(errorMsg);
    throw new Error(errorMsg);
  } finally {
    // 释放请求资源
    httpRequest.destroy();
  }
}

/**
 * 获取首页数据
 * 
 * @param userId 用户ID
 * @returns 首页数据 - 返回HomePageData类型
 */
export function getHomePageData(userId: number): Promise<HomePageData> {
  console.info(`正在请求首页数据，userId: ${userId}`);
  try {
    return request<HomePageData>(RequestMethod.GET, `/home/${userId}`);
  } catch (error) {
    console.error(`获取首页数据失败: ${(error instanceof Error ? error.message : String(error))}`);
    throw new Error(`获取首页数据失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 获取用户梦想统计数据
 * 
 * @param userId 用户ID
 * @returns 梦想统计数据
 */
export function getDreamStats(userId: number): Promise<DreamStats> {
  try {
    // 从后端API获取数据，API返回的是ApiResponse<DreamStats>格式
    return request<ApiResponse<DreamStats>>(RequestMethod.GET, `/dreams/user/${userId}/stats`)
      .then(response => {
        // 处理ApiResponse，提取data字段并返回
        if (response && response.data) {
          console.info(`成功获取梦想统计: ${JSON.stringify(response.data)}`);
          return response.data;
        }
        // 如果响应没有data字段，抛出错误
        throw new Error('获取梦想统计数据失败: 响应格式错误');
      });
  } catch (error) {
    console.error(`获取梦想统计数据失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取梦想统计数据失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 获取用户今日任务列表
 * 
 * @param userId 用户ID
 * @param page 页码
 * @param size 每页大小
 * @returns 今日任务列表
 */
export function getTodayTasks(userId: number, page: number = 0, size: number = 5): Promise<PageResponse<Task>> {
  const params: RequestData = { page, size };
  try {
    return request<PageResponse<Task>>(
    RequestMethod.GET, 
    `/tasks/user/${userId}/today`, 
      params as QueryParams
  );
  } catch (error) {
    console.error(`获取今日任务列表失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取今日任务列表失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 获取用户即将到期的任务列表
 * 
 * @param userId 用户ID
 * @param days 天数
 * @param page 页码
 * @param size 每页大小
 * @returns 即将到期的任务列表
 */
export function getUpcomingTasks(userId: number, days: number = 7, page: number = 0, size: number = 5): Promise<PageResponse<Task>> {
  const params: RequestData = { days, page, size };
  try {
    return request<PageResponse<Task>>(
    RequestMethod.GET, 
    `/tasks/user/${userId}/upcoming`, 
      params as QueryParams
  );
  } catch (error) {
    console.error(`获取即将到期任务列表失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取即将到期任务列表失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 获取用户所有梦想列表
 * 
 * @param userId 用户ID
 * @returns 梦想列表
 */
export function getDreamsByUserId(userId: number): Promise<Dream[]> {
  try {
    return request<Dream[]>(RequestMethod.GET, `/dreams/user/${userId}`);
  } catch (error) {
    console.error(`获取用户梦想列表失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取用户梦想列表失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 获取用户特定状态的梦想列表
 * 
 * @param userId 用户ID
 * @param status 状态
 * @returns 梦想列表
 */
export function getDreamsByStatus(userId: number, status: number): Promise<ApiResponse<Dream[]>> {
  return request<ApiResponse<Dream[]>>(RequestMethod.GET, `/dreams/user/${userId}/status/${status}`);
}

/**
 * 更新任务状态
 * 
 * @param taskId 任务ID
 * @param status 新状态
 * @returns 更新后的任务
 */
export function updateTaskStatus(taskId: number, status: number): Promise<Task> {
  try {
    return request<Task>(RequestMethod.PUT, `/tasks/${taskId}/status/${status}`);
  } catch (error) {
    console.error(`更新任务状态失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`更新任务状态失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 获取用户特定分类的梦想列表
 * 
 * @param userId 用户ID
 * @param category 分类名称
 * @returns 梦想列表
 */
export function getDreamsByUserIdAndCategory(userId: number, category: string): Promise<Dream[]> {
  try {
    return request<Dream[]>(RequestMethod.GET, `/dreams/user/${userId}/category/${category}`);
  } catch (error) {
    console.error(`获取用户${category}分类梦想列表失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取用户${category}分类梦想列表失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 搜索用户的梦想
 * 
 * @param userId 用户ID
 * @param keyword 搜索关键词
 * @returns 梦想列表分页
 */
export function searchDreams(userId: number, keyword: string): Promise<PageResponse<Dream>> {
  try {
    const params: RequestData = { userId, keyword };
    return request<PageResponse<Dream>>(RequestMethod.GET, `/dreams/search`, params as QueryParams);
  } catch (error) {
    console.error(`搜索梦想失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`搜索梦想失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 创建新梦想
 * 
 * @param dream 梦想数据
 * @returns 创建的梦想
 */
export function createDream(dream: Dream): Promise<Dream> {
  console.info(`开始创建梦想: ${dream.title}`);
  try {
    // 转换为符合请求数据类型的对象
    const requestData: RequestData = {
      userId: dream.userId,
      title: dream.title,
      description: dream.description,
      category: dream.category,
      priority: dream.priority,
      status: dream.status,
      completionRate: dream.completionRate,
      deadline: dream.deadline,
      imageUrl: dream.imageUrl,
      isPublic: dream.isPublic,
      expectedDays: dream.expectedDays,
      // 确保后端不会因为tags为null而崩溃
      tags: dream.tags || []
    };
    
    console.info(`请求数据: ${JSON.stringify(requestData)}`);
    return request<Dream>(RequestMethod.POST, `/dreams`, EmptyParams, requestData)
      .then(newDream => {
        // 处理图片URL
        if (newDream && newDream.imageUrl) {
          newDream.imageUrl = processImageUrl(newDream.imageUrl);
        }
        return newDream;
      });
  } catch (error) {
    const errorMsg = `创建梦想失败: ${error instanceof Error ? error.message : String(error)}`;
    console.error(errorMsg);
    console.error(`梦想数据: ${JSON.stringify(dream)}`); // 记录失败时的梦想数据
    
    // 检查是否是后端dreamTags相关错误
    const errorString = String(error);
    if (errorString.includes('NullPointerException') || 
        errorString.includes('dreamTags') || 
        errorString.includes('stream()')) {
      throw new Error(`服务器处理标签时出错 (dreamTags为null): ${errorString}`);
    }
    
    throw new Error(errorMsg);
  }
}

/**
 * 更新梦想
 * 
 * @param id 梦想ID
 * @param dream 梦想数据
 * @returns 更新后的梦想
 */
export function updateDream(id: number, dream: Dream): Promise<Dream> {
  console.info(`开始更新梦想: ${dream.title}`);
  try {
    // 转换为符合请求数据类型的对象
    const requestData: RequestData = {
      userId: dream.userId,
      title: dream.title,
      description: dream.description,
      category: dream.category,
      priority: dream.priority,
      status: dream.status,
      completionRate: dream.completionRate,
      deadline: dream.deadline,
      imageUrl: dream.imageUrl,
      isPublic: dream.isPublic,
      expectedDays: dream.expectedDays,
      // 确保后端不会因为tags为null而崩溃
      tags: dream.tags || []
    };
    
    console.info(`请求数据: ${JSON.stringify(requestData)}`);
    return request<Dream>(RequestMethod.PUT, `/dreams/${id}`, EmptyParams, requestData)
      .then(updatedDream => {
        // 处理图片URL
        if (updatedDream && updatedDream.imageUrl) {
          updatedDream.imageUrl = processImageUrl(updatedDream.imageUrl);
        }
        return updatedDream;
      });
  } catch (error) {
    const errorMsg = `更新梦想失败: ${error instanceof Error ? error.message : String(error)}`;
    console.error(errorMsg);
    console.error(`梦想数据: ${JSON.stringify(dream)}`); // 记录失败时的梦想数据
    
    // 检查是否是后端dreamTags相关错误
    const errorString = String(error);
    if (errorString.includes('NullPointerException') || 
        errorString.includes('dreamTags') || 
        errorString.includes('stream()')) {
      throw new Error(`服务器处理标签时出错 (dreamTags为null): ${errorString}`);
    }
    
    throw new Error(errorMsg);
  }
}

/**
 * 上传图片（Base64格式）
 * 
 * @param data 包含Base64图片数据和文件名的对象
 * @returns 上传后的图片URL和文件名
 */
export interface UploadImageParams {
  base64Image: string;
  fileName: string;
}

interface UploadImageResponse {
  url: string;
  filename: string;
}

export async function uploadImage(data: UploadImageParams): Promise<UploadImageResponse> {
  try {
    console.info('准备上传图片，文件名：', data.fileName);
    
    // 构建图片上传请求数据
    const requestData: RequestData = {
      fileContent: data.base64Image, // 使用fileContent字段名替代base64Image
      file: data.fileName, // 添加file字段，后端需要这个字段
      fileName: data.fileName // 保留fileName字段
    };
    
    // 调用API上传图片
    const response = await request<ApiResponse<UploadImageResponse>>(
      RequestMethod.POST,
      '/files/upload',
      {},
      requestData
    );
    
    console.info('图片上传成功，服务器返回：', JSON.stringify({url: response.data.url, filename: response.data.filename}));
    
    // 处理图片URL，确保能在当前环境正确访问
    const processedUrl = processImageUrl(response.data.url);
    console.info('处理后的图片URL:', processedUrl);
    
    return {
      url: processedUrl, // 返回处理后的URL
      filename: response.data.filename
    };
  } catch (error) {
    console.error('图片上传失败：', error);
    throw new Error(error instanceof Error ? error.message : String(error));
  }
}

/**
 * 获取梦想详情
 * 
 * @param id 梦想ID
 * @returns 梦想详情
 */
export function getDreamById(id: number): Promise<Dream> {
  console.info(`开始获取梦想详情, ID: ${id}`);
  try {
    return request<Dream>(RequestMethod.GET, `/dreams/${id}`)
      .then(dreamDetail => {
        // 处理图片URL
        if (dreamDetail && dreamDetail.imageUrl) {
          dreamDetail.imageUrl = processImageUrl(dreamDetail.imageUrl);
          console.info(`梦想图片URL处理后: ${dreamDetail.imageUrl}`);
        }
        return dreamDetail;
      });
  } catch (error) {
    const errorMsg = `获取梦想详情失败: ${error instanceof Error ? error.message : String(error)}`;
    console.error(errorMsg);
    console.error(`梦想ID: ${id}`);
    throw new Error(errorMsg);
  }
}

/**
 * 获取梦想下的任务列表
 * 
 * @param dreamId 梦想ID
 * @returns 任务列表
 */
export function getTasksByDreamId(dreamId: number): Promise<Task[]> {
  try {
    console.info(`获取梦想任务列表, dreamId: ${dreamId}`);
    return request<Task[]>(RequestMethod.GET, `/tasks/dream/${dreamId}`);
  } catch (error) {
    const errorMsg = `获取梦想任务列表失败: ${error instanceof Error ? error.message : String(error)}`;
    console.error(errorMsg);
    throw new Error(errorMsg);
  }
}

/**
 * 获取社区动态列表
 * 
 * @param page 页码
 * @param size 每页大小
 * @param type 动态类型: 0-推荐, 1-关注, 2-热门
 * @returns 动态列表分页数据
 */
export function getPosts(page: number, size: number, type: number): Promise<PageResponse<Post>> {
  try {
    console.info(`获取社区动态, page: ${page}, size: ${size}, type: ${type}`);
    
    // 根据type映射到category参数
    let category: string;
    switch(type) {
      case 0: 
        category = "recommendation"; // 推荐
        break;
      case 1:
        category = "following"; // 关注
        break;
      case 2:
        category = "hot"; // 热门
        break;
      default:
        category = "recommendation";
    }
    
    const params: RequestData = {
      page,
      pageSize: size, // 改用pageSize参数名
      category // 使用category参数替代type
    };
    
    return request<PostApiResponse>(RequestMethod.GET, '/posts', params as QueryParams)
      .then((apiResponse) => {
        console.info(`收到社区动态响应`);
        
        // 检查API响应是否有效
        if (!apiResponse || !apiResponse.data || !apiResponse.data.posts) {
          console.error('无效的API响应格式');
          const emptyResponse: PageResponse<Post> = {
            content: [],
            totalElements: 0,
            totalPages: 0,
            size: size,
            number: page,
            first: true,
            last: true
          };
          return emptyResponse;
        }
        
        // 将API响应转换为PageResponse格式
        const pageResponse: PageResponse<Post> = {
          content: apiResponse.data.posts || [],
          totalElements: apiResponse.data.totalItems || 0,
          totalPages: apiResponse.data.totalPages || 0,
          size: size,
          number: apiResponse.data.currentPage || 0,
          first: (apiResponse.data.currentPage || 0) === 0,
          last: (apiResponse.data.currentPage || 0) >= (apiResponse.data.totalPages || 1) - 1
        };
        
        // 处理数据，确保posts数组中的每个元素都有imageUrls字段
        if (pageResponse.content) {
          pageResponse.content.forEach(post => {
            // 确保每个post对象都有imageUrls属性
            if (!post.imageUrls) {
              post.imageUrls = [];
            }
            
            // 将后端返回的images字符串转换为前端需要的imageUrls数组
            if (post.images && typeof post.images === 'string' && post.images.trim() !== '') {
              post.imageUrls = post.images.split(',').filter(url => url && url.trim() !== '');
            }
          });
        }
        
        console.info(`社区动态数据处理完成，共${pageResponse.content.length}条记录`);
        return pageResponse;
      });
  } catch (error) {
    console.error(`获取社区动态失败: ${error instanceof Error ? error.message : String(error)}`);
    // 返回一个空的但结构完整的响应，避免UI崩溃
    const emptyResponse: PageResponse<Post> = {
      content: [],
      totalElements: 0,
      totalPages: 0,
      size: size,
      number: page,
      first: true,
      last: true
    };
    return Promise.resolve(emptyResponse);
  }
}

/**
 * 点赞动态
 * 
 * @param id 动态ID
 */
export function likePost(id: number): Promise<void> {
  try {
    console.info(`点赞动态, id: ${id}`);
    return request<void>(RequestMethod.POST, `/posts/${id}/like`);
  } catch (error) {
    const errorMsg = `点赞动态失败: ${error instanceof Error ? error.message : String(error)}`;
    console.error(errorMsg);
    throw new Error(errorMsg);
  }
}

/**
 * 取消点赞动态
 * 
 * @param id 动态ID
 */
export function unlikePost(id: number): Promise<void> {
  try {
    console.info(`取消点赞动态, id: ${id}`);
    return request<void>(RequestMethod.DELETE, `/posts/${id}/like`);
  } catch (error) {
    const errorMsg = `取消点赞动态失败: ${error instanceof Error ? error.message : String(error)}`;
    console.error(errorMsg);
    throw new Error(errorMsg);
  }
}

/**
 * 获取动态评论
 * 
 * @param id 动态ID
 * @param page 页码
 * @param size 每页大小
 * @returns 评论列表
 */
export function getPostComments(id: number, page: number, size: number): Promise<Comment[]> {
  try {
    console.info(`获取动态评论, id: ${id}, page: ${page}, size: ${size}`);
    
    const params: RequestData = {
      page,
      size
    };
    
    return request<Comment[]>(RequestMethod.GET, `/posts/${id}/comments`, params as QueryParams);
  } catch (error) {
    const errorMsg = `获取动态评论失败: ${error instanceof Error ? error.message : String(error)}`;
    console.error(errorMsg);
    throw new Error(errorMsg);
  }
}

/**
 * 发表评论
 * 
 * @param postId 动态ID
 * @param comment 评论内容
 * @returns 创建的评论
 */
export function createComment(postId: number, comment: Comment): Promise<Comment> {
  try {
    console.info(`发表评论, postId: ${postId}, content: ${comment.content}`);
    // 将comment转为RequestData对象
    const requestData: RequestData = {
      id: comment.id,
      postId: comment.postId,
      userId: comment.userId,
      content: comment.content,
      parentId: comment.parentId
    };
    return request<Comment>(RequestMethod.POST, `/posts/${postId}/comments`, EmptyParams, requestData);
  } catch (error) {
    const errorMsg = `发表评论失败: ${error instanceof Error ? error.message : String(error)}`;
    console.error(errorMsg);
    throw new Error(errorMsg);
  }
}

/**
 * 删除梦想
 * 
 * @param id 梦想ID
 * @returns 删除结果，通常为空对象或状态码
 */
export function deleteDream(id: number): Promise<void> {
  console.info(`开始删除梦想, ID: ${id}`);
  try {
    return request<void>(RequestMethod.DELETE, `/dreams/${id}`);
  } catch (error) {
    const errorMsg = `删除梦想失败: ${error instanceof Error ? error.message : String(error)}`;
    console.error(errorMsg);
    console.error(`梦想ID: ${id}`);
    throw new Error(errorMsg);
  }
}

/**
 * 用户相关API
 */

// 登录请求接口
export interface LoginRequest {
  username: string;
  password: string;
}

// 登录响应接口
export interface LoginResponse {
  id: number;
  username: string;
  nickname: string;
  avatar: string;
  token: string;
}

// 注册请求接口
export interface RegisterRequest {
  username: string;
  password: string;
  nickname?: string;
  email?: string;
  phone?: string;
}

/**
 * 用户登录
 * 
 * @param params 登录参数
 * @returns 登录结果Promise
 */
export async function login(params: LoginParams): Promise<ApiResponse<AuthResponse>> {
  console.info('登录请求参数:', JSON.stringify(params));
  try {
    // 将LoginParams转换为RequestData类型
    const requestData: RequestData = {
      username: params.username,
      password: params.password
    };
    
    const response = await request<ApiResponse<AuthResponse>>(
      RequestMethod.POST,
      '/auth/login',
      EmptyParams,
      requestData
    );
    console.info('登录响应:', JSON.stringify(response));
    return response;
  } catch (error) {
    console.error('登录失败:', error);
    throw new Error(error)
  }
}

/**
 * 用户注册
 * 
 * @param params 注册参数
 * @returns 注册结果Promise
 */
export async function register(params: RegisterParams): Promise<ApiResponse<AuthResponse>> {
  console.info('注册请求参数:', JSON.stringify(params));
  try {
    // 将RegisterParams转换为RequestData类型
    const requestData: RequestData = {
      username: params.username,
      password: params.password,
      nickname: params.nickname,
      email: params.email,
      phone: params.phone
    };
    
    const response = await request<ApiResponse<AuthResponse>>(
      RequestMethod.POST,
      '/auth/register',
      EmptyParams,
      requestData
    );
    console.info('注册响应:', JSON.stringify(response));
    return response;
  } catch (error) {
    console.error('注册失败:', error);
    throw new Error(error)
  }
}

/**
 * 检查用户名是否可用
 * 
 * @param username 用户名
 * @returns 检查结果Promise
 */
export async function checkUsername(username: string): Promise<ApiResponse<boolean>> {
  console.info('检查用户名:', username);
  try {
    // 创建一个符合QueryParams类型的对象
    const queryParams: QueryParams = {};
    queryParams['username'] = username;
    
    const response = await request<ApiResponse<boolean>>(
      RequestMethod.GET,
      '/auth/check-username',
      queryParams
    );
    console.info('检查用户名响应:', JSON.stringify(response));
    return response;
  } catch (error) {
    console.error('检查用户名失败:', error);
    throw new Error(error)
  }
}

/**
 * 用户登出
 * 
 * @returns 登出结果Promise
 */
export async function logout(): Promise<ApiResponse<void>> {
  console.info('发起登出请求');
  try {
    const response = await request<ApiResponse<void>>(
      RequestMethod.POST,
      '/auth/logout',
      EmptyParams
    );
    console.info('登出响应:', JSON.stringify(response));
    return response;
  } catch (error) {
    console.error('登出请求失败:', error);
    // 登出功能即使失败也应该允许用户登出
    // 返回模拟的成功响应
    return {
      code: 200,
      message: '登出成功',
      data: undefined
    };
  }
}