/**
 * 系统图标组件
 * 由于ArkUI限制，临时使用Text组件模拟图标
 */
import { CommonConstants } from '../model/CommonTypes';

/**
 * 图标字符映射类型
 */
export type IconMappingType = Record<string, string>;

/**
 * 图标映射常量类
 */
class IconConstants {
  static readonly ICON_HOME: string = '⌂';
  static readonly ICON_ADD: string = '+';
  static readonly ICON_SEARCH: string = '🔍';
  static readonly ICON_CALENDAR: string = '📅';
  static readonly ICON_TASK: string = '✓';
  static readonly ICON_DREAM: string = '★';
  static readonly ICON_COMMUNITY: string = '👥';
  static readonly ICON_USER: string = '👤';
  static readonly ICON_MINE: string = '👤';
  static readonly ICON_DELETE: string = '🗑';
  static readonly ICON_EDIT: string = '✎';
  static readonly ICON_SHARE: string = '↗';
  static readonly ICON_LIKE: string = '♥';
  static readonly ICON_COMMENT: string = '💬';
  static readonly ICON_NOTIFICATION: string = '🔔';
  static readonly ICON_SETTINGS: string = '⚙';
  static readonly ICON_ARROW_RIGHT: string = '→';
  static readonly ICON_VIEW: string = '👁';
  static readonly ICON_PROGRESS: string = '▶';
  static readonly ICON_STAR: string = '★';
  static readonly ICON_HELP: string = '?';
  static readonly ICON_CHECK: string = '✓';
  static readonly ICON_CLOSE: string = '✕';
  static readonly ICON_TIME: string = '⏱';
  static readonly ICON_LOCATION: string = '📍';
  static readonly ICON_MENU: string = '☰';
  static readonly ICON_DEFAULT: string = '●';
}

@Component
export struct SystemIcon {
  // 图标名称
  name?: string = '';
  // 是否选中状态
  selected: boolean = false;
  // 图标大小
  iconSize?: number = 24;
  // 图标颜色
  color?: ResourceColor = '#333333';
  // 选中状态颜色
  selectedColor?: ResourceColor = CommonConstants.COLOR_PRIMARY;

  // 将图标名称映射为字符
  private getIconChar(): string {
    switch (this.name) {
      case 'home': return IconConstants.ICON_HOME;
      case 'add': return IconConstants.ICON_ADD;
      case 'search': return IconConstants.ICON_SEARCH;
      case 'calendar': return IconConstants.ICON_CALENDAR;
      case 'task': return IconConstants.ICON_TASK;
      case 'dream': return IconConstants.ICON_DREAM;
      case 'community': return IconConstants.ICON_COMMUNITY;
      case 'user': return IconConstants.ICON_USER;
      case 'mine': return IconConstants.ICON_MINE;
      case 'delete': return IconConstants.ICON_DELETE;
      case 'edit': return IconConstants.ICON_EDIT;
      case 'share': return IconConstants.ICON_SHARE;
      case 'like': return IconConstants.ICON_LIKE;
      case 'comment': return IconConstants.ICON_COMMENT;
      case 'notification': return IconConstants.ICON_NOTIFICATION;
      case 'settings': return IconConstants.ICON_SETTINGS;
      case 'arrow_right': return IconConstants.ICON_ARROW_RIGHT;
      case 'view': return IconConstants.ICON_VIEW;
      case 'progress': return IconConstants.ICON_PROGRESS;
      case 'star': return IconConstants.ICON_STAR;
      case 'help': return IconConstants.ICON_HELP;
      case 'check': return IconConstants.ICON_CHECK;
      case 'close': return IconConstants.ICON_CLOSE;
      case 'time': return IconConstants.ICON_TIME;
      case 'location': return IconConstants.ICON_LOCATION;
      case 'menu': return IconConstants.ICON_MENU;
      default: return IconConstants.ICON_DEFAULT;
    }
  }

  build() {
    // 使用Text显示图标字符
    Text(this.getIconChar())
      .width(this.iconSize)
      .height(this.iconSize)
      .fontSize(this.iconSize)
      .fontColor(this.selected ? this.selectedColor : this.color)
      .textAlign(TextAlign.Center)
  }
} 