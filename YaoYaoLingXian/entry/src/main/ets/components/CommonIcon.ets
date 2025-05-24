/**
 * 通用图标组件，支持系统图标和自定义图标
 */
import { CommonConstants } from '../model/CommonTypes';
import { SystemIcon } from './SystemIcon';

@Component
export struct CommonIcon {
  // 图标名称
  name?: string = '';
  // 是否使用系统图标
  useSystemSymbol: boolean = false;
  // 是否选中状态
  selected: boolean = false;
  // 图标大小
  iconSize?: number = 24;
  // 图标颜色
  color?: ResourceColor = '#333333';
  // 选中状态颜色
  selectedColor?: ResourceColor = CommonConstants.COLOR_PRIMARY;

  build() {
    if (this.useSystemSymbol) {
      Column() {
        SystemIcon({
          name: this.name,
          selected: this.selected,
          iconSize: this.iconSize,
          color: this.selected ? this.selectedColor : this.color,
        })
      }
    } else {
      // 因为现在没有真实图标资源，使用SystemIcon代替
      Column() {
        SystemIcon({
          name: this.name,
          selected: this.selected,
          iconSize: this.iconSize,
          color: this.selected ? this.selectedColor : this.color,
        })
      }
      // 实际项目中图标存在时应该使用下面的代码：
      // Image(this.name ? $r('app.media.' + this.name) : $r('app.media.ic_default'))
      //   .width(this.iconSize)
      //   .height(this.iconSize)
      //   .fillColor(this.selected ? this.selectedColor : this.color)
    }
  }
} 