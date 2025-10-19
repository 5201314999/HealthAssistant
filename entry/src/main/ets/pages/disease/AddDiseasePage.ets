/**
 * 添加疾病页面
 */

import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { HealthDataManager } from '../../utils/HealthDataManager';
import { BuiltInTemplates } from '../../config/BuiltInTemplates';
import { DiseaseTemplate } from '../../models/DiseaseTemplate';

@Entry
@Component
struct AddDiseasePage {
  @State templates: DiseaseTemplate[] = [];
  @State selectedTemplateId: string = '';

  aboutToAppear() {
    // 获取所有可用的疾病模板
    this.templates = BuiltInTemplates.getAllTemplates();
  }

  async addDisease() {
    if (!this.selectedTemplateId) {
      promptAction.showToast({ message: '请选择一种疾病' });
      return;
    }

    // 添加疾病模板到活跃列表
    await HealthDataManager.getInstance().activateDiseaseTemplate(this.selectedTemplateId);
    
    // 返回上一页
    promptAction.showToast({ message: '添加成功' });
    router.back();
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

        Text('添加疾病')
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
          // 说明文字
          Text('请选择您需要管理的慢性病类型')
            .fontSize(14)
            .fontColor('#757575')
            .width('100%')
            .padding({ left: 16, right: 16, top: 16 })

          // 疾病列表
          Column({ space: 12 }) {
            ForEach(this.templates, (template: DiseaseTemplate) => {
              this.DiseaseTemplateCard(template);
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      // 底部按钮
      Column() {
        Button('添加')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor($r('app.color.primary'))
          .borderRadius(24)
          .onClick(() => {
            this.addDisease();
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
  DiseaseTemplateCard(template: DiseaseTemplate) {
    Row() {
      // 图标
      Row() {
        Text(template.name.charAt(0))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor(template.color)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      // 信息
      Column({ space: 4 }) {
        Text(template.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')

        Text(template.description || '点击选择此疾病')
          .fontSize(13)
          .fontColor('#9E9E9E')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 选择状态
      Radio({ value: template.id, group: 'diseaseTemplates' })
        .checked(this.selectedTemplateId === template.id)
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.selectedTemplateId = template.id;
          }
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      this.selectedTemplateId = template.id;
    })
  }
}
