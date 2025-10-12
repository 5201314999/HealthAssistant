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
  @State stock: string = '';
  @State startDate: number = Date.now();
  @State endDate: number = Date.now() + 30 * 24 * 60 * 60 * 1000;
  @State note: string = '';

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
    switch (timeSlot) {
      case 'morning':
        return { hour: 8, minute: 0 };
      case 'noon':
        return { hour: 12, minute: 0 };
      case 'evening':
        return { hour: 18, minute: 0 };
      case 'bedtime':
        return { hour: 22, minute: 0 };
      default:
        return { hour: 8, minute: 0 };
    }
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

        Text('保存')
          .fontSize(16)
          .fontColor('#FF9800')
          .onClick(() => {
            this.saveData();
          })
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

            Row({ space: 12 }) {
              this.TimeButton('早上', this.frequency.includes('morning'), () => {
                this.toggleFrequency('morning');
              })

              this.TimeButton('中午', this.frequency.includes('noon'), () => {
                this.toggleFrequency('noon');
              })

              this.TimeButton('晚上', this.frequency.includes('evening'), () => {
                this.toggleFrequency('evening');
              })

              this.TimeButton('睡前', this.frequency.includes('bedtime'), () => {
                this.toggleFrequency('bedtime');
              })
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
                  // 这里可以打开日期选择器
                  promptAction.showToast({ message: '日期选择功能待完善' });
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
                  // 这里可以打开日期选择器
                  promptAction.showToast({ message: '日期选择功能待完善' });
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
        .padding({ bottom: 20 })
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TimeButton(text: string, selected: boolean, onClick: () => void) {
    Text(text)
      .fontSize(14)
      .fontColor(selected ? '#FFFFFF' : '#FF9800')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(selected ? '#FF9800' : '#FFF3E0')
      .borderRadius(16)
      .onClick(onClick)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
  }
}

