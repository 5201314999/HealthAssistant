import { HealthDataManager } from '../utils/HealthDataManager';
import { BuiltInTemplates } from '../config/BuiltInTemplates';
import  router  from '@ohos.router';
@Entry
@Component
export struct ProfilePage {
  @State diseaseCount: number = 0;
  @State medicineCount: number = 0;
  @State adherenceRate: number = 0;
  @State notificationEnabled: boolean = true;
  @State strictReminderEnabled: boolean = false;

  async aboutToAppear() {
    await this.loadStatistics();
  }

  async loadStatistics() {
    const activeTemplates = await HealthDataManager.getInstance().getActiveDiseaseTemplates();
    this.diseaseCount = activeTemplates.length;
    
    const medicineList = await HealthDataManager.getInstance().getMedicineList();
    this.medicineCount = medicineList.length;
    
    // 计算服药率
    const allRecords = await HealthDataManager.getInstance().getMedicineRecords();
    if (allRecords.length > 0) {
      const takenCount = allRecords.filter(r => r.taken).length;
      this.adherenceRate = Math.round((takenCount / allRecords.length) * 100);
    } else {
      this.adherenceRate = 0;
    }
  }

  build() {
    Scroll() {
      Column() {
        // 顶部导航栏
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .onClick(() => {
              router.back();
            })
            .visibility(Visibility.Hidden)

          Text('个人中心')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          // 占位保持居中
          Row()
            .width(24)
            .height(24)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')

        // 用户信息卡片
        Column() {
          Row() {
            // 头像
            Row() {
              Image($r('app.media.user'))
                .width(32)
                .height(32)
                .fillColor('#FFFFFF')
            }
            .width(64)
            .height(64)
            .borderRadius(32)
            .backgroundColor($r('app.color.primary'))
            .justifyContent(FlexAlign.Center)
            .margin({ right: 16 })

            // 用户信息
            Column({ space: 4 }) {
              Text('张三')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#212121')

              Text('zhangsan@email.com')
                .fontSize(14)
                .fontColor('#757575')

              Text('2024年1月加入')
                .fontSize(12)
                .fontColor('#9E9E9E')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(20)

          // 统计信息
          Row() {
            Column({ space: 4 }) {
              Text(`${this.diseaseCount}`)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.primary'))

              Text('管理疾病')
                .fontSize(12)
                .fontColor('#757575')
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(`${this.medicineCount}`)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#4CAF50')

              Text('服用药品')
                .fontSize(12)
                .fontColor('#757575')
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(`${this.adherenceRate}%`)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#9C27B0')

              Text('服药率')
                .fontSize(12)
                .fontColor('#757575')
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 20 })
        }
        .width('100%')
        .margin({ left: 16, right: 16, top: 16 })
        .backgroundColor('#F5F9FC')
        .borderRadius(16)

        // 快捷设置
        Column({ space: 0 }) {
          Text('快捷设置')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#212121')
            .width('100%')
            .padding({ left: 16, top: 12, bottom: 12 })

          // 推送通知
          Row() {
            Row() {
              Image($r('app.media.settings'))
                .width(24)
                .height(24)
                .fillColor($r('app.color.primary'))
            }
            .width(40)
            .height(40)
            .borderRadius(8)
            .backgroundColor('#E3F2FD')
            .justifyContent(FlexAlign.Center)
            .margin({ right: 12 })

            Column({ space: 2 }) {
              Text('推送通知')
                .fontSize(15)
                .fontColor('#212121')

              Text('接收用药提醒通知')
                .fontSize(12)
                .fontColor('#9E9E9E')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.notificationEnabled })
              .onChange((isOn: boolean) => {
                this.notificationEnabled = isOn;
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Divider()
            .strokeWidth(0.5)
            .color('#EEEEEE')
            .margin({ left: 68 })

          // 严格提醒
          Row() {
            Row() {
              Image($r('sys.media.ohos_ic_public_clock'))
                .width(24)
                .height(24)
                .fillColor('#FF9800')
            }
            .width(40)
            .height(40)
            .borderRadius(8)
            .backgroundColor('#FFF3E0')
            .justifyContent(FlexAlign.Center)
            .margin({ right: 12 })

            Column({ space: 2 }) {
              Text('严格提醒')
                .fontSize(15)
                .fontColor('#212121')

              Text('错过时间后继续提醒')
                .fontSize(12)
                .fontColor('#9E9E9E')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.strictReminderEnabled })
              .onChange((isOn: boolean) => {
                this.strictReminderEnabled = isOn;
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
        }
        .width('100%')
        .margin({ left: 16, right: 16, top: 20 })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)

        // 个人信息
        Column() {
          Row() {
            Row() {
              Image($r('app.media.user'))
                .width(24)
                .height(24)
                .fillColor('#757575')
            }
            .width(40)
            .height(40)
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .justifyContent(FlexAlign.Center)
            .margin({ right: 12 })

            Text('个人信息')
              .fontSize(15)
              .fontColor('#212121')
              .layoutWeight(1)

            Image($r('sys.media.ohos_ic_public_arrow_right'))
              .width(20)
              .height(20)
              .fillColor('#BDBDBD')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
        }
        .width('100%')
        .margin({ left: 16, right: 16, top: 20, bottom: 20 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

