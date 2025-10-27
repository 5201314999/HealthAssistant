/**
 * 用户偏好设置管理器
 * 专注于存储用户配置数据（推送开关、提醒设置等）
 * 健康记录和药品数据由 HealthRecordDatabase 管理
 * 参考: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-persistence-by-preferences
 */

import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ErrorUtils } from './ErrorUtil';

const PREFERENCES_NAME = 'medical_assistant_preferences';
const USER_PREFS_KEY = 'user_preferences';
const TAG = 'UserPreferenceManager';
const DOMAIN = 0x0000;

export interface UserPreferences {
  joinDate: number;
  notificationEnabled: boolean;
  strictReminderEnabled: boolean;
}

/**
 * 用户偏好设置管理器（单例）
 * 负责管理应用配置数据
 */
export class UserPreferenceManager {
  private static instance: UserPreferenceManager;
  private dataPreferences: preferences.Preferences | null = null;
  private initPromise: Promise<void> | null = null;
  private isInitialized: boolean = false;
  
  private constructor() {}
  
  static getInstance(): UserPreferenceManager {
    if (!UserPreferenceManager.instance) {
      UserPreferenceManager.instance = new UserPreferenceManager();
    }
    return UserPreferenceManager.instance;
  }

  /**
   * 初始化Preferences存储
   * 必须在应用启动时调用，且只应调用一次
   * @param context 应用上下文
   */
  async init(context: Context): Promise<void> {
    // 避免重复初始化
    if (this.isInitialized) {
      return;
    }
    
    if (this.initPromise) {
      return this.initPromise;
    }

    this.initPromise = this._performInit(context);
    await this.initPromise;
  }

  private async _performInit(context: Context): Promise<void> {
    try {
      // 获取Preferences实例
      this.dataPreferences = await preferences.getPreferences(context, PREFERENCES_NAME);
      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, 'Preferences initialized successfully');
      
      // 初始化用户首次使用时间
      const userPrefs = await this.getUserPreferences();
      if (!userPrefs.joinDate) {
        userPrefs.joinDate = Date.now();
        await this.saveUserPreferences(userPrefs);
      }
    } catch (err) {
      this.isInitialized = false;
      const e =ErrorUtils.toError(err)
      hilog.error(DOMAIN, TAG, 'Init failed:%{public}s', JSON.stringify(e));
      throw e;
    }
  }

  /**
   * 检查是否已初始化
   */
  private checkInitialized(): void {
    if (!this.isInitialized || !this.dataPreferences) {
      throw new Error('[UserPreferenceManager] Preferences未初始化，请先调用init()方法');
    }
  }
  
  /**
   * 获取用户偏好设置
   */
  async getUserPreferences(): Promise<UserPreferences> {
    try {
      this.checkInitialized();
      const dataStr = this.dataPreferences!.getSync(USER_PREFS_KEY, '{}') as string;
      const prefs = JSON.parse(dataStr) as UserPreferences;
      return {
        joinDate: prefs.joinDate || 0,
        notificationEnabled: prefs.notificationEnabled !== undefined ? prefs.notificationEnabled : true,
        strictReminderEnabled: prefs.strictReminderEnabled !== undefined ? prefs.strictReminderEnabled : false
      };
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Get preferences failed:%{public}s', JSON.stringify(err));
      return {
        joinDate: 0,
        notificationEnabled: true,
        strictReminderEnabled: false
      };
    }
  }
  
  /**
   * 保存用户偏好设置
   */
  async saveUserPreferences(prefs: UserPreferences): Promise<void> {
    try {
      this.checkInitialized();
      this.dataPreferences!.putSync(USER_PREFS_KEY, JSON.stringify(prefs));
      await this.dataPreferences!.flush();
      hilog.info(DOMAIN, TAG, 'User preferences saved successfully');
    } catch (err) {
      const e=ErrorUtils.toError(err)
      hilog.error(DOMAIN, TAG, 'Save preferences failed:%{public}s', JSON.stringify(e));
      throw e;
    }
  }
}

