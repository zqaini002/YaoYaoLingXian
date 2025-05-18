import router from '@ohos.router';
import { CommonConstants, Dream, DreamSimple } from '../../model/CommonTypes';
import { AppIcons } from '../../utils/IconUtils';
import { getDreamsByUserId, getDreamsByUserIdAndCategory, searchDreams } from '../../services/ApiService';

@Component
export struct DreamPage {
  // 假设当前用户ID为2
  private userId: number = 2;
  @State searchText: string = '';
  @State selectedCategory: string = '全部';
  @State categories: string[] = ['全部', '学习', '健康', '旅行', '创作', '艺术', '职业', '生活技能'];
  @State isDreamsLoading: boolean = false;
  @State isSearchMode: boolean = false;
  
  // 防抖搜索相关
  private searchTimerId: number = -1;
  private readonly SEARCH_DELAY: number = 500; // 搜索延迟时间，单位毫秒
  
  // 初始化空数组，将在页面创建时从API获取真实数据
  @State dreams: Dream[] = [];

  aboutToAppear() {
    this.getData();
  }
  
  onPageShow() {
    // 页面每次显示时刷新数据，以便在创建或编辑梦想后更新列表
    this.getData();
  }
  
  // 防抖搜索处理
  handleSearch(keyword: string) {
    this.searchText = keyword;
    
    // 清除之前的定时器
    if (this.searchTimerId !== -1) {
      clearTimeout(this.searchTimerId);
    }
    
    // 设置新的定时器
    if (keyword.trim().length > 0) {
      this.searchTimerId = setTimeout(() => {
        this.isSearchMode = true;
        this.searchDreams(keyword);
      }, this.SEARCH_DELAY);
    } else {
      this.isSearchMode = false;
      this.getData();
    }
  }
  
  // 执行搜索
  async searchDreams(keyword: string) {
    try {
      this.isDreamsLoading = true;
      const result = await searchDreams(this.userId, keyword);
      this.dreams = result.content;
      console.info(`搜索梦想成功，关键词: ${keyword}, 结果数量: ${this.dreams.length}`);
    } catch (error) {
      console.error(`搜索梦想失败: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      this.isDreamsLoading = false;
    }
  }

  // 获取真实数据的方法
  async getData() {
    try {
      this.isDreamsLoading = true;
      
      if (this.selectedCategory === '全部') {
        // 获取所有梦想
        this.dreams = await getDreamsByUserId(this.userId);
      } else {
        // 获取特定分类的梦想
        this.dreams = await getDreamsByUserIdAndCategory(this.userId, this.selectedCategory);
      }
      
      console.info(`成功获取用户梦想列表，分类: ${this.selectedCategory}, 数量: ${this.dreams.length}`);
    } catch (error) {
      console.error(`获取梦想列表失败: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      this.isDreamsLoading = false;
    }
  }

  // 点击创建新梦想
  navigateToCreateDream() {
    router.pushUrl({
      url: 'pages/dream/DreamEditPage'
    });
  }
  
  // 点击梦想卡片，进入编辑页面
  navigateToEditDream(dreamId: number | undefined) {
    if (dreamId === undefined) {
      console.error('梦想ID为undefined，无法导航到编辑页面');
      return;
    }
    
    router.pushUrl({
      url: 'pages/dream/DreamEditPage',
      params: {
        dreamId: dreamId
      }
    });
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部搜索栏
        Row() {
          Text('我的梦想')
            .fontSize(CommonConstants.FONT_SIZE_XXLARGE)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .padding({ 
          top: CommonConstants.MARGIN_LARGE, 
          bottom: CommonConstants.MARGIN_NORMAL,
          left: CommonConstants.MARGIN_LARGE,
          right: CommonConstants.MARGIN_LARGE
        })
        
        // 搜索框
        Row() {
          Image(AppIcons.search)
            .width(24)
            .height(24)
            .fillColor($r('app.color.text_primary'))
            .margin({ right: CommonConstants.MARGIN_NORMAL })
          
          TextInput({ placeholder: '搜索梦想...', text: this.searchText })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(Color.Transparent)
            .placeholderColor($r('app.color.text_placeholder'))
            .onChange((value: string) => {
              this.handleSearch(value);
            })
        }
        .width('90%')
        .padding({ left: CommonConstants.MARGIN_LARGE, right: CommonConstants.MARGIN_LARGE })
        .borderRadius(CommonConstants.RADIUS_NORMAL)
        .backgroundColor($r('app.color.search_background'))
        .height(50)
        .alignItems(VerticalAlign.Center)
        
        // 分类选择（搜索模式下隐藏）
        if (!this.isSearchMode) {
          Scroll() {
            Row() {
              ForEach(this.categories, (category: string) => {
                Text(category)
                  .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                  .fontColor(this.selectedCategory === category ? 
                    Color.White : $r('app.color.text_primary'))
                  .backgroundColor(this.selectedCategory === category ? 
                    $r('app.color.primary_color') : $r('app.color.category_background'))
                  .borderRadius(CommonConstants.RADIUS_NORMAL)
                  .padding({
                    left: CommonConstants.MARGIN_LARGE,
                    right: CommonConstants.MARGIN_LARGE,
                    top: CommonConstants.MARGIN_NORMAL,
                    bottom: CommonConstants.MARGIN_NORMAL
                  })
                  .margin({ right: CommonConstants.MARGIN_NORMAL })
                  .onClick(() => {
                    if (this.selectedCategory !== category) {
                      this.selectedCategory = category;
                      // 切换分类时重新获取数据
                      this.getData();
                    }
                  })
              })
            }
            .padding({ 
              left: CommonConstants.MARGIN_LARGE, 
              right: CommonConstants.MARGIN_LARGE,
              top: CommonConstants.MARGIN_MEDIUM,
              bottom: CommonConstants.MARGIN_MEDIUM
            })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        } else {
          // 搜索模式下显示搜索提示
          Row() {
            Text('搜索: "' + this.searchText + '"')
              .fontSize(CommonConstants.FONT_SIZE_NORMAL)
              .fontColor($r('app.color.text_secondary'))
            
            Text('取消')
              .fontSize(CommonConstants.FONT_SIZE_NORMAL)
              .fontColor($r('app.color.primary_color'))
              .margin({ left: CommonConstants.MARGIN_LARGE })
              .onClick(() => {
                this.searchText = '';
                this.isSearchMode = false;
                this.getData();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({ 
            left: CommonConstants.MARGIN_LARGE, 
            right: CommonConstants.MARGIN_LARGE,
            top: CommonConstants.MARGIN_MEDIUM,
            bottom: CommonConstants.MARGIN_MEDIUM
          })
        }
        
        // 梦想列表
        if (this.isDreamsLoading) {
          // 加载中状态
          Column() {
            LoadingProgress()
              .color($r('app.color.primary_color'))
              .width(40)
              .height(40)
            
            Text('加载中...')
              .fontSize(CommonConstants.FONT_SIZE_NORMAL)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: CommonConstants.MARGIN_NORMAL })
          }
          .width('100%')
          .height('60%')
          .justifyContent(FlexAlign.Center)
        } else if (this.dreams.length === 0) {
          // 空状态
          Column() {
            Image(AppIcons.emptyState)
              .width(120)
              .height(120)
              .opacity(0.6)
            
            if (this.isSearchMode) {
              Text('未找到相关梦想')
                .fontSize(CommonConstants.FONT_SIZE_LARGE)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: CommonConstants.MARGIN_LARGE })
              
              Text('请尝试其他关键词')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontColor($r('app.color.text_secondary'))
                .opacity(0.8)
                .margin({ top: CommonConstants.MARGIN_SMALL })
            } else {
              Text('暂无梦想')
                .fontSize(CommonConstants.FONT_SIZE_LARGE)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: CommonConstants.MARGIN_LARGE })
              
              Text('点击右上角"+"按钮创建您的第一个梦想')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontColor($r('app.color.text_secondary'))
                .opacity(0.8)
                .margin({ top: CommonConstants.MARGIN_SMALL })
                .textAlign(TextAlign.Center)
            }
          }
          .width('100%')
          .height('60%')
          .justifyContent(FlexAlign.Center)
        } else {
          // 显示梦想列表
          Scroll() {
            Column() {
              ForEach(this.dreams, (dream: Dream) => {
                Column() {
                  Stack({ alignContent: Alignment.BottomStart }) {
                    Image(dream.imageUrl)
                      .width('100%')
                      .height(180)
                      .borderRadius(CommonConstants.RADIUS_NORMAL)
                      .objectFit(ImageFit.Cover)
                    
                    Column() {
                      Row() {
                        Text(dream.title)
                          .fontSize(CommonConstants.FONT_SIZE_LARGE)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(Color.White)
                        
                        Text(dream.category)
                          .fontSize(CommonConstants.FONT_SIZE_SMALL)
                          .fontColor(Color.White)
                          .backgroundColor($r('app.color.category_tag'))
                          .borderRadius(CommonConstants.RADIUS_SMALL)
                          .padding({
                            left: CommonConstants.MARGIN_NORMAL,
                            right: CommonConstants.MARGIN_NORMAL,
                            top: 2,
                            bottom: 2
                          })
                      }
                      .width('100%')
                      .justifyContent(FlexAlign.SpaceBetween)
                      .alignItems(VerticalAlign.Center)
                      
                      Text(dream.description)
                        .fontSize(CommonConstants.FONT_SIZE_SMALL)
                        .fontColor(Color.White)
                        .opacity(0.9)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: CommonConstants.MARGIN_SMALL })
                    }
                    .width('100%')
                    .padding(CommonConstants.MARGIN_MEDIUM)
                    .linearGradient({
                      angle: 180,
                      colors: [
                        [0x00000000, 0.0],
                        [0x99000000, 0.7],
                        [0xDD000000, 1.0]
                      ]
                    })
                    .borderRadius(CommonConstants.RADIUS_NORMAL)
                  }
                  
                  // 进度信息
                  Row() {
                    Column() {
                      Text('当前进度')
                        .fontSize(CommonConstants.FONT_SIZE_SMALL)
                        .fontColor($r('app.color.text_secondary'))
                      
                      Row() {
                        Progress({ value: dream.completionRate, total: 100 })
                          .color($r('app.color.primary_color'))
                          .height(8)
                          .width('85%')
                          .margin({ right: CommonConstants.MARGIN_SMALL })
                        
                        Text(dream.completionRate.toString() + '%')
                          .fontSize(CommonConstants.FONT_SIZE_SMALL)
                          .fontColor($r('app.color.primary_color'))
                          .fontWeight(FontWeight.Bold)
                      }
                      .alignItems(VerticalAlign.Center)
                      .margin({ top: 2 })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    
                    Column() {
                      Text('截止日期')
                        .fontSize(CommonConstants.FONT_SIZE_SMALL)
                        .fontColor($r('app.color.text_secondary'))
                        .textAlign(TextAlign.End)
                      
                      Text(dream.deadline)
                        .fontSize(CommonConstants.FONT_SIZE_SMALL)
                        .fontWeight(FontWeight.Bold)
                        .margin({ top: 2 })
                        .textAlign(TextAlign.End)
                    }
                    .alignItems(HorizontalAlign.End)
                  }
                  .width('100%')
                  .margin({ top: CommonConstants.MARGIN_NORMAL })
                }
                .width('100%')
                .borderRadius(CommonConstants.RADIUS_NORMAL)
                .backgroundColor($r('app.color.card_background'))
                .padding(CommonConstants.MARGIN_MEDIUM)
                .margin({ bottom: CommonConstants.MARGIN_LARGE })
                .onClick(() => {
                  if (dream.id !== undefined) {
                    this.navigateToEditDream(dream.id);
                  } else {
                    console.error('梦想ID为undefined，无法导航到编辑页面');
                  }
                })
              })
            }
            .width('100%')
            .padding({ left: CommonConstants.MARGIN_LARGE, right: CommonConstants.MARGIN_LARGE })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
      
      // 添加浮动按钮
      Button() {
        Row() {
          Image(AppIcons.add)
            .width(24)
            .height(24)
            .fillColor(Color.White)
          
          Text('创建梦想')
            .fontColor(Color.White)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 8 })
        }
      }
      .type(ButtonType.Capsule)
      .backgroundColor($r('app.color.primary_color'))
      .width(140)
      .height(48)
      .margin(16)
      .onClick(() => this.navigateToCreateDream())
    }
    .width('100%')
    .height('100%')
  }
} 