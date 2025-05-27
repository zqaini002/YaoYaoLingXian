import { CommonConstants, Post, Comment } from '../../model/CommonTypes';
import { AppIcons } from '../../utils/IconUtils';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import * as ApiService from '../../services/ApiService';
import { UserSession } from '../../utils/auth/UserSession';

interface GeneratedObjectLiteralInterface_1 {
  id: number;
  username: string;
  nickname: string;
  avatar: string;
}

@Entry
@Component
export struct PostDetailPage {
  @State post: Post | null = null;
  @State loading: boolean = true;
  @State error: string = '';
  @State commentText: string = '';
  @State comments: Comment[] = [];
  @State commentLoading: boolean = false;
  @State pageNumber: number = 0;
  @State pageSize: number = 20;
  @State hasMoreComments: boolean = true;
  private userSession: UserSession = UserSession.getInstance();
  private postId: number = 0;
  
  aboutToAppear() {
    const params = router.getParams() as Record<string, string | number>;
    if (params && typeof params.postId !== 'undefined') {
      this.postId = Number(params.postId);
      this.fetchPostDetail();
      this.fetchComments();
    } else {
      this.error = '无效的帖子ID';
      this.loading = false;
      promptAction.showToast({
        message: '无效的帖子ID',
        duration: 2000
      });
    }
  }
  
  // 获取帖子详情
  async fetchPostDetail(): Promise<void> {
    try {
      this.loading = true;
      
      try {
      this.post = await ApiService.getPostById(this.postId);
      
        // 添加详细日志
        console.info(`获取到帖子详情数据: ${JSON.stringify({
          id: this.post?.id,
          title: this.post?.title,
          // 输出作者信息
          author: this.post?.author ? ({
            id: this.post.author.id,
            username: this.post.author.username,
            nickname: this.post.author.nickname,
            avatar: this.post.author.avatar?.substring(0, 50) + '...'
          } as GeneratedObjectLiteralInterface_1) : '未定义',
          // 原始用户信息
          userId: this.post?.userId,
          username: this.post?.username,
          nickname: this.post?.nickname,
          userAvatar: this.post?.userAvatar,
          // 图片信息
          hasImages: this.post?.images ? true : false,
          imageCount: this.post?.imageUrls?.length || 0
        })}`);
        
        // 确保所有计数字段都有默认值，防止undefined.toString()错误
        if (this.post) {
          // 初始化计数字段，避免undefined错误
          this.post.likeCount = this.post.likeCount ?? 0;
          this.post.commentCount = this.post.commentCount ?? 0;
          this.post.viewCount = this.post.viewCount ?? 0;
          
          // 处理图片URLs - 使用明确的类型断言处理图片数据
          if (this.post.images) {
            // 显式类型断言
            const imagesValue = this.post.images as string | string[];
            if (typeof imagesValue === 'string' && imagesValue.trim() !== '') {
              // 如果是字符串，则分割为数组
              this.post.imageUrls = imagesValue.split(',').filter((url: string) => url && url.trim() !== '');
              console.info(`处理后的图片URLs: ${this.post.imageUrls.length}张`);
            } else if (Array.isArray(imagesValue)) {
              // 如果已经是数组，直接使用
              this.post.imageUrls = imagesValue;
              console.info(`图片URLs数组: ${this.post.imageUrls.length}张`);
      } else {
        this.post.imageUrls = [];
              console.info(`无有效图片`);
            }
          } else if (this.post) {
            this.post.imageUrls = [];
            console.info(`帖子无图片字段`);
          }
        }
      } catch (error) {
        // 如果API返回404，显示友好提示
        this.error = `帖子不存在或已被删除`;
        console.error(`获取帖子详情失败: ${error instanceof Error ? error.message : String(error)}`);
        promptAction.showToast({
          message: this.error,
          duration: 2000
        });
      }
      
    } catch (error) {
      this.error = `获取帖子详情失败: ${error instanceof Error ? error.message : String(error)}`;
      promptAction.showToast({
        message: this.error,
        duration: 2000
      });
    } finally {
      this.loading = false;
    }
  }
  
  // 获取评论列表
  async fetchComments(refresh: boolean = true): Promise<void> {
    try {
      if (refresh) {
        this.pageNumber = 0;
        this.commentLoading = true;
      }
      
      if (!this.hasMoreComments && !refresh) {
        return;
      }
      
      try {
        // 确保传递认证信息
        console.info(`加载评论列表，当前用户登录状态: ${this.userSession.isLoggedIn()}`);
        if (this.userSession.isLoggedIn()) {
          console.info(`当前登录用户ID: ${this.userSession.getUserId()}`);
        }
        
        // 使用空数组作为默认值，避免解构时出错
        const newComments = await ApiService.getPostComments(this.postId, this.pageNumber, this.pageSize) || [];
      
      if (refresh) {
        this.comments = newComments;
      } else {
        this.comments = [...this.comments, ...newComments];
      }
      
      this.hasMoreComments = newComments.length === this.pageSize;
      this.pageNumber++;
      } catch (error) {
        // 内部捕获API错误，确保UI不会崩溃
        console.warn(`评论获取失败，但UI不受影响: ${error instanceof Error ? error.message : String(error)}`);
        // 当评论获取失败时，设置为空列表
        if (refresh) {
          this.comments = [];
        }
        this.hasMoreComments = false;
      }
      
    } catch (error) {
      // 只显示提示，不会影响UI继续展示
      promptAction.showToast({
        message: `获取评论失败，将显示空评论列表`,
        duration: 2000
      });
      if (refresh) {
        this.comments = [];
      }
      this.hasMoreComments = false;
    } finally {
      this.commentLoading = false;
    }
  }
  
  // 提交评论
  async submitComment(): Promise<void> {
    if (!this.commentText.trim()) {
      promptAction.showToast({
        message: '评论内容不能为空',
        duration: 2000
      });
      return;
    }
    
    // 检查用户是否已登录
    if (!this.userSession.isLoggedIn()) {
      promptAction.showToast({
        message: '请先登录后再发表评论',
        duration: 2000
      });
      // 跳转到登录页面
      router.pushUrl({
        url: 'pages/user/LoginPage',
        params: {
          redirectUrl: 'pages/community/PostDetailPage',
          postId: this.postId
        }
      });
      return;
    }
    
    // 获取登录用户ID - 确保用户ID有效
    const userId = this.userSession.getUserId();
    if (!userId) {
      promptAction.showToast({
        message: '无法获取用户信息，请重新登录',
        duration: 2000
      });
      return;
    }
    
    console.info(`准备发送评论，用户ID: ${userId}`);
    console.info(`认证令牌: ${this.userSession.getToken()?.substring(0, 10)}...`);
    
    try {
      this.commentLoading = true;
      
      // 创建评论对象 - 确保包含正确的用户ID
      const comment: Comment = {
        id: 0,
        postId: this.postId,
        userId: userId, // 使用会话中的用户ID
        content: this.commentText,
        createdAt: new Date().toISOString(),
        parentId: 0,
        status: 1
      };
      
      try {
      const newComment = await ApiService.createComment(this.postId, comment);
      
      // 更新本地评论列表
      this.comments = [newComment, ...this.comments];
      this.commentText = '';
      
      // 更新帖子的评论数
      if (this.post) {
        this.post.commentCount++;
      }
      
      promptAction.showToast({
        message: '评论成功',
        duration: 2000
      });
      } catch (error) {
        // API错误处理 - 使用更友好的提示
        const errorMessage = error instanceof Error ? error.message : String(error);
        
        // 检查是否是未登录错误
        if (errorMessage.includes('未登录') || errorMessage.includes('需要登录') || 
            errorMessage.includes('401') || errorMessage.includes('认证失败')) {
          promptAction.showToast({
            message: '请先登录后再发表评论',
            duration: 2000
          });
          
          // 跳转到登录页面
          router.pushUrl({
            url: 'pages/user/LoginPage',
            params: {
              redirectUrl: 'pages/community/PostDetailPage',
              postId: this.postId
            }
          });
        } else if (errorMessage.includes('404')) {
          promptAction.showToast({
            message: '评论功能暂不可用 (后端API未实现)',
            duration: 2000
          });
        } else {
          promptAction.showToast({
            message: `评论失败: ${errorMessage}`,
            duration: 2000
          });
        }
        
        // 错误发生时不清空评论输入，方便用户重试
      }
    } catch (error) {
      promptAction.showToast({
        message: `发表评论失败: ${error instanceof Error ? error.message : String(error)}`,
        duration: 2000
      });
    } finally {
      this.commentLoading = false;
    }
  }

  // 处理点赞
  async handleLike(): Promise<void> {
    if (!this.post) return;
    
    try {
      if (this.post.isLiked) {
        await ApiService.unlikePost(this.post.id);
        this.post.likeCount = Math.max(0, this.post.likeCount - 1);
      } else {
        await ApiService.likePost(this.post.id);
        this.post.likeCount++;
      }
      this.post.isLiked = !this.post.isLiked;
    } catch (error) {
      promptAction.showToast({
        message: `操作失败: ${error instanceof Error ? error.message : String(error)}`,
        duration: 2000
      });
    }
  }

  // 处理评论点赞
  handleCommentLike(comment: Comment): void {
    if (comment && comment.likeCount !== undefined) {
      if (comment.isLiked) {
        comment.likeCount = Math.max(0, comment.likeCount - 1);
      } else {
        comment.likeCount += 1;
      }
      comment.isLiked = !comment.isLiked;
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .width(40)
        .height(40)
        .backgroundColor($r('app.color.primary_color'))
        .borderRadius(20)
        .onClick(() => {
          router.back();
        })
        
        Text('帖子详情')
          .fontSize(CommonConstants.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .margin({ left: CommonConstants.MARGIN_LARGE })
        
        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: CommonConstants.MARGIN_LARGE, right: CommonConstants.MARGIN_LARGE })
      .alignItems(VerticalAlign.Center)
      
      // 内容区域
      if (this.loading) {
        // 加载中
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 100 })
      } else if (this.error) {
        // 错误提示
        Column() {
          Image(AppIcons.error)
            .width(60)
            .height(60)
            .fillColor($r('app.color.text_tertiary'))
            .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          Text(this.error)
            .fontSize(CommonConstants.FONT_SIZE_MEDIUM)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          Button('返回')
            .fontSize(CommonConstants.FONT_SIZE_NORMAL)
            .backgroundColor($r('app.color.primary_color'))
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.post) {
        // 帖子详情
        Scroll() {
          Column() {
            // 作者信息
            Row() {
              Image(this.post?.author?.avatar || '')
                .width(48)
                .height(48)
                .borderRadius(24)
                .margin({ right: CommonConstants.MARGIN_MEDIUM })
                .alt($r('app.media.default_avatar'))
                .onError(() => {
                  console.warn('作者头像加载失败');
                })
              
              Column() {
                // 显示作者昵称，使用多层次的降级策略
                Text(this.post?.author?.nickname || this.post?.author?.username || this.post?.nickname || this.post?.username || '未知用户')
                  .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                  .fontWeight(FontWeight.Medium)
                
                Text(this.post?.createdAt || '')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_tertiary'))
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              
              // 关注按钮已移除
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding(CommonConstants.MARGIN_LARGE)
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            
            // 内容
            Column() {
              if (this.post.title) {
                Text(this.post.title)
                  .fontSize(CommonConstants.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: CommonConstants.MARGIN_NORMAL })
              }
              
              Text(this.post.content)
                .fontSize(CommonConstants.FONT_SIZE_MEDIUM)
                .margin({ bottom: CommonConstants.MARGIN_LARGE })
              
              // 关联梦想
              if (this.post.dream?.title) {
                Row() {
                  Image(AppIcons.dream)
                    .width(20)
                    .height(20)
                    .fillColor($r('app.color.primary_color'))
                    .margin({ right: CommonConstants.MARGIN_SMALL })
                  
                  Text('关联梦想: ' + this.post.dream.title)
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.primary_color'))
                }
                .backgroundColor(Color.Transparent)
                .borderRadius(CommonConstants.RADIUS_SMALL)
                .padding({
                  left: CommonConstants.MARGIN_MEDIUM,
                  right: CommonConstants.MARGIN_MEDIUM,
                  top: 6,
                  bottom: 6
                })
                .margin({ bottom: CommonConstants.MARGIN_MEDIUM })
                .border({
                  width: 1,
                  color: $r('app.color.primary_color'),
                  style: BorderStyle.Dashed
                })
              }
              
              // 图片
              if (this.post?.imageUrls && Array.isArray(this.post.imageUrls) && this.post.imageUrls.length > 0) {
                Column() {
                  Grid() {
                    ForEach(this.post.imageUrls, (image: string) => {
                      GridItem() {
                        Image(image)
                          .width('100%')
                          .height('100%')
                          .objectFit(ImageFit.Cover)
                          .borderRadius(CommonConstants.RADIUS_SMALL)
                          .onClick(() => {
                            // 查看大图逻辑（暂不实现）
                          })
                      }
                    }, (item: string) => item)
                  }
                  .columnsTemplate(this.post.imageUrls.length === 1 ? '1fr' : (this.post.imageUrls.length === 2 || this.post.imageUrls.length === 4) ? '1fr 1fr' : '1fr 1fr 1fr')
                  .rowsTemplate(this.post.imageUrls.length <= 3 ? '1fr' : this.post.imageUrls.length <= 6 ? '1fr 1fr' : '1fr 1fr 1fr')
                  .columnsGap(CommonConstants.MARGIN_SMALL)
                  .rowsGap(CommonConstants.MARGIN_SMALL)
                  .height(this.post.imageUrls.length === 1 ? 300 : this.post.imageUrls.length <= 4 ? 400 : 500)
                }
                .width('100%')
                .margin({ bottom: CommonConstants.MARGIN_LARGE })
              }
            }
            .width('100%')
            .padding(CommonConstants.MARGIN_LARGE)
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .margin({ top: CommonConstants.MARGIN_LARGE })
            
            // 互动统计
            Row() {
              Row() {
                Image(AppIcons.view)
                  .width(20)
                  .height(20)
                  .fillColor($r('app.color.text_tertiary'))
                  .margin({ right: 4 })
                Text((this.post.viewCount || 0).toString() + ' 浏览')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_tertiary'))
              }
              .layoutWeight(1)
              
              Row() {
                Image(this.post.isLiked ? AppIcons.like_filled : AppIcons.like)
                  .width(20)
                  .height(20)
                  .fillColor(this.post.isLiked ? $r('app.color.primary_color') : $r('app.color.text_tertiary'))
                  .margin({ right: 4 })
                Text(((this.post.likeCount !== undefined && this.post.likeCount !== null) ? this.post.likeCount : 0).toString() + ' 点赞')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor(this.post.isLiked ? $r('app.color.primary_color') : $r('app.color.text_tertiary'))
              }
              .layoutWeight(1)
              .onClick(() => {
                this.handleLike();
              })
              
              Row() {
                Image(AppIcons.comment)
                  .width(20)
                  .height(20)
                  .fillColor($r('app.color.text_tertiary'))
                  .margin({ right: 4 })
                Text(this.post.commentCount.toString() + ' 评论')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_tertiary'))
              }
              .layoutWeight(1)
              
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
            }
            .width('100%')
            .padding(CommonConstants.MARGIN_LARGE)
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .margin({ top: CommonConstants.MARGIN_LARGE })
            
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
            .padding(CommonConstants.MARGIN_LARGE)
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .margin({ top: CommonConstants.MARGIN_LARGE })
            
            // 评论列表
            Column() {
              Text('全部评论 (' + this.post.commentCount + ')')
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: CommonConstants.MARGIN_NORMAL })
              
              if (this.commentLoading && this.comments.length === 0) {
                // 加载中
                Row() {
                  LoadingProgress()
                    .width(20)
                    .height(20)
                    .margin({ right: CommonConstants.MARGIN_SMALL })
                  Text('加载中...')
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_tertiary'))
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_LARGE })
              } else if (this.comments.length === 0) {
                // 无评论
                Column() {
                  Image(AppIcons.empty)
                    .width(60)
                    .height(60)
                    .fillColor($r('app.color.text_tertiary'))
                    .margin({ bottom: CommonConstants.MARGIN_MEDIUM })
                  
                  Text('暂无评论，快来发表第一条评论吧')
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_tertiary'))
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .padding({ top: CommonConstants.MARGIN_XLARGE, bottom: CommonConstants.MARGIN_XLARGE })
              } else {
                // 评论列表
                List() {
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
                          
                          // 点赞
                          Row() {
                            Image(comment.isLiked ? AppIcons.like_filled : AppIcons.like)
                              .width(20)
                              .height(20)
                              .fillColor(comment.isLiked ? '#FF6B6B' : '#999999')
                            Text((comment.likeCount || 0).toString())
                              .fontSize(12)
                              .fontColor('#999999')
                              .margin({ left: 4 })
                          }
                          .onClick(() => {
                            this.handleCommentLike(comment);
                          })
                        }
                        .width('100%')
                        .alignItems(VerticalAlign.Center)
                        
                        // 评论内容
                        Text(comment.content)
                          .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                          .margin({ top: CommonConstants.MARGIN_SMALL, left: 46 })
                          .width('100%')
                        
                        // 回复区域
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
                          .margin({ top: CommonConstants.MARGIN_SMALL, left: 46 })
                        }
                        
                        Divider()
                          .width('100%')
                          .height(1)
                          .color('#E0E0E0')
                      }
                      .width('100%')
                      .padding({ top: CommonConstants.MARGIN_MEDIUM, bottom: CommonConstants.MARGIN_MEDIUM })
                    }
                  })
                }
                .width('100%')
                .layoutWeight(1)
              }
              
              // 加载更多
              if (this.hasMoreComments) {
                Row() {
                  Text(this.commentLoading ? '加载中...' : '加载更多评论')
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_tertiary'))
                    .margin({ right: this.commentLoading ? CommonConstants.MARGIN_SMALL : 0 })
                  
                  if (this.commentLoading) {
                    LoadingProgress()
                      .width(16)
                      .height(16)
                  }
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_LARGE })
                .onClick(() => {
                  if (!this.commentLoading) {
                    this.fetchComments(false);
                  }
                })
              } else if (this.comments.length > 0) {
                Text('已加载全部评论')
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_tertiary'))
                  .margin({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_LARGE })
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
            }
            .width('100%')
            .padding(CommonConstants.MARGIN_LARGE)
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .margin({ top: CommonConstants.MARGIN_LARGE, bottom: CommonConstants.MARGIN_LARGE })
          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
} 