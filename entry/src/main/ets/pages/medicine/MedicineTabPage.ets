import router from '@ohos.router';
import { HealthRecordDatabase } from '../../utils/HealthRecordDatabase';
import { MedicineData, MedicineRecord } from '../../models/MedicineData';
import { promptAction } from '@kit.ArkUI';
import { NotificationManager } from '../../utils/NotificationManager';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MedicineTabPage';
const DOMAIN = 0x0000;

@Component
export struct MedicineTabPage {
  @State currentTab: number = 0;
  @State medicineList: MedicineData[] = [];
  @State todayRecords: MedicineRecord[] = [];

  async aboutToAppear() {
    hilog.debug(DOMAIN, TAG, 'aboutToAppear');
    await this.loadData();
  }

  onPageShow() {
    hilog.debug(DOMAIN, TAG, 'onPageShow - reloading data');
    this.loadData();
  }

  async loadData() {
    try {
      this.medicineList = await HealthRecordDatabase.getInstance().getMedicineList();
      this.todayRecords = await HealthRecordDatabase.getInstance().getMedicineRecords(Date.now());
      hilog.info(DOMAIN, TAG, 'Data loaded: %{public}d medicines, %{public}d today records', 
        this.medicineList.length, this.todayRecords.length);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to load data: %{public}s', JSON.stringify(err));
    }
  }

  async toggleRecordStatus(record: MedicineRecord) {
    record.taken = !record.taken;
    record.takenTime = record.taken ? Date.now() : 0;
    await HealthRecordDatabase.getInstance().saveMedicineRecord(record);
    await this.loadData();
    promptAction.showToast({ message: record.taken ? '已打卡' : '已取消打卡' });
  }

  getTakenCount(): number {
    return this.todayRecords.filter(r => r.taken).length;
  }

  getCompletionRate(): number {
    if (this.todayRecords.length === 0) return 0;
    return Math.round((this.getTakenCount() / this.todayRecords.length) * 100);
  }

  @Builder
  TabBarItem(title: string, active: boolean) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(active ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(active ? $r('app.color.primary') : '#757575')
      if (active) {
        Divider()
          .strokeWidth(3)
          .color($r('app.color.primary'))
          .width(60)
          .margin({ top: 8 })
      }
    }
    .height(48)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('用药管理')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // Tabs 官方实现
      Tabs({ barPosition: BarPosition.Start, index: this.currentTab }) {
        TabContent() {
          this.MedicineReminderContent()
        }
        .tabBar(this.TabBarItem('用药提醒', this.currentTab === 0))

        TabContent() {
          this.MyMedicineContent()
        }
        .tabBar(this.TabBarItem('我的用药', this.currentTab === 1))
      }
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.currentTab = index;
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  MedicineReminderContent() {
    Column() {
      // 日期和完成度
      Row() {
        Row({ space: 8 }) {
          Image($r('app.media.calendar'))
            .width(20)
            .height(20)
            .fillColor('#757575')

          Text(this.getTodayDateString())
            .fontSize(14)
            .fontColor('#757575')
        }
        .layoutWeight(1)

        Text(`${this.getCompletionRate()}% 完成`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#4CAF50')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      if (this.todayRecords.length === 0) {
        // 空状态
        Column() {
          Column({ space: 16 }) {
            Text('今日进度')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')
              .width('100%')

            Text(`已完成 0 / 0 次用药`)
              .fontSize(14)
              .fontColor('#757575')
              .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#F8F9FA')
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 16 })

          Column({ space: 16 }) {
            Text('今日提醒')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')
              .width('100%')

            Column() {
              Text('💊')
                .fontSize(60)
                .margin({ top: 40 })

              Text('暂无用药提醒')
                .fontSize(14)
                .fontColor('#BDBDBD')
                .margin({ top: 16, bottom: 40 })

              Button('+ 添加药品')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
                .backgroundColor($r('app.color.primary'))
                .width(200)
                .height(48)
                .borderRadius(24)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/medicine/AddMedicinePage' });
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            // 今日进度卡片
            Column({ space: 16 }) {
              Text('今日进度')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#212121')
                .width('100%')

              Row() {
                Column({ space: 8 }) {
                  Text(`${this.getCompletionRate()}%`)
                    .fontSize(48)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.primary'))

                  Text(`已完成 ${this.getTakenCount()} / ${this.todayRecords.length} 次用药`)
                    .fontSize(13)
                    .fontColor('#757575')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Progress({
                  value: this.getTakenCount(),
                  total: this.todayRecords.length,
                  type: ProgressType.Ring
                })
                .width(80)
                .height(80)
                .color($r('app.color.primary'))
              }
              .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#F8F9FA')
            .borderRadius(12)
            .margin({ left: 16, right: 16, top: 16 })

            // 今日提醒列表
            Column({ space: 12 }) {
              Text('今日提醒')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#212121')
                .width('100%')
                .padding({ left: 16 })

              ForEach(this.todayRecords, (record: MedicineRecord) => {
                this.RecordCard(record);
              })
            }
            .width('100%')
            .padding({ bottom: 16 })
          }
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MyMedicineContent() {
    Column() {
      if (this.medicineList.length === 0) {
        Column() {
          Column({ space: 8 }) {
            Text('0')
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')

            Text('正在服用的药品')
              .fontSize(14)
              .fontColor('#757575')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 16 })

          Column() {
            Text('💊')
              .fontSize(60)
              .margin({ top: 40 })

            Text('暂无药品记录')
              .fontSize(14)
              .fontColor('#BDBDBD')
              .margin({ top: 16, bottom: 40 })

            Button('+ 添加药品')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .backgroundColor($r('app.color.primary'))
              .width(200)
              .height(48)
              .borderRadius(24)
              .onClick(() => {
                router.pushUrl({ url: 'pages/medicine/AddMedicinePage' });
              })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Column() {
          // 药品数量统计
          Row() {
            Column({ space: 8 }) {
              Text(`${this.medicineList.length}`)
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor('#212121')

              Text('正在服用的药品')
                .fontSize(14)
                .fontColor('#757575')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button('+ 添加药品')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .backgroundColor($r('app.color.primary'))
              .height(44)
              .borderRadius(22)
              .onClick(() => {
                router.pushUrl({ url: 'pages/medicine/AddMedicinePage' });
              })
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 16 })

          // 药品列表
          Scroll() {
            Column({ space: 12 }) {
              ForEach(this.medicineList, (medicine: MedicineData) => {
                this.MedicineCard(medicine);
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
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
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')
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
    .margin({ left: 16, right: 16 })
  }

  @Builder
  MedicineCard(medicine: MedicineData) {
    Column({ space: 12 }) {
      Row() {
        Text(medicine.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')
          .layoutWeight(1)

        Text('×')
          .fontSize(24)
          .fontColor('#F44336')
          .fontWeight(FontWeight.Bold)
          .onClick(async () => {
            await HealthRecordDatabase.getInstance().deleteMedicine(medicine.id);
            await this.cancelMedicineReminders(medicine);
            await this.loadData();
            promptAction.showToast({ message: '删除成功' });
          })
      }
      .width('100%')

      if (medicine.specification) {
        Text(`规格：${medicine.specification}`)
          .fontSize(13)
          .fontColor('#757575')
          .width('100%')
      }

      if (medicine.dosage) {
        Text(`用法用量：${medicine.dosage}`)
          .fontSize(13)
          .fontColor('#757575')
          .width('100%')
      }

      Row() {
        Text('服用时间：')
          .fontSize(13)
          .fontColor('#757575')

        Text(medicine.frequency.map((f: string) => {
          const timeName = this.getTimeName(f);
          const reminderTime = medicine.reminderTimes[f];
          if (reminderTime) {
            const hour = String(reminderTime.hour).padStart(2, '0');
            const minute = String(reminderTime.minute).padStart(2, '0');
            return `${timeName}(${hour}:${minute})`;
          }
          return timeName;
        }).join('、'))
          .fontSize(13)
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

  getTodayDateString(): string {
    const today = new Date();
    return `${today.getFullYear()}年${today.getMonth() + 1}月${today.getDate()}日`;
  }

  async cancelMedicineReminders(medicine: MedicineData) {
    const notificationMgr = NotificationManager.getInstance();

    for (const time of medicine.frequency) {
      const reminderId = parseInt(medicine.id.substring(0, 8), 36) + time.charCodeAt(0);
      await notificationMgr.cancelReminder(reminderId);
    }
  }
}

