/**
 * 时间相关工具类
 */

/**
 * 获取当前时间段的问候语
 * @returns 根据当前时间返回适当的问候语
 */
export function getTimeOfDay(): string {
  const hour = new Date().getHours();
  
  if (hour >= 0 && hour < 6) {
    return '凌晨';
  } else if (hour >= 6 && hour < 9) {
    return '早上';
  } else if (hour >= 9 && hour < 12) {
    return '上午';
  } else if (hour >= 12 && hour < 14) {
    return '中午';
  } else if (hour >= 14 && hour < 18) {
    return '下午';
  } else if (hour >= 18 && hour < 22) {
    return '晚上';
  } else {
    return '深夜';
  }
}

/**
 * 格式化日期
 * @param date 日期对象
 * @param format 格式化字符串，默认为 'YYYY-MM-DD'
 * @returns 格式化后的日期字符串
 */
export function formatDate(date: Date, format: string = 'YYYY-MM-DD'): string {
  const year = date.getFullYear();
  const month = date.getMonth() + 1;
  const day = date.getDate();
  const hour = date.getHours();
  const minute = date.getMinutes();
  const second = date.getSeconds();
  
  // 补零函数
  const padZero = (num: number): string => {
    return num < 10 ? `0${num}` : `${num}`;
  };
  
  // 替换格式字符串中的占位符
  return format
    .replace('YYYY', `${year}`)
    .replace('MM', padZero(month))
    .replace('DD', padZero(day))
    .replace('HH', padZero(hour))
    .replace('mm', padZero(minute))
    .replace('ss', padZero(second));
}

/**
 * 获取相对时间描述
 * @param dateTime 目标日期时间
 * @returns 相对时间描述
 */
export function getRelativeTimeDesc(dateTime: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - dateTime.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  
  if (diffSec < 60) {
    return '刚刚';
  }
  
  const diffMin = Math.floor(diffSec / 60);
  if (diffMin < 60) {
    return `${diffMin}分钟前`;
  }
  
  const diffHour = Math.floor(diffMin / 60);
  if (diffHour < 24) {
    return `${diffHour}小时前`;
  }
  
  const diffDay = Math.floor(diffHour / 24);
  if (diffDay < 30) {
    return `${diffDay}天前`;
  }
  
  const diffMonth = Math.floor(diffDay / 30);
  if (diffMonth < 12) {
    return `${diffMonth}个月前`;
  }
  
  const diffYear = Math.floor(diffMonth / 12);
  return `${diffYear}年前`;
}

/**
 * 判断日期是否为今天
 * @param date 日期对象
 * @returns 是否为今天
 */
export function isToday(date: Date): boolean {
  const today = new Date();
  return date.getDate() === today.getDate() &&
    date.getMonth() === today.getMonth() &&
    date.getFullYear() === today.getFullYear();
}

/**
 * 获取当前星期几的中文表示
 * @returns 星期几的中文表示
 */
export function getDayOfWeekChinese(): string {
  const weekDays = ['日', '一', '二', '三', '四', '五', '六'];
  const day = new Date().getDay();
  return `星期${weekDays[day]}`;
}

/**
 * 时间工具类
 */
export class TimeUtils {
  /**
   * 根据当前时间返回问候语
   * @returns 问候语
   */
  static getGreetingByTime(): string {
    const hour = new Date().getHours();
    
    if (hour >= 0 && hour < 6) {
      return '凌晨好';
    } else if (hour >= 6 && hour < 9) {
      return '早上好';
    } else if (hour >= 9 && hour < 12) {
      return '上午好';
    } else if (hour >= 12 && hour < 14) {
      return '中午好';
    } else if (hour >= 14 && hour < 18) {
      return '下午好';
    } else if (hour >= 18 && hour < 22) {
      return '晚上好';
    } else {
      return '深夜好';
    }
  }
  
  /**
   * 获取当天的开始时间
   * @returns 当天开始时间的Date对象
   */
  static getStartOfDay(): Date {
    const date = new Date();
    date.setHours(0, 0, 0, 0);
    return date;
  }
  
  /**
   * 获取当天的结束时间
   * @returns 当天结束时间的Date对象
   */
  static getEndOfDay(): Date {
    const date = new Date();
    date.setHours(23, 59, 59, 999);
    return date;
  }
  
  /**
   * 格式化日期为 YYYY-MM-DD 格式
   * @param date 日期对象
   * @returns 格式化后的日期字符串
   */
  static formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
  
  /**
   * 格式化时间为 HH:MM 格式
   * @param date 日期对象
   * @returns 格式化后的时间字符串
   */
  static formatTime(date: Date): string {
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }
  
  /**
   * 计算两个日期之间的天数差
   * @param date1 第一个日期
   * @param date2 第二个日期
   * @returns 天数差
   */
  static daysBetween(date1: Date, date2: Date): number {
    const oneDay = 24 * 60 * 60 * 1000; // 一天的毫秒数
    const diffTime = Math.abs(date2.getTime() - date1.getTime());
    return Math.round(diffTime / oneDay);
  }
  
  /**
   * 检查日期是否为今天
   * @param date 需要检查的日期
   * @returns 是否为今天
   */
  static isToday(date: Date): boolean {
    const today = new Date();
    return date.getDate() === today.getDate() && 
           date.getMonth() === today.getMonth() && 
           date.getFullYear() === today.getFullYear();
  }
  
  /**
   * 获取相对日期描述（如"今天"、"明天"、"3天后"等）
   * @param date 需要描述的日期
   * @returns 相对日期描述
   */
  static getRelativeDateDescription(date: Date): string {
    const today = new Date();
    const days = TimeUtils.daysBetween(today, date);
    
    if (TimeUtils.isToday(date)) {
      return '今天';
    } else if (days === 1 && date > today) {
      return '明天';
    } else if (days === 2 && date > today) {
      return '后天';
    } else if (days > 0 && days < 7 && date > today) {
      return `${days}天后`;
    } else {
      return TimeUtils.formatDate(date);
    }
  }
} 