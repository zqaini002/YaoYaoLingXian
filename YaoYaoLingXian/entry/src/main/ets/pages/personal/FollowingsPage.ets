import router from '@ohos.router';
import { getUserFollowings, unfollowUser } from '../../services/ApiService';
import type { UserInfo, PageResponse } from '../../model/CommonTypes';
import { UserSession } from '../../utils/auth/UserSession';
import promptAction from '@ohos.promptAction';

// 定义路由参数接口
interface RouteParams {
  userId?: number;
}

/**
 * 关注列表页面
 */
@Entry
@Component
struct FollowingsPage {
  @State followings: Array<UserInfo> = [];
  @State loading: boolean = false;
  @State refreshing: boolean = false;
  @State hasMore: boolean = true;
  @State currentPage: number = 0;
  @State pageSize: number = 20;
  @State userId: number = 0;

  aboutToAppear() {
    try {
      // 获取路由参数中的userId
      const params = router.getParams() as RouteParams;
      if (params && params.userId) {
        this.userId = params.userId;
        console.info(`从路由获取userId: ${this.userId}`);
      } else {
        // 如果没有传递userId，则使用当前登录用户的ID
        const userSession = UserSession.getInstance();
        if (userSession.isLoggedIn()) {
          this.userId = userSession.getUserId();
          console.info(`使用当前登录用户ID: ${this.userId}`);
        } else {
          console.error('用户未登录且未提供userId');
        }
      }
      
      // 加载关注列表
      this.loadFollowings();
    } catch (error) {
      console.error(`初始化关注页面出错: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  async loadFollowings() {
    if (this.loading || (!this.hasMore && this.currentPage > 0)) {
      return;
    }

    this.loading = true;
    try {
      const response: PageResponse<UserInfo> = await getUserFollowings(this.userId, this.currentPage, this.pageSize);
      if (this.currentPage === 0) {
        this.followings = response.content;
      } else {
        // 不使用扩展运算符，使用concat方法
        const newArray = this.followings.concat(response.content);
        this.followings = newArray;
      }

      // 更新分页信息
      this.hasMore = !response.last;
      if (this.hasMore) {
        this.currentPage++;
      }
    } catch (error) {
      console.error(`加载关注列表失败: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      this.loading = false;
      this.refreshing = false;
    }
  }

  refreshData() {
    this.currentPage = 0;
    this.hasMore = true;
    this.refreshing = true;
    this.loadFollowings();
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.back_icon'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .onClick(() => {
            router.back();
          })

        Text('我的关注')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 关注列表
      Refresh({ refreshing: this.refreshing }) {
        List() {
          if (this.followings.length === 0) {
            ListItem() {
              Column() {
                Image($r('app.media.empty_icon'))
                  .width(100)
                  .height(100)
                  .margin({ top: 100, bottom: 16 })
                  .opacity(0.5)
                Text('暂无关注')
                  .fontSize(16)
                  .fontColor('#999')
              }
              .width('100%')
            }
          } else {
            ForEach(this.followings, (following: UserInfo) => {
              ListItem() {
                Row() {
                  Image(following.avatar ? following.avatar : $r('app.media.default_avatar'))
                    .width(48)
                    .height(48)
                    .borderRadius(24)
                    .margin({ right: 16 })

                  Column() {
                    Text(following.nickname ? following.nickname : following.username)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .margin({ bottom: 4 })
                    Text(following.signature ? following.signature : '这个人很懒，什么都没留下')
                      .fontSize(14)
                      .fontColor('#999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Button('已关注')
                    .fontSize(14)
                    .fontColor('#ffffff')
                    .backgroundColor('#4D8CFE')
                    .borderRadius(16)
                    .width(80)
                    .height(32)
                    .onClick(() => {
                      // 在此实现取消关注功能
                      this.handleUnfollow(following.id);
                    })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              }
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/personal/UserDetailPage',
                  params: { userId: following.id }
                });
              })
            })

            // 底部加载更多
            if (this.loading) {
              ListItem() {
                Row() {
                  LoadingProgress()
                    .width(24)
                    .height(24)
                    .margin({ right: 8 })
                  Text('加载中...')
                    .fontSize(14)
                    .fontColor('#999')
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding({ top: 12, bottom: 12 })
              }
            } else if (this.hasMore) {
              ListItem() {
                Text('上拉加载更多')
                  .fontSize(14)
                  .fontColor('#999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 12, bottom: 12 })
              }
            } else {
              ListItem() {
                Text('没有更多数据了')
                  .fontSize(14)
                  .fontColor('#999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 12, bottom: 12 })
              }
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .onReachEnd(() => {
          if (this.hasMore && !this.loading) {
            this.loadFollowings();
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .onRefreshing(() => {
        this.refreshData();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  // 处理取消关注
  async handleUnfollow(followingId: number) {
    try {
      await unfollowUser(this.userId, followingId);
      // 更新列表，移除已取消关注的用户
      this.followings = this.followings.filter(item => item.id !== followingId);
      promptAction.showToast({ message: '取消关注成功' });
    } catch (error) {
      console.error(`取消关注失败: ${error instanceof Error ? error.message : String(error)}`);
      promptAction.showToast({ message: '取消关注失败' });
    }
  }
} 