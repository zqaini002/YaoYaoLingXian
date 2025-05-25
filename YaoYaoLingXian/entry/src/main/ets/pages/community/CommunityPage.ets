import { AppIcons } from '../../utils/IconUtils';
import { CommonConstants, Post, ApiResponse, PageResponse, Comment } from '../../model/CommonTypes';
import http from '@ohos.net.http';
import * as ApiService from '../../services/ApiService';
import promptAction from '@ohos.promptAction';
import refresh from '@ohos.app.ability.common';
import router from '@ohos.router';
// 鸿蒙API15中使用正确的导入路径
import inputEvent from '@ohos.multimodalInput.inputEvent';
import { UserSession } from '../../utils/auth/UserSession';

// 空接口，不再定义不支持的方法
interface ClickEvent {
  // 在ArkTS API15中直接返回true来阻止事件冒泡
}

@Component
export struct CommunityPage {
  @State searchText: string = '';
  @State selectedTab: number = 0;
  @State tabs: string[] = ['推荐', '关注', '热门'];
  @State posts: Post[] = [];
  @State loading: boolean = false;
  @State dataError: string = '';
  @State currentPage: number = 0;
  @State hasMore: boolean = true;
  @State isRefreshing: boolean = false;
  
  // 评论相关状态
  @State showCommentDialog: boolean = false;
  @State currentPostId: number = 0;
  @State commentText: string = '';
  @State commentLoading: boolean = false;
  @State comments: Comment[] = [];
  
  // 当前登录用户ID
  @State currentUserId: number = 0;

  aboutToAppear() {
    // 获取当前用户ID
    const userSession = UserSession.getInstance();
    if (userSession.isLoggedIn()) {
      this.currentUserId = userSession.getUserId();
    }
    
    this.fetchPosts();
  }

  // 获取帖子数据
  async fetchPosts(refresh: boolean = true) {
    if (refresh) {
      this.currentPage = 0;
      this.hasMore = true;
    }

    if (!this.hasMore || this.loading) {
      return;
    }

    try {
      this.loading = true;
      this.dataError = '';
      
      console.info(`开始获取社区帖子, 页码=${this.currentPage}, 分类=${this.tabs[this.selectedTab]}`);

      // 传递当前用户ID，用于获取关注状态
      const result: PageResponse<Post> = await ApiService.getPosts(this.currentPage, 10, this.selectedTab, this.currentUserId);
      console.info(`获取到社区帖子数据: 总数=${result.content?.length || 0}, 总页数=${result.totalPages}`);
      
      if (refresh) {
        this.posts = result.content || [];
      } else {
        this.posts = this.posts.concat(result.content || []);
      }
      this.hasMore = !result.last;
      this.currentPage++;
      
      console.info(`社区帖子数据处理完成, 当前列表长度=${this.posts.length}, 是否有更多=${this.hasMore}`);
      
      // 调试日志：帖子数据检查
      if (this.posts.length > 0) {
        const firstPost = this.posts[0];
        console.info(`第一条帖子信息: ID=${firstPost.id}, 标题=${firstPost.title}, 图片=${firstPost.imageUrls?.length || 0}张`);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.dataError = `加载数据出错: ${errorMessage}`;
      console.error(`获取帖子数据错误: ${errorMessage}`);
      
      // 显示提示
      promptAction.showToast({
        message: this.dataError,
        duration: 3000
      });
    } finally {
      this.loading = false;
    }
  }

  // 处理点赞
  async handleLike(post: Post) {
    try {
      if (post.isLiked) {
        await ApiService.unlikePost(post.id);
        post.likeCount = Math.max(0, post.likeCount - 1);
      } else {
        await ApiService.likePost(post.id);
        post.likeCount++;
      }
      post.isLiked = !post.isLiked;
    } catch (error) {
      console.error(`点赞操作失败: ${error instanceof Error ? error.message : String(error)}`);
      // 创建提示配置对象
      interface ToastOptions {
        message: string;
        duration: number;
      }
      
      const toastOptions: ToastOptions = {
        message: `操作失败: ${error instanceof Error ? error.message : String(error)}`,
        duration: 2000
      };
      
      promptAction.showToast(toastOptions);
    }
  }

  // 打开评论对话框
  async openCommentDialog(postId: number) {
    this.currentPostId = postId;
    this.commentText = '';
    this.showCommentDialog = true;
    
    try {
      this.commentLoading = true;
      this.comments = await ApiService.getPostComments(postId, 0, 20);
    } catch (error) {
      console.error(`获取评论失败: ${error instanceof Error ? error.message : String(error)}`);
      promptAction.showToast({
        message: `获取评论失败: ${error instanceof Error ? error.message : String(error)}`,
        duration: 2000
      });
    } finally {
      this.commentLoading = false;
    }
  }

  // 提交评论
  async submitComment() {
    if (!this.commentText.trim()) {
      promptAction.showToast({
        message: '评论内容不能为空',
        duration: 2000
      });
      return;
    }
    
    try {
      this.commentLoading = true;
      
      // 定义评论请求参数接口
      interface CommentRequest {
        id: number;
        postId: number;
        userId: number;
        content: string;
        createdAt: string;
        parentId: number;
        username: string;  // 修正属性名为username
        avatar: string;
        likeCount: number;
        replyCount: number;
      }
      
      // 创建评论对象
      const comment: CommentRequest = {
        id: 0,
        postId: this.currentPostId,
        userId: 0, // 后端会从当前认证用户中获取
        content: this.commentText,
        createdAt: new Date().toISOString(),
        parentId: 0,
        username: '',  // 使用正确的属性名
        avatar: '',
        likeCount: 0,
        replyCount: 0
      };
      
      const newComment: Comment = await ApiService.createComment(this.currentPostId, comment as Comment);
      
      // 使用concat方法替代展开运算符
      this.comments = [newComment].concat(this.comments);
      this.commentText = '';
      
      // 更新帖子的评论数
      const post = this.posts.find(p => p.id === this.currentPostId);
      if (post) {
        post.commentCount++;
      }
      
      promptAction.showToast({
        message: '评论成功',
        duration: 2000
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error(`发表评论失败: ${errorMessage}`);
      promptAction.showToast({
        message: `发表评论失败: ${errorMessage}`,
        duration: 2000
      });
    } finally {
      this.commentLoading = false;
    }
  }

  // 加载更多数据
  loadMoreData() {
    if (!this.loading && this.hasMore) {
      this.fetchPosts(false);
    }
  }

  // 处理关注用户
  async handleFollow(authorId: number) {
    console.info(`开始处理关注操作: authorId=${authorId}, currentUserId=${this.currentUserId}`);
    
    if (!this.currentUserId) {
      promptAction.showToast({
        message: '请先登录再进行操作',
        duration: 2000
      });
      console.error('未登录，无法关注用户');
      return;
    }
    
    try {
      // 找到所有包含该作者的帖子
      const postsWithAuthor = this.posts.filter(post => post.author?.id === authorId);
      if (postsWithAuthor.length === 0) {
        console.error(`未找到该作者(${authorId})的帖子`);
        return;
      }
      
      // 获取当前关注状态
      const isFollowed = postsWithAuthor[0].author?.isFollowed;
      console.info(`当前关注状态: ${isFollowed ? '已关注' : '未关注'}`);
      
      if (isFollowed) {
        // 如果已关注，则取消关注
        console.info(`准备取消关注: ${this.currentUserId} -> ${authorId}`);
        await ApiService.unfollowUser(this.currentUserId, authorId);
        console.info('取消关注API调用成功');
        promptAction.showToast({
          message: '已取消关注',
          duration: 2000
        });
      } else {
        // 如果未关注，则关注
        console.info(`准备关注用户: ${this.currentUserId} -> ${authorId}`);
        await ApiService.followUser(this.currentUserId, authorId);
        console.info('关注用户API调用成功');
        promptAction.showToast({
          message: '关注成功',
          duration: 2000
        });
      }
      
      // 更新所有包含该作者的帖子的关注状态
      this.posts.forEach(post => {
        if (post.author?.id === authorId) {
          if (post.author) {
            post.author.isFollowed = !isFollowed;
          }
        }
      });
      console.info(`已更新UI关注状态为: ${!isFollowed ? '已关注' : '未关注'}`);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error(`关注操作失败: ${errorMessage}`);
      
      // 显示详细错误信息
      promptAction.showToast({
        message: `操作失败: ${errorMessage}`,
        duration: 3000
      });
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶部标题栏
        Row() {
          Text('梦想社区')
            .fontSize(CommonConstants.FONT_SIZE_XXLARGE)
            .fontWeight(FontWeight.Bold)
          
          Image(AppIcons.add)
            .width(24)
            .height(24)
            .fillColor($r('app.color.text_primary'))
            .margin({ left: CommonConstants.MARGIN_LARGE })
            .onClick(() => {
              // 导航到发布帖子页面
              router.pushUrl({
                url: 'pages/community/PostCreatePage'
              });
            })
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
        
        // 自定义标签栏
        Row() {
          ForEach(this.tabs, (tabName: string, index: number) => {
            Column() {
              Text(tabName)
                .fontSize(CommonConstants.FONT_SIZE_MEDIUM)
                .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedTab === index ? $r('app.color.primary_color') : $r('app.color.text_primary'))
                .margin({ top: CommonConstants.MARGIN_SMALL, bottom: CommonConstants.MARGIN_SMALL })
              
              Divider()
                .width('60%')
                .height(3)
                .backgroundColor(this.selectedTab === index ? $r('app.color.primary_color') : 'transparent')
            }
            .width('33.3%') // 三等分宽度
            .height(48)
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              if (this.selectedTab !== index) {
                this.selectedTab = index;
                this.fetchPosts();
              }
            })
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        
        // 内容区域
        Stack({ alignContent: Alignment.TopStart }) {
          ForEach(this.tabs, (tabName: string, index: number) => {
            if (this.selectedTab === index) {
              this.postList()
            }
          })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      
      // 添加浮动按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.add'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
      }
      .width(56)
      .height(56)
      .backgroundColor($r('app.color.primary_color'))
      .position({
        x: '82%',
        y: '85%'
      })
      .shadow({
        radius: 8,
        color: '#33000000',
        offsetX: 2,
        offsetY: 4
      })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/community/PostCreatePage'
        });
      })
      
      // 评论对话框
      if (this.showCommentDialog) {
        this.CommentDialog()
      }
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  postList() {
    Column() {
      // 添加刷新提示和按钮
      if (this.isRefreshing) {
        Row() {
          LoadingProgress()
            .width(24)
            .height(24)
            .margin({ right: CommonConstants.MARGIN_SMALL })
          Text('正在刷新...')
            .fontSize(CommonConstants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: CommonConstants.MARGIN_MEDIUM, bottom: CommonConstants.MARGIN_MEDIUM })
      } else {
        Row() {
          Text('下拉刷新')
            .fontSize(CommonConstants.FONT_SIZE_SMALL)
            .fontColor($r('app.color.text_tertiary'))
            .onClick(() => {
              this.isRefreshing = true;
              this.fetchPosts().then(() => {
                this.isRefreshing = false;
              }).catch((err: Error) => {
                this.isRefreshing = false;
              });
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: CommonConstants.MARGIN_MEDIUM, bottom: CommonConstants.MARGIN_MEDIUM })
      }
      
      Scroll() {
        Column() {
          // 加载状态提示
          if (this.loading && this.posts.length === 0) {
            Row() {
              LoadingProgress()
                .width(24)
                .height(24)
                .margin({ right: CommonConstants.MARGIN_SMALL })
              Text('加载中...')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_tertiary'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: CommonConstants.MARGIN_XLARGE, bottom: CommonConstants.MARGIN_XLARGE })
          }
          
          // 错误提示
          if (this.dataError && this.posts.length === 0) {
            Row() {
              Image(AppIcons.error)
                .width(24)
                .height(24)
                .fillColor($r('app.color.text_tertiary'))
                .margin({ right: CommonConstants.MARGIN_SMALL })
              Text(this.dataError)
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_tertiary'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: CommonConstants.MARGIN_XLARGE, bottom: CommonConstants.MARGIN_XLARGE })
          }
          
          // 没有内容的提示
          if (!this.loading && !this.dataError && this.posts.length === 0) {
            Column() {
              Image(AppIcons.empty)
                .width(80)
                .height(80)
                .fillColor($r('app.color.text_tertiary'))
                .margin({ bottom: CommonConstants.MARGIN_LARGE })
              
              Text('暂无内容')
                .fontSize(CommonConstants.FONT_SIZE_MEDIUM)
                .fontColor($r('app.color.text_tertiary'))
              
              Button('刷新试试')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .backgroundColor($r('app.color.primary_color'))
                .margin({ top: CommonConstants.MARGIN_LARGE })
                .onClick(() => {
                  this.fetchPosts();
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 100, bottom: 100 })
          }
          
          // 帖子列表
          ForEach(this.posts, (post: Post) => {
            Column() {
              // 用户信息
              Row() {
                Image(post.author?.avatar || '')
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .margin({ right: CommonConstants.MARGIN_MEDIUM })
                
                Column() {
                  Text(post.author?.nickname || '')
                    .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                    .fontWeight(FontWeight.Medium)
                  
                  Text(post.createdAt)
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_tertiary'))
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                
                // 关注按钮
                Text(post.author?.isFollowed ? '已关注' : '关注')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor(post.author?.isFollowed ? $r('app.color.text_tertiary') : $r('app.color.primary_color'))
                  .borderRadius(CommonConstants.RADIUS_SMALL)
                  .padding({
                    left: CommonConstants.MARGIN_LARGE,
                    right: CommonConstants.MARGIN_LARGE,
                    top: 4,
                    bottom: 4
                  })
                  .border({
                    width: 1,
                    color: post.author?.isFollowed ? $r('app.color.text_tertiary') : $r('app.color.primary_color'),
                    style: BorderStyle.Solid,
                    radius: CommonConstants.RADIUS_SMALL
                  })
                  .onClick((event?: ClickEvent) => {
                    console.info('关注按钮被点击');
                    // 处理作者ID
                    if (post.author && post.author.id) {
                      console.info(`处理关注用户: ${post.author.id}`);
                      this.handleFollow(post.author.id);
                    } else {
                      console.error('作者ID不存在');
                    }
                    // 在ArkTS中通过单独的组件和返回true阻止事件冒泡
                    return true;
                  })
                  // 增加一个额外的点击区域，使按钮更容易被点击
                  .margin({ right: 10 })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              
              // 动态内容
              Column() {
                if (post.title) {
                  Text(post.title)
                    .fontSize(CommonConstants.FONT_SIZE_LARGE)
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: CommonConstants.MARGIN_NORMAL, bottom: CommonConstants.MARGIN_SMALL })
                    .width('100%')
                }
                
                Text(post.content)
                  .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                  .margin({ top: CommonConstants.MARGIN_SMALL })
                  .width('100%')
                
                if (post.dream?.title) {
                  Text('梦想：' + post.dream.title)
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor(Color.White)
                    .backgroundColor($r('app.color.primary_color'))
                    .borderRadius(CommonConstants.RADIUS_SMALL)
                    .padding({
                      left: CommonConstants.MARGIN_MEDIUM,
                      right: CommonConstants.MARGIN_MEDIUM,
                      top: 4,
                      bottom: 4
                    })
                    .margin({ top: CommonConstants.MARGIN_MEDIUM })
                    .alignSelf(ItemAlign.Start)
                }
                
                // 图片展示
                if (post.imageUrls && post.imageUrls.length > 0) {
                  Grid() {
                    ForEach(post.imageUrls, (image: string) => {
                      GridItem() {
                        Image(image)
                          .width('100%')
                          .height('100%')
                          .borderRadius(CommonConstants.RADIUS_SMALL)
                          .objectFit(ImageFit.Cover)
                      }
                    })
                  }
                  .columnsTemplate(post.imageUrls.length === 1 ? '1fr' : post.imageUrls.length === 2 ? '1fr 1fr' : '1fr 1fr 1fr')
                  .rowsTemplate(post.imageUrls.length <= 3 ? '1fr' : '1fr 1fr')
                  .columnsGap(CommonConstants.MARGIN_SMALL)
                  .rowsGap(CommonConstants.MARGIN_SMALL)
                  .height(post.imageUrls.length === 1 ? 200 : 240)
                  .width('100%')
                  .margin({ top: CommonConstants.MARGIN_MEDIUM })
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .margin({ top: CommonConstants.MARGIN_NORMAL })
              
              // 互动栏
              Row() {
                Row() {
                  Image(AppIcons.view)
                    .width(20)
                    .height(20)
                    .fillColor($r('app.color.text_tertiary'))
                    .margin({ right: 4 })
                  Text('浏览 ' + (post.viewCount?.toString() || '0'))
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_tertiary'))
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                
                Row() {
                  Image(post.isLiked ? AppIcons.like_filled : AppIcons.like)
                    .width(20)
                    .height(20)
                    .fillColor(post.isLiked ? $r('app.color.primary_color') : $r('app.color.text_tertiary'))
                    .margin({ right: 4 })
                  Text('点赞 ' + post.likeCount.toString())
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor(post.isLiked ? $r('app.color.primary_color') : $r('app.color.text_tertiary'))
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                .onClick(() => {
                  this.handleLike(post);
                })
                
                Row() {
                  Image(AppIcons.comment)
                    .width(20)
                    .height(20)
                    .fillColor($r('app.color.text_tertiary'))
                    .margin({ right: 4 })
                  Text('评论 ' + post.commentCount.toString())
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_tertiary'))
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                .onClick(() => {
                  this.openCommentDialog(post.id);
                })
                
                Row() {
                  Image(AppIcons.share)
                    .width(20)
                    .height(20)
                    .fillColor($r('app.color.text_tertiary'))
                    .margin({ right: 4 })
                  Text('分享')
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_tertiary'))
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
              }
              .width('100%')
              .margin({ top: CommonConstants.MARGIN_LARGE })
            }
            .width('100%')
            .padding(CommonConstants.MARGIN_LARGE)
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .margin({ bottom: CommonConstants.MARGIN_LARGE })
            .onClick(() => {
              // 导航到帖子详情页
              router.pushUrl({
                url: 'pages/community/PostDetailPage',
                params: {
                  postId: post.id
                }
              });
            })
          })
          
          // 加载更多
          if (this.posts.length > 0) {
            if (this.loading) {
              Row() {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .margin({ right: CommonConstants.MARGIN_SMALL })
                Text('加载更多...')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_tertiary'))
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_LARGE })
            } else if (this.hasMore) {
              Text('上拉加载更多')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_LARGE })
            } else {
              Text('没有更多内容了')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_LARGE })
            }
          }
        }
        .width('100%')
        .padding({ left: CommonConstants.MARGIN_LARGE, right: CommonConstants.MARGIN_LARGE })
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
      .onReachEnd(() => {
        this.loadMoreData();
      })
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  CommentDialog() {
    Column() {
      // 对话框标题
      Row() {
        Text('评论')
          .fontSize(CommonConstants.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
        
        Image(AppIcons.close)
          .width(24)
          .height(24)
          .fillColor($r('app.color.text_primary'))
          .onClick(() => {
            this.showCommentDialog = false;
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ 
        top: CommonConstants.MARGIN_LARGE, 
        bottom: CommonConstants.MARGIN_NORMAL,
        left: CommonConstants.MARGIN_LARGE,
        right: CommonConstants.MARGIN_LARGE
      })
      
      Divider()
        .width('100%')
        .height(1)
        .color($r('app.color.card_background'))
      
      // 评论列表
      List() {
        if (this.commentLoading) {
          ListItem() {
            Row() {
              LoadingProgress()
                .width(20)
                .height(20)
                .margin({ right: CommonConstants.MARGIN_SMALL })
              Text('加载评论中...')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_tertiary'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_LARGE })
          }
        } else if (this.comments.length === 0) {
          ListItem() {
            Text('暂无评论，快来发表第一条评论吧')
              .fontSize(CommonConstants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_LARGE })
          }
        } else {
          ForEach(this.comments, (comment: Comment) => {
            ListItem() {
              Column() {
                // 评论用户信息
                Row() {
                  Image(comment.userAvatar || '')
                    .width(36)
                    .height(36)
                    .borderRadius(18)
                    .margin({ right: CommonConstants.MARGIN_MEDIUM })
                  
                  Column() {
                    Text(comment.username || '')
                      .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                      .fontWeight(FontWeight.Medium)
                    
                    Text(comment.createdAt)
                      .fontSize(CommonConstants.FONT_SIZE_SMALL)
                      .fontColor($r('app.color.text_tertiary'))
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                
                // 评论内容
                Text(comment.content)
                  .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                  .margin({ top: CommonConstants.MARGIN_SMALL, left: 44 })
                  .width('100%')
                
                // 回复评论展示
                if (comment.replies && comment.replies.length > 0) {
                  Column() {
                    ForEach(comment.replies, (reply: Comment) => {
                      Row() {
                        Text(reply.username || '')
                          .fontSize(CommonConstants.FONT_SIZE_SMALL)
                          .fontWeight(FontWeight.Medium)
                          .fontColor($r('app.color.primary_color'))
                        
                        Text('回复')
                          .fontSize(CommonConstants.FONT_SIZE_SMALL)
                          .fontColor($r('app.color.text_tertiary'))
                          .margin({ left: 4, right: 4 })
                        
                        Text(comment.username || '')
                          .fontSize(CommonConstants.FONT_SIZE_SMALL)
                          .fontWeight(FontWeight.Medium)
                          .fontColor($r('app.color.primary_color'))
                          
                        Text('：')
                          .fontSize(CommonConstants.FONT_SIZE_SMALL)
                          .fontColor($r('app.color.text_primary'))
                          
                        Text(reply.content)
                          .fontSize(CommonConstants.FONT_SIZE_SMALL)
                          .fontColor($r('app.color.text_primary'))
                          .layoutWeight(1)
                      }
                      .width('100%')
                      .alignItems(VerticalAlign.Center)
                      .margin({ top: 4 })
                    })
                  }
                  .width('100%')
                  .backgroundColor($r('app.color.background'))
                  .borderRadius(CommonConstants.RADIUS_SMALL)
                  .padding(CommonConstants.MARGIN_SMALL)
                  .margin({ top: CommonConstants.MARGIN_SMALL, left: 44 })
                }
                
                Divider()
                  .width('100%')
                  .height(0.5)
                  .color($r('app.color.card_background'))
                  .margin({ top: CommonConstants.MARGIN_LARGE })
              }
              .width('100%')
              .padding({ 
                top: CommonConstants.MARGIN_MEDIUM, 
                bottom: CommonConstants.MARGIN_MEDIUM,
                left: CommonConstants.MARGIN_LARGE,
                right: CommonConstants.MARGIN_LARGE
              })
            }
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
      
      // 评论输入框
      Row() {
        TextInput({ placeholder: '发表评论...', text: this.commentText })
          .height(40)
          .borderRadius(CommonConstants.RADIUS_NORMAL)
          .backgroundColor($r('app.color.background'))
          .padding({ left: CommonConstants.MARGIN_MEDIUM, right: CommonConstants.MARGIN_MEDIUM })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.commentText = value;
          })
        
        Button('发送')
          .height(40)
          .backgroundColor($r('app.color.primary_color'))
          .borderRadius(CommonConstants.RADIUS_NORMAL)
          .margin({ left: CommonConstants.MARGIN_MEDIUM })
          .fontSize(CommonConstants.FONT_SIZE_NORMAL)
          .onClick(() => {
            this.submitComment();
          })
      }
      .width('100%')
      .padding({ 
        top: CommonConstants.MARGIN_MEDIUM, 
        bottom: CommonConstants.MARGIN_MEDIUM,
        left: CommonConstants.MARGIN_LARGE,
        right: CommonConstants.MARGIN_LARGE
      })
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('80%')
    .backgroundColor(Color.White)
    .borderRadius({
      topLeft: CommonConstants.RADIUS_LARGE,
      topRight: CommonConstants.RADIUS_LARGE
    })
    .position({ x: 0, y: '20%' })
  }
} 