import { AbilityConstant, ConfigurationConstant, UIAbility, Want, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { HealthRecordDatabase } from '../utils/HealthRecordDatabase';
import { UserPreferenceManager } from '../utils/DataPreference';
import { ErrorUtils } from '../utils/ErrorUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import notificationManager from '@ohos.notificationManager';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }
  
  /**
   * 请求通知和提醒权限
   */
  private async requestNotificationPermissions(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '========== Starting permission request ==========');
      const atManager = abilityAccessCtrl.createAtManager();
      const permissions: Array<Permissions> = ['ohos.permission.PUBLISH_AGENT_REMINDER'];
      
      hilog.info(DOMAIN, TAG, 'AccessTokenId: %{public}s', this.context.applicationInfo.accessTokenId.toString());
      
      // 检查权限是否已授予
      const grantStatus = await atManager.checkAccessToken(
        this.context.applicationInfo.accessTokenId,
        permissions[0]
      );
      
      hilog.info(DOMAIN, TAG, 'Current grant status: %{public}d (0=DENIED, -1=GRANTED)', grantStatus);
      
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        hilog.info(DOMAIN, TAG, '✅ Notification permission already granted');
        return;
      }
      
      // 请求权限
      hilog.info(DOMAIN, TAG, '🔔 Requesting notification permissions from user...');
      const result = await atManager.requestPermissionsFromUser(this.context, permissions);
      
      hilog.info(DOMAIN, TAG, 'Permission result - permissions: %{public}s, authResults: %{public}s', 
        JSON.stringify(result.permissions), JSON.stringify(result.authResults));
      
      if (result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        hilog.info(DOMAIN, TAG, '✅ Notification permission GRANTED by user');
      } else {
        hilog.warn(DOMAIN, TAG, '❌ Notification permission DENIED by user (status: %{public}d)', result.authResults[0]);
      }
      
      // 第二步：检查并启用通知
      try {
        const isEnabled = await notificationManager.isNotificationEnabled();
        hilog.info(DOMAIN, TAG, '🔔 Notification enabled status: %{public}s', isEnabled ? 'true' : 'false');
        
        if (!isEnabled) {
          hilog.warn(DOMAIN, TAG, '⚠️ Notification is disabled, requesting to enable...');
          await notificationManager.requestEnableNotification(this.context);
          
          // 再次检查
          const isEnabledAfter = await notificationManager.isNotificationEnabled();
          hilog.info(DOMAIN, TAG, '🔔 Notification status after request: %{public}s', isEnabledAfter ? 'ENABLED' : 'DISABLED');
        } else {
          hilog.info(DOMAIN, TAG, '✅ Notification already enabled');
        }
      } catch (notifyErr) {
        const error = notifyErr as BusinessError;
        hilog.error(DOMAIN, TAG, '❌ Enable notification failed: code=%{public}d, message=%{public}s', 
          error.code, error.message);
      }
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, '❌ Request notification permissions failed: code=%{public}d, message=%{public}s', 
        error.code, error.message);
    }
    hilog.info(DOMAIN, TAG, '========== Permission request completed ==========');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    // 先请求权限，再初始化数据和加载UI
    this.requestNotificationPermissions().then(() => {
      // 初始化数据管理器
      return this.initializeDataManager();
    }).then(() => {
      // 等待权限和初始化都完成后再加载内容
      windowStage.loadContent('pages/common/MainPage', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
      });
    }).catch((err:object) => {
      const e = ErrorUtils.toError(err)
      hilog.error(DOMAIN, TAG, 'Failed to initialize before loading content: %{public}s', JSON.stringify(e));
      // 即使初始化失败也要加载内容
      windowStage.loadContent('pages/common/MainPage', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(e));
          return;
        }
        hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
      });
    });
  }

  private async initializeDataManager(): Promise<void> {
    try {
      // 首先初始化RDB数据库（必须先初始化）
      await HealthRecordDatabase.getInstance().init(this.context);
      hilog.info(DOMAIN, TAG, '%{public}s', 'HealthRecordDatabase initialized successfully');
      
      // 再初始化Preferences管理器
      await UserPreferenceManager.getInstance().init(this.context);
      hilog.info(DOMAIN, TAG, '%{public}s', 'UserPreferenceManager initialized successfully');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize data managers: %{public}s', JSON.stringify(err));
    }
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