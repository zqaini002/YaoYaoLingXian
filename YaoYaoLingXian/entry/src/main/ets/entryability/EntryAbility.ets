import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import type common from '@ohos.app.ability.common';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

// 用于存储UIAbility上下文的静态引用
export class AppContext {
  private static context: common.Context | null = null;

  // 设置上下文引用
  static setContext(context: common.Context): void {
    AppContext.context = context;
    hilog.info(DOMAIN, TAG, 'AppContext: 已保存UIAbility上下文引用');
  }

  // 获取上下文引用
  static getContext(): common.Context | null {
    return AppContext.context;
  }
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 保存上下文引用到静态类
    AppContext.setContext(this.context);
    
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    // 改回直接加载Index页面，登录状态检查将在Index中处理
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the Index page.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }
}