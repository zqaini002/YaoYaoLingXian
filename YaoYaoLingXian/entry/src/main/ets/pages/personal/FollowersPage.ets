import { getUserFollowers } from '../../services/ApiService';
import type { UserInfo, PageResponse } from '../../model/CommonTypes';
import { UserSession } from '../../utils/auth/UserSession';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

// 定义路由参数接口
interface RouteParams {
  userId?: number;
}

/**
 * 粉丝列表页面
 */
@Entry
@Component
struct FollowersPage {
  @State followers: Array<UserInfo> = [];
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
      
      // 加载粉丝列表
      this.loadFollowers();
    } catch (error) {
      console.error(`初始化粉丝页面出错: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  async loadFollowers() {
    if (this.loading || (!this.hasMore && this.currentPage > 0)) {
      return;
    }

    this.loading = true;
    try {
      const response: PageResponse<UserInfo> = await getUserFollowers(this.userId, this.currentPage, this.pageSize);
      if (this.currentPage === 0) {
        this.followers = response.content;
      } else {
        const newArray = this.followers.concat(response.content);
        this.followers = newArray;
      }

      // 更新分页信息
      this.hasMore = !response.last;
      if (this.hasMore) {
        this.currentPage++;
      }
    } catch (error) {
      console.error(`加载粉丝列表失败: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      this.loading = false;
      this.refreshing = false;
    }
  }

  refreshData() {
    this.currentPage = 0;
    this.hasMore = true;
    this.refreshing = true;
    this.loadFollowers();
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

        Text('我的粉丝')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 粉丝列表
      Refresh({ refreshing: this.refreshing }) {
        List() {
          if (this.followers.length === 0) {
            ListItem() {
              Column() {
                Image($r('app.media.empty_icon'))
                  .width(100)
                  .height(100)
                  .margin({ top: 100, bottom: 16 })
                  .opacity(0.5)
                Text('暂无粉丝')
                  .fontSize(16)
                  .fontColor('#999')
              }
              .width('100%')
            }
          } else {
            ForEach(this.followers, (follower: UserInfo) => {
              ListItem() {
                Row() {
                  Image(follower.avatar ? follower.avatar : $r('app.media.default_avatar'))
                    .width(48)
                    .height(48)
                    .borderRadius(24)
                    .margin({ right: 16 })

                  Column() {
                    Text(follower.nickname ? follower.nickname : follower.username)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .margin({ bottom: 4 })
                    Text(follower.signature ? follower.signature : '这个人很懒，什么都没留下')
                      .fontSize(14)
                      .fontColor('#999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              }
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/personal/UserDetailPage',
                  params: { userId: follower.id }
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
            this.loadFollowers();
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
} 