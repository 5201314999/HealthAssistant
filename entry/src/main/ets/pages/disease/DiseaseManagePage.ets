/**
 * 通用疾病管理页面
 * 根据模板ID动态加载对应的疾病数据
 */

import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { HealthDataManager } from '../../utils/HealthDataManager';
import {
  DiseaseTemplate,
  IndicatorGroup,
  HealthRecord,
  IndicatorDefinition,
  IndicatorOption
} from '../../models/DiseaseTemplate';
import { BuiltInTemplates } from '../../config/BuiltInTemplates';

@Entry
@Component
struct DiseaseManagePage {
  @State template: DiseaseTemplate | null = null;
  @State records: HealthRecord[] = [];
  @State currentGroupIndex: number = 0;

  async aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    const templateId = params['templateId'] as string;

    this.template = BuiltInTemplates.getTemplateById(templateId) || null;
    if (this.template) {
      await this.loadData();
    }
  }

  onPageShow() {
    if (this.template) {
      this.loadData();
    }
  }

  async loadData() {
    if (!this.template) {
      return;
    }

    const currentGroup = this.template.indicatorGroups[this.currentGroupIndex];
    if (currentGroup) {
      this.records = await HealthDataManager.getInstance().getHealthRecords(
        this.template.id,
        currentGroup.id
      );
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

        Text(this.template?.name || '疾病管理')
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

      // 指标组切换（如果有多个组）
      if (this.template && this.template.indicatorGroups.length > 1) {
        Tabs({ barPosition: BarPosition.Start, index: this.currentGroupIndex }) {
          ForEach(this.template.indicatorGroups, (group: IndicatorGroup) => {
            TabContent() {
              this.RecordListView(group);
            }
            .tabBar(group.name)
          })
        }
        .barMode(BarMode.Fixed)
        .layoutWeight(1)
        .onChange((index: number) => {
          this.currentGroupIndex = index;
          this.loadData();
        })
      } else if (this.template && this.template.indicatorGroups.length === 1) {
        this.RecordListView(this.template.indicatorGroups[0]);
      }

      // 底部录入按钮
      if (this.template) {
        this.BottomButtons();
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  RecordListView(group: IndicatorGroup) {
    if (this.records.length === 0) {
      Column() {
        Text('📋')
          .fontSize(80)
          .margin({ top: 100 })

        Text('暂无数据')
          .fontSize(16)
          .fontColor('#9E9E9E')
          .margin({ top: 16 })

        Text(`点击下方按钮录入${group.name}`)
          .fontSize(14)
          .fontColor('#BDBDBD')
          .margin({ top: 8 })
      }
      .width('100%')
      .height('100%')
    } else {
      List({ space: 12 }) {
        ForEach(this.records, (record: HealthRecord) => {
          ListItem() {
            this.RecordCard(record, group);
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
  RecordCard(record: HealthRecord, group: IndicatorGroup) {
    Column({ space: 8 }) {
      // 日期和类型
      Row() {
        Text(new Date(record.date).toLocaleDateString('zh-CN'))
          .fontSize(14)
          .fontColor('#1F1F1F')
          .fontWeight(FontWeight.Medium)

        Text(group.name)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({
            left: 8,
            right: 8,
            top: 2,
            bottom: 2
          })
          .backgroundColor(this.template?.color || '#4CAF50')
          .borderRadius(4)
          .margin({ left: 8 })

        Blank()

        Text('×')
          .fontSize(24)
          .fontColor('#F44336')
          .fontWeight(FontWeight.Bold)
          .onClick(async () => {
            if (this.template) {
              await HealthDataManager.getInstance().deleteHealthRecord(this.template.id, record.id);
              await this.loadData();
              promptAction.showToast({ message: '删除成功' });
            }
          })
      }
      .width('100%')

      // 指标数据展示
      this.buildIndicatorList(record, group);

      if (record.note) {
        Text(`备注：${record.note}`)
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

  @Builder
  buildIndicatorList(record: HealthRecord, group: IndicatorGroup) {
    Column({ space: 6 }) {
      ForEach(group.indicators, (indicator: IndicatorDefinition) => {
        this.buildIndicatorRow(record, indicator);
      })
    }
    .width('100%')
  }

  @Builder
  buildIndicatorRow(record: HealthRecord, indicator: IndicatorDefinition) {
    Row() {
      Text(indicator.name)
        .fontSize(14)
        .fontColor('#424242')
        .width(100)

      this.buildIndicatorValue(record, indicator);
    }
    .width('100%')
  }

  @Builder
  buildIndicatorValue(record: HealthRecord, indicator: IndicatorDefinition) {
    if (indicator.type === 'select' && indicator.options) {
      this.buildSelectValue(record, indicator);
    } else {
      this.buildNumberValue(record, indicator);
    }
  }

  @Builder
  buildSelectValue(record: HealthRecord, indicator: IndicatorDefinition) {
    Text(this.getSelectLabel(record, indicator))
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor('#424242')
      .layoutWeight(1)
  }

  @Builder
  buildNumberValue(record: HealthRecord, indicator: IndicatorDefinition) {
    Text(this.getIndicatorValueText(record, indicator))
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.getIndicatorValueColor(record, indicator))
      .layoutWeight(1)

    if (indicator.unit) {
      Text(indicator.unit)
        .fontSize(12)
        .fontColor('#9E9E9E')
        .width(60)
    }

    if (indicator.referenceMin !== undefined && indicator.referenceMax !== undefined) {
      Text(`(${indicator.referenceMin}-${indicator.referenceMax})`)
        .fontSize(12)
        .fontColor('#9E9E9E')
    }
  }

  getSelectLabel(record: HealthRecord, indicator: IndicatorDefinition): string {
    const value = record.getIndicator(indicator.id);
    if (value === undefined || !indicator.options) {
      return '';
    }
    const option = indicator.options.find((opt: IndicatorOption) => opt.value === value);
    return option?.label || (value as string);
  }

  getIndicatorValueText(record: HealthRecord, indicator: IndicatorDefinition): string {
    const value = record.getIndicator(indicator.id);
    return value !== undefined ? `${value}` : '';
  }

  getIndicatorValueColor(record: HealthRecord, indicator: IndicatorDefinition): string {
    const value = record.getIndicator(indicator.id);
    if (value === undefined || typeof value !== 'number') {
      return '#424242';
    }
    return this.getIndicatorColor(indicator, value);
  }

  @Builder
  BottomButtons() {
    if (this.template && this.template.indicatorGroups.length === 1) {
      this.SingleButton();
    } else if (this.template && this.template.indicatorGroups.length > 1) {
      this.MultipleButtons();
    }
  }

  @Builder
  SingleButton() {
    if (!this.template) {
      // Builder方法不能返回null，使用空组件代替
      Blank();
    } else {
      Row() {
        Button(`录入${this.template!.indicatorGroups[0].name}`)
          .width('100%')
          .backgroundColor(this.template!.color)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/common/DataEntryPage',
              params: {
                templateId: this.template?.id,
                groupId: this.template!.indicatorGroups[0].id
              }
            });
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
    }
  }

  @Builder
  MultipleButtons() {
    Row({ space: 12 }) {
      ForEach(this.template?.indicatorGroups, (group: IndicatorGroup, index: number) => {
        Button(`录入${group.name}`)
          .layoutWeight(1)
          .backgroundColor(this.template?.color)
          .opacity(index === 0 ? 1 : 0.8)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/common/DataEntryPage',
              params: {
                templateId: this.template?.id,
                groupId: group.id
              }
            });
          })
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  getIndicatorColor(indicator: IndicatorDefinition, value: number): string {
    if (!indicator.warningLevels) {
      return '#424242';
    }

    for (const level of indicator.warningLevels) {
      const minOk = level.min === undefined || value >= level.min;
      const maxOk = level.max === undefined || value <= level.max;

      if (minOk && maxOk) {
        switch (level.level) {
          case 'normal':
            return '#4CAF50';
          case 'warning':
            return '#FF9800';
          case 'danger':
            return '#F44336';
          default:
            return '#424242';
        }
      }
    }

    return '#F44336';
  }
}

