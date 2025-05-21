import { CommonConstants, Task, Dream } from '../../model/CommonTypes';
import { AppIcons } from '../../utils/IconUtils';
import prompt from '@ohos.promptAction';
import router from '@ohos.router';
import { createTask, updateTask, deleteTask, getTaskProgress } from '../../services/TaskService';
import type { Progress } from '../../services/TaskService';
import { getDreamsByUserId } from '../../services/ApiService';
import reminderAgent from '@ohos.reminderAgentManager';
import { BusinessError } from '@ohos.base';
import notification from '@ohos.notificationManager';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { Option } from '../../model/OptionTypes';
import actionSheet from '@ohos.promptAction';

// 按钮数据接口声明
interface CustomDialogButtonData {
  value: string;
  color: Resource;
  action: () => void;
}

interface RouterParams {
  isEdit?: boolean;
  task?: Task;
  taskId?: number;
  userId?: number;
}

interface DialogButton {
  value: string;
  fontColor?: Resource;
  action: () => void;
}

// AlertDialog按钮定义接口
interface AlertDialogButton {
  value: string;
  color: Resource;
  action: () => void;
}

// 定义梦想按钮类型
interface DreamButton {
  value: string;
  color: Resource;
  action: () => void;
}

// 定义ActionSheet项目接口
interface ActionSheetItem {
  value: string;
}

// 定义对话框结果接口
interface DialogResultType {
  index: number;
}

// 定义ActionSheet选项接口
interface ActionSheetOptions {
  title: string;
  items: ActionSheetItem[];
  cancel?: () => void;
  select?: (index: number) => void;
}

// 对话框按钮定义接口
interface DialogPrimaryButton {
  value: string;
  action: () => void;
}

interface DialogSecondaryButton {
  value: string;
  fontColor?: Resource;
  action: () => void;
}

// 定义AlertDialog选项接口
interface AlertDialogOptions {
  title: string;
  message: string;
  autoCancel: boolean;
  alignment: DialogAlignment;
  primaryButton: DialogPrimaryButton;
  secondaryButton: DialogSecondaryButton;
}

@Entry
@Component
export struct TaskEditPage {
  @State task: Task = {
    id: 0,
    title: '',
    description: '',
    status: 0, // 默认为待开始
    priority: 3, // 默认为中等优先级
    startDate: new Date().toISOString().split('T')[0],
    dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 默认一周后截止
    dreamId: 0,
    userId: 0,
    completedAt: null,
    reminderTime: null,
    parentTaskId: null,
    createdAt: '',
    updatedAt: ''
  };
  
  @State isEdit: boolean = false;
  @State isSubmitting: boolean = false;
  @State dreams: Dream[] = [];
  @State isLoading: boolean = false;
  @State showDeleteDialog: boolean = false;
  @State selectedDream: Dream | null = null;
  @State taskProgress: Progress[] = [];
  @State hasReminder: boolean = false;
  @State reminderDate: string = '';
  @State reminderTime: string = '';
  @State reminderId: number = -1;
  
  // 用于日期选择
  private startDateController: TextInputController = new TextInputController();
  private dueDateController: TextInputController = new TextInputController();
  
  // 优先级选项
  private priorities: Option[] = [
    { value: 1, label: '最高' } as Option,
    { value: 2, label: '高' } as Option,
    { value: 3, label: '中' } as Option,
    { value: 4, label: '低' } as Option,
    { value: 5, label: '最低' } as Option
  ];
  
  // 状态选项
  private statuses: Option[] = [
    { value: 0, label: '待开始' } as Option,
    { value: 1, label: '进行中' } as Option,
    { value: 2, label: '已完成' } as Option,
    { value: 3, label: '已延期' } as Option
  ];
  
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams();
    
    if (params) {
      const routeParams: RouterParams = params as RouterParams;
      this.isEdit = routeParams.isEdit || false;
      
      if (this.isEdit) {
        const routeTask = routeParams.task;
        if (routeTask) {
          this.task = {
            id: routeTask.id,
            title: routeTask.title,
            description: routeTask.description,
            status: routeTask.status,
            priority: routeTask.priority,
            startDate: routeTask.startDate,
            dueDate: routeTask.dueDate,
            dreamId: routeTask.dreamId,
            userId: routeTask.userId,
            completedAt: routeTask.completedAt,
            reminderTime: routeTask.reminderTime,
            parentTaskId: routeTask.parentTaskId,
            createdAt: routeTask.createdAt,
            updatedAt: routeTask.updatedAt
          };
          
          // 设置提醒状态
          if (this.task.reminderTime) {
            this.hasReminder = true;
            const reminderDateTime = new Date(this.task.reminderTime);
            this.reminderDate = reminderDateTime.toISOString().split('T')[0];
            this.reminderTime = reminderDateTime.toTimeString().split(' ')[0].substring(0, 5);
            
            // 加载任务进度
            this.loadTaskProgress();
          }
        } else {
          const taskId = routeParams.taskId || 0;
          if (taskId > 0) {
            // 如果只传了ID，需要请求任务详情
            // 这里暂不实现
          }
        }
      } else {
        const userId = routeParams.userId || 2; // 默认用户ID为2
        this.task.userId = userId;
        this.reminderDate = new Date().toISOString().split('T')[0];
        this.reminderTime = new Date().toTimeString().split(' ')[0].substring(0, 5);
      }
    }
    
    this.loadDreams();
  }
  
  // 加载用户的梦想列表
  async loadDreams() {
    this.isLoading = true;
    try {
      const dreams: Dream[] = await getDreamsByUserId(this.task.userId);
      if (dreams && dreams.length > 0) {
        this.dreams = dreams;
        
        // 如果是新任务且未选择梦想，默认选择第一个梦想
        if (!this.isEdit && this.task.dreamId === 0 && this.dreams.length > 0) {
          const firstDreamId = this.dreams[0]?.id;
          if (firstDreamId !== undefined) {
            this.task.dreamId = firstDreamId;
          }
        }
        
        // 设置选中的梦想
        if (this.task.dreamId > 0) {
          const foundDream = this.dreams.find((d: Dream) => d.id === this.task.dreamId);
          if (foundDream) {
            this.selectedDream = foundDream;
          }
        }
      }
    } catch (error) {
      const err: Error = error as Error;
      console.error(`加载梦想列表失败: ${err.message}`);
      const toastOptions: promptAction.ShowToastOptions = {
        message: '加载梦想列表失败，请稍后重试',
        duration: 2000
      };
      prompt.showToast(toastOptions);
    } finally {
      this.isLoading = false;
    }
  }
  
  // 加载任务进度
  async loadTaskProgress() {
    if (!this.task.id) return;
    
    try {
      const progress = await getTaskProgress(this.task.id);
      if (progress && progress.length > 0) {
        this.taskProgress = progress;
      }
    } catch (error) {
      const err: Error = error as Error;
      console.error(`加载任务进度失败: ${err.message}`);
    }
  }
  
  // 保存任务
  async saveTask() {
    // 表单验证
    if (!this.task.title.trim()) {
      const toastOptions: promptAction.ShowToastOptions = {
        message: '请输入任务标题',
        duration: 2000
      };
      prompt.showToast(toastOptions);
      return;
    }
    
    if (!this.task.dreamId) {
      const toastOptions: promptAction.ShowToastOptions = {
        message: '请选择关联的梦想',
        duration: 2000
      };
      prompt.showToast(toastOptions);
      return;
    }
    
    // 设置提醒时间
    if (this.hasReminder && this.reminderDate && this.reminderTime) {
      const reminderDateTime = new Date(`${this.reminderDate}T${this.reminderTime}:00`);
      this.task.reminderTime = reminderDateTime.toISOString();
    } else {
      this.task.reminderTime = null;
    }
    
    this.isSubmitting = true;
    
    try {
      let result: Task;
      if (this.isEdit && this.task.id) {
        // 更新任务
        result = await updateTask(this.task.id, this.task);
      } else {
        // 创建任务
        result = await createTask(this.task);
      }
      
      if (result) {
        // 处理提醒
        if (this.hasReminder && this.task.reminderTime) {
          await this.setReminder(result);
        } else if (this.reminderId >= 0) {
          // 删除已有提醒
          await this.cancelReminder();
        }
        
        const toastOptions: promptAction.ShowToastOptions = {
          message: this.isEdit ? '任务更新成功' : '任务创建成功',
          duration: 2000
        };
        prompt.showToast(toastOptions);
        // 返回上一页
        router.back();
      }
    } catch (error) {
      console.error(`${this.isEdit ? '更新' : '创建'}任务失败: ${error instanceof Error ? error.message : String(error)}`);
      const toastOptions: promptAction.ShowToastOptions = {
        message: `${this.isEdit ? '更新' : '创建'}任务失败，请稍后重试`,
        duration: 2000
      };
      prompt.showToast(toastOptions);
    } finally {
      this.isSubmitting = false;
    }
  }
  
  // 处理提醒
  async setReminder(task: Task) {
    if (!task.reminderTime) return;
    
    try {
      // 先取消已有提醒
      if (this.reminderId >= 0) {
        await this.cancelReminder();
      }
      
      const reminderDateTime = new Date(task.reminderTime);
      
      // 创建提醒请求
      let reminderRequest: reminderAgent.ReminderRequestCalendar = {
        reminderType: reminderAgent.ReminderType.REMINDER_TYPE_CALENDAR,
        title: task.title,
        content: task.description || '任务提醒',
        dateTime: {
          year: reminderDateTime.getFullYear(),
          month: reminderDateTime.getMonth() + 1,
          day: reminderDateTime.getDate(),
          hour: reminderDateTime.getHours(),
          minute: reminderDateTime.getMinutes(),
          second: 0
        },
        ringDuration: 10,
        snoozeTimes: 3,
        timeInterval: 5,
        actionButton: [
          {
            title: '完成',
            type: reminderAgent.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
          },
          {
            title: '稍后提醒',
            type: reminderAgent.ActionButtonType.ACTION_BUTTON_TYPE_SNOOZE
          }
        ],
        wantAgent: {
          pkgName: 'com.yaoyaolingxian.app',
          abilityName: 'EntryAbility'
        },
        notificationId: 1001,
        slotType: notification.SlotType.SOCIAL_COMMUNICATION
      };
      
      // 发布提醒
      try {
        const reminderId = await reminderAgent.publishReminder(reminderRequest);
        this.reminderId = reminderId;
        console.info(`提醒已设置，ID: ${reminderId}`);
      } catch (error) {
        const err = error as BusinessError;
        console.error(`设置提醒失败: ${err.code}, ${err.message}`);
        const toastOptions: promptAction.ShowToastOptions = {
          message: `设置提醒失败: ${err.message}`,
          duration: 2000
        };
        prompt.showToast(toastOptions);
      }
    } catch (error) {
      const err = error as Error;
      console.error(`提醒设置错误: ${err.message}`);
      const toastOptions: promptAction.ShowToastOptions = {
        message: '设置提醒失败，请稍后重试',
        duration: 2000
      };
      prompt.showToast(toastOptions);
    }
  }
  
  // 取消提醒
  async cancelReminder() {
    if (this.reminderId < 0) return;
    
    try {
      await reminderAgent.cancelReminder(this.reminderId);
      console.info(`已取消提醒，ID: ${this.reminderId}`);
      this.reminderId = -1;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`取消提醒失败: ${err.code}, ${err.message}`);
    }
  }
  
  // 删除任务
  async confirmDeleteTask() {
    if (!this.task.id) return;
    
    this.isSubmitting = true;
    try {
      await deleteTask(this.task.id);
      const toastOptions: promptAction.ShowToastOptions = {
        message: '任务删除成功',
        duration: 2000
      };
      prompt.showToast(toastOptions);
      // 返回上一页
      router.back();
    } catch (error) {
      const err: Error = error as Error;
      console.error(`删除任务失败: ${err.message}`);
      const toastOptions: promptAction.ShowToastOptions = {
        message: '删除任务失败，请稍后重试',
        duration: 2000
      };
      prompt.showToast(toastOptions);
    } finally {
      this.isSubmitting = false;
      this.showDeleteDialog = false;
    }
  }
  
  // 获取梦想名称
  getDreamName(dreamId: number): string {
    if (dreamId <= 0) {
      return '选择梦想';
    }
    const dream = this.dreams.find((d: Dream) => d.id === dreamId);
    return dream ? dream.title : '选择梦想';
  }
  
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
  
  getStatusColor(status: number): Resource {
    switch (status) {
      case 0:
        return $r('app.color.pending_color');
      case 1:
        return $r('app.color.progress_color');
      case 2:
        return $r('app.color.completed_color');
      case 3:
        return $r('app.color.overdue_color');
      default:
        return $r('app.color.text_primary');
    }
  }
  
  // 设置标准格式的日期和时间显示字符串
  formatDateTimeString(dateTimeString: string | null): string {
    if (!dateTimeString) return '未设置';
    
    try {
      const dateObj = new Date(dateTimeString);
      const year = dateObj.getFullYear();
      const month = (dateObj.getMonth() + 1).toString().padStart(2, '0');
      const day = dateObj.getDate().toString().padStart(2, '0');
      const hour = dateObj.getHours().toString().padStart(2, '0');
      const minute = dateObj.getMinutes().toString().padStart(2, '0');
      
      return `${year}-${month}-${day} ${hour}:${minute}`;
    } catch (error) {
      return '日期格式错误';
    }
  }

  // 日期选择器回调，使用明确的类型
  onDateChange(selectedDate: string, isStartDate: boolean): void {
    if (isStartDate) {
      this.task.startDate = selectedDate;
    } else {
      this.task.dueDate = selectedDate;
    }
  }

  // 使用明确的类型
  onSelectDream(dream: Dream): void {
    if (dream) {
      this.selectedDream = dream;
      if (dream.id !== undefined && dream.id > 0) {
        this.task.dreamId = dream.id;
      }
    }
  }
  
  @Builder
  pageContent() {
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
        .onClick((): void => {
          router.back();
        })
        
        Text(this.isEdit ? '编辑任务' : '创建任务')
          .fontSize(CommonConstants.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        
        if (this.isEdit) {
          Image(AppIcons.delete)
            .width(24)
            .height(24)
            .fillColor($r('app.color.error_color'))
            .onClick((): void => {
              this.showDeleteConfirmDialog();
            })
        } else {
          Blank()
            .width(24)
        }
      }
      .width('100%')
      .padding({
        left: CommonConstants.MARGIN_LARGE,
        right: CommonConstants.MARGIN_LARGE,
        top: CommonConstants.MARGIN_LARGE,
        bottom: CommonConstants.MARGIN_NORMAL
      })
      .alignItems(VerticalAlign.Center)
      
      // 任务内容表单
      Scroll() {
        Column() {
          // 任务标题
          Column() {
            Text('任务标题')
              .fontSize(CommonConstants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: CommonConstants.MARGIN_SMALL })
            
            TextInput({ placeholder: '请输入任务标题', text: this.task.title })
              .fontSize(CommonConstants.FONT_SIZE_NORMAL)
              .placeholderFont({ size: CommonConstants.FONT_SIZE_NORMAL })
              .height(48)
              .width('100%')
              .backgroundColor(Color.White)
              .borderRadius(CommonConstants.RADIUS_SMALL)
              .onChange((value: string): void => {
                this.task.title = value;
              })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          // 任务描述
          Column() {
            Text('任务描述')
              .fontSize(CommonConstants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: CommonConstants.MARGIN_SMALL })
            
            TextArea({ placeholder: '请输入任务描述', text: this.task.description })
              .fontSize(CommonConstants.FONT_SIZE_NORMAL)
              .placeholderFont({ size: CommonConstants.FONT_SIZE_NORMAL })
              .height(120)
              .width('100%')
              .backgroundColor(Color.White)
              .borderRadius(CommonConstants.RADIUS_SMALL)
              .onChange((value: string): void => {
                this.task.description = value;
              })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          // 关联梦想
          Column() {
            Text('关联梦想')
              .fontSize(CommonConstants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: CommonConstants.MARGIN_SMALL })
            
            Row() {
              // 显示已选梦想的图片
              if (this.selectedDream && this.selectedDream.imageUrl) {
                Image(this.selectedDream.imageUrl)
                  .width(40)
                  .height(40)
                  .borderRadius(CommonConstants.RADIUS_SMALL)
                  .margin({ right: CommonConstants.MARGIN_NORMAL })
              } else {
                Image(AppIcons.target)
                  .width(40)
                  .height(40)
                  .fillColor($r('app.color.primary_color'))
                  .margin({ right: CommonConstants.MARGIN_NORMAL })
              }
              
              Column() {
                Text(this.getDreamName(this.task.dreamId))
                  .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                  .fontColor(this.task.dreamId > 0 ? $r('app.color.text_primary') : $r('app.color.text_tertiary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                
                if (this.selectedDream) {
                  Text(this.selectedDream.category || '未分类')
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor($r('app.color.text_tertiary'))
                    .margin({ top: 4 })
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              
              Image(AppIcons.arrowRight)
                .width(20)
                .height(20)
                .fillColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .height(64)
            .backgroundColor(Color.White)
            .borderRadius(CommonConstants.RADIUS_SMALL)
            .padding({
              left: CommonConstants.MARGIN_NORMAL,
              right: CommonConstants.MARGIN_NORMAL
            })
            .onClick((): void => {
              this.handleDreamSelection();
            })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          // 任务优先级
          Column() {
            Text('优先级')
              .fontSize(CommonConstants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: CommonConstants.MARGIN_SMALL })
            
            Row() {
              ForEach(this.priorities, (item: Option) => {
                Row() {
                  Circle({ width: 12, height: 12 })
                    .fill(this.getPriorityColor(item.value))
                    .margin({ right: CommonConstants.MARGIN_SMALL })
                  
                  Text(item.label)
                    .fontSize(CommonConstants.FONT_SIZE_SMALL)
                    .fontColor(this.task.priority === item.value ? $r('app.color.primary_color') : $r('app.color.text_primary'))
                    .fontWeight(this.task.priority === item.value ? FontWeight.Bold : FontWeight.Normal)
                }
                .backgroundColor(this.task.priority === item.value ? $r('app.color.primary_light_background') : Color.White)
                .borderRadius(CommonConstants.RADIUS_SMALL)
                .padding(CommonConstants.MARGIN_SMALL)
                .margin({ right: CommonConstants.MARGIN_SMALL })
                .onClick((): void => {
                  this.task.priority = item.value;
                })
              })
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          // 任务状态
          Column() {
            Text('状态')
              .fontSize(CommonConstants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: CommonConstants.MARGIN_SMALL })
            
            Row() {
              ForEach(this.statuses, (item: Option) => {
                Text(item.label)
                  .fontSize(CommonConstants.FONT_SIZE_SMALL)
                  .fontColor(this.task.status === item.value ? this.getStatusColor(item.value) : $r('app.color.text_primary'))
                  .fontWeight(this.task.status === item.value ? FontWeight.Bold : FontWeight.Normal)
                  .backgroundColor(this.task.status === item.value ? Color.Transparent : Color.White)
                  .borderRadius(CommonConstants.RADIUS_SMALL)
                  .padding(CommonConstants.MARGIN_SMALL)
                  .border({
                    width: 1,
                    color: this.task.status === item.value ? this.getStatusColor(item.value) : $r('app.color.border_color'),
                    style: BorderStyle.Solid,
                    radius: CommonConstants.RADIUS_SMALL
                  })
                  .margin({ right: CommonConstants.MARGIN_SMALL })
                  .onClick((): void => {
                    this.task.status = item.value;
                  })
              })
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          // 开始日期
          Column() {
            Text('开始日期')
              .fontSize(CommonConstants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: CommonConstants.MARGIN_SMALL })
            
            Row() {
              TextInput({ 
                placeholder: '选择开始日期', 
                text: this.task.startDate || '',
                controller: this.startDateController
              })
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .placeholderFont({ size: CommonConstants.FONT_SIZE_NORMAL })
                .height(48)
                .width('100%')
                .backgroundColor(Color.White)
                .borderRadius(CommonConstants.RADIUS_SMALL)
                .enabled(false)
              
              Image(AppIcons.calendar)
                .width(24)
                .height(24)
                .fillColor($r('app.color.text_primary'))
                .position({ x: '92%' })
            }
            .width('100%')
            .onClick((): void => {
              DatePickerDialog.show({
                start: new Date('2020-01-01'),
                end: new Date('2030-12-31'),
                selected: new Date(this.task.startDate || Date.now()),
                onAccept: (value: DatePickerResult): void => {
                  const date = new Date(value.year, value.month, value.day);
                  this.task.startDate = date.toISOString().split('T')[0];
                }
              });
            })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          // 截止日期
          Column() {
            Text('截止日期')
              .fontSize(CommonConstants.FONT_SIZE_SMALL)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: CommonConstants.MARGIN_SMALL })
            
            Row() {
              TextInput({ 
                placeholder: '选择截止日期', 
                text: this.task.dueDate || '',
                controller: this.dueDateController
              })
                .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                .placeholderFont({ size: CommonConstants.FONT_SIZE_NORMAL })
                .height(48)
                .width('100%')
                .backgroundColor(Color.White)
                .borderRadius(CommonConstants.RADIUS_SMALL)
                .enabled(false)
              
              Image(AppIcons.calendar)
                .width(24)
                .height(24)
                .fillColor($r('app.color.text_primary'))
                .position({ x: '92%' })
            }
            .width('100%')
            .onClick((): void => {
              DatePickerDialog.show({
                start: new Date('2020-01-01'),
                end: new Date('2030-12-31'),
                selected: new Date(this.task.dueDate || Date.now()),
                onAccept: (value: DatePickerResult): void => {
                  const date = new Date(value.year, value.month, value.day);
                  this.task.dueDate = date.toISOString().split('T')[0];
                }
              });
            })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          // 提醒设置
          Column() {
            Row() {
              Text('设置提醒')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_secondary'))
              
              Toggle({ type: ToggleType.Switch, isOn: this.hasReminder })
                .width(40)
                .height(20)
                .selectedColor($r('app.color.primary_color'))
                .onChange((isOn: boolean): void => {
                  this.hasReminder = isOn;
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: CommonConstants.MARGIN_SMALL })
            
            if (this.hasReminder) {
              Row() {
                // 提醒日期
                Row() {
                  TextInput({ 
                    placeholder: '选择日期', 
                    text: this.reminderDate,
                    controller: new TextInputController()
                  })
                    .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                    .placeholderFont({ size: CommonConstants.FONT_SIZE_NORMAL })
                    .height(48)
                    .width('100%')
                    .backgroundColor(Color.White)
                    .borderRadius(CommonConstants.RADIUS_SMALL)
                    .enabled(false)
                  
                  Image(AppIcons.calendar)
                    .width(24)
                    .height(24)
                    .fillColor($r('app.color.text_primary'))
                    .position({ x: '92%' })
                }
                .layoutWeight(1)
                .margin({ right: CommonConstants.MARGIN_NORMAL })
                .onClick((): void => {
                  DatePickerDialog.show({
                    start: new Date(),
                    end: new Date('2030-12-31'),
                    selected: new Date(this.reminderDate || Date.now()),
                    onAccept: (value: DatePickerResult): void => {
                      const date = new Date(value.year, value.month, value.day);
                      this.reminderDate = date.toISOString().split('T')[0];
                    }
                  });
                })
                
                // 提醒时间
                Row() {
                  TextInput({ 
                    placeholder: '选择时间', 
                    text: this.reminderTime,
                    controller: new TextInputController()
                  })
                    .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                    .placeholderFont({ size: CommonConstants.FONT_SIZE_NORMAL })
                    .height(48)
                    .width('100%')
                    .backgroundColor(Color.White)
                    .borderRadius(CommonConstants.RADIUS_SMALL)
                    .enabled(false)
                  
                  Image(AppIcons.clock)
                    .width(24)
                    .height(24)
                    .fillColor($r('app.color.text_primary'))
                    .position({ x: '92%' })
                }
                .layoutWeight(1)
                .onClick((): void => {
                  TimePickerDialog.show({
                    selected: new Date(`2000-01-01T${this.reminderTime || '00:00'}:00`),
                    onAccept: (value: TimePickerResult): void => {
                      this.reminderTime = `${value.hour.toString().padStart(2, '0')}:${value.minute.toString().padStart(2, '0')}`;
                    }
                  });
                })
              }
              .width('100%')
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ bottom: CommonConstants.MARGIN_LARGE })
          
          // 任务进度记录 (仅编辑模式显示)
          if (this.isEdit && this.taskProgress.length > 0) {
            Column() {
              Text('进度记录')
                .fontSize(CommonConstants.FONT_SIZE_SMALL)
                .fontColor($r('app.color.text_secondary'))
                .margin({ bottom: CommonConstants.MARGIN_SMALL })
              
              List() {
                ForEach(this.taskProgress, (item: Progress, index: number) => {
                  ListItem() {
                    Column() {
                      Row() {
                        Text(new Date(item.createdAt).toLocaleString())
                          .fontSize(CommonConstants.FONT_SIZE_SMALL)
                          .fontColor($r('app.color.text_tertiary'))
                        
                        Blank()
                      }
                      .width('100%')
                      .margin({ bottom: 4 })
                      
                      Text(item.description)
                        .fontSize(CommonConstants.FONT_SIZE_NORMAL)
                        .fontColor($r('app.color.text_primary'))
                        .width('100%')
                        .margin({ bottom: 8 })
                      
                      if (item.images) {
                        Row() {
                          ForEach(item.images.split(','), (img: string) => {
                            Image(img)
                              .width(80)
                              .height(80)
                              .objectFit(ImageFit.Cover)
                              .borderRadius(CommonConstants.RADIUS_SMALL)
                              .margin({ right: 8 })
                          })
                        }
                        .width('100%')
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .width('100%')
                    .padding(CommonConstants.MARGIN_NORMAL)
                    .backgroundColor(Color.White)
                    .borderRadius(CommonConstants.RADIUS_SMALL)
                  }
                  .margin({ bottom: CommonConstants.MARGIN_NORMAL })
                })
              }
              .width('100%')
              .divider({
                strokeWidth: 0,
                color: Color.Transparent
              })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .margin({ bottom: CommonConstants.MARGIN_LARGE })
          }
        }
        .width('100%')
        .padding({
          left: CommonConstants.MARGIN_LARGE,
          right: CommonConstants.MARGIN_LARGE,
          bottom: 80 // 为底部按钮预留空间
        })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)
      
      // 底部保存按钮
      Row() {
        if (this.isEdit) {
          // 编辑模式：显示保存和删除按钮
          Button('保存')
            .width('48%')
            .height(48)
            .fontSize(CommonConstants.FONT_SIZE_NORMAL)
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.primary_color'))
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .enabled(!this.isSubmitting)
            .stateEffect(true)
            .onClick((): void => {
              void this.saveTask();
            })
          
          Button('删除')
            .width('48%')
            .height(48)
            .fontSize(CommonConstants.FONT_SIZE_NORMAL)
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.error_color'))
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .enabled(!this.isSubmitting)
            .stateEffect(true)
            .onClick((): void => {
              this.showDeleteConfirmDialog();
            })
        } else {
          // 创建模式：只显示保存按钮
          Button('保存')
            .width('100%')
            .height(48)
            .fontSize(CommonConstants.FONT_SIZE_NORMAL)
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.primary_color'))
            .borderRadius(CommonConstants.RADIUS_NORMAL)
            .enabled(!this.isSubmitting)
            .stateEffect(true)
            .onClick((): void => {
              void this.saveTask();
            })
        }
      }
      .width('100%')
      .justifyContent(this.isEdit ? FlexAlign.SpaceBetween : FlexAlign.Center)
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

  build() {
    Column() {
      this.pageContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
  }
  
  // 显示删除确认对话框的方法
  showDeleteConfirmDialog(): void {
    this.showDeleteDialog = true;
    
    const dialogOptions: promptAction.ShowDialogOptions = {
      title: '确认删除',
      message: '确定要删除这个任务吗？删除后将无法恢复。',
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
    };
    
    promptAction.showDialog(dialogOptions)
      .then((result: DialogResultType) => {
        if (result.index === 1) {
          // 用户选择了"删除"按钮
          this.confirmDeleteTask();
        } else {
          // 用户选择了"取消"按钮
          this.showDeleteDialog = false;
        }
      })
      .catch((err: Error) => {
        console.error(`显示删除对话框失败: ${err}`);
      });
  }

  // 梦想选择按钮点击事件
  handleDreamSelection(): void {
    // 显示梦想选择对话框
    if (this.dreams.length > 0) {
      // 创建结构化的按钮数组
      const dreamButtons: promptAction.Button[] = this.dreams.map((dream: Dream) => {
        const button: promptAction.Button = {
          text: dream.title,
          color: $r('app.color.text_primary')
        };
        return button;
      });
      
      // 添加取消按钮
      const buttonCancel: promptAction.Button = {
        text: '取消',
        color: $r('app.color.text_secondary')
      };
      
      // 所有按钮，包括梦想和取消
      const allButtons: promptAction.Button[] = [...dreamButtons, buttonCancel];
      
      const dialogOptions: promptAction.ShowDialogOptions = {
        title: '请选择关联的梦想目标',
        message: '选择一个梦想关联到此任务',
        buttons: allButtons
      };
      
      prompt.showDialog(dialogOptions)
        .then((result: DialogResultType) => {
          if (result.index < this.dreams.length) {
            // 用户选择了某个梦想
            const selectedDream = this.dreams[result.index];
            if (selectedDream && selectedDream.id !== undefined && selectedDream.id > 0) {
              this.task.dreamId = selectedDream.id;
              this.selectedDream = selectedDream;
            }
          } else {
            // 用户选择了取消
            console.info('取消选择梦想');
          }
        })
        .catch((err: Error) => {
          console.error(`对话框错误: ${err}`);
        });
    } else {
      const toastOptions: promptAction.ShowToastOptions = {
        message: '暂无可选梦想，请先创建梦想',
        duration: 2000
      };
      prompt.showToast(toastOptions);
    }
  }
} 