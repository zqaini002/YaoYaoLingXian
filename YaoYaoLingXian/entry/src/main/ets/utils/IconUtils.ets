/**
 * 图标资源工具类
 * 用于统一管理应用中的图标资源引用
 */

// 自定义Resource类型，避免导入系统模块
export type ResourceStr = PixelMap | Resource | string;

// 定义图标映射类
export class IconMapping {
  defaultIcon = $r('app.media.default_icon');
}

/**
 * 应用图标工具类
 */
export class AppIcons {
  // 通用图标
  static readonly back: string = '/common/icons/back.png';
  static readonly home: string = '/common/icons/home.png';
  static readonly task: string = '/common/icons/task.png';
  static readonly dream: string = '/common/icons/dream.png';
  static readonly discover: string = '/common/icons/discover.png';
  static readonly mine: string = '/common/icons/mine.png';
  static readonly add: string = '/common/icons/add.png';
  static readonly delete: string = '/common/icons/delete.png';
  static readonly edit: string = '/common/icons/edit.png';
  static readonly search: string = '/common/icons/search.png';
  static readonly done: string = '/common/icons/done.png';
  static readonly calendar: string = '/common/icons/calendar.png';
  static readonly time: string = '/common/icons/time.png';
  static readonly error: string = '/common/icons/error.png';
  static readonly empty: string = '/common/icons/empty.png';
  static readonly image: string = '/common/icons/image.png';  // 添加图片图标
  static readonly tag: string = '/common/icons/tag.png';  // 添加标签图标
  
  // 任务相关图标
  static readonly target: string = '/common/icons/target.png';
  static readonly clock: string = '/common/icons/clock.png';
  static readonly arrowRight: string = '/common/icons/arrow_right.png';
  static readonly attachment: string = '/common/icons/attachment.png';

  // 徽章图标
  static readonly badge_beginner: string = '/common/icons/badge_beginner.png';
  static readonly badge_consistent: string = '/common/icons/badge_consistent.png';
  static readonly badge_explorer: string = '/common/icons/badge_explorer.png';
  static readonly badge_locked: string = '/common/icons/badge_locked.png';
  static readonly like: string = '/common/icons/like.png';
  static readonly close: string = '/common/icons/close.png';

  // 梦想相关图标
  static readonly star_icon: string = '/common/icons/star.png';
  static readonly heart: string = '/common/icons/heart.png';
  
  // 导航图标
  static readonly user: Resource = $r('app.media.mine'); // 使用mine作为user
  static readonly community: Resource = $r('app.media.community');
  
  // 导航选中状态图标
  static readonly home_selected: Resource = $r('app.media.home_selected');
  static readonly task_selected: Resource = $r('app.media.task_selected');
  static readonly dream_selected: Resource = $r('app.media.dream_selected');
  static readonly community_selected: Resource = $r('app.media.community_selected');
  static readonly mine_selected: Resource = $r('app.media.mine_selected');
  
  // 功能图标
  static readonly add_post: Resource = $r('app.media.add_post');
  static readonly view: Resource = $r('app.media.view');
  static readonly like_filled: Resource = $r('app.media.like_filled');
  static readonly progress: Resource = $r('app.media.progress');
  static readonly star: Resource = $r('app.media.star');
  static readonly help: Resource = $r('app.media.help');
  static readonly check: Resource = $r('app.media.check');
  static readonly comment: Resource = $r('app.media.comment');
  static readonly share: Resource = $r('app.media.share');
  static readonly notification: Resource = $r('app.media.notification');
  static readonly date: Resource = $r('app.media.calendar'); // 使用日历图标替代
  static readonly settings: Resource = $r('app.media.settings');
  static readonly emptyState: Resource = $r('app.media.ic_empty_task'); // 修改为任务空状态图标
  static readonly default_icon: Resource = $r('app.media.default_icon');
}

/**
 * 系统图标名称常量
 */
export class SystemSymbols {
  // 常用系统图标
  static readonly add: string = 'add';
  static readonly search: string = 'search';
  static readonly back: string = 'arrow_left';
  static readonly close: string = 'close';
  static readonly check: string = 'checkmark';
  static readonly more: string = 'menu';
  static readonly settings: string = 'settings';
  static readonly edit: string = 'edit';
  static readonly delete: string = 'delete';
  static readonly share: string = 'share';
  static readonly like: string = 'heart';
  static readonly star: string = 'star';
  static readonly download: string = 'download';
  static readonly menu: string = 'menu';
}

/**
 * 根据名称获取图标资源 - 导航栏专用方法
 * 由于ArkTS限制，不能使用动态字符串拼接资源路径，此方法专为导航栏设计
 * @param name 图标名称
 * @param selected 是否选中状态
 * @returns 图标资源
 */
export function getNavIconByName(name: string, selected: boolean = false): ResourceStr {
  if (name === '首页' || name === 'home') {
    return selected ? AppIcons.home_selected : AppIcons.home;
  } else if (name === '梦想' || name === 'dream') {
    return selected ? AppIcons.dream_selected : AppIcons.dream;
  } else if (name === '任务' || name === 'task') {
    return selected ? AppIcons.task_selected : AppIcons.task;
  } else if (name === '社区' || name === 'community') {
    return selected ? AppIcons.community_selected : AppIcons.community;
  } else if (name === '我的' || name === 'mine') {
    return selected ? AppIcons.mine_selected : AppIcons.mine;
  } else {
    return AppIcons.default_icon;
  }
}

/**
 * 根据名称获取功能图标
 * @param name 图标名称
 * @returns 图标资源
 */
export function getFunctionIconByName(name: string): ResourceStr {
  switch (name.toLowerCase()) {
    case 'add': return AppIcons.add;
    case 'search': return AppIcons.search;
    case 'progress': return AppIcons.progress;
    case 'star': return AppIcons.star;
    case 'notification': return AppIcons.notification;
    case 'settings': return AppIcons.settings;
    case 'help': return AppIcons.help;
    case 'check': return AppIcons.check;
    // 徽章图标
    case 'badge_beginner': return AppIcons.badge_beginner;
    case 'badge_consistent': return AppIcons.badge_consistent;
    case 'badge_explorer': return AppIcons.badge_explorer;
    case 'badge_locked': return AppIcons.badge_locked;
    // 交互图标
    case 'arrowRight': return AppIcons.arrowRight;
    case 'add_post': return AppIcons.add_post;
    case 'view': return AppIcons.view;
    case 'like': return AppIcons.like;
    case 'like_filled': return AppIcons.like_filled;
    case 'comment': return AppIcons.comment;
    case 'share': return AppIcons.share;
    case 'calendar': return AppIcons.calendar;
    default: return AppIcons.default_icon;
  }
}

/**
 * 根据名称获取图标资源
 * @param name 图标名称
 * @param selected 是否选中状态
 * @returns 图标资源
 */
export function getIconByName(name: string, selected: boolean = false): ResourceStr {
  // 处理导航栏图标特殊情况
  if (['首页', '梦想', '任务', '社区', '我的', 'home', 'dream', 'task', 'community', 'mine'].includes(name)) {
    return getNavIconByName(name, selected);
  }
  
  // 处理其他图标
  return getFunctionIconByName(name);
}

/**
 * 获取系统图标资源（由于ArkTS限制，已重新实现为静态映射）
 * @param symbolName 系统图标名称
 * @returns 系统图标资源或默认图标
 */
export function getSystemSymbol(symbolName: string): ResourceStr {
  switch (symbolName) {
    // 导航和功能图标，现在返回我们自己的图标作为替代
    case 'add': return AppIcons.add;
    case 'search': return AppIcons.search;
    case 'arrow_left': return AppIcons.arrowRight; // 使用箭头替代
    case 'close': return AppIcons.default_icon;
    case 'checkmark': return AppIcons.check;
    case 'menu': return AppIcons.default_icon;
    case 'settings': return AppIcons.settings;
    case 'edit': return AppIcons.default_icon;
    case 'delete': return AppIcons.default_icon;
    case 'share': return AppIcons.share;
    case 'heart': return AppIcons.like;
    case 'star': return AppIcons.star;
    case 'download': return AppIcons.default_icon;
    default: return AppIcons.default_icon;
  }
}

/**
 * 判断图标是否存在（因ArkTS限制，改为直接返回匹配结果）
 * @param name 图标名称
 * @returns 是否存在
 */
export function hasIcon(name: string): boolean {
  const icon = getFunctionIconByName(name); 
  return icon !== AppIcons.default_icon;
}

/**
 * 判断系统图标是否存在（因ArkTS限制，不再进行动态尝试）
 * @param symbolName 系统图标名称
 * @returns 是否存在
 */
export function hasSystemSymbol(symbolName: string): boolean {
  const systemIcons = ['add', 'search', 'arrow_left', 'close', 'checkmark', 
                      'menu', 'settings', 'edit', 'delete', 'share', 
                      'heart', 'star', 'download'];
  return systemIcons.includes(symbolName);
}

/**
 * 根据名称获取图标资源的直接引用
 * 这个函数在实际开发中应被弃用，因为ArkTS不支持动态引用资源
 * @param name 图标名称
 * @returns 资源直接引用
 */
export function getIconResource(name: string): ResourceStr {
  // 使用SystemIcon组件而不是直接引用资源
  return AppIcons.default_icon;
}