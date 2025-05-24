import { DreamTag } from './DreamTag';

/**
 * 梦想实体类
 */
export interface Dream {
  // 基本信息
  id: number;
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
  tags?: string[]; // 标签列表
  likesCount?: number;
  commentsCount?: number;
} 