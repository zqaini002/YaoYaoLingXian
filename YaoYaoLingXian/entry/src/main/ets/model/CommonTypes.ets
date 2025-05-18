/**
 * 通用常量
 */
export class CommonConstants {
  // 颜色常量
  static readonly COLOR_PRIMARY: string = '#4D8CFE';
  static readonly COLOR_PRIMARY_LIGHT: string = '#6BA0FF';
  static readonly COLOR_SECONDARY: string = '#4CAF50';
  static readonly COLOR_ACCENT: string = '#FF6B6B';
  static readonly COLOR_BACKGROUND: string = '#F5F7FA';

  // 字体大小
  static readonly FONT_SIZE_SMALL: number = 12;
  static readonly FONT_SIZE_NORMAL: number = 14;
  static readonly FONT_SIZE_MEDIUM: number = 16;
  static readonly FONT_SIZE_LARGE: number = 18;
  static readonly FONT_SIZE_XLARGE: number = 20;
  static readonly FONT_SIZE_XXLARGE: number = 24;

  // 边距
  static readonly MARGIN_SMALL: number = 4;
  static readonly MARGIN_NORMAL: number = 8;
  static readonly MARGIN_MEDIUM: number = 12;
  static readonly MARGIN_LARGE: number = 16;
  static readonly MARGIN_XLARGE: number = 24;

  // 圆角
  static readonly RADIUS_SMALL: number = 4;
  static readonly RADIUS_NORMAL: number = 8;
  static readonly RADIUS_MEDIUM: number = 12;
  static readonly RADIUS_LARGE: number = 16;

  // HTTP请求方法
  static readonly METHOD_GET: string = 'GET';
  static readonly METHOD_POST: string = 'POST';
  static readonly METHOD_PUT: string = 'PUT';
  static readonly METHOD_DELETE: string = 'DELETE';
}

/**
 * 梦想目标完整模型
 * 与models/Dream.ets保持一致
 */
export interface Dream {
  // 基本信息
  id?: number;
  userId: number;
  title: string;
  description: string;
  category: string;
  
  // 状态与进度
  priority: number; // 优先级：1-5
  status: number;   // 状态：0-未开始，1-进行中，2-已完成，3-已放弃
  completionRate: number; // 完成进度百分比：0-100
  
  // 时间相关
  deadline: string; // 截止日期，格式：YYYY-MM-DD
  createdAt?: string;
  updatedAt?: string;
  expectedDays: number; // 预期完成天数
  
  // 其他属性
  imageUrl: string; // 封面图片URL
  isPublic: number; // 是否公开：0-私密，1-公开
  
  // 可选属性
  tags?: string[];
  likesCount?: number;
  commentsCount?: number;
  
  // 额外属性
  taskCount?: number;
  completedTaskCount?: number;
}

/**
 * 梦想目标简化模型
 */
export interface DreamSimple {
  id: number;
  userId: number;
  title: string;
  description: string;
  category: string;
  priority: number;
  status: number;
  completionRate: number;
  deadline: string;
  imageUrl: string;
  isPublic: number; // 在数据库中是tinyint，需要使用number类型
  taskCount?: number; 
  completedTaskCount?: number;
}

/**
 * 任务模型
 */
export interface Task {
  id: number;
  dreamId: number;
  userId: number;
  title: string;
  description: string;
  status: number;
  priority: number;
  startDate: string;
  dueDate: string;
  completedAt: string | null;
  reminderTime: string | null;
  parentTaskId: number | null;
  createdAt: string;
  updatedAt: string;
  dreamTitle?: string;
  isTodayTask?: boolean;
  isOverdue?: boolean;
  isUpcomingTask?: boolean;
}

/**
 * 社区帖子模型
 */
export interface Post {
  id: number;
  userId: number;
  dreamId?: number;
  title: string;
  content: string;
  images?: string;  // 添加images字段，用于接收后端返回的原始图片字符串
  imageUrls?: string[];  // 前端处理后的图片URL数组
  likeCount: number;
  commentCount: number;
  viewCount?: number;
  createdAt: string;
  updatedAt: string;
  author?: User;
  dream?: DreamSimple;
  isLiked?: boolean;
}

/**
 * 用户模型
 */
export interface User {
  id: number;
  username: string;
  nickname: string;
  avatar: string;
  email?: string;
  bio?: string;
  followersCount?: number;
  followingCount?: number;
  createdAt?: string;
}

/**
 * 评论模型
 */
export interface Comment {
  id: number;
  postId: number;
  userId: number;
  content: string;
  parentId?: number;
  status?: number;
  createdAt: string;
  updatedAt?: string;
  username?: string;
  userAvatar?: string;
  likeCount?: number;
  isLiked?: boolean;
  replies?: Comment[];
  author?: User;
}

/**
 * API响应结构
 */
export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

/**
 * 分页响应
 */
export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first: boolean;
  last: boolean;
}

/**
 * HTTP请求方法
 */
export enum RequestMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE'
}

/**
 * 系统图标定义
 */
export class SystemSymbols {
  static readonly Calendar: string = 'calendar';
  static readonly Task: string = 'task';
  static readonly Home: string = 'home';
  static readonly User: string = 'user';
  static readonly Add: string = 'add';
}

/**
 * 梦想统计数据
 */
export interface DreamStats {
  userId: number;
  totalDreams: number;
  inProgressDreams: number;
  completedDreams: number;
  abandonedDreams: number;
  dreamCompletionRate: number;
  totalTasks: number;
  completedTasks: number;
  taskCompletionRate: number;
}

/**
 * 首页数据接口
 */
export interface HomePageData {
  dreamStats: DreamStats;
  todayTasks: PageResponse<Task>;
  upcomingTasks: PageResponse<Task>;
  recentDreams: Dream[];
}

/**
 * 请求参数接口
 */
export type RequestParams = Record<string, string | number | boolean | undefined | null>;

/**
 * 查询参数类型
 * ArkTS不支持索引签名，使用Record类型代替
 */
export type QueryParams = Record<string, string | number | boolean | undefined | null>; 