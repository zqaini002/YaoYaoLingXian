/**
 * 全局常量定义
 */
export class CommonConstants {
  /**
   * 字体大小定义
   */
  static readonly FONT_SIZE_SMALL: number = 14;
  static readonly FONT_SIZE_NORMAL: number = 16;
  static readonly FONT_SIZE_LARGE: number = 20;
  static readonly FONT_SIZE_XLARGE: number = 24;
  
  /**
   * 边距定义
   */
  static readonly MARGIN_SMALL: number = 4;
  static readonly MARGIN_NORMAL: number = 8;
  static readonly MARGIN_LARGE: number = 16;
  static readonly MARGIN_XLARGE: number = 24;
  
  /**
   * 圆角定义
   */
  static readonly RADIUS_SMALL: number = 4;
  static readonly RADIUS_NORMAL: number = 8;
  static readonly RADIUS_LARGE: number = 16;
  
  /**
   * 颜色定义
   */
  static readonly COLOR_PRIMARY: string = '#2196F3';
  static readonly COLOR_PRIMARY_DARK: string = '#1976D2';
  static readonly COLOR_ACCENT: string = '#FF4081';
  static readonly COLOR_BACKGROUND: string = '#F5F5F5';
  static readonly COLOR_TEXT_PRIMARY: string = '#333333';
  static readonly COLOR_TEXT_SECONDARY: string = '#666666';
  static readonly COLOR_TEXT_TERTIARY: string = '#999999';
  
  /**
   * 梦想分类
   */
  static readonly DREAM_CATEGORIES: string[] = ['学习', '健康', '旅行', '创作', '艺术', '职业', '生活技能'];
  
  /**
   * 梦想优先级
   */
  static readonly DREAM_PRIORITIES: number[] = [1, 2, 3, 4, 5];
  static readonly DREAM_PRIORITY_LABELS: string[] = ['最高', '较高', '中等', '较低', '最低'];
  
  /**
   * 梦想状态
   */
  static readonly DREAM_STATUS_NOT_STARTED: number = 0;
  static readonly DREAM_STATUS_IN_PROGRESS: number = 1;
  static readonly DREAM_STATUS_COMPLETED: number = 2;
  static readonly DREAM_STATUS_ABANDONED: number = 3;
  
  /**
   * 梦想状态标签
   */
  static readonly DREAM_STATUS_LABELS: string[] = ['未开始', '进行中', '已完成', '已放弃'];
} 