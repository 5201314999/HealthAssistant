import router from '@ohos.router';
import { HealthDataManager } from '../../utils/HealthDataManager';
import { MedicineData, MedicineRecord, RemindTime } from '../../models/MedicineData';
import { promptAction } from '@kit.ArkUI';
import { NotificationManager } from '../../utils/NotificationManager';

@Entry
@Component
struct MedicineManagePage {
  @State currentTab: number = 0;
  @State medicineList: MedicineData[] = [];
  @State todayRecords: MedicineRecord[] = [];

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    this.medicineList = await HealthDataManager.getInstance().getMedicineList();
    this.todayRecords = await HealthDataManager.getInstance().getMedicineRecords(Date.now());
  }

  onPageShow() {
    this.loadData();
  }

  async toggleRecordStatus(record: MedicineRecord) {
    record.taken = !record.taken;
    record.takenTime = record.taken ? Date.now() : 0;
    await HealthDataManager.getInstance().saveMedicineRecord(record);
    await this.loadData();
    promptAction.showToast({ message: record.taken ? '已打卡' : '已取消打卡' });
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })

        Text('用药管理')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 24 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Tab切换
      Tabs({ barPosition: BarPosition.Start, index: this.currentTab }) {
        TabContent() {
          this.TodayRecordsView();
        }
        .tabBar('今日用药')

        TabContent() {
          this.MedicineListView();
        }
        .tabBar('药品列表')
      }
      .barMode(BarMode.Fixed)
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentTab = index;
      })

      // 底部按钮
      if (this.currentTab === 1) {
        Row() {
          Button('添加药品')
            .width('100%')
            .backgroundColor('#FF9800')
            .onClick(() => {
              router.pushUrl({ url: 'pages/medicine/AddMedicinePage' });
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TodayRecordsView() {
    if (this.todayRecords.length === 0) {
      Column() {
        Text('⏰')
          .fontSize(80)
          .margin({ top: 100 })
        
        Text('今日暂无用药记录')
          .fontSize(16)
          .fontColor('#9E9E9E')
          .margin({ top: 16 })
        
        Text('添加药品后会自动生成用药记录')
          .fontSize(14)
          .fontColor('#BDBDBD')
          .margin({ top: 8 })
        
        Button('添加药品')
          .width(200)
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#FF9800')
          .borderRadius(24)
          .margin({ top: 40 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/medicine/AddMedicinePage' });
          })
      }
      .width('100%')
      .height('100%')
    } else {
      Scroll() {
        Column({ space: 12 }) {
          // 统计信息
          Row() {
            Column() {
              Text(`${this.todayRecords.filter(r => r.taken).length}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#4CAF50')
              
              Text('已服用')
                .fontSize(12)
                .fontColor('#757575')
            }
            .layoutWeight(1)

            Column() {
              Text(`${this.todayRecords.filter(r => !r.taken).length}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF9800')
              
              Text('待服用')
                .fontSize(12)
                .fontColor('#757575')
            }
            .layoutWeight(1)

            Column() {
              Text(`${this.todayRecords.length}`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2196F3')
              
              Text('总计')
                .fontSize(12)
                .fontColor('#757575')
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)

          // 用药记录列表
          ForEach(this.todayRecords, (record: MedicineRecord) => {
            this.RecordCard(record);
          })
        }
        .padding(16)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
  }

  @Builder
  MedicineListView() {
    if (this.medicineList.length === 0) {
      Column() {
        Text('💊')
          .fontSize(80)
          .margin({ top: 100 })
        
        Text('暂无药品')
          .fontSize(16)
          .fontColor('#9E9E9E')
          .margin({ top: 16 })
        
        Text('点击下方按钮添加药品')
          .fontSize(14)
          .fontColor('#BDBDBD')
          .margin({ top: 8 })
      }
      .width('100%')
      .height('100%')
    } else {
      List({ space: 12 }) {
        ForEach(this.medicineList, (medicine: MedicineData) => {
          ListItem() {
            this.MedicineCard(medicine);
          }
        })
      }
      .width('100%')
      .height('100%')
      .padding(16)
      .backgroundColor('#F5F5F5')
    }
  }

  @Builder
  RecordCard(record: MedicineRecord) {
    Row() {
      Checkbox()
        .select(record.taken)
        .onChange((value: boolean) => {
          this.toggleRecordStatus(record);
        })
        .margin({ right: 12 })

      Column({ space: 4 }) {
        Text(record.medicineName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F')
          .decoration({ type: record.taken ? TextDecorationType.LineThrough : TextDecorationType.None })
        
        Text(this.getTimeName(record.time))
          .fontSize(12)
          .fontColor('#757575')
        
        if (record.taken && record.takenTime > 0) {
          Text(`已于 ${new Date(record.takenTime).toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })} 打卡`)
            .fontSize(11)
            .fontColor('#4CAF50')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (record.taken) {
        Image($r('sys.media.ohos_ic_public_ok'))
          .width(24)
          .height(24)
          .fillColor('#4CAF50')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  MedicineCard(medicine: MedicineData) {
    Column({ space: 8 }) {
      Row() {
        Text(medicine.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F')
          .layoutWeight(1)

        Text('×')
          .fontSize(24)
          .fontColor('#F44336')
          .fontWeight(FontWeight.Bold)
          .onClick(async () => {
            await HealthDataManager.getInstance().deleteMedicine(medicine.id);
            // 取消该药品的所有提醒
            await this.cancelMedicineReminders(medicine);
            await this.loadData();
            promptAction.showToast({ message: '删除成功' });
          })
      }
      .width('100%')

      if (medicine.specification) {
        Text(`规格：${medicine.specification}`)
          .fontSize(12)
          .fontColor('#757575')
          .width('100%')
      }

      if (medicine.dosage) {
        Text(`用法用量：${medicine.dosage}`)
          .fontSize(12)
          .fontColor('#757575')
          .width('100%')
      }

      Row() {
        Text('服用时间：')
          .fontSize(12)
          .fontColor('#757575')
        
        Text(medicine.frequency.map((f: string) => {
          const timeName = this.getTimeName(f);
          const reminderTime = medicine.reminderTimes.get(f);
          if (reminderTime) {
            const hour = String(reminderTime.hour).padStart(2, '0');
            const minute = String(reminderTime.minute).padStart(2, '0');
            return `${timeName}(${hour}:${minute})`;
          }
          return timeName;
        }).join('、'))
          .fontSize(12)
          .fontColor($r('app.color.primary'))
          .fontColor($r('app.color.primary'))
      }
      .width('100%')

      Row() {
        Text(`用药周期：${new Date(medicine.startDate).toLocaleDateString('zh-CN')} 至 ${new Date(medicine.endDate).toLocaleDateString('zh-CN')}`)
          .fontSize(12)
          .fontColor('#757575')
          .layoutWeight(1)
        
        if (medicine.stock > 0) {
          Text(`库存：${medicine.stock}`)
            .fontSize(12)
            .fontColor(medicine.stock < 10 ? '#F44336' : '#4CAF50')
        }
      }
      .width('100%')

      if (medicine.note) {
        Text(`备注：${medicine.note}`)
          .fontSize(12)
          .fontColor('#757575')
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
  
  getTimeName(time: string): string {
    switch (time) {
      case 'morning':
        return '早上';
      case 'noon':
        return '中午';
      case 'evening':
        return '晚上';
      case 'bedtime':
        return '睡前';
      default:
        return time;
    }
  }

  // 取消药品提醒
  async cancelMedicineReminders(medicine: MedicineData) {
    const notificationMgr = NotificationManager.getInstance();
    
    for (const time of medicine.frequency) {
      const reminderId = parseInt(medicine.id.substring(0, 8), 36) + time.charCodeAt(0);
      await notificationMgr.cancelReminder(reminderId);
    }
  }
}

