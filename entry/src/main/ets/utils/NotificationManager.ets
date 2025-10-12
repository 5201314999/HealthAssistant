import { wantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';

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
      // 创建 WantAgent（用于点击通知后打开应用）
      const wantAgentInfo:wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: 'com.example.medicalassistant',
            abilityName: 'EntryAbility',
            parameters: {
              action: 'medicine_reminder'
            }
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
      console.info(`Medicine reminder created for ${medicineName} at ${hour}:${minute}`);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Create medicine reminder failed: code: ${error.code}, message: ${error.message}`);
      return false;
    }
  }

  /**
   * 取消提醒
   */
  async cancelReminder(reminderId: number): Promise<boolean> {
    try {
      await reminderAgentManager.cancelReminder(reminderId);
      console.info(`Reminder ${reminderId} cancelled`);
      return true;
    } catch (err) {
      console.error('Cancel reminder failed:', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 取消所有提醒
   */
  async cancelAllReminders(): Promise<void> {
    try {
      await reminderAgentManager.cancelAllReminders();
      console.info('All reminders cancelled');
    } catch (err) {
      console.error('Cancel all reminders failed:', JSON.stringify(err));
    }
  }

  /**
   * 获取所有有效的提醒
   */
  async getAllReminders(): Promise<Array<reminderAgentManager.ReminderRequest>> {
    try {
      return await reminderAgentManager.getValidReminders();
    } catch (err) {
      console.error('Get all reminders failed:', JSON.stringify(err));
      return [];
    }
  }
}

