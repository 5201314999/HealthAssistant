import { wantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';

const TAG = 'NotificationManager';
const DOMAIN = 0x0000;
const MAX_REMINDERS_LIMIT = 30;  // 系统允许的最大提醒数
const KEEP_REMINDERS_COUNT = 15;  // 清理时保留的提醒数


interface RemainState{ current: number; max: number; remaining: number }

/**
 * 通知管理器
 * 负责药物提醒功能（使用后台代理提醒）
 */
export class NotificationManager {
  private static instance: NotificationManager;

  private constructor() {}

  static getInstance(): NotificationManager {
    if (!NotificationManager.instance) {
      NotificationManager.instance = new NotificationManager();
    }
    return NotificationManager.instance;
  }

  /**
   * 检查并清理过期提醒
   * 当提醒数量接近限制时，删除旧提醒
   */
  private async checkAndCleanReminders(): Promise<void> {
    try {
      const currentReminders = await this.getAllReminders();
      const reminderCount = currentReminders.length;
      
      hilog.debug(DOMAIN, TAG, 'Current reminders count: %{public}d', reminderCount);
      
      // 如果提醒数量超过安全阈值，清理旧提醒
      if (reminderCount >= MAX_REMINDERS_LIMIT - 5) {  // 提前5个时清理
        hilog.warn(DOMAIN, TAG, 'Reminders approaching limit (%{public}d/%{public}d), cleaning old reminders', 
          reminderCount, MAX_REMINDERS_LIMIT);
        
        // 按创建时间排序（假设前面的是旧提醒）
        const itemsToCancel = currentReminders.slice(0, reminderCount - KEEP_REMINDERS_COUNT);
        
        hilog.info(DOMAIN, TAG, 'Cancelling %{public}d old reminders', itemsToCancel.length);
        
        for (const reminder of itemsToCancel) {
          try {
            await reminderAgentManager.cancelReminder(reminder.notificationId);
            hilog.debug(DOMAIN, TAG, 'Cancelled old reminder: %{public}d', reminder.notificationId);
          } catch (err) {
            hilog.warn(DOMAIN, TAG, 'Failed to cancel reminder %{public}d: %{public}s', 
              reminder.notificationId, JSON.stringify(err));
          }
        }
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Check and clean reminders failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 创建用药提醒（使用后台代理提醒）
   * @param reminderId 提醒ID
   * @param medicineName 药物名称
   * @param hour 小时（0-23）
   * @param minute 分钟（0-59）
   * @param title 提醒标题
   */
  async createMedicineReminder(
    reminderId: number,
    medicineName: string,
    hour: number,
    minute: number,
    title: string = '用药提醒'
  ): Promise<boolean> {
    try {
      // 在创建新提醒前，检查并清理过期提醒
      await this.checkAndCleanReminders();
      
      // 创建 WantAgent（用于点击通知后打开应用）
      const wantAgentInfo:wantAgent.WantAgentInfo = {
        wants: [
          {
            deviceId:"",
            bundleName: 'cn.myapp.medicalassistant',
            abilityName: 'EntryAbility',
            parameters: {
              action: 'medicine_reminder'
            }
            // action: "action.system.health.reminder"
          }
        ],
        requestCode: reminderId,
        operationType: wantAgent.OperationType.START_ABILITY,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };

      const myWantAgent = await wantAgent.getWantAgent(wantAgentInfo);


      // 定义按钮接口
      interface ActionButton {
        title: string;
        type: reminderAgentManager.ActionButtonType;
      }

      // 创建按钮数组
      const actionButtons: [ActionButton,ActionButton] = [
        {
          title: '已服用',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
        },
        {
          title: '稍后提醒',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_SNOOZE
        }
      ];

      // 创建定时提醒
      const reminderRequest: reminderAgentManager.ReminderRequestAlarm = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
        hour: hour,
        minute: minute,
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // 每天重复
        title: title,
        ringDuration: 5, // 响铃时长（秒）
        snoozeTimes: 3, // 延迟提醒次数
        timeInterval: 300, // 延迟间隔（秒）
        actionButton: actionButtons,
        wantAgent: myWantAgent as reminderAgentManager.WantAgent,
        content: `该服用 ${medicineName} 了`,
        expiredContent: `您错过了 ${medicineName} 的服用时间`,
        snoozeContent: `${medicineName} 再次提醒`,
        notificationId: reminderId
      };

      await reminderAgentManager.publishReminder(reminderRequest);
      hilog.info(DOMAIN, TAG, 'Medicine reminder created for %{public}s at %{public}d:%{public}d', medicineName, hour, minute);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Create medicine reminder failed: code:%{public}d, message:%{public}s', error.code, error.message);
      
      // 如果是超过限制的错误码（1700002）
      if (error.code === 1700002) {
        hilog.warn(DOMAIN, TAG, 'Reminder limit exceeded, attempting to clean old reminders');
        // 尝试更激进的清理
        try {
          const currentReminders = await this.getAllReminders();
          if (currentReminders.length > 0) {
            // 删除最旧的几个提醒
            const itemsToCancel = currentReminders.slice(0, Math.ceil(currentReminders.length * 0.3));
            for (const reminder of itemsToCancel) {
              await reminderAgentManager.cancelReminder(reminder.notificationId);
            }
            // 重试创建提醒
            return await this.createMedicineReminder(reminderId, medicineName, hour, minute, title);
          }
        } catch (cleanErr) {
          hilog.error(DOMAIN, TAG, 'Cleanup and retry failed: %{public}s', JSON.stringify(cleanErr));
        }
      }
      return false;
    }
  }

  /**
   * 取消提醒
   */
  async cancelReminder(reminderId: number): Promise<boolean> {
    try {
      await reminderAgentManager.cancelReminder(reminderId);
      hilog.info(DOMAIN, TAG, 'Reminder %{public}d cancelled', reminderId);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Cancel reminder failed:%{public}s', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 取消所有提醒
   */
  async cancelAllReminders(): Promise<void> {
    try {
      await reminderAgentManager.cancelAllReminders();
      hilog.info(DOMAIN, TAG, 'All reminders cancelled');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Cancel all reminders failed:%{public}s', JSON.stringify(err));
    }
  }

  /**
   * 获取所有有效的提醒
   */
  async getAllReminders(): Promise<Array<reminderAgentManager.ReminderRequest>> {
    try {
      return await reminderAgentManager.getValidReminders();
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Get all reminders failed:%{public}s', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 获取提醒数量统计
   */
  async getReminderStats(): Promise<RemainState> {
    try {
      const reminders = await this.getAllReminders();
      return {
        current: reminders.length,
        max: MAX_REMINDERS_LIMIT,
        remaining: MAX_REMINDERS_LIMIT - reminders.length
      };
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Get reminder stats failed:%{public}s', JSON.stringify(err));
      return {
        current: 0,
        max: MAX_REMINDERS_LIMIT,
        remaining: MAX_REMINDERS_LIMIT
      };
    }
  }
}

