import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HealthRecordDatabase } from '../../utils/HealthRecordDatabase';
import { MedicineData, RemindTime } from '../../models/MedicineData';
import { promptAction } from '@kit.ArkUI';
import { NotificationManager } from '../../utils/NotificationManager';
import common from '@ohos.app.ability.common';

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

@Entry
@Component
struct AddMedicinePage {
  @State medicineName: string = '';
  @State specification: string = '';
  @State dosage: string = '';
  @State customTimes: CustomTimeItem[] = []; // 改用自定义时间列表
  @State stock: string = '';
  @State startDate: number = Date.now();
  @State endDate: number = Date.now() + 30 * 24 * 60 * 60 * 1000;
  @State note: string = '';

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

    await HealthRecordDatabase.getInstance().saveMedicine(medicine);
    
    // 生成今日用药记录
    await HealthRecordDatabase.getInstance().generateTodayMedicineRecords();
    
    // 创建用药提醒通知
    await this.createMedicineReminders(medicine);
    
    promptAction.showToast({ message: '保存成功，已设置用药提醒' });
    router.back();
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
  async createMedicineReminders(medicine: MedicineData) {
    const notificationMgr = NotificationManager.getInstance();
    
    // 检查当前提醒数量
    const stats = await notificationMgr.getReminderStats();
    hilog.info(DOMAIN, TAG, 'Current reminder stats: %{public}d/%{public}d', stats.current, stats.max);
    
    // 如果剩余提醒数不足以创建新提醒
    if (stats.remaining < this.customTimes.length) {
      hilog.warn(DOMAIN, TAG, 'Not enough reminder slots. Required: %{public}d, Remaining: %{public}d', 
        this.customTimes.length, stats.remaining);
      promptAction.showToast({ 
        message: `提醒数量已达上限，仅为部分时间设置提醒` 
      });
    }

    let successCount = 0;
    let failCount = 0;

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
    
    // 显示提醒创建结果
    if (failCount > 0) {
      hilog.warn(DOMAIN, TAG, 'Reminder creation: %{public}d succeeded, %{public}d failed', successCount, failCount);
      promptAction.showToast({ 
        message: `已为 ${successCount} 个时间设置提醒，${failCount} 个失败（提醒数达上限）` 
      });
    }
  }

  // 显示开始日期选择器
  showStartDatePicker() {
    this.getUIContext().showDatePickerDialog({
      start: new Date(),
      end: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 一年后
      selected: new Date(this.startDate),
      onDateAccept: (value:Date) => {
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
        this.endDate = value.getTime();
        
        // 如果结束日期小于开始日期，自动调整开始日期
        if (this.endDate < this.startDate) {
          this.startDate = this.endDate - 30 * 24 * 60 * 60 * 1000; // 默认30天前
          if (this.startDate < Date.now()) {
            this.startDate = Date.now();
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

