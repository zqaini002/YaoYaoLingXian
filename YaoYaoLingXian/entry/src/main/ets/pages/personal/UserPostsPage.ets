import { Post, PageResponse } from '../../model/CommonTypes';
import * as ApiService from '../../services/ApiService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { MyLoadingProgress } from '../../components/LoadingProgress';
import { UserSession } from '../../utils/auth/UserSession';

// 定义常量
const FONT_SIZE_SMALL: number = 14;
const FONT_SIZE_NORMAL: number = 16;
const FONT_SIZE_LARGE: number = 18;
const PADDING_SMALL: number = 8;
const PADDING_MEDIUM: number = 16;

// 定义路由参数接口
interface RouteParams {
  userId: number;
  username?: string;
  nickname?: string;
}

// 定义操作结果接口
interface OperationResult {
  index: number;
  message?: string;
}

@Entry
@Component
export struct UserPostsPage {
  @State posts: Post[] = [];
  @State isRefreshing: boolean = false;
  @State isLoadingMore: boolean = false;
  @State hasMoreData: boolean = true;
  @State errorMsg: string = '';
  @State currentPage: number = 0;
  @State pageSize: number = 10;
  @State userId: number = 0;
  @State username: string = '';
  @State nickname: string = '';
  @State noDataText: string = '暂无动态内容';
  @State isLogin: boolean = false;
  @State isLoading: boolean = true; // 初始加载状态
  @State isCurrentUser: boolean = false; // 是否为当前登录用户查看自己的动态
  @State isDeleting: boolean = false; // 是否正在删除帖子

  private scroller: Scroller = new Scroller();
  private userSession: UserSession = UserSession.getInstance();

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouteParams;
    console.info('UserPostsPage路由参数:', JSON.stringify(params));
    
    if (params && params.userId) {
      this.userId = params.userId;
      this.username = params.username || '';
      this.nickname = params.nickname || this.username || '用户';
      
      // 检查是否为当前登录用户查看自己的动态
      if (this.userSession.isLoggedIn()) {
        this.isCurrentUser = this.userId === this.userSession.getUserId();
        console.info(`是否为当前用户查看自己的动态: ${this.isCurrentUser}`);
      }
      
      // 加载数据
      this.loadData(true);
    } else {
      this.errorMsg = '无效的用户ID';
      console.error('UserPostsPage: 无效的用户ID');
      this.isLoading = false; // 确保设置isLoading为false以显示错误消息
    }
  }

  /**
   * 加载帖子数据
   * @param refresh 是否刷新（true为下拉刷新，false为加载更多）
   */
  async loadData(refresh: boolean = false) {
    // 移除对isLoading的检查，确保初始加载时能执行
    // if (this.isLoading) return;
    
    try {
      this.isLoading = true;
      if (refresh) {
        this.isRefreshing = true;
        this.currentPage = 0;
      } else {
        this.isLoadingMore = true;
      }
      
      console.info(`加载用户动态: userId=${this.userId}, page=${this.currentPage}, size=${this.pageSize}`);
      
      // 调用API获取用户发布的帖子
      const response = await ApiService.getUserPosts(this.userId, this.currentPage, this.pageSize);
      console.info('获取用户动态响应:', JSON.stringify(response));
      
      if (refresh) {
        this.posts = response.content || [];
      } else {
        this.posts = [...this.posts, ...(response.content || [])];
      }
      
      // 更新分页信息
      this.hasMoreData = !response.last;
      this.currentPage++;
      
      // 清除错误信息
      this.errorMsg = '';
    } catch (error) {
      console.error(`加载用户动态失败: ${error instanceof Error ? error.message : String(error)}`);
      this.errorMsg = `加载失败: ${error instanceof Error ? error.message : String(error)}`;
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
      this.isLoadingMore = false;
    }
  }

  /**
   * 下拉刷新
   */
  onPullDownRefresh() {
    if (this.isRefreshing || this.isLoadingMore) {
      return;
    }
    this.loadData(true);
  }

  /**
   * 加载更多
   */
  onLoadMore() {
    if (this.isRefreshing || this.isLoadingMore || !this.hasMoreData) {
      return;
    }
    this.loadData(false);
  }
  
  /**
   * 显示帖子操作菜单
   */
  showOperationMenu(post: Post) {
    if (!this.isCurrentUser || !post || !post.id) return;
    
    // 避免在删除操作进行时再次显示菜单
    if (this.isDeleting) return;
    
    // 使用提示对话框模拟操作菜单
    // 鸿蒙OS ArkTS API 15 不支持showActionSheet，使用showDialog替代
    promptAction.showDialog({
      title: '帖子操作',
      message: post.title || '选择要执行的操作',
      buttons: [
        {
          text: '编辑',
          color: '#1976d2'
        },
        {
          text: '删除',
          color: '#FF4757'
        },
        {
          text: '取消',
          color: '#666666'
        }
      ]
    })
    .then((result: OperationResult) => {
      // 根据按钮索引执行不同操作
      switch (result.index) {
        case 0: // 编辑
          this.navigateToEditPost(post);
          break;
        case 1: // 删除
          this.showDeleteConfirm(post);
          break;
        default: // 取消
          break;
      }
    })
    .catch((err: Error) => {
      console.error('操作菜单显示失败:', err.message);
    });
  }
  
  /**
   * 显示删除确认对话框
   */
  showDeleteConfirm(post: Post) {
    if (!post || !post.id) return;
    
    promptAction.showDialog({
      title: '确认删除',
      message: '确定要删除这条动态吗？删除后将无法恢复。',
      buttons: [
        {
          text: '取消',
          color: '#666666'
        },
        {
          text: '删除',
          color: '#FF4757'
        }
      ]
    })
    .then((result: OperationResult) => {
      if (result.index === 1) { // 点击了删除按钮
        this.deletePost(post.id);
      }
    })
    .catch((err: Error) => {
      console.error('删除确认对话框显示失败:', err.message);
    });
  }
  
  /**
   * 删除帖子
   */
  async deletePost(postId: number) {
    if (!postId) return;
    
    try {
      this.isDeleting = true;
      
      // 调用API删除帖子
      const result = await ApiService.deletePost(postId);
      
      if (result) {
        // 删除成功，提示用户
        promptAction.showToast({
          message: '删除成功',
          duration: 2000
        });
        
        // 从当前列表中移除被删除的帖子
        this.posts = this.posts.filter(post => post.id !== postId);
        
        // 如果删除后列表为空，显示空状态
        if (this.posts.length === 0) {
          this.noDataText = '暂无动态内容';
        }
      } else {
        // 删除失败
        promptAction.showToast({
          message: '删除失败，请重试',
          duration: 2000
        });
      }
    } catch (error) {
      console.error(`删除帖子失败: ${error instanceof Error ? error.message : String(error)}`);
      
      // 显示错误提示
      promptAction.showToast({
        message: `删除失败: ${error instanceof Error ? error.message : String(error)}`,
        duration: 2000
      });
    } finally {
      this.isDeleting = false;
    }
  }
  
  /**
   * 跳转到编辑帖子页面
   */
  navigateToEditPost(post: Post) {
    if (!post || !post.id) return;
    
    router.pushUrl({
      url: 'pages/community/PostEditPage',
      params: { 
        postId: post.id,
        title: post.title || '',
        content: post.content || '',
        imageUrls: post.imageUrls || [],
        dreamId: post.dream?.id || null
      }
    });
  }

  /**
   * 简化版PostItem组件
   */
  @Builder
  PostItemBuilder(post: Post) {
    Column() {
      // 帖子作者信息
      Row() {
        // 头像
        Image(post.author?.avatar || '')
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#F1F3F5')
        
        // 用户名和时间
        Column() {
          Text(post.author?.nickname || post.author?.username || '未知用户')
            .fontSize(FONT_SIZE_NORMAL)
            .fontWeight(FontWeight.Medium)
          
          Text(post.createdAt || '')
            .fontSize(FONT_SIZE_SMALL)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        .layoutWeight(1)
        
        // 操作菜单按钮 - 仅当是当前用户查看自己的动态时显示
        if (this.isCurrentUser && post.id) {
          Text('⋮')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .onClick((event) => {
              // 在鸿蒙OS ArkTS API15中，ClickEvent没有stopPropagation方法
              // 使用合成事件或其他方法隔离点击事件
              this.showOperationMenu(post);
            })
        }
      }
      .width('100%')
      .padding(PADDING_MEDIUM)
      
      // 帖子内容
      Column() {
        // 帖子标题
        if (post.title) {
          Text(post.title)
            .fontSize(FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })
            .width('100%')
        }
        
        // 帖子内容
        if (post.content) {
          Text(post.content)
            .fontSize(FONT_SIZE_NORMAL)
            .margin({ bottom: 8 })
            .width('100%')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        
        // 帖子图片
        if (post.imageUrls && post.imageUrls.length > 0) {
          Grid() {
            ForEach(post.imageUrls.slice(0, 3), (imgUrl: string) => {
              GridItem() {
                Image(imgUrl)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(4)
                  .width('100%')
                  .aspectRatio(1)
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr')
          .columnsGap(5)
          .rowsGap(5)
          .width('100%')
          .height(post.imageUrls.length <= 3 ? 90 : 185)
          .margin({ bottom: 8 })
        }
        
        // 帖子互动数据
        Row() {
          // 点赞
          Row() {
            Image($r('app.media.like'))
              .width(16)
              .height(16)
              .fillColor('#999999')
              .margin({ right: 4 })
            
            Text(post.likeCount?.toString() || '0')
              .fontSize(FONT_SIZE_SMALL)
              .fontColor('#999999')
          }
          .margin({ right: PADDING_MEDIUM })
          
          // 评论
          Row() {
            Image($r('app.media.comment'))
              .width(16)
              .height(16)
              .fillColor('#999999')
              .margin({ right: 4 })
            
            Text(post.commentCount?.toString() || '0')
              .fontSize(FONT_SIZE_SMALL)
              .fontColor('#999999')
          }
          .margin({ right: PADDING_MEDIUM })
          
          // 浏览量
          Row() {
            Image($r('app.media.view'))
              .width(16)
              .height(16)
              .fillColor('#999999')
              .margin({ right: 4 })
            
            Text(post.viewCount?.toString() || '0')
              .fontSize(FONT_SIZE_SMALL)
              .fontColor('#999999')
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .padding({ left: PADDING_MEDIUM, right: PADDING_MEDIUM, bottom: PADDING_MEDIUM })
    }
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 10 })
    .width('100%')
  }
  
  /**
   * 简化版RefreshFooter组件
   */
  @Builder
  RefreshFooterBuilder(hasMore: boolean, isLoading: boolean) {
    Row() {
      if (isLoading) {
        MyLoadingProgress()
          .width(20)
          .height(20)
          .margin({ right: 8 })
        
        Text('正在加载...')
          .fontSize(FONT_SIZE_SMALL)
          .fontColor('#999999')
      } else if (!hasMore) {
        Text('没有更多内容了')
          .fontSize(FONT_SIZE_SMALL)
          .fontColor('#999999')
      }
    }
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Stack() {
      // 内容区域
      Column() {
        // 顶部标题栏
        Row() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .margin({ right: 16 })
            .onClick(() => {
              router.back();
            })
          
          Text(`${this.nickname}的动态`)
            .fontSize(FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .padding({ left: PADDING_MEDIUM, right: PADDING_MEDIUM })
        .backgroundColor(Color.White)
        
        // 内容列表
        if (!this.isLoading) {
          if (this.posts.length > 0) {
            Refresh({ refreshing: $$this.isRefreshing, offset: 120 }) {
              List({ scroller: this.scroller }) {
                ForEach(this.posts, (post: Post, index: number) => {
                  ListItem() {
                    this.PostItemBuilder(post)
                  }
                  .padding({ 
                    bottom: index === this.posts.length - 1 ? 80 : 0 
                  })
                  .onClick(() => {
                    // 点击帖子跳转到详情页
                    router.pushUrl({
                      url: 'pages/community/PostDetailPage',
                      params: { postId: post.id }
                    });
                  })
                })
                
                // 底部加载更多
                ListItem() {
                  if (this.posts.length > 0) {
                    this.RefreshFooterBuilder(this.hasMoreData, this.isLoadingMore)
                  }
                }
              }
              .width('100%')
              .divider({ strokeWidth: 0.5, color: Color.Gray })
              .onReachEnd(() => {
                this.onLoadMore();
              })
            }
            .onRefreshing(() => {
              this.onPullDownRefresh();
            })
          } else {
            // 空状态
            Column() {
              Image($r('app.media.ic_empty_state'))
                .width(120)
                .height(120)
                .opacity(0.6)
                .margin({ bottom: 16 })
              
              Text(this.errorMsg || this.noDataText)
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .height('80%')
            .justifyContent(FlexAlign.Center)
          }
        } else {
          // 加载状态
          Column() {
            MyLoadingProgress()
              .width(30)
              .height(30)
              .margin({ bottom: 16 })
            
            Text('加载中...')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .height('80%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      
      // 错误提示
      if (this.errorMsg && !this.isLoading) {
        Column() {
          Text(this.errorMsg)
            .fontSize(16)
            .fontColor(Color.White)
        }
        .padding(16)
        .backgroundColor('#FF0000')
        .borderRadius(8)
        .position({
          x: '50%',
          y: 100
        })
        .translate({ x: '-50%' })
        .opacity(0.9)
      }
    }
    .width('100%')
    .height('100%')
  }
} 