import { CommonConstants, Task } from '../../model/CommonTypes';
import { AppIcons } from '../../utils/IconUtils';
import prompt from '@ohos.promptAction';
import router from '@ohos.router';
import { addTaskProgress, Progress, getTaskById } from '../../services/TaskService';
import media from '@ohos.multimedia.media';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import fileio from '@ohos.fileio';
import image from '@ohos.multimedia.image';
import request from '@ohos.request';
import { BASE_URL } from '../../services/ApiService';
import promptAction from '@ohos.promptAction';

// 定义自定义图片选择结果接口
interface CustomPhotoResult {
  uris: string[];
}

@Entry
@Component
export struct TaskProgressPage {
  @State task: Task | null = null;
  @State isLoading: boolean = false;
  @State isSubmitting: boolean = false;
  @State description: string = '';
  @State uploadedImages: string[] = [];
  @State selectedImages: string[] = [];
  @State imageUris: string[] = [];
  @State uploadProgress: number = 0;
  @State isUploading: boolean = false;

  private taskId: number = 0;
  private context = getContext(this);

  aboutToAppear() {
    // 从路由参数获取任务ID
    const params = router.getParams() as Record<string, string | number>;
    this.taskId = params['taskId'] as number || 0;
    
    if (this.taskId) {
      this.loadTaskDetails();
    } else {
      const toastOptions: promptAction.ShowToastOptions = {
        message: '无法找到任务信息',
        duration: 2000
      };
      prompt.showToast(toastOptions);
      router.back();
    }
  }
  
  // 加载任务详情
  async loadTaskDetails(): Promise<void> {
    if (!this.taskId) return;
    
    this.isLoading = true;
    try {
      const task = await getTaskById(this.taskId);
      if (task) {
        this.task = task;
      } else {
        const toastOptions: promptAction.ShowToastOptions = {
          message: '无法找到任务信息',
          duration: 2000
        };
        prompt.showToast(toastOptions);
        router.back();
      }
    } catch (error) {
      console.error(`加载任务详情失败: ${String(error)}`);
      const toastOptions: promptAction.ShowToastOptions = {
        message: '加载任务详情失败，请稍后重试',
        duration: 2000
      };
      prompt.showToast(toastOptions);
      router.back();
    } finally {
      this.isLoading = false;
    }
  }
  
  // 选择图片
  async pickImages(): Promise<void> {
    try {
      // 使用更新后的文件选择器实现
      const imageSelectOptions = new picker.PhotoSelectOptions();
      // 设置最大数量
      imageSelectOptions.maxSelectNumber = 9 - this.selectedImages.length;
      
      // 创建图片选择器实例
      const photoPicker = new picker.PhotoViewPicker();
      
      // 使用Promise方式调用
      photoPicker.select(imageSelectOptions)
        .then((photos) => {
          if (photos && photos.photoUris && photos.photoUris.length > 0) {
            // 合并新URI到现有列表
            this.imageUris = [...this.imageUris, ...photos.photoUris];
            
            // 同时保存到selectedImages用于显示
            this.selectedImages = [...this.selectedImages, ...photos.photoUris];
          }
        })
        .catch((error:undefined) => {
          console.error(`选择图片失败: ${String(error)}`);
          const toastOptions: promptAction.ShowToastOptions = {
            message: '选择图片失败，请稍后重试',
            duration: 2000
          };
          prompt.showToast(toastOptions);
        });
    } catch (error) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      console.error(`选择图片失败: ${err.message}`);
      const toastOptions: promptAction.ShowToastOptions = {
        message: '选择图片失败，请稍后重试',
        duration: 2000
      };
      prompt.showToast(toastOptions);
    }
  }
  
  // 删除已选图片
  removeImage(index: number): void {
    // 创建新数组而不是修改原数组
    const newSelectedImages: string[] = [];
    const newImageUris: string[] = [];
    
    for (let i = 0; i < this.selectedImages.length; i++) {
      if (i !== index) {
        newSelectedImages.push(this.selectedImages[i]);
        newImageUris.push(this.imageUris[i]);
      }
    }
    
    this.selectedImages = newSelectedImages;
    this.imageUris = newImageUris;
  }

  // 模拟上传图片到服务器，实际环境中应使用真实服务器API
  async uploadImages(): Promise<string[]> {
    if (this.imageUris.length === 0) {
      return [];
    }

    this.isUploading = true;
    this.uploadProgress = 0;
    
    try {
      // 在实际项目中，这里应该调用服务器的图片上传API
      // 以下代码仅做模拟演示
      const uploadedUrls: string[] = [];
      
      for (let i = 0; i < this.imageUris.length; i++) {
        try {
          // 模拟上传过程
          await new Promise<void>((resolve: () => void): void => {
            setTimeout((): void => {
              // 模拟进度更新
              this.uploadProgress = Math.floor((i + 1) / this.imageUris.length * 100);
              resolve();
            }, 500); // 延迟500ms模拟网络请求
          });
          
          // 模拟服务器返回的图片URL (实际项目中应返回真实URL)
          const mockServerUrl: string = `${BASE_URL}/uploads/images/task_${this.taskId}_image_${Date.now()}_${i}.jpg`;
          uploadedUrls.push(mockServerUrl);
        } catch (error) {
          console.error(`上传图片失败: ${String(error)}`);
          // 继续上传其他图片
        }
      }
      
      return uploadedUrls;
    } catch (error) {
      console.error(`上传图片过程出错: ${String(error)}`);
      throw new Error(`上传图片过程出错: ${String(error)}`);
    } finally {
      this.isUploading = false;
    }
  }
  
  // 保存进度记录
  async saveProgress(): Promise<void> {
    if (!this.description.trim()) {
      const toastOptions: promptAction.ShowToastOptions = {
        message: '请输入进度描述',
        duration: 2000
      };
      prompt.showToast(toastOptions);
      return;
    }
    
    this.isSubmitting = true;
    
    try {
      if (!this.task) {
        throw new Error('任务数据不存在');
      }
      
      // 处理图片上传
      let imageUrls: string = '';
      if (this.imageUris.length > 0) {
        try {
          // 上传图片到服务器并获取URL
          const uploadedImages: string[] = await this.uploadImages();
          if (uploadedImages && uploadedImages.length > 0) {
            imageUrls = uploadedImages.join(',');
          } else {
            // 上传失败时，提示用户但仍然允许继续保存文本内容
            const toastOptions: promptAction.ShowToastOptions = {
              message: '部分或全部图片上传失败，将保存文本内容',
              duration: 2000
            };
            prompt.showToast(toastOptions);
          }
        } catch (error) {
          console.error(`上传图片失败: ${String(error)}`);
          const toastOptions: promptAction.ShowToastOptions = {
            message: '图片上传失败，将保存文本内容',
            duration: 2000
          };
          prompt.showToast(toastOptions);
        }
      }
      
      // 创建进度记录
      const progressData: Progress = {
        id: 0,
        taskId: this.task.id,
        dreamId: this.task.dreamId,
        userId: this.task.userId,
        description: this.description,
        images: imageUrls,
        createdAt: new Date().toISOString()
      };
      
      // 调用API保存进度记录
      const result: Progress = await addTaskProgress(progressData);
      
      if (result) {
        const toastOptions: promptAction.ShowToastOptions = {
          message: '进度记录添加成功',
          duration: 2000
        };
        prompt.showToast(toastOptions);
        
        // 返回上一页
        router.back();
      }
    } catch (error) {
      console.error(`添加进度记录失败: ${String(error)}`);
      const toastOptions: promptAction.ShowToastOptions = {
        message: '添加进度记录失败，请稍后重试',
        duration: 2000
      };
      prompt.showToast(toastOptions);
    } finally {
      this.isSubmitting = false;
    }
  }
  
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Row() {
            Image(AppIcons.back)
              .width(20)
              .height(20)
              .fillColor(Color.White)
              .margin({ right: 4 })
            
            Text('返回')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
          .alignItems(VerticalAlign.Center)
        }
        .backgroundColor($r('app.color.primary_color'))
        .borderRadius(CommonConstants.RADIUS_SMALL)
        .height(36)
        .padding({ left: 12, right: 12 })
        .border({
          width: 2,
          color: Color.White,
          style: BorderStyle.Solid
        })
        .shadow({
          radius: 6,
          color: 'rgba(0, 0, 0, 0.3)',
          offsetX: 2,
          offsetY: 2
        })
        .onClick(() => router.back())
        
        Text('记录进度')
          .fontSize(CommonConstants.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        
        Blank()
          .width(24)
      }
      .width('100%')
      .padding({
        left: CommonConstants.MARGIN_LARGE,
        right: CommonConstants.MARGIN_LARGE,
        top: CommonConstants.MARGIN_LARGE,
        bottom: CommonConstants.MARGIN_NORMAL
      })
      .alignItems(VerticalAlign.Center)
      
      // 内容区域
      if (this.isLoading) {
        // 加载状态
        LoadingProgress()
          .width(50)
          .height(50)
          .color($r('app.color.primary_color'))
          .margin({ top: 100 })
      } else if (this.task) {
        // 任务信息
        Column() {
          // 任务标题和详情
          Row() {
            Column() {
              Text(this.task.title)
                .fontSize(CommonConstants.FONT_SIZE_MEDIUM)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .textAlign(TextAlign.Start)
                .margin({ bottom: 4 })
              
              if (this.task.description) {
                Text(this.task.description)
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_secondary'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ bottom: 4 })
              }
              
              Row() {
                if (this.task.dueDate) {
                  Row() {
                    Image(AppIcons.calendar)
                      .width(16)
                      .height(16)
                      .fillColor($r('app.color.text_tertiary'))
                      .margin({ right: 4 })
                    
                    Text(this.task.dueDate)
                      .fontSize(CommonConstants.FONT_SIZE_SMALL)
                      .fontColor($r('app.color.text_tertiary'))
                  }
                  .margin({ right: 16 })
                }
                
                Row() {
                  Circle({ width: 12, height: 12 })
                    .fill(this.getPriorityColor(this.task.priority))
                    .margin({ right: 4 })
                  
                  Text(this.getPriorityText(this.task.priority))
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_tertiary'))
                }
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(CommonConstants.RADIUS_SMALL)
          .padding(CommonConstants.MARGIN_NORMAL)
          .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          // 进度描述
          Column() {
            Text('进度描述')
              .fontSize(CommonConstants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: CommonConstants.MARGIN_SMALL })
            
            TextArea({ placeholder: '描述一下你的进度...\n例如：已完成任务的哪个部分？遇到了什么困难？', text: this.description })
              .fontSize(CommonConstants.FONT_SIZE_NORMAL)
              .placeholderFont({ size: CommonConstants.FONT_SIZE_NORMAL })
              .height(120)
              .width('100%')
              .backgroundColor(Color.White)
              .borderRadius(CommonConstants.RADIUS_SMALL)
              .onChange((value: string) => {
                this.description = value;
              })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          // 上传图片
          Column() {
            Row() {
              Text('添加图片')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_secondary'))
              
              Text(`${this.selectedImages.length}/9`)
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_tertiary'))
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: CommonConstants.MARGIN_SMALL })
            
            // 图片预览区域
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              // 已选图片
              ForEach(this.selectedImages, (item: string, index: number) => {
                Stack() {
                  // 使用URI字符串而不是Resource
                  Image(item)
                    .width(80)
                    .height(80)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(CommonConstants.RADIUS_SMALL)
                  
                  // 删除按钮
                  Circle({ width: 20, height: 20 })
                    .fill(Color.Black)
                    .opacity(0.6)
                    .position({ x: 60, y: 0 })
                  
                  Image(AppIcons.close)
                    .width(16)
                    .height(16)
                    .fillColor(Color.White)
                    .position({ x: 62, y: 2 })
                    .onClick(() => {
                      this.removeImage(index);
                    })
                }
                .width(80)
                .height(80)
                .margin({
                  right: (index % 3) === 2 ? 0 : CommonConstants.MARGIN_NORMAL,
                  bottom: CommonConstants.MARGIN_NORMAL
                })
              })
              
              // 添加图片按钮
              if (this.selectedImages.length < 9) {
                Column() {
                  Image(AppIcons.add)
                    .width(32)
                    .height(32)
                    .fillColor($r('app.color.primary_color'))
                  
                  Text('添加图片')
                    .fontSize(12)
                    .fontColor($r('app.color.primary_color'))
                    .margin({ top: 8 })
                }
                .width(80)
                .height(80)
                .backgroundColor(Color.White)
                .borderRadius(CommonConstants.RADIUS_SMALL)
                .border({ 
                  width: 1, 
                  color: $r('app.color.primary_color'),
                  style: BorderStyle.Dashed 
                })
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .onClick(() => {
                  this.pickImages();
                })
              }
            }
            .width('100%')
            
            // 上传进度条
            if (this.isUploading) {
              Column() {
                Text(`上传图片中... ${this.uploadProgress}%`)
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ top: CommonConstants.MARGIN_NORMAL, bottom: CommonConstants.MARGIN_SMALL })
                
                Progress({ value: this.uploadProgress, total: 100 })
                  .width('100%')
                  .height(4)
                  .color($r('app.color.primary_color'))
              }
              .width('100%')
              .margin({ top: CommonConstants.MARGIN_SMALL })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: CommonConstants.MARGIN_LARGE })
        }
        .width('100%')
        .padding({
          left: CommonConstants.MARGIN_LARGE,
          right: CommonConstants.MARGIN_LARGE,
          bottom: 80 // 为底部按钮预留空间
        })
      } else {
        // 错误状态
        Column() {
          Image(AppIcons.error)
            .width(120)
            .height(120)
            .fillColor($r('app.color.error_color'))
            .opacity(0.7)
            .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          Text('无法加载任务信息')
            .fontSize(CommonConstants.FONT_SIZE_MEDIUM)
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: CommonConstants.MARGIN_NORMAL })
          
          Button('返回')
            .width(120)
            .height(48)
            .fontSize(CommonConstants.FONT_SIZE_NORMAL)
            .backgroundColor($r('app.color.primary_color'))
            .borderRadius(CommonConstants.RADIUS_SMALL)
            .onClick(() => router.back())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding({
          left: CommonConstants.MARGIN_LARGE,
          right: CommonConstants.MARGIN_LARGE
        })
      }
      
      // 底部保存按钮
      if (this.task) {
        Row() {
          Button('保存进度')
            .width('100%')
            .height(48)
            .fontSize(CommonConstants.FONT_SIZE_NORMAL)
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.primary_color'))
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .enabled(!this.isSubmitting && !this.isUploading)
            .stateEffect(true)
            .onClick(() => this.saveProgress())
        }
        .width('100%')
        .padding({
          left: CommonConstants.MARGIN_LARGE,
          right: CommonConstants.MARGIN_LARGE,
          bottom: CommonConstants.MARGIN_LARGE,
          top: CommonConstants.MARGIN_NORMAL
        })
        .backgroundColor($r('app.color.background_color'))
        .position({
          x: 0,
          y: '90%'
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
  }
  
  // 获取优先级对应的颜色
  getPriorityColor(priority: number): Resource {
    switch (priority) {
      case 1:
        return $r('app.color.priority_highest');
      case 2:
        return $r('app.color.priority_high');
      case 3:
        return $r('app.color.priority_medium');
      case 4:
        return $r('app.color.priority_low');
      case 5:
        return $r('app.color.priority_lowest');
      default:
        return $r('app.color.priority_medium');
    }
  }
  
  // 获取优先级文本
  getPriorityText(priority: number): string {
    switch (priority) {
      case 1:
        return '最高';
      case 2:
        return '高';
      case 3:
        return '中';
      case 4:
        return '低';
      case 5:
        return '最低';
      default:
        return '中';
    }
  }
} 