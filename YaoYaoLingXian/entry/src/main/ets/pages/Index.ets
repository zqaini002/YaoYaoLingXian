import { TabBar } from '../components/TabBar';
import { HomePage } from './home/HomePage';
import { DreamPage } from './dream/DreamPage';
import { TaskPage } from './task/TaskPage';
import { CommunityPage } from './community/CommunityPage';
import { MinePage } from './personal/MinePage';

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;

  build() {
    Column() {
      // 主内容区域 - 使用Flex布局控制空间
      Flex({ direction: FlexDirection.Column }) {
        Swiper() {
          HomePage()
          DreamPage()
          TaskPage()
          CommunityPage()
          MinePage()
        }
        .index(this.selectedIndex)
        .indicator(false)
        .loop(false)
        .duration(300)
        .onChange((index: number) => {
          this.selectedIndex = index;
        })
        .width('100%')
        .flexGrow(1)
      }
      .width('100%')
      .height('calc(100% - 60px)') // 减去导航栏高度

      // 底部导航栏
      TabBar({ selectedIndex: $selectedIndex })
        .height(40)
        .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
  }
}