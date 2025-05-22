import dataPreferences from '@ohos.data.preferences';
import Ability  from '@ohos.app.ability.UIAbility';

// 存储名称
const PREFERENCES_NAME = 'yao_yao_ling_xian_prefs';

class Storage {
  private preferences: dataPreferences.Preferences | null = null;

  /**
   * 初始化存储
   */
  public async init() {
    try {
      if (!this.preferences) {
        const context = getContext();
        this.preferences = await dataPreferences.getPreferences(context, PREFERENCES_NAME);
        console.info('存储初始化成功');
      }
    } catch (error) {
      console.error('存储初始化失败:', error);
      throw new Error('存储初始化失败');
    }
  }

  /**
   * 存储数据
   * 
   * @param key 键
   * @param value 值
   */
  public async set(key: string, value: string | number | boolean | object): Promise<void> {
    try {
      await this.ensureInitialized();

      if (typeof value === 'object') {
        await this.preferences?.put(key, JSON.stringify(value));
      } else {
        await this.preferences?.put(key, value);
      }
      
      await this.preferences?.flush();
      console.info(`存储数据成功: ${key}`);
    } catch (error) {
      console.error(`存储数据失败: ${key}`, error);
      throw new Error(`存储数据失败: ${key}`);
    }
  }

  /**
   * 获取数据
   * 
   * @param key 键
   * @param defaultValue 默认值
   * @returns 存储的值
   */
  public async get(key: string, defaultValue: string = ''): Promise<string> {
    try {
      await this.ensureInitialized();
      const value = await this.preferences?.get(key, defaultValue);
      return value as string;
    } catch (error) {
      console.error(`获取数据失败: ${key}`, error);
      return defaultValue;
    }
  }

  /**
   * 获取对象数据
   * 
   * @param key 键
   * @param defaultValue 默认值
   * @returns 存储的对象
   */
  public async getObject<T>(key: string, defaultValue: T): Promise<T> {
    try {
      await this.ensureInitialized();
      const jsonString = await this.preferences?.get(key, '');
      
      if (!jsonString) {
        return defaultValue;
      }
      
      return JSON.parse(jsonString as string) as T;
    } catch (error) {
      console.error(`获取对象数据失败: ${key}`, error);
      return defaultValue;
    }
  }

  /**
   * 删除数据
   * 
   * @param key 键
   */
  public async remove(key: string): Promise<void> {
    try {
      await this.ensureInitialized();
      await this.preferences?.delete(key);
      await this.preferences?.flush();
      console.info(`删除数据成功: ${key}`);
    } catch (error) {
      console.error(`删除数据失败: ${key}`, error);
      throw new Error(`删除数据失败: ${key}`);
    }
  }

  /**
   * 清空所有数据
   */
  public async clear(): Promise<void> {
    try {
      await this.ensureInitialized();
      await this.preferences?.clear();
      await this.preferences?.flush();
      console.info('清空所有数据成功');
    } catch (error) {
      console.error('清空所有数据失败:', error);
      throw new Error('清空所有数据失败');
    }
  }

  /**
   * 确保存储已初始化
   */
  private async ensureInitialized(): Promise<void> {
    if (!this.preferences) {
      await this.init();
    }
  }
}

// 导出单例
export const storage = new Storage(); 