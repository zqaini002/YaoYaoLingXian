import { AppIcons, type ResourceStr } from '../utils/IconUtils';
import { CommonConstants } from '../model/CommonTypes';

// 定义TabItem接口，解决对象字面量类型错误
interface TabItem {
  name: string;
  icon: ResourceStr;
  iconSelected: ResourceStr;
}

@Component
export struct TabBar {
  @Link selectedIndex: number;
  private tabItems: TabItem[] = [
    {
      name: '首页',
      icon: AppIcons.home,
      iconSelected: AppIcons.home_selected
    },
    {
      name: '梦想',
      icon: AppIcons.dream,
      iconSelected: AppIcons.dream_selected
    },
    {
      name: '任务',
      icon: AppIcons.task,
      iconSelected: AppIcons.task_selected
    },
    {
      name: '社区',
      icon: AppIcons.community,
      iconSelected: AppIcons.community_selected
    },
    {
      name: '我的',
      icon: AppIcons.mine,
      iconSelected: AppIcons.mine_selected
    }
  ];

  build() {
    Tabs({
      barPosition: BarPosition.End,
      controller: new TabsController()
    }) {
      ForEach(this.tabItems, (item: TabItem, index: number) => {
        TabContent() {
          // 通过索引切换页面
        }
        .tabBar(this.TabBuilder(item.name, index, item.icon, item.iconSelected))
      })
    }
    .onChange((index: number) => {
      this.selectedIndex = index;
    })
    .width('100%')
    .backgroundColor($r('app.color.tab_bar_background'))
  }

  @Builder
  TabBuilder(name: string, index: number, icon: ResourceStr, iconSelected: ResourceStr) {
    Column() {
      Image(this.selectedIndex === index ? iconSelected : icon)
        .width(24)
        .height(24)
        .fillColor(this.selectedIndex === index ? $r('app.color.primary_color') : $r('app.color.text_secondary'))
        .margin({ bottom: 4 })
      Text(name)
        .fontSize(CommonConstants.FONT_SIZE_SMALL)
        .fontColor(this.selectedIndex === index ? $r('app.color.primary_color') : $r('app.color.text_secondary'))
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.selectedIndex = index;
    })
  }
}