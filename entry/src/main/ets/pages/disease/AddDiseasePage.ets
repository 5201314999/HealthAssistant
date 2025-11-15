/**
 * 添加疾病页面
 */

import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HealthRecordDatabase } from '../../utils/HealthRecordDatabase';
import { BuiltInTemplates } from '../../config/BuiltInTemplates';
import { DiseaseTemplate } from '../../models/DiseaseTemplate';

const TAG = 'AddDiseasePage';
const DOMAIN = 0x0000;

@Entry
@Component
struct AddDiseasePage {
  @State templates: DiseaseTemplate[] = [];
  @State selectedTemplateId: string = '';
  @State activeTemplateIds: string[] = [];
  @State isAdding: boolean = false; // 添加防抖标志

  async aboutToAppear() {
    hilog.debug(DOMAIN, TAG, 'aboutToAppear start');
    // 获取所有可用的疾病模板
    this.templates = BuiltInTemplates.getAllTemplates();
    hilog.info(DOMAIN, TAG, 'Loaded templates count:%{public}d', this.templates.length);

    // 获取已激活的疾病模板
    const db = HealthRecordDatabase.getInstance();
    const activeTemplates = await db.getActiveDiseaseTemplates();
    this.activeTemplateIds = activeTemplates.map((t) => t.templateId);
    hilog.info(DOMAIN, TAG, 'Active templates count:%{public}d', this.activeTemplateIds.length);
  }

  async addDisease() {
    hilog.debug(DOMAIN, TAG, 'addDisease called, selectedTemplate:%{public}s', this.selectedTemplateId);
    // 防抖：防止快速重复点击
    if (this.isAdding) {
      promptAction.showToast({ message: '操作处理中，请稍候...' });
      return;
    }

    if (!this.selectedTemplateId) {
      promptAction.showToast({ message: '请选择一种疾病' });
      return;
    }

    // 检查是否已经添加过该疾病
    if (this.activeTemplateIds.includes(this.selectedTemplateId)) {
      hilog.warn(DOMAIN, TAG, 'Disease already exists:%{public}s', this.selectedTemplateId);
      promptAction.showToast({ message: '该疾病已经添加过了，无需重复添加' });
      return;
    }

    this.isAdding = true;
    try {
      // 获取选中的模板名称
      const template = this.templates.find((t) => t.id === this.selectedTemplateId);
      if (!template) {
        hilog.error(DOMAIN, TAG, 'Template not found:%{public}s', this.selectedTemplateId);
        promptAction.showToast({ message: '未找到选择的疾病' });
        this.isAdding = false;
        return;
      }

      // 激活疾病模板
      const db = HealthRecordDatabase.getInstance();
      await db.activateDiseaseTemplate(this.selectedTemplateId, template.name);
      hilog.info(DOMAIN, TAG, 'Disease activated:%{public}s', template.name);

      // 立即更新本地状态，防止重复添加
      if (!this.activeTemplateIds.includes(this.selectedTemplateId)) {
        this.activeTemplateIds = [...this.activeTemplateIds,this.selectedTemplateId];
        // 触发UI更新
        // this.activeTemplateIds = JSON.parse(JSON.stringify(this.activeTemplateIds));
      }

      promptAction.showToast({ message: '添加成功' });

      // 延迟返回，让用户看到成功提示
      setTimeout(() => {
        router.back();
      }, 500);

    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to add disease:%{public}s', JSON.stringify(err));
      promptAction.showToast({ message: '添加失败，请重试' });
    } finally {
      this.isAdding = false;
    }
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
            ForEach(this.templates, (item: DiseaseTemplate) => {
                DiseaseTemplateCard({
                  template: item,
                  activeIds: this.activeTemplateIds,
                  isAlreadyAdded: this.activeTemplateIds.indexOf(item.id)>=0,
                  selectedTemplateId: this.selectedTemplateId,
                  onTemplateSelect: (id: string) => {
                    this.selectedTemplateId = id
                  }
                })
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .constraintSize({minHeight:'100%'})
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
}


@ComponentV2
struct DiseaseTemplateCard
{
  @Param template: DiseaseTemplate|null=null;
  @Param activeIds: string[] =[];
  @Param isAlreadyAdded:boolean = false;
  @Param selectedTemplateId: string = '';
  @Event onTemplateSelect: (id: string) => void;

  build() {
    Row() {
      // 图标
      Row() {
        Text(this.template!.name.charAt(0))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor(this.template!.color)
      .justifyContent(FlexAlign.Center)
      .margin({ right: 12 })

      // 信息
      Column({ space: 4 }) {
        Text(this.template!.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')

        if (this.isAlreadyAdded) {
          Text('已添加')
            .fontSize(13)
            .fontColor($r('app.color.primary'))
        } else {
          Text(this.template!.description || '点击选择此疾病')
            .fontSize(13)
            .fontColor('#9E9E9E')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 选择状态
      if (!this.isAlreadyAdded) {
        Radio({ value: this.template!.id, group: 'diseaseTemplates' })
          .checked(this.selectedTemplateId === this.template!.id)
          .onChange((isChecked: boolean) => {
            if (isChecked) {
              this.onTemplateSelect(this.template!.id)
            }
          })
      } else {
        Image($r('sys.media.ohos_ic_public_ok'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.primary'))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isAlreadyAdded ? '#F5F5F5' : (this.selectedTemplateId === this.template!.id ? '#E3F2FD' : '#FFFFFF'))
    .borderRadius(12)
    .onClick(() => {
      if (!this.isAlreadyAdded) {
        this.onTemplateSelect(this.template!.id)
      }
    })
  }
}
