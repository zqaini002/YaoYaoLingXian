/**
 * 加载进度指示器组件
 */
@Component
export struct MyLoadingProgress {
  @State color: ResourceColor = Color.Blue;
  @State progressSize: number = 36;
  
  build() {
    Progress({
      value: 0,
      total: 100,
      type: ProgressType.ScaleRing
    })
      .color(this.color)
      .width(this.progressSize)
      .height(this.progressSize)
  }
} 