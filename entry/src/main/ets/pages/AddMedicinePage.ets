import  router from '@ohos.router';
import { HealthDataManager } from '../utils/HealthDataManager';
import { MedicineData,RemindTime } from '../models/MedicineData';
import { promptAction } from '@kit.ArkUI';
import { NotificationManager } from '../utils/NotificationManager';

@Entry
@Component
struct AddMedicinePage {
  @State medicineName: string = '';
  @State specification: string = '';
  @State dosage: string = '';
  @State frequency: string[] = [];
  @State reminderTimes: Map<string, RemindTime> = this.getDefaultReminderTimes();
  @State stock: string = '';
  @State startDate: number = Date.now();
  @State endDate: number = Date.now() + 30 * 24 * 60 * 60 * 1000;
  @State note: string = '';

  // 获取默认提醒时间
  getDefaultReminderTimes(): Map<string, RemindTime> {
    const map = new Map<string, RemindTime>();
    const morningTime: RemindTime = { hour: 8, minute: 0 };
    const noonTime: RemindTime = { hour: 12, minute: 0 };
    const eveningTime: RemindTime = { hour: 18, minute: 0 };
    const bedtimeTime: RemindTime = { hour: 22, minute: 0 };
    
    map.set('morning', morningTime);
    map.set('noon', noonTime);
    map.set('evening', eveningTime);
    map.set('bedtime', bedtimeTime);
    
    return map;
  }

  async saveData() {
    if (!this.medicineName) {
      promptAction.showToast({ message: '请输入药品名称' });
      return;
    }

    if (this.frequency.length === 0) {
      promptAction.showToast({ message: '请选择服用时间' });
      return;
    }

    const medicine = new MedicineData();
    medicine.name = this.medicineName;
    medicine.specification = this.specification;
    medicine.dosage = this.dosage;
    medicine.frequency = this.frequency;
    medicine.reminderTimes = new Map(this.reminderTimes);
    medicine.stock = this.stock ? parseInt(this.stock) : 0;
    medicine.startDate = this.startDate;
    medicine.endDate = this.endDate;
    medicine.note = this.note;

    await HealthDataManager.getInstance().saveMedicine(medicine);
    
    // 生成今日用药记录
    await HealthDataManager.getInstance().generateTodayMedicineRecords();
    
    // 创建用药提醒通知
    await this.createMedicineReminders(medicine);
    
    promptAction.showToast({ message: '保存成功，已设置用药提醒' });
    router.back();
  }

  // 获取服用时间对应的小时和分钟
  getReminderTime(timeSlot: string): RemindTime {
    const time = this.reminderTimes.get(timeSlot);
    return time || { hour: 8, minute: 0 };
  }

  // 显示时间选择器
  showTimePickerForSlot(timeSlot: string) {
    const currentTime = this.reminderTimes.get(timeSlot) || { hour: 8, minute: 0 };
    const selectedDate = new Date();
    selectedDate.setHours(currentTime.hour, currentTime.minute);

    TimePickerDialog.show({
      selected: selectedDate,
      useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        const newTime: RemindTime = {
          hour: value.hour as number,
          minute: value.minute as number
        };
        this.reminderTimes.set(timeSlot, newTime);
        this.reminderTimes = new Map(this.reminderTimes); // 触发UI更新
        promptAction.showToast({ 
          message: `已设置为 ${String(newTime.hour).padStart(2, '0')}:${String(newTime.minute).padStart(2, '0')}` 
        });
      }
    });
  }

  // 格式化时间显示
  formatTime(timeSlot: string): string {
    const time = this.reminderTimes.get(timeSlot);
    if (!time) return '';
    return `${String(time.hour).padStart(2, '0')}:${String(time.minute).padStart(2, '0')}`;
  }

  // 创建用药提醒
  async createMedicineReminders(medicine: MedicineData) {
    const notificationMgr = NotificationManager.getInstance();

    // 为每个服用时间创建提醒
    for (const time of medicine.frequency) {
      const timeInfo = this.getReminderTime(time);
      const reminderId = parseInt(medicine.id.substring(0, 8), 36) + time.charCodeAt(0);
      
      const success = await notificationMgr.createMedicineReminder(
        reminderId,
        medicine.name,
        timeInfo.hour,
        timeInfo.minute,
        `${medicine.name}用药提醒`
      );
      
      if (!success) {
        console.warn(`Failed to create reminder for ${medicine.name} at ${timeInfo.hour}:${timeInfo.minute}`);
      }
    }
  }

  toggleFrequency(time: string) {
    const index = this.frequency.indexOf(time);
    if (index >= 0) {
      this.frequency.splice(index, 1);
    } else {
      this.frequency.push(time);
    }
    this.frequency = [...this.frequency];
  }

  // 显示开始日期选择器
  showStartDatePicker() {
    DatePickerDialog.show({
      start: new Date(),
      end: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 一年后
      selected: new Date(this.startDate),
      lunar: false,
      onAccept: (value: DatePickerResult) => {
        const year = value.year as number;
        const month = value.month as number;
        const day = value.day as number;
        this.startDate = new Date(year, month, day).getTime();
        
        // 如果开始日期大于结束日期，自动调整结束日期
        if (this.startDate > this.endDate) {
          this.endDate = this.startDate + 30 * 24 * 60 * 60 * 1000; // 默认30天后
        }
      }
    });
  }

  // 显示结束日期选择器
  showEndDatePicker() {
    DatePickerDialog.show({
      start: new Date(this.startDate),
      end: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 一年后
      selected: new Date(this.endDate),
      lunar: false,
      onAccept: (value: DatePickerResult) => {
        const year = value.year as number;
        const month = value.month as number;
        const day = value.day as number;
        this.endDate = new Date(year, month, day).getTime();
        
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

            Column({ space: 8 }) {
              this.TimeCard('早上', 'morning', this.frequency.includes('morning'))
              this.TimeCard('中午', 'noon', this.frequency.includes('noon'))
              this.TimeCard('晚上', 'evening', this.frequency.includes('evening'))
              this.TimeCard('睡前', 'bedtime', this.frequency.includes('bedtime'))
            }
            .width('100%')
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
          .backgroundColor('#FF9800')
          .borderRadius(24)
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
  TimeCard(text: string, timeSlot: string, selected: boolean) {
    Row() {
      Checkbox()
        .select(selected)
        .onChange((value: boolean) => {
          this.toggleFrequency(timeSlot);
        })
        .margin({ right: 12 })

      Column({ space: 4 }) {
        Text(text)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F')
        
        Text(this.formatTime(timeSlot))
          .fontSize(12)
          .fontColor('#757575')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button('设置时间')
        .fontSize(14)
        .height(32)
        .backgroundColor(selected ? '#FF9800' : '#E0E0E0')
        .fontColor(selected ? '#FFFFFF' : '#9E9E9E')
        .enabled(selected)
        .onClick(() => {
          if (selected) {
            this.showTimePickerForSlot(timeSlot);
          }
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
  }
}

