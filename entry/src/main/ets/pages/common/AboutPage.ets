/**
 * 关于页面
 * 显示应用信息、版本、反馈联系方式等
 */

import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';
import { DebugTools } from '../../utils/DebugTools';

const TAG = 'AboutPage';
const DOMAIN = 0x0000;

@Entry
@Component
export struct AboutPage {
  @State showDebugDialog: boolean = false;
  @State dbStats: Record<string, number> = {};
  @State debugPressCount: number = 0;
  @State debugMessage: string = '';

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

        Text('关于')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row()
          .width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 24 }) {
          // 应用信息卡片
          Column({ space: 16 }) {
            // 应用图标和名称
            Column({ space: 12 }) {
              Row() {
                Column() {
                  Image($r('app.media.startIcon'))
                    .width(80)
                    .height(80)
                    .borderRadius(20)
                }
                .width(80)
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)

              Text('慢性病助手')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#212121')
                .textAlign(TextAlign.Center)
                .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)

            Divider()
              .strokeWidth(1)
              .color('#EEEEEE')
              .margin({ top: 8, bottom: 8 })

            // 版本信息（长按激活调试）
            Row() {
              Column({ space: 4 }) {
                Text('版本')
                  .fontSize(14)
                  .fontColor('#757575')

                Text('v1.0.0')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#212121')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .gesture(
              LongPressGesture({ repeat: true, duration: 500 })
                .onAction(() => {
                  this.debugPressCount++;
                  if (this.debugPressCount >= 3) {
                    this.showDebugPanel();
                    this.debugPressCount = 0;
                  }
                })
            )

            // 应用描述
            Row() {
              Column({ space: 4 }) {
                Text('描述')
                  .fontSize(14)
                  .fontColor('#757575')

                Text('智能健康管理专家')
                  .fontSize(14)
                  .fontColor('#424242')

                Text('帮助您更好地管理慢性病')
                  .fontSize(14)
                  .fontColor('#424242')

              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ left: 16, right: 16, top: 0 })

          // 反馈信息卡片
          Column({ space: 12 }) {
            Text('问题反馈')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')
              .width('100%')

            // 邮箱
            Row() {
              Column({ space: 4 }) {
                Text('邮箱')
                  .fontSize(14)
                  .fontColor('#757575')

                Text('1446418561@qq.com')
                  .fontSize(15)
                  .fontColor($r('app.color.primary'))
                  .fontWeight(FontWeight.Medium)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              // Image($r('sys.media.ohos_ic_public_arrow_right'))
              //   .width(20)
              //   .height(20)
              //   .fillColor('#BDBDBD')
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .onClick(() => {
              promptAction.showToast({ message: '邮箱已复制到剪贴板' });
              hilog.info(DOMAIN, TAG, 'Feedback email clicked');
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })

          // 其他信息
          Column({ space: 12 }) {
            Text('其他')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')
              .width('100%')

            // 用户协议
            Row() {
              Text('用户协议')
                .fontSize(15)
                .fontColor('#212121')
                .layoutWeight(1)

              Image($r('sys.media.ohos_ic_public_arrow_right'))
                .width(20)
                .height(20)
                .fillColor('#BDBDBD')
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)

            // 隐私政策
            Row() {
              Text('隐私政策')
                .fontSize(15)
                .fontColor('#212121')
                .layoutWeight(1)

              Image($r('sys.media.ohos_ic_public_arrow_right'))
                .width(20)
                .height(20)
                .fillColor('#BDBDBD')
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 40 })
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  async showDebugPanel() {
    this.showDebugDialog = true;
    // 获取统计信息
    try {
      this.dbStats = await DebugTools.getInstance().getDatabaseStats(getContext(this));
      this.debugMessage = `数据库统计:\n` +
        `健康记录: ${this.dbStats['health_records'] || 0}\n` +
        `激活疾病: ${this.dbStats['active_disease_templates'] || 0}\n` +
        `药品数据: ${this.dbStats['medicine_data'] || 0}\n` +
        `用药记录: ${this.dbStats['medicine_records'] || 0}`;
      hilog.info(DOMAIN, TAG, 'Debug stats retrieved');
    } catch (err) {
      this.debugMessage = '获取统计信息失败';
      hilog.error(DOMAIN, TAG, 'Failed to get stats: %{public}s', JSON.stringify(err));
    }

    // 弹窗显示调试信息
    AlertDialog.show({
      title: '🔧 调试工具',
      message: this.debugMessage,
      primaryButton: {
        value: '重置RDB',
        action: async () => {
          try {
            await DebugTools.getInstance().resetRdbDatabase(getContext(this));
            promptAction.showToast({ message: 'RDB已重置' });
          } catch (err) {
            promptAction.showToast({ message: '重置失败' });
          }
        }
      },
      secondaryButton: {
        value: '重置全部',
        action: async () => {
          try {
            await DebugTools.getInstance().resetAllData(getContext(this));
            promptAction.showToast({ message: '所有数据已重置' });
          } catch (err) {
            promptAction.showToast({ message: '重置失败' });
          }
        }
      }
    });
  }
}
