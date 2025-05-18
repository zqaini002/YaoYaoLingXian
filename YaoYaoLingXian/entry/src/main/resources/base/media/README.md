# 图标资源使用说明

## 图标列表

本应用使用SVG格式的图标，以保证在不同分辨率下的显示效果。所有图标都位于 `resources/base/media` 目录下。

### 导航栏图标

导航栏图标包含未选中和选中两种状态：

| 功能 | 未选中状态 | 选中状态 |
|-----|----------|---------|
| 首页 | home.svg | home_selected.svg |
| 梦想 | dream.svg | dream_selected.svg |
| 任务 | task.svg | task_selected.svg |
| 社区 | community.svg | community_selected.svg |
| 我的 | mine.svg | mine_selected.svg |

### 功能图标

| 功能 | 图标文件 |
|-----|---------|
| 添加 | add.svg |
| 搜索 | search.svg |
| 进度 | progress.svg |
| 星标 | star.svg |
| 通知 | notification.svg |
| 设置 | settings.svg |
| 帮助 | help.svg |

## 使用方法

### 在ArkUI中使用图标

1. 使用Image组件加载图标：

```typescript
Image($r('app.media.home'))
  .width(24)
  .height(24)
  .fillColor(Color.Black) // 可以自定义图标颜色
```

2. 使用IconUtils工具类：

```typescript
import { AppIcons, getIconByName } from '../utils/IconUtils';

// 直接使用预定义图标
Image(AppIcons.home)
  .width(24)
  .height(24)
  .fillColor(this.selected ? Color.Blue : Color.Gray)
  
// 通过名称获取图标
Image(getIconByName('home', this.selected))
  .width(24)
  .height(24)
```

3. 使用SystemSymbol系统图标：

```typescript
import { SystemSymbols, getSystemSymbol } from '../utils/IconUtils';

// 使用系统预定义图标
Image($r('sys.symbol.add'))
  .width(24)
  .height(24)
  
// 通过名称获取系统图标
Image(getSystemSymbol(SystemSymbols.add))
  .width(24)
  .height(24)
```

## 注意事项

1. SVG图标使用`currentColor`作为填充色，可以通过Image组件的`.fillColor()`方法动态设置颜色
2. 图标大小统一为24x24，可以根据需要调整显示大小
3. 如需添加新图标，请按照同样的命名规范，并更新IconUtils.ets文件中的AppIcons类

## 图标维护

1. 所有图标应保持统一的设计风格
2. 避免使用光栅图像格式（如PNG），优先使用SVG格式
3. 如果需要修改图标，请更新对应的SVG文件，无需修改代码 