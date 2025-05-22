/**
 * 用户会话管理模块
 * 处理用户登录状态
 */

import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { UserInfo } from '../../model/CommonTypes';
import * as ApiService from '../../services/ApiService';
import promptAction from '@ohos.promptAction';
import { AppContext } from '../../entryability/EntryAbility';
// StorageUtils导入错误，先注释掉，后续再根据需要处理
//import { StorageUtils } from '../StorageUtils';

const PREFERENCE_NAME = 'auth_store';
const KEY_USER_TOKEN = 'user_token';
const KEY_USER_ID = 'user_id';
const KEY_USER_NAME = 'user_name';
const KEY_USER_NICKNAME = 'user_nickname';
const KEY_USER_AVATAR = 'user_avatar';

/**
 * 操作结果接口
 */
export interface OperationResult {
  success: boolean;
  message: string;
}

/**
 * 用户会话管理类
 */
export class UserSession {
  private static instance: UserSession;
  private preferences: preferences.Preferences | null = null;
  private currentUser: UserInfo | null = null;
  private initialized: boolean = false;
  private readonly PREFERENCE_NAME: string = 'user_session';
  private readonly KEY_USER_INFO: string = 'user_info';
  private readonly KEY_TOKEN: string = 'token';

  /**
   * 私有构造函数，防止直接实例化
   */
  private constructor() {
    console.info('UserSession: 构造函数调用');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): UserSession {
    if (!UserSession.instance) {
      console.info('UserSession: 创建实例');
      UserSession.instance = new UserSession();
    } else {
      console.info('UserSession: 返回已有实例');
    }
    return UserSession.instance;
  }

  /**
   * 检查会话是否已初始化
   */
  public isInitialized(): boolean {
    console.info('UserSession: 检查是否已初始化:', this.initialized);
    return this.initialized;
  }

  /**
   * 初始化会话
   */
  public async init(): Promise<void> {
    if (this.initialized) {
      console.info('UserSession: 会话已初始化，无需重复操作');
      return;
    }

    try {
      console.info('UserSession: 开始初始化会话');
      
      // 使用AppContext获取上下文
      const context = AppContext.getContext();
      console.info('UserSession: AppContext.getContext()返回:', context ? '有效上下文' : 'null或undefined');
      
      if (!context) {
        console.error('UserSession: 无法从AppContext获取上下文，尝试使用备用方法');
        
        // 使用备用方法获取上下文
        console.info('UserSession: 无法获取上下文，初始化失败');
        throw new Error('无法获取有效的上下文，请重启应用');
      } else {
        console.info('UserSession: 成功从AppContext获取上下文');
        // 使用获取到的上下文初始化偏好存储
        console.info('UserSession: 开始使用AppContext上下文初始化偏好存储');
        this.preferences = await preferences.getPreferences(context, this.PREFERENCE_NAME);
        console.info('UserSession: 使用AppContext上下文初始化偏好存储成功');
      }
      
      // 尝试从存储加载用户信息
      console.info('UserSession: 尝试从存储加载用户信息');
      await this.restoreSession();
      
      this.initialized = true;
      console.info('UserSession: 会话初始化完成，登录状态:', this.isLoggedIn());
    } catch (error) {
      console.error('UserSession: 初始化用户会话失败:', error);
      // 初始化失败，设置为未初始化状态，以便下次重试
      this.initialized = false;
      // 确保抛出的是标准Error对象
      if (error instanceof Error) {
        throw error; // 已经是Error对象，直接抛出
      } else {
        throw new Error(typeof error === 'string' ? error : '初始化用户会话失败');
      }
    }
  }

  /**
   * 恢复用户会话
   */
  private async restoreSession(): Promise<void> {
    try {
      if (!this.preferences) {
        console.error('UserSession: 偏好存储未初始化');
        return;
      }
      
      // 获取存储的用户信息
      const userInfoStr = await this.preferences.get(this.KEY_USER_INFO, '');
      if (userInfoStr && typeof userInfoStr === 'string' && userInfoStr !== '') {
        this.currentUser = JSON.parse(userInfoStr) as UserInfo;
        console.info('UserSession: 恢复用户会话成功');
      } else {
        console.info('UserSession: 无存储的用户会话');
      }
    } catch (error) {
      console.error(`UserSession: 恢复会话失败: ${error}`);
    }
  }

  /**
   * 保存用户会话
   */
  private async saveSession(): Promise<void> {
    try {
      if (!this.preferences) {
        console.error('UserSession: 偏好存储未初始化');
        return;
      }
      
      if (this.currentUser) {
        // 保存用户信息
        await this.preferences.put(this.KEY_USER_INFO, JSON.stringify(this.currentUser));
        // 保存token
        if (this.currentUser.token) {
          await this.preferences.put(this.KEY_TOKEN, this.currentUser.token);
        }
        // 刷新到磁盘
        await this.preferences.flush();
        console.info('UserSession: 保存用户会话成功');
      } else {
        console.info('UserSession: 无用户信息可保存');
      }
    } catch (error) {
      console.error(`UserSession: 保存会话失败: ${error}`);
    }
  }

  /**
   * 用户登录
   * 
   * @param username 用户名
   * @param password 密码
   * @returns 登录结果
   */
  public async login(username: string, password: string): Promise<boolean> {
    try {
      const response = await ApiService.login({ username, password });
      
      if (response.code === 200 && response.data) {
        // 设置当前用户信息
        const userData: UserInfo = {
          id: response.data.user.id,
          username: response.data.user.username,
          nickname: response.data.user.nickname,
          avatar: response.data.user.avatar,
          email: response.data.user.email,
          phone: response.data.user.phone,
          gender: response.data.user.gender,
          birthday: response.data.user.birthday,
          signature: response.data.user.signature,
          status: response.data.user.status,
          token: response.data.token
        };
        
        this.currentUser = userData;
        
        // 保存会话
        await this.saveSession();
        return true;
      } else {
        promptAction.showToast({
          message: response.message || '登录失败',
          duration: 2000
        });
        return false;
      }
    } catch (error) {
      console.error(`UserSession: 登录失败: ${error}`);
      
      // 根据错误类型提供更具体的错误信息
      let errorMessage = '登录失败，请稍后重试';
      
      // 尝试判断错误类型
      const errorStr = String(error);
      if (errorStr.includes('400')) {
        errorMessage = '用户名或密码错误';
      } else if (errorStr.includes('500') || errorStr.includes('WeakKeyException')) {
        errorMessage = '服务器配置错误，请联系管理员';
      } else if (errorStr.includes('timeout') || errorStr.includes('network')) {
        errorMessage = '网络连接超时，请检查网络设置';
      }
      
      promptAction.showToast({
        message: errorMessage,
        duration: 3000
      });
      return false;
    }
  }

  /**
   * 用户注册
   * 
   * @param username 用户名
   * @param password 密码
   * @param nickname 昵称
   * @param email 邮箱
   * @param phone 手机号
   * @returns 注册结果
   */
  public async register(username: string, password: string, nickname: string, email?: string, phone?: string): Promise<boolean> {
    try {
      const response = await ApiService.register({ 
        username, 
        password, 
        nickname,
        email,
        phone
      });
      
      if (response.code === 200 && response.data) {
        // 设置当前用户信息
        const userData: UserInfo = {
          id: response.data.user.id,
          username: response.data.user.username,
          nickname: response.data.user.nickname,
          avatar: response.data.user.avatar,
          email: response.data.user.email,
          phone: response.data.user.phone,
          gender: response.data.user.gender,
          birthday: response.data.user.birthday,
          signature: response.data.user.signature,
          status: response.data.user.status,
          token: response.data.token
        };
        
        this.currentUser = userData;
        
        // 保存会话
        await this.saveSession();
        return true;
      } else {
        promptAction.showToast({
          message: response.message || '注册失败',
          duration: 2000
        });
        return false;
      }
    } catch (error) {
      console.error(`UserSession: 注册失败: ${error}`);
      
      // 根据错误类型提供更具体的错误信息
      let errorMessage = '注册失败，请稍后重试';
      
      // 尝试判断错误类型
      const errorStr = String(error);
      if (errorStr.includes('400')) {
        errorMessage = '注册信息有误，请检查输入';
      } else if (errorStr.includes('500') || errorStr.includes('WeakKeyException')) {
        errorMessage = '服务器配置错误，请联系管理员';
      } else if (errorStr.includes('timeout') || errorStr.includes('network')) {
        errorMessage = '网络连接超时，请检查网络设置';
      }
      
      promptAction.showToast({
        message: errorMessage,
        duration: 3000
      });
      return false;
    }
  }

  /**
   * 检查用户名是否可用
   * 
   * @param username 用户名
   * @returns 是否可用
   */
  public async checkUsername(username: string): Promise<boolean> {
    try {
      const response = await ApiService.checkUsername(username);
      return response.code === 200 && response.data === true;
    } catch (error) {
      console.error(`UserSession: 检查用户名失败: ${error}`);
      return false;
    }
  }

  /**
   * 用户登出
   */
  public async logout(): Promise<void> {
    console.info('UserSession: 开始登出流程');
    
    try {
      // 调用后端API进行登出
      await ApiService.logout();
      
      // 清除当前用户
      this.currentUser = null;
      
      // 清除存储
      await this.clearUserStorage();
      console.info('UserSession: 登出完成');
    } catch (error) {
      console.error('UserSession: 登出过程中出错:', error);
      // 即使API调用失败，也要清除本地信息
      this.currentUser = null;
      try {
        await this.clearUserStorage();
      } catch (storageError) {
        console.error('UserSession: 清除本地存储失败:', storageError);
      }
      
      // 重新抛出错误以便上层处理
      throw new Error('登出失败，请重试');
    }
  }

  /**
   * 获取当前用户信息
   */
  public getCurrentUser(): UserInfo | null {
    return this.currentUser;
  }

  /**
   * 判断用户是否已登录
   */
  public isLoggedIn(): boolean {
    const isLoggedIn = this.currentUser !== null && !!this.currentUser.token;
    console.info('UserSession: 检查用户是否已登录', isLoggedIn ? '已登录' : '未登录');
    return isLoggedIn;
  }

  /**
   * 获取用户Token
   */
  public getToken(): string | undefined {
    return this.currentUser?.token;
  }

  /**
   * 获取用户ID
   */
  public getUserId(): number {
    return this.currentUser?.id || 0;
  }

  /**
   * 清除存储的用户信息
   */
  private async clearUserStorage(): Promise<void> {
    if (!this.preferences) {
      console.error('UserSession: 偏好存储未初始化，无法清除用户信息');
      return;
    }

    try {
      console.info('UserSession: 正在清除存储的用户信息');
      await this.preferences.delete(this.KEY_USER_INFO);
      await this.preferences.delete(this.KEY_TOKEN);
      await this.preferences.flush();
      console.info('UserSession: 已清除存储的用户信息');
    } catch (error) {
      console.error('UserSession: 清除用户信息失败:', error);
      throw new Error('清除用户信息失败');
    }
  }

  /**
   * 更新用户信息
   * 
   * @param userInfo 用户信息
   */
  public async updateUserInfo(userInfo: UserInfo): Promise<void> {
    if (!this.currentUser) {
      console.error('UserSession: 无当前用户，无法更新');
      return;
    }
    
    // 更新用户信息
    // 手动合并对象，不使用展开运算符
    if (userInfo.id) this.currentUser.id = userInfo.id;
    if (userInfo.username) this.currentUser.username = userInfo.username;
    if (userInfo.nickname) this.currentUser.nickname = userInfo.nickname;
    if (userInfo.avatar) this.currentUser.avatar = userInfo.avatar;
    if (userInfo.email) this.currentUser.email = userInfo.email;
    if (userInfo.phone) this.currentUser.phone = userInfo.phone;
    if (userInfo.gender !== undefined) this.currentUser.gender = userInfo.gender;
    if (userInfo.birthday) this.currentUser.birthday = userInfo.birthday;
    if (userInfo.signature) this.currentUser.signature = userInfo.signature;
    if (userInfo.status !== undefined) this.currentUser.status = userInfo.status;
    if (userInfo.token) this.currentUser.token = userInfo.token;
    
    // 保存会话
    await this.saveSession();
  }
}