/**
 * API服务类，用于封装对后端接口的调用
 */

import http from '@ohos.net.http';
import { RequestMethod, ApiResponse, PageResponse, Dream, Task, DreamStats, QueryParams, HomePageData, RequestParams, Post, Comment, LoginParams, RegisterParams, AuthResponse, UserInfo } from '../model/CommonTypes';
import { UserSession } from '../utils/auth/UserSession';

// 导出需要的类型，解决模块导出问题
export { UserInfo, PageResponse } from '../model/CommonTypes';

// 在CommonTypes之后，定义辅助接口
export interface UserRequest {
  id: number;
}

export interface DreamRequest {
  id: number;
}

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
  // 图片字段 - 修改为string类型以匹配Post接口
  images?: string;
  imageUrls?: string[];
  
  // 用户认证相关字段
  username?: string;
  password?: string;
  nickname?: string;
  email?: string;
  phone?: string;
  
  // 新增参数
  currentUserId?: number;
  authorId?: number; // 添加authorId字段，用于筛选特定用户的帖子
  
  // 对象类型字段
  user?: UserRequest;
  dream?: DreamRequest;
  
  // 计数字段
  likeCount?: number;
  commentCount?: number;
  viewCount?: number;
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
  // 确保endpoint以/开头，避免BASE_URL末尾的/api与endpoint之间缺少分隔符
  const formattedEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
  
  // 构建URL
  let url = `${BASE_URL}${formattedEndpoint}`;

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
    
    // 添加用户认证令牌
    const userSession = UserSession.getInstance();
    if (userSession && userSession.isLoggedIn()) {
      const token = userSession.getToken();
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
        console.info('已添加用户认证令牌到请求');
      }
    }
    
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
  return request<Dream[]>(RequestMethod.GET, `dreams/user/${userId}`, EmptyParams);
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
 * @param currentUserId 当前用户ID，用于获取关注状态
 * @returns 动态列表分页数据
 */
export function getPosts(page: number, size: number, type: number, currentUserId?: number): Promise<PageResponse<Post>> {
  try {
    console.info(`获取社区动态, page: ${page}, size: ${size}, type: ${type}, currentUserId: ${currentUserId}`);
    
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
    
    // 如果有当前用户ID，将其作为参数传递用于判断点赞和关注状态，但使用不同的参数名称
    if (currentUserId) {
      params.currentUserId = currentUserId; // 使用不同的参数名称，避免后端将其用于过滤帖子
    }
    
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
            if (post.images) {
              try {
                // 安全处理：始终将images视为可能是任何类型，并转换为字符串
                let imagesString = '';
                
                // 处理各种可能的类型情况
                if (typeof post.images === 'string') {
                  imagesString = post.images;
                } else if (Array.isArray(post.images)) {
                  // 兼容处理：如果后端返回了数组（这不应该发生，但为了防御性编程）
                  imagesString = String(post.images);
                } else if (post.images) {
                  imagesString = String(post.images);
                }
                
                // 安全地处理字符串
                if (imagesString && imagesString.trim && imagesString.trim() !== '') {
                  const urls = imagesString.trim().split(',');
                  // 过滤出有效的URL
                  post.imageUrls = urls.filter(url => url && typeof url === 'string' && url.trim() !== '');
                }
              } catch (error) {
                console.error(`处理帖子图片时出错: ${error instanceof Error ? error.message : String(error)}`);
                post.imageUrls = []; // 出错时确保imageUrls是空数组
              }
            }
            
            // 处理作者关注状态
            if (post.author && post.author.id) {
              // 如果后端已返回isFollowed状态，使用它
              // 否则先默认为false，后续可能需要单独查询
              if (post.author.isFollowed === undefined) {
                post.author.isFollowed = false;
              }
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
    
    // 获取当前用户会话
    const userSession = UserSession.getInstance();
    
    // 确保用户已登录
    if (!userSession.isLoggedIn()) {
      console.error('用户未登录，无法点赞');
      return Promise.reject(new Error('用户未登录，请先登录'));
    }
    
    // 获取用户ID
    const userId = userSession.getUserId();
    if (!userId) {
      console.error('无法获取当前登录用户ID');
      return Promise.reject(new Error('无法获取用户ID，请重新登录'));
    }
    
    // 添加userId作为查询参数
    const params = {} as QueryParams;
    params.userId = userId;

    return request<void>(RequestMethod.POST, `/posts/${id}/like`, params);
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
    
    // 获取当前用户会话
    const userSession = UserSession.getInstance();
    
    // 确保用户已登录
    if (!userSession.isLoggedIn()) {
      console.error('用户未登录，无法取消点赞');
      return Promise.reject(new Error('用户未登录，请先登录'));
    }
    
    // 获取用户ID
    const userId = userSession.getUserId();
    if (!userId) {
      console.error('无法获取当前登录用户ID');
      return Promise.reject(new Error('无法获取用户ID，请重新登录'));
    }
    
    // 添加userId作为查询参数
    const params = {} as QueryParams;
    params.userId = userId;

    return request<void>(RequestMethod.DELETE, `/posts/${id}/like`, params);
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
    
    // 确保路径以"/"开头，修复URL结构
    return request<ApiResponse<Comment[]>>(RequestMethod.GET, `/posts/${id}/comments`, params as QueryParams)
      .then((response: ApiResponse<Comment[]>) => {
        // 正确解析ApiResponse结构
        if (response && response.data) {
          return response.data || [];
        }
        return [];
      })
      .catch((error: Error) => {
        // 如果API返回404或其他错误，记录日志但返回空数组，避免前端崩溃
        console.warn(`评论API错误: ${error.message}, 返回空列表`);
        return [] as Comment[];
      });
  } catch (error) {
    // 捕获其他可能的错误，仍然返回空数组
    console.error(`获取动态评论失败: ${error instanceof Error ? error.message : String(error)}`);
    return Promise.resolve([] as Comment[]);
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
  // 获取当前用户会话
  const userSession = UserSession.getInstance();
  
  // 确保用户已登录
  if (!userSession.isLoggedIn()) {
    console.error('用户未登录，无法发表评论');
    return Promise.reject(new Error('用户未登录，请先登录'));
  }

  // 确保包含用户ID
  const userId = userSession.getUserId();
  if (!userId) {
    console.error('无法获取当前登录用户ID');
    return Promise.reject(new Error('无法获取用户ID，请重新登录'));
  }
  
  // 记录详细的会话信息用于调试
  console.info(`发表评论 - 详细验证信息:`);
  console.info(`登录状态: ${userSession.isLoggedIn()}`);
  console.info(`用户ID: ${userId}`);
  console.info(`认证令牌: ${userSession.getToken()?.substring(0, 15)}...`);

  // 构建评论数据 - 确保包含用户ID
  const commentData: RequestData = {
    content: comment.content,
    parentId: comment.parentId || 0,
    userId: userId // 明确使用会话中的用户ID
  };

  try {
    console.info(`尝试发表评论: postId=${postId}, userId=${commentData.userId}, content=${comment.content.substring(0, 20)}...`);
    
    // 确保路径以"/"开头
    return request<ApiResponse<Comment>>(RequestMethod.POST, `/posts/${postId}/comments`, EmptyParams, commentData)
      .then(response => {
        // 记录完整响应
        console.info(`评论API响应: ${JSON.stringify(response)}`);
        
        // 正确解析ApiResponse结构
        if (response && response.data) {
          console.info(`评论发表成功: id=${response.data.id}`);
          return response.data;
        }
        throw new Error('服务器返回了无效的响应格式');
      })
      .catch((error: Error) => {
        // 分析错误类型
        const errorStr = error.message || '';
        let friendlyMessage = '';
        
        if (errorStr.includes('404')) {
          friendlyMessage = '评论功能尚未实现 (后端API返回404)';
        } else if (errorStr.includes('401') || errorStr.includes('403') || errorStr.includes('未登录')) {
          friendlyMessage = '没有权限发表评论，请先登录';
        } else {
          friendlyMessage = `评论发表失败: ${errorStr}`;
        }
        
        console.warn(friendlyMessage);
        
        // 创建一个带有错误信息的错误对象
        const enhancedError = new Error(friendlyMessage);
        throw enhancedError;
      });
  } catch (error) {
    // 捕获其他可能的错误
    const errorMsg = `评论发表失败: ${error instanceof Error ? error.message : String(error)}`;
    console.error(errorMsg);
    throw new Error(errorMsg);
  }
}

/**
 * 创建社区帖子
 * 
 * @param post 帖子信息
 * @returns 创建的帖子信息
 */
export function createPost(post: Post): Promise<Post> {
  // 创建请求数据对象
  const requestData: RequestData = {};
  
  // 设置基本字段
  requestData.title = post.title || '';
  requestData.content = post.content || '';
  requestData.images = post.images;
  requestData.status = 1; // 1表示正常状态
  requestData.likeCount = 0;
  requestData.commentCount = 0;
  requestData.viewCount = 0;
  
  // 设置用户关联
  if (post.userId) {
    const user: UserRequest = { id: post.userId };
    requestData.user = user;
  }
  
  // 设置梦想关联
  if (post.dreamId) {
    const dream: DreamRequest = { id: post.dreamId };
    requestData.dream = dream;
  }
  
  console.info(`创建帖子请求数据: ${JSON.stringify(requestData)}`);
  return request<Post>(RequestMethod.POST, '/posts', EmptyParams, requestData);
}

/**
 * 获取帖子详情
 * 
 * @param id 帖子ID
 * @returns 帖子详情
 */
export function getPostById(id: number): Promise<Post> {
  try {
    console.info(`获取帖子详情, id: ${id}`);
    return request<ApiResponse<Post>>(RequestMethod.GET, `/posts/${id}`)
      .then(response => {
        if (!response || !response.data) {
          console.error('获取帖子详情失败: 无效的API响应格式');
          throw new Error('获取帖子详情失败: 服务器返回无效数据');
        }
        
        const post = response.data;
        console.info(`收到帖子详情: ID=${post.id}, 作者信息=${post.author ? '已包含' : '不存在'}`);
        
        // 确保author字段存在，如果不存在则根据其他字段创建
        if (!post.author && post.userId) {
          // 使用postVO中的用户相关字段创建author对象
          const userId = post.userId || 0;
          const username = post.username || '未知用户';
          const nickname = post.nickname || post.username || '未知用户';
          const avatar = post.userAvatar || '';
          
          console.info(`创建作者对象: userId=${userId}, username=${username}, nickname=${nickname}`);
          
          post.author = {
            id: userId,
            username: username,
            nickname: nickname,
            avatar: avatar,
            isFollowed: false
          };
        } else if (!post.author) {
          // 如果没有用户相关信息，则创建默认作者对象
          post.author = {
            id: 0,
            username: '未知用户',
            nickname: '未知用户',
            avatar: '',
            isFollowed: false
          };
        }

        // 处理作者头像URL
        if (post.author && post.author.avatar) {
          try {
            post.author.avatar = processImageUrl(post.author.avatar);
            console.info(`处理后的作者头像URL: ${post.author.avatar.substring(0, 50)}...`);
          } catch (error) {
            console.error(`处理作者头像URL失败: ${error instanceof Error ? error.message : String(error)}`);
            // 确保avatar字段不为undefined
            post.author.avatar = '';
          }
        }

        // 处理图片URLs
        if (!post.imageUrls) {
          post.imageUrls = [];
        }
        
        if (post.images) {
          try {
            if (typeof post.images === 'string' && post.images.trim() !== '') {
              post.imageUrls = post.images.split(',')
                .filter(url => url && url.trim() !== '')
                .map((url: string) => processImageUrl(url));
              console.info(`处理后的图片URLs: ${post.imageUrls.length}张`);
            } else if (Array.isArray(post.images)) {
              post.imageUrls = post.images.map((url: string) => processImageUrl(url));
              console.info(`图片URLs数组: ${post.imageUrls.length}张`);
            } else {
              console.info(`无图片数据`);
            }
          } catch (error) {
            console.error(`处理图片URL失败: ${error instanceof Error ? error.message : String(error)}`);
            post.imageUrls = [];
          }
        } else {
          console.info(`帖子无图片字段`);
        }
        
        return post;
      });
  } catch (error) {
    const errorMsg = `获取帖子详情失败: ${error instanceof Error ? error.message : String(error)}`;
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
    throw new Error(error instanceof Error ? error.message : String(error));
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
    throw new Error(error instanceof Error ? error.message : String(error));
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
    throw new Error(error instanceof Error ? error.message : String(error));
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
    // 创建一个明确类型的响应对象
    const mockResponse: ApiResponse<void> = {
      code: 200,
      message: '登出成功',
      data: undefined
    };
    return mockResponse;
  }
}

/**
 * 关注用户
 * 
 * @param followerId 关注者ID（当前用户）
 * @param followingId 被关注者ID
 * @returns 操作结果
 */
export async function followUser(followerId: number, followingId: number): Promise<void> {
  console.info(`API调用: 关注用户, followerId: ${followerId}, followingId: ${followingId}`);
  
  try {
    // 检查参数
    if (!followerId || !followingId) {
      throw new Error('关注用户失败: 用户ID不能为空');
    }
    
    // 构建URL和请求
    const url = `${BASE_URL}/users/${followerId}/follow/${followingId}`;
    console.info(`发送关注请求到: ${url}`);
    
    // 使用低级http请求以便查看更多详细信息
    const httpRequest = http.createHttp();
    const options: RequestOptions = {
      method: http.RequestMethod.POST,
      readTimeout: TIMEOUT,
      connectTimeout: TIMEOUT,
      header: {
        'Content-Type': 'application/json'
      }
    };
    
    // 添加认证令牌
    const userSession = UserSession.getInstance();
    if (userSession && userSession.isLoggedIn()) {
      const token = userSession.getToken();
      if (token) {
        options.header['Authorization'] = `Bearer ${token}`;
      }
    }
    
    const response = await httpRequest.request(url, options);
    console.info(`关注用户响应: ${response.responseCode}, ${JSON.stringify(response.result)}`);
    
    if (response.responseCode >= 200 && response.responseCode < 300) {
      console.info('关注用户成功');
      return;
    } else {
      throw new Error(`关注用户失败: HTTP ${response.responseCode} - ${JSON.stringify(response.result)}`);
    }
  } catch (error) {
    console.error(`关注用户API异常: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`关注用户失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 取消关注用户
 * 
 * @param followerId 关注者ID（当前用户）
 * @param followingId 被关注者ID
 * @returns 操作结果
 */
export async function unfollowUser(followerId: number, followingId: number): Promise<void> {
  console.info(`API调用: 取消关注用户, followerId: ${followerId}, followingId: ${followingId}`);
  
  try {
    // 检查参数
    if (!followerId || !followingId) {
      throw new Error('取消关注用户失败: 用户ID不能为空');
    }
    
    // 构建URL和请求
    const url = `${BASE_URL}/users/${followerId}/unfollow/${followingId}`;
    console.info(`发送取消关注请求到: ${url}`);
    
    // 使用低级http请求以便查看更多详细信息
    const httpRequest = http.createHttp();
    const options: RequestOptions = {
      method: http.RequestMethod.DELETE,
      readTimeout: TIMEOUT,
      connectTimeout: TIMEOUT,
      header: {
        'Content-Type': 'application/json'
      }
    };
    
    // 添加认证令牌
    const userSession = UserSession.getInstance();
    if (userSession && userSession.isLoggedIn()) {
      const token = userSession.getToken();
      if (token) {
        options.header['Authorization'] = `Bearer ${token}`;
      }
    }
    
    const response = await httpRequest.request(url, options);
    console.info(`取消关注用户响应: ${response.responseCode}, ${JSON.stringify(response.result)}`);
    
    if (response.responseCode >= 200 && response.responseCode < 300) {
      console.info('取消关注用户成功');
      return;
    } else {
      throw new Error(`取消关注用户失败: HTTP ${response.responseCode} - ${JSON.stringify(response.result)}`);
    }
  } catch (error) {
    console.error(`取消关注用户API异常: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`取消关注用户失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 检查是否已关注用户
 * 
 * @param followerId 关注者ID（当前用户）
 * @param followingId 被关注者ID
 * @returns 是否已关注
 */
export function isFollowingUser(followerId: number, followingId: number): Promise<boolean> {
  try {
    console.info(`检查是否已关注用户, followerId: ${followerId}, followingId: ${followingId}`);
    return request<boolean>(RequestMethod.GET, `/users/${followerId}/is-following/${followingId}`);
  } catch (error) {
    console.error(`检查关注状态失败: ${error instanceof Error ? error.message : String(error)}`);
    return Promise.resolve(false); // 出错时默认返回未关注
  }
}

/**
 * 获取用户关注列表
 * 
 * @param userId 用户ID
 * @param page 页码
 * @param size 每页大小
 * @returns 关注列表
 */
export function getUserFollowings(userId: number, page: number = 0, size: number = 20): Promise<PageResponse<UserInfo>> {
  try {
    console.info(`获取用户关注列表, userId: ${userId}, page: ${page}, size: ${size}`);
    const params = {} as QueryParams;
    params.page = page;
    params.size = size;
    
    return request<PageResponse<UserInfo>>(RequestMethod.GET, `/users/${userId}/followings`, params);
  } catch (error) {
    console.error(`获取用户关注列表失败: ${error instanceof Error ? error.message : String(error)}`);
    // 返回空数据结构
    const emptyResponse: PageResponse<UserInfo> = {
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
 * 获取用户粉丝列表
 * 
 * @param userId 用户ID
 * @param page 页码
 * @param size 每页大小
 * @returns 粉丝列表
 */
export function getUserFollowers(userId: number, page: number = 0, size: number = 20): Promise<PageResponse<UserInfo>> {
  try {
    console.info(`获取用户粉丝列表, userId: ${userId}, page: ${page}, size: ${size}`);
    const params = {} as QueryParams;
    params.page = page;
    params.size = size;
    
    return request<PageResponse<UserInfo>>(RequestMethod.GET, `/users/${userId}/followers`, params);
  } catch (error) {
    console.error(`获取用户粉丝列表失败: ${error instanceof Error ? error.message : String(error)}`);
    // 返回空数据结构
    const emptyResponse: PageResponse<UserInfo> = {
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
 * 根据ID获取用户信息
 * 
 * @param userId 用户ID
 * @returns 用户信息
 */
export function getUserById(userId: number): Promise<UserInfo> {
  try {
    console.info(`获取用户信息, userId: ${userId}`);
    return request<UserInfo>(RequestMethod.GET, `/users/${userId}`);
  } catch (error) {
    console.error(`获取用户信息失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取用户信息失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 获取用户帖子列表
 * 
 * @param userId 用户ID
 * @param page 页码
 * @param size 每页大小
 * @returns 帖子列表分页数据
 */
export function getUserPosts(userId: number, page: number = 0, size: number = 10): Promise<PageResponse<Post>> {
  try {
    console.info(`获取用户帖子列表, userId: ${userId}, page: ${page}, size: ${size}`);
    
    const params: RequestData = {
      page,
      pageSize: size,
      authorId: userId // 使用authorId作为参数筛选特定用户的帖子
    };
    
    // 获取当前用户ID用于检查关注状态和点赞状态
    const userSession = UserSession.getInstance();
    const currentUserId = userSession.isLoggedIn() ? userSession.getUserId() : undefined;
    
    if (currentUserId) {
      params.currentUserId = currentUserId;
    }
    
    return request<PostApiResponse>(RequestMethod.GET, '/posts', params as QueryParams)
      .then((apiResponse) => {
        console.info(`收到用户帖子列表响应`);
        
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
            if (post.images) {
              try {
                // 安全处理：始终将images视为可能是任何类型，并转换为字符串
                let imagesString = '';
                
                // 处理各种可能的类型情况
                if (typeof post.images === 'string') {
                  imagesString = post.images;
                } else if (Array.isArray(post.images)) {
                  // 兼容处理：如果后端返回了数组（这不应该发生，但为了防御性编程）
                  imagesString = String(post.images);
                } else if (post.images) {
                  imagesString = String(post.images);
                }
                
                // 安全地处理字符串
                if (imagesString && imagesString.trim && imagesString.trim() !== '') {
                  const urls = imagesString.trim().split(',');
                  // 处理图片URL，确保能在当前环境正确访问
                  post.imageUrls = urls.filter(url => url && typeof url === 'string' && url.trim() !== '')
                    .map(url => processImageUrl(url));
                }
              } catch (error) {
                console.error(`处理帖子图片时出错: ${error instanceof Error ? error.message : String(error)}`);
                post.imageUrls = []; // 出错时确保imageUrls是空数组
              }
            }
            
            // 处理作者关注状态
            if (post.author && post.author.id) {
              // 如果后端已返回isFollowed状态，使用它
              // 否则先默认为false，后续可能需要单独查询
              if (post.author.isFollowed === undefined) {
                post.author.isFollowed = false;
              }
            }
          });
        }
        
        console.info(`用户帖子列表数据处理完成，共${pageResponse.content.length}条记录`);
        return pageResponse;
      });
  } catch (error) {
    console.error(`获取用户帖子列表失败: ${error instanceof Error ? error.message : String(error)}`);
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
 * 更新帖子
 * 
 * @param postId 要更新的帖子ID
 * @param postData 要更新的帖子数据
 * @returns 更新后的帖子
 */
export async function updatePost(postId: number, postData: RequestData): Promise<Post> {
  try {
    console.info(`更新帖子, postId: ${postId}, postData:`, JSON.stringify(postData));
    
    // 检查参数
    if (!postId) {
      throw new Error('更新帖子失败: 帖子ID不能为空');
    }
    
    // 获取当前用户会话，确保用户已登录
    const userSession = UserSession.getInstance();
    if (!userSession.isLoggedIn()) {
      throw new Error('更新帖子失败: 用户未登录');
    }
    
    // 明确设置用户ID，确保后端能识别用户
    if (!postData.userId) {
      postData.userId = userSession.getUserId();
      console.info(`设置用户ID=${postData.userId}，确保后端能正确识别用户`);
    }
    
    // 将imageUrls数组转换为后端需要的images字符串格式
    if (postData.imageUrls && Array.isArray(postData.imageUrls) && postData.imageUrls.length > 0) {
      postData.images = postData.imageUrls.join(',');
    }
    
    // 确保status字段设置为1，避免数据库null值错误
    postData.status = 1;
    console.info('设置status=1，确保更新不会出现null值错误');
    
    // 发送更新请求
    const updatedPost = await request<Post>(RequestMethod.PUT, `/posts/${postId}`, {}, postData);
    console.info('更新帖子成功', JSON.stringify(updatedPost));
    
    // 处理图片URL数组，确保updatedPost具有imageUrls字段
    if (updatedPost && updatedPost.images && !updatedPost.imageUrls) {
      const imagesStr = String(updatedPost.images);
      if (imagesStr && imagesStr.trim() !== '') {
        const urls = imagesStr.trim().split(',');
        updatedPost.imageUrls = urls.filter(url => url && url.trim() !== '')
          .map(url => processImageUrl(url));
      } else {
        updatedPost.imageUrls = [];
      }
    }
    
    return updatedPost;
  } catch (error) {
    console.error(`更新帖子失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`更新帖子失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 删除帖子
 * 
 * @param postId 要删除的帖子ID
 * @returns 删除成功返回true
 */
export async function deletePost(postId: number): Promise<boolean> {
  try {
    console.info(`删除帖子, postId: ${postId}`);
    
    // 检查参数
    if (!postId) {
      throw new Error('删除帖子失败: 帖子ID不能为空');
    }
    
    // 获取当前用户会话，确保用户已登录
    const userSession = UserSession.getInstance();
    if (!userSession.isLoggedIn()) {
      throw new Error('删除帖子失败: 用户未登录');
    }
    
    // 获取用户ID和令牌，双重确认认证状态
    const userId = userSession.getUserId();
    const token = userSession.getToken();
    if (!token || !userId) {
      throw new Error('删除帖子失败: 无效的用户认证状态');
    }
    
    console.info(`开始删除帖子 ID=${postId}, 用户ID=${userId}, 令牌=${token.substring(0, 15)}...`);
    
    // 构建完整URL，包含用户ID作为查询参数
    const url = `${BASE_URL}/posts/${postId}?userId=${userId}`;
    console.info(`发送删除请求到: ${url}`);
    
    // 使用底层HTTP请求，精确控制请求头
    const httpRequest = http.createHttp();
    const options: RequestOptions = {
      method: http.RequestMethod.DELETE,
      readTimeout: TIMEOUT,
      connectTimeout: TIMEOUT,
      header: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    };
    
    // 发送请求
    const response = await httpRequest.request(url, options);
    console.info(`删除响应: 状态码=${response.responseCode}, 结果=${typeof response.result === 'string' ? response.result.substring(0, 100) : '非字符串'}`);
    
    // 解析响应
    let responseData: ApiResponse<void> = {
      code: 0,
      message: '',
      data: undefined
    };
    
    if (typeof response.result === 'string') {
      responseData = JSON.parse(response.result);
    }
    
    console.info('删除帖子响应详情:', JSON.stringify(responseData));
    
    // 释放HTTP请求资源
    httpRequest.destroy();
    
    // 如果返回500但包含"用户未登录"错误，尝试提供更具体的错误信息
    if (responseData.code === 500 && responseData.message && responseData.message.includes('用户未登录')) {
      console.error('后端报告用户未登录错误，但客户端已发送令牌，可能是后端安全配置问题');
      throw new Error('删除失败: 后端无法识别用户认证信息，请联系管理员');
    }
    
    // 检查响应是否成功
    return responseData && responseData.code === 200;
  } catch (error) {
    console.error(`删除帖子失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`删除帖子失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}