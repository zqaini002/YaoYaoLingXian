import promptAction from '@ohos.promptAction';

/**
 * 自定义按钮接口
 */
interface DialogButton {
  text: string;
  color: string;
}

/**
 * 对话框结果接口
 */
interface DialogResult {
  index: number;
}

/**
 * 提示工具类，封装了各种提示方法
 */
export { promptAction };

/**
 * 显示确认对话框
 * 
 * @param title 标题
 * @param message 消息内容
 * @param confirmText 确认按钮文本
 * @param cancelText 取消按钮文本
 * @returns Promise<boolean> 用户是否确认
 */
export function showConfirmDialog(
  title: string,
  message: string,
  confirmText: string = '确定',
  cancelText: string = '取消'
): Promise<boolean> {
  return new Promise((resolve) => {
    try {
      // 创建按钮数组
      const buttons: DialogButton[] = [
        {
          text: cancelText,
          color: '#666666'
        },
        {
          text: confirmText,
          color: '#0A59F7'
        }
      ];
      
      // 显示对话框
      promptAction.showDialog({
        title: title,
        message: message,
        buttons: buttons
      }).then((result: DialogResult) => {
        // index为1表示点击了确认按钮
        resolve(result.index === 1);
      }).catch(() => {
        // 出错时默认为取消
        resolve(false);
      });
    } catch (error) {
      console.error('显示确认对话框失败:', error);
      promptAction.showToast({ message: '显示对话框失败' });
      resolve(false);
    }
  });
}

/**
 * 显示加载提示
 * 
 * @param message 消息内容
 */
export function showLoading(message: string = '加载中...') {
  try {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  } catch (error) {
    console.error('显示加载提示失败:', error);
  }
}

/**
 * 显示成功提示
 * 
 * @param message 消息内容
 */
export function showSuccess(message: string) {
  try {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  } catch (error) {
    console.error('显示成功提示失败:', error);
  }
}

/**
 * 显示错误提示
 * 
 * @param message 消息内容
 */
export function showError(message: string) {
  try {
    promptAction.showToast({
      message: message,
      duration: 3000
    });
  } catch (error) {
    console.error('显示错误提示失败:', error);
  }
} 