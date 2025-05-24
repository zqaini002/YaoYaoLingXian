# 图标替换指南

## 现有图标资源

目前应用中的图标由两部分组成：
1. 应用本地图标：放置在media目录下的PNG图标文件，目前是占位图标
2. 系统Symbol图标：鸿蒙系统内置的图标库，可直接使用

## 使用方法

### 1. 本地图标（PNG/SVG）

本地图标需要放置在`resources/base/media`目录中，有以下几种使用方式：

#### 方式一：直接使用Image组件

```typescript
Image($r('app.media.icon_name'))
  .width(24)
  .height(24)
  .fillColor($r('app.color.text_primary'))
```

#### 方式二：使用AppIcons常量对象

```typescript
import { AppIcons } from '../utils/IconUtils';

Image(AppIcons.notification)
  .width(24)
  .height(24)
  .fillColor($r('app.color.text_primary'))
```

#### 方式三：使用CommonIcon组件

```typescript
CommonIcon({ 
  name: 'icon_name',
  iconSize: 24,
  color: $r('app.color.text_primary')
})
```

### 2. 系统Symbol图标

鸿蒙系统内置了丰富的Symbol图标库，不需要单独下载图标文件，可直接使用，有以下几种使用方式：

#### 方式一：直接使用SymbolSpan组件

```typescript
Text() {
  SymbolSpan($r('sys.symbol.add'))
    .fontSize(24)
    .fontColor($r('app.color.text_primary'))
}
```

#### 方式二：使用SystemSymbols常量对象和SymbolSpan

```typescript
import { SystemSymbols } from '../utils/IconUtils';

Text() {
  SymbolSpan($r('sys.symbol.' + SystemSymbols.add))
    .fontSize(24)
    .fontColor($r('app.color.text_primary'))
}
```

#### 方式三：使用CommonIcon组件和SystemSymbols常量

```typescript
import { SystemSymbols } from '../utils/IconUtils';

CommonIcon({ 
  name: SystemSymbols.add,
  useSystemSymbol: true,  // 使用系统Symbol图标
  iconSize: 24,
  color: $r('app.color.text_primary')
})
```

## 系统Symbol图标资源

HarmonyOS内置了大量系统图标，可以在以下位置查看完整的图标库：
https://developer.huawei.com/consumer/cn/design/harmonyos-symbol/

常用的系统图标已经在SystemSymbols常量对象中定义，可以直接使用。

## 设计规范

为保持应用界面的一致性和美观，请在设计图标时遵循以下规范：

### 1. 尺寸要求
- 建议图标尺寸为96x96像素（HDPI）
- 确保图标在各种尺寸下都清晰可辨，尤其是小尺寸显示时

### 2. 风格统一
- 使用统一的线条粗细
- 保持统一的颜色风格
- 采用简洁、现代的设计语言
- 遵循鸿蒙系统的设计规范和美学

### 3. 颜色使用
- 主要图标使用应用的主题色: #155BC2
- 选中状态的图标颜色更加鲜明: #155BC2
- 未选中状态可以使用灰色: #6E7074
- 功能图标保持一致的配色方案

### 4. 透明度
- 图标应使用透明背景，保存为PNG格式
- 确保阴影、高光等效果表现良好

## 替换步骤

1. 准备符合上述规范的图标文件
2. 将图标文件命名为与当前占位图标相同的名称（见README.md中的图标列表）
3. 用新图标替换当前占位图标
4. 测试应用中图标的显示效果

## 注意事项

- 不要更改图标的文件名，以免引用失效
- 如果需要添加新图标，请同时更新IconUtils.ts文件和README.md文件
- 为了适应深色模式，可能需要准备不同颜色版本的图标
- 优先考虑使用系统Symbol图标，可以减少应用体积并保持与系统的一致性

## 优化建议

图标资源优化可以考虑以下几点：

- 适当压缩图片以减小应用体积
- 考虑使用SVG格式以获得更好的缩放效果
- 为不同分辨率的设备准备多套图标资源
- 考虑图标在不同背景色上的可见性 