import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HealthRecordDatabase } from '../../utils/HealthRecordDatabase';
import { MedicineData, RemindTime } from '../../models/MedicineData';
import { promptAction } from '@kit.ArkUI';
import { NotificationManager, RemainState } from '../../utils/NotificationManager';
import common from '@ohos.app.ability.common';
import { abilityAccessCtrl, Want, Permissions } from '@kit.AbilityKit';
import notificationManager from '@ohos.notificationManager';

const TAG = 'AddMedicinePage';
const DOMAIN = 0x0000;

// 自定义时间项接口
interface CustomTimeItem {
  id: string;
  hour: number;
  minute: number;
  label: string; // 用于显示的标签
}

// 快捷时间选项接口
interface QuickTimeOption {
  hour: number;
  minute: number;
  label: string;
}

// 提醒创建结果接口
interface ReminderCreationResult {
  success: number;
  failed: number;
  permissionDenied: boolean;
}

@Entry
@Component
struct AddMedicinePage {
  @State medicineName: string = '';
  @State specification: string = '';
  @State dosage: string = '';
  @State customTimes: CustomTimeItem[] = []; // 改用自定义时间列表
  @State stock: string = '';
  @State startDate: number = (() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return today.getTime();
  })();
  @State endDate: number = (() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return today.getTime() + 30 * 24 * 60 * 60 * 1000;
  })();
  @State note: string = '';
  @State hasPermission: boolean = true; // 权限状态

  // 快捷时间选项
  private quickTimeOptions: QuickTimeOption[] = [
    { hour: 8, minute: 0, label: '早上 08:00' } as QuickTimeOption,
    { hour: 12, minute: 0, label: '中午 12:00' } as QuickTimeOption,
    { hour: 14, minute: 0, label: '下午 14:00' } as QuickTimeOption,
    { hour: 18, minute: 0, label: '晚上 18:00' } as QuickTimeOption,
    { hour: 22, minute: 0, label: '睡前 22:00' } as QuickTimeOption
  ];

  // 生成唯一ID
  generateTimeId(): string {
    return Date.now().toString() + Math.random().toString(36).substr(2, 9);
  }

  // 页面即将显示时检查权限
  async aboutToAppear() {
    this.hasPermission = await this.checkPermissionStatus();
  }

  // 检查权限状态和通知启用状态
  async checkPermissionStatus(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const context = getContext(this) as common.UIAbilityContext;
      
      // 检查权限
      const grantStatus = await atManager.checkAccessToken(
        context.applicationInfo.accessTokenId,
        'ohos.permission.PUBLISH_AGENT_REMINDER'
      );
      
      if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return false;
      }
      
      // 检查通知是否启用
      const isEnabled = await notificationManager.isNotificationEnabled();
      return isEnabled;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Check permission failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  // 确保权限已授予并且通知已启用
  async ensurePermission(): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const context = getContext(this) as common.UIAbilityContext;
      const permissions: Array<Permissions> = ['ohos.permission.PUBLISH_AGENT_REMINDER'];
      
      // 第一步：检查权限
      const grantStatus = await atManager.checkAccessToken(
        context.applicationInfo.accessTokenId,
        permissions[0]
      );
      
      hilog.info(DOMAIN, TAG, '🔍 Step 1 - Checking permission, status: %{public}d', grantStatus);
      
      if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        // 权限未授予，尝试请求
        hilog.info(DOMAIN, TAG, '⚠️ Permission not granted, requesting...');
        const result = await atManager.requestPermissionsFromUser(context, permissions);
        
        if (result.authResults[0] !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          hilog.warn(DOMAIN, TAG, '❌ Permission denied after request');
          this.hasPermission = false;
          return;
        }
        hilog.info(DOMAIN, TAG, '✅ Permission granted after request');
      } else {
        hilog.info(DOMAIN, TAG, '✅ Permission already granted');
      }
      
      // 第二步：检查通知是否启用
      try {
        const isEnabled = await notificationManager.isNotificationEnabled();
        hilog.info(DOMAIN, TAG, '🔍 Step 2 - Notification enabled status: %{public}s', isEnabled ? 'true' : 'false');
        
        if (!isEnabled) {
          hilog.warn(DOMAIN, TAG, '⚠️ Notification is disabled, requesting to enable...');
          // 请求启用通知
          await notificationManager.requestEnableNotification(context);
          hilog.info(DOMAIN, TAG, '✅ Notification enable request sent');
          
          // 再次检查
          const isEnabledAfter = await notificationManager.isNotificationEnabled();
          hilog.info(DOMAIN, TAG, '🔍 Notification status after request: %{public}s', isEnabledAfter ? 'true' : 'false');
          this.hasPermission = isEnabledAfter;
        } else {
          hilog.info(DOMAIN, TAG, '✅ Notification already enabled');
          this.hasPermission = true;
        }
      } catch (notifyErr) {
        hilog.error(DOMAIN, TAG, '❌ Check/enable notification failed: %{public}s', JSON.stringify(notifyErr));
        this.hasPermission = false;
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ Ensure permission failed: %{public}s', JSON.stringify(err));
      this.hasPermission = false;
    }
  }

  // 打开系统设置
  async openPermissionSettings() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      
      // 跳转到应用详情页
      const wantInfo: Want = {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: 'application_info_entry',
        parameters: {
          pushParams: context.applicationInfo.name
        }
      };
      
      await context.startAbility(wantInfo);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Open settings failed: %{public}s', JSON.stringify(err));
      promptAction.showToast({ 
        message: '请在"设置 > 应用 > 慢性病助手 > 权限"中手动开启通知权限',
        duration: 3000
      });
    }
  }

  async saveData() {
    hilog.debug(DOMAIN, TAG, 'saveData called');
    if (!this.medicineName) {
      promptAction.showToast({ message: '请输入药品名称' });
      return;
    }

    if (this.customTimes.length === 0) {
      promptAction.showToast({ message: '请添加至少一个服用时间' });
      return;
    }

    // 在保存前再次检查并请求权限
    await this.ensurePermission();

    const medicine = new MedicineData();
    medicine.name = this.medicineName;
    medicine.specification = this.specification;
    medicine.dosage = this.dosage;
    
    // 将自定义时间转换为旧的数据格式以保持兼容性
    medicine.frequency = this.customTimes.map((_, index) => `time_${index}`);
    const reminderTimesObj: Record<string, RemindTime> = {};
    this.customTimes.forEach((time, index) => {
      reminderTimesObj[`time_${index}`] = { hour: time.hour, minute: time.minute };
    });
    medicine.reminderTimes = reminderTimesObj;
    
    medicine.stock = this.stock ? parseInt(this.stock) : 0;
    medicine.startDate = this.startDate;
    medicine.endDate = this.endDate;
    medicine.note = this.note;

    hilog.info(DOMAIN, TAG, '💊 Saving medicine: %{public}s, startDate: %{public}s, endDate: %{public}s',
      medicine.name,
      new Date(medicine.startDate).toLocaleString('zh-CN'),
      new Date(medicine.endDate).toLocaleString('zh-CN'));

    await HealthRecordDatabase.getInstance().saveMedicine(medicine);
    
    // 生成今日用药记录
    await HealthRecordDatabase.getInstance().generateTodayMedicineRecords();
    
    // 创建用药提醒通知
    const reminderResult = await this.createMedicineReminders(medicine);
    
    // 根据提醒创建结果显示不同的消息
    if (reminderResult.permissionDenied) {
      // 权限被拒绝，显示对话框引导用户开启权限
      hilog.warn(DOMAIN, TAG, 'Permission denied, showing alert to user');
      this.getUIContext().showAlertDialog({
        title: '药品已保存',
        message: '通知权限未开启，无法创建用药提醒。\n\n请按以下步骤开启：\n1. 点击"去设置"按钮\n2. 找到"通知管理"\n3. 开启"允许通知"',
        primaryButton: {
          value: '去设置',
          action: () => {
            this.openPermissionSettings();
          }
        },
        secondaryButton: {
          value: '稍后再说',
          action: () => {
            router.back();
          }
        }
      });
    } else {
      // 权限正常，显示普通提示
      let message = '药品保存成功';
      if (reminderResult.success > 0 && reminderResult.failed === 0) {
        message += '，已设置用药提醒';
        hilog.info(DOMAIN, TAG, '✅ All reminders created successfully');
      } else if (reminderResult.success > 0 && reminderResult.failed > 0) {
        message += `，已为 ${reminderResult.success} 个时间设置提醒`;
        hilog.warn(DOMAIN, TAG, '⚠️ Partial success: %{public}d succeeded, %{public}d failed', 
          reminderResult.success, reminderResult.failed);
      }
      promptAction.showToast({ message: message });
      router.back();
    }
  }

  // 添加快捷时间
  addQuickTime(hour: number, minute: number, label: string) {
    // 检查是否已存在相同时间
    const exists = this.customTimes.some(time => time.hour === hour && time.minute === minute);
    if (exists) {
      promptAction.showToast({ message: '该时间已添加' });
      return;
    }

    const newTime: CustomTimeItem = {
      id: this.generateTimeId(),
      hour: hour,
      minute: minute,
      label: label
    };
    this.customTimes.push(newTime);
    this.customTimes = [...this.customTimes]; // 触发UI更新
    promptAction.showToast({ message: `已添加 ${label}` });
  }

  // 显示自定义时间选择器
  showCustomTimePicker() {
    const selectedDate = new Date();
    selectedDate.setHours(8, 0); // 默认8点

    this.getUIContext().showTimePickerDialog({
      selected: selectedDate,
      onAccept: (value) => {
        const hour = value.hour;
        const minute = value.minute;
        
        // 检查是否已存在相同时间
        const exists = this.customTimes.some(time => time.hour === hour && time.minute === minute);
        if (exists) {
          promptAction.showToast({ message: '该时间已添加' });
          return;
        }

        const timeStr = `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
        const newTime: CustomTimeItem = {
          id: this.generateTimeId(),
          hour: hour,
          minute: minute,
          label: timeStr
        };
        this.customTimes.push(newTime);
        this.customTimes = [...this.customTimes]; // 触发UI更新
        promptAction.showToast({ message: `已添加 ${timeStr}` });
      }
    });
  }

  // 删除时间
  deleteTime(id: string) {
    const index = this.customTimes.findIndex(time => time.id === id);
    if (index >= 0) {
      this.customTimes.splice(index, 1);
      this.customTimes = [...this.customTimes];
    }
  }

  // 格式化时间显示
  formatTimeDisplay(hour: number, minute: number): string {
    return `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
  }

  // 创建用药提醒
  async createMedicineReminders(medicine: MedicineData): Promise<ReminderCreationResult> {
    const notificationMgr = NotificationManager.getInstance();
    
    let successCount = 0;
    let failCount = 0;
    let permissionDenied = false;
    
    // 检查当前提醒数量
    let stats: RemainState | null = null;
    try {
      stats = await notificationMgr.getReminderStats();
      hilog.info(DOMAIN, TAG, 'Current reminder stats: %{public}d/%{public}d', stats.current, stats.max);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Get reminder stats failed: code:%{public}d', error.code);
      
      // 如果是通知权限未开启（1700001）
      if (error.code === 1700001) {
        permissionDenied = true;
        const result: ReminderCreationResult = {
          success: 0,
          failed: this.customTimes.length,
          permissionDenied: true
        };
        return result;
      }
    }
    
    // 如果剩余提醒数不足以创建新提醒
    if (stats && stats.remaining < this.customTimes.length) {
      hilog.warn(DOMAIN, TAG, 'Not enough reminder slots. Required: %{public}d, Remaining: %{public}d', 
        this.customTimes.length, stats.remaining);
    }

    // 为每个服用时间创建提醒
    for (let i = 0; i < this.customTimes.length; i++) {
      const time = this.customTimes[i];
      const reminderId = parseInt(medicine.id.substring(0, 8), 36) + i;
      
      const success = await notificationMgr.createMedicineReminder(
        reminderId,
        medicine.name,
        time.hour,
        time.minute,
        `${medicine.name}用药提醒`
      );
      
      if (success) {
        successCount++;
        hilog.debug(DOMAIN, TAG, 'Reminder created for %{public}s at %{public}d:%{public}d', 
          medicine.name, time.hour, time.minute);
      } else {
        failCount++;
        hilog.warn(DOMAIN, TAG, `Failed to create reminder for ${medicine.name} at ${time.hour}:${time.minute}`);
      }
    }
    
    hilog.info(DOMAIN, TAG, 'Reminder creation complete: %{public}d succeeded, %{public}d failed', successCount, failCount);
    
    // 如果所有提醒都创建失败，很可能是权限问题
    if (successCount === 0 && failCount > 0) {
      // 重新检查权限状态
      const hasPermission = await this.checkPermissionStatus();
      if (!hasPermission) {
        permissionDenied = true;
      }
    }
    
    const result: ReminderCreationResult = {
      success: successCount,
      failed: failCount,
      permissionDenied: permissionDenied
    };
    return result;
  }

  // 显示开始日期选择器
  showStartDatePicker() {
    this.getUIContext().showDatePickerDialog({
      start: new Date(),
      end: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 一年后
      selected: new Date(this.startDate),
      onDateAccept: (value:Date) => {
        // 将选择的日期设置为当天 00:00:00
        value.setHours(0, 0, 0, 0);
        this.startDate = value.getTime();
        
        // 如果开始日期大于结束日期，自动调整结束日期
        if (this.startDate > this.endDate) {
          this.endDate = this.startDate + 30 * 24 * 60 * 60 * 1000; // 默认30天后
        }
      }
    });
  }

  // 显示结束日期选择器
  showEndDatePicker() {
    this.getUIContext().showDatePickerDialog({
      start: new Date(this.startDate),
      end: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 一年后
      selected: new Date(this.endDate),
      onDateAccept: (value) => {
        // 将选择的日期设置为当天 00:00:00
        value.setHours(0, 0, 0, 0);
        this.endDate = value.getTime();
        
        // 如果结束日期小于开始日期，自动调整开始日期
        if (this.endDate < this.startDate) {
          // 调整开始日期也要是 00:00:00
          const adjustedStart = new Date(this.endDate - 30 * 24 * 60 * 60 * 1000);
          adjustedStart.setHours(0, 0, 0, 0);
          this.startDate = adjustedStart.getTime();
          
          const today = new Date();
          today.setHours(0, 0, 0, 0);
          if (this.startDate < today.getTime()) {
            this.startDate = today.getTime();
          }
        }
      }
    });
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Image($r('sys.media.ohos_ic_public_cancel'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })

        Text('添加药品')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位元素保持标题居中
        Row()
          .width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 16 }) {
          // 基本信息
          Column({ space: 12 }) {
            Text('基本信息')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F1F1F')
              .alignSelf(ItemAlign.Start)

            Column({ space: 8 }) {
              Text('药品名称 *')
                .fontSize(14)
                .fontColor('#424242')
                .alignSelf(ItemAlign.Start)
              
              TextInput({ placeholder: '请输入药品名称', text: this.medicineName })
                .onChange((value: string) => {
                  this.medicineName = value;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('规格')
                .fontSize(14)
                .fontColor('#424242')
                .alignSelf(ItemAlign.Start)
              
              TextInput({ placeholder: '如：50mg/片', text: this.specification })
                .onChange((value: string) => {
                  this.specification = value;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('用法用量')
                .fontSize(14)
                .fontColor('#424242')
                .alignSelf(ItemAlign.Start)
              
              TextInput({ placeholder: '如：一次1片', text: this.dosage })
                .onChange((value: string) => {
                  this.dosage = value;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('库存数量')
                .fontSize(14)
                .fontColor('#424242')
                .alignSelf(ItemAlign.Start)
              
              TextInput({ placeholder: '当前药品数量', text: this.stock })
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.stock = value;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 16 })

          // 服用时间
          Column({ space: 12 }) {
            Text('服用时间 *')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F1F1F')
              .alignSelf(ItemAlign.Start)

            // 权限警告提示
            if (!this.hasPermission) {
              Row() {
                // Image($r('sys.media.ohos_ic_public_warn'))
                //   .width(16)
                //   .height(16)
                //   .fillColor('#FF9800')
                //
                Text('通知权限未开启，将无法收到用药提醒')
                  .fontSize(12)
                  .fontColor('#FF9800')
                  .layoutWeight(1)
                  .margin({ left: 4 })
                
                Text('去开启')
                  .fontSize(12)
                  .fontColor('#2196F3')
                  .fontWeight(FontWeight.Medium)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#E3F2FD')
                  .borderRadius(4)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.openPermissionSettings();
                  })
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFF3E0')
              .borderRadius(8)
            }

            // 快捷时间选择
            Column({ space: 8 }) {
              Text('快捷添加')
                .fontSize(14)
                .fontColor('#757575')
                .alignSelf(ItemAlign.Start)
              
              // 快捷时间按钮
              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                ForEach(this.quickTimeOptions, (option: QuickTimeOption) => {
                  Button(option.label)
                    .fontSize(12)
                    .height(32)
                    .backgroundColor('#E3F2FD')
                    .fontColor('#2196F3')
                    .margin({ right: 8, bottom: 8 })
                    .onClick(() => {
                      this.addQuickTime(option.hour, option.minute, option.label);
                    })
                })
              }
              .width('100%')
              
              // 自定义添加按钮
              Button('+ 自定义时间')
                .fontSize(14)
                .height(40)
                .width('100%')
                .backgroundColor('#F5F5F5')
                .fontColor('#2196F3')
                .borderRadius(8)
                .onClick(() => {
                  this.showCustomTimePicker();
                })
            }
            .width('100%')

            // 已添加的时间列表
            if (this.customTimes.length > 0) {
              Column({ space: 8 }) {
                Text('已添加的时间')
                  .fontSize(14)
                  .fontColor('#757575')
                  .alignSelf(ItemAlign.Start)
                  .margin({ top: 8 })
                
                ForEach(this.customTimes, (timeItem: CustomTimeItem) => {
                  this.CustomTimeCard(timeItem)
                })
              }
              .width('100%')
            } else {
              Text('请至少添加一个服用时间')
                .fontSize(14)
                .fontColor('#FF9800')
                .alignSelf(ItemAlign.Start)
                .margin({ top: 8 })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16 })

          // 用药周期
          Column({ space: 12 }) {
            Text('用药周期')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F1F1F')
              .alignSelf(ItemAlign.Start)

            Row() {
              Text('开始日期')
                .fontSize(14)
                .fontColor('#424242')
                .width(80)
              
              Text(new Date(this.startDate).toLocaleDateString('zh-CN'))
                .fontSize(14)
                .fontColor('#2196F3')
                .layoutWeight(1)
                .onClick(() => {
                  this.showStartDatePicker();
                })
            }
            .width('100%')

            Row() {
              Text('结束日期')
                .fontSize(14)
                .fontColor('#424242')
                .width(80)
              
              Text(new Date(this.endDate).toLocaleDateString('zh-CN'))
                .fontSize(14)
                .fontColor('#2196F3')
                .layoutWeight(1)
                .onClick(() => {
                  this.showEndDatePicker();
                })
            }
            .width('100%')

            // 快捷设置
            Row({ space: 8 }) {
              Text('快捷设置：')
                .fontSize(12)
                .fontColor('#757575')
              
              Text('7天')
                .fontSize(12)
                .fontColor('#2196F3')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor('#E3F2FD')
                .borderRadius(4)
                .onClick(() => {
                  this.endDate = this.startDate + 7 * 24 * 60 * 60 * 1000;
                })
              
              Text('30天')
                .fontSize(12)
                .fontColor('#2196F3')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor('#E3F2FD')
                .borderRadius(4)
                .onClick(() => {
                  this.endDate = this.startDate + 30 * 24 * 60 * 60 * 1000;
                })
              
              Text('90天')
                .fontSize(12)
                .fontColor('#2196F3')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor('#E3F2FD')
                .borderRadius(4)
                .onClick(() => {
                  this.endDate = this.startDate + 90 * 24 * 60 * 60 * 1000;
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16 })

          // 备注
          Column({ space: 8 }) {
            Text('备注')
              .fontSize(14)
              .fontColor('#424242')
              .alignSelf(ItemAlign.Start)

            TextArea({ placeholder: '添加备注信息（选填）', text: this.note })
              .height(100)
              .onChange((value: string) => {
                this.note = value;
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16 })
        }
        .padding({ bottom: 80 })
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      // 底部保存按钮
      Column() {
        Button('保存')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(24)
          .backgroundColor($r('app.color.primary'))
          .onClick(() => {
            this.saveData();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .shadow({
        radius: 8,
        color: '#10000000',
        offsetY: -2
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CustomTimeCard(timeItem: CustomTimeItem) {
    Row() {
      // 时间显示区域
      Row({ space: 8 }) {
        // 时钟图标（使用文字表情代替）
        Text('🕐')
          .fontSize(20)
        
        Column({ space: 2 }) {
          Text(timeItem.label)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F1F1F')
          
          Text(this.formatTimeDisplay(timeItem.hour, timeItem.minute))
            .fontSize(12)
            .fontColor('#757575')
        }
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)

      // 删除按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.delete'))
          .width(20)
          .height(20)
          // .fillColor('#F44336')
      }
      .width(36)
      .height(36)
      .backgroundColor('#F44336')
      .onClick(() => {
        this.deleteTime(timeItem.id);
      })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
  }
}

