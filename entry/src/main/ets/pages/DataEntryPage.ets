/**
 * 通用数据录入页面
 * 根据模板和指标组动态生成表单
 */

import  router  from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { HealthDataManager } from '../utils/HealthDataManager';
import { DiseaseTemplate, IndicatorGroup, HealthRecord, IndicatorDefinition, IndicatorType, IndicatorOption } from '../models/DiseaseTemplate';
import { BuiltInTemplates } from '../config/BuiltInTemplates';

@Entry
@Component
struct DataEntryPage {
  @State template: DiseaseTemplate | null = null;
  @State group: IndicatorGroup | null = null;
  @State formData: Map<string, number | string> = new Map();
  @State note: string = '';
  @State hospital: string = ''; // 医院名称
  @State doctor: string = ''; // 医生姓名
  @State checkTime: number = Date.now(); // 检查时间

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    const templateId = params['templateId'] as string;
    const groupId = params['groupId'] as string;
    
    this.template = BuiltInTemplates.getTemplateById(templateId) || null;
    if (this.template) {
      this.group = this.template.indicatorGroups.find((g: IndicatorGroup) => g.id === groupId) || null;
      
      // 初始化表单数据
      if (this.group) {
        this.group.indicators.forEach((indicator: IndicatorDefinition) => {
          if (indicator.type === IndicatorType.SELECT && indicator.options && indicator.options.length > 0) {
            this.formData.set(indicator.id, indicator.options[0].value);
          } else {
            this.formData.set(indicator.id, '');
          }
        });
      }
    }
  }

  async saveData() {
    if (!this.template || !this.group) {
      return;
    }

    // 验证必填项
    for (const indicator of this.group.indicators) {
      if (indicator.required && !this.formData.get(indicator.id)) {
        promptAction.showToast({ message: `请填写${indicator.name}` });
        return;
      }
    }

    // 创建健康记录
    const record = new HealthRecord(this.template.id, this.group.id);
    // 复制 formData 到 record.indicators
    this.formData.forEach((value: number | string, key: string) => {
      record.setIndicator(key, value);
    });
    record.note = this.note;
    record.hospital = this.hospital;
    record.doctor = this.doctor;
    record.checkTime = this.checkTime;

    await HealthDataManager.getInstance().saveHealthRecord(record);
    promptAction.showToast({ message: '保存成功' });
    router.back();
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

        Text(this.group ? `录入${this.group.name}` : '数据录入')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('保存')
          .fontSize(16)
          .fontColor(this.template?.color || '#4CAF50')
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
          // 说明文字
          if (this.group?.description) {
            Text(this.group.description)
              .fontSize(14)
              .fontColor('#757575')
              .width('100%')
              .padding({ left: 16, right: 16, top: 16 })
          }

          // 检查信息卡片（新增）
          Column({ space: 12 }) {
            Text('检查信息')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#212121')
              .alignSelf(ItemAlign.Start)

            // 医院名称
            Column({ space: 6 }) {
              Text('医院名称')
                .fontSize(14)
                .fontColor('#757575')
                .alignSelf(ItemAlign.Start)
              
              TextInput({
                placeholder: '请输入医院名称（选填）',
                text: this.hospital
              })
                .onChange((value: string) => {
                  this.hospital = value;
                })
            }
            .width('100%')

            // 医生姓名
            Column({ space: 6 }) {
              Text('医生姓名')
                .fontSize(14)
                .fontColor('#757575')
                .alignSelf(ItemAlign.Start)
              
              TextInput({
                placeholder: '请输入医生姓名（选填）',
                text: this.doctor
              })
                .onChange((value: string) => {
                  this.doctor = value;
                })
            }
            .width('100%')

            // 检查时间
            Column({ space: 6 }) {
              Text('检查时间')
                .fontSize(14)
                .fontColor('#757575')
                .alignSelf(ItemAlign.Start)
              
              Row() {
                Text(this.formatDate(this.checkTime))
                  .fontSize(16)
                  .fontColor('#212121')
                  .layoutWeight(1)
                
                Text('选择时间')
                  .fontSize(14)
                  .fontColor(this.template?.color || '#4CAF50')
                  .onClick(() => {
                    // TODO: 打开时间选择器
                    this.checkTime = Date.now();
                  })
              }
              .width('100%')
              .height(48)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ left: 16, right: 16, top: 16 })
          .shadow({
            radius: 8,
            color: '#10000000',
            offsetY: 2
          })

          // 检测指标卡片
          if (this.group) {
            Column({ space: 16 }) {
              Text('检测指标')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#212121')
                .alignSelf(ItemAlign.Start)
              
              ForEach(this.group.indicators, (indicator: IndicatorDefinition) => {
                this.FormItem(indicator);
              })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .margin({ left: 16, right: 16 })
            .shadow({
              radius: 8,
              color: '#10000000',
              offsetY: 2
            })
          }

          // 备注卡片
          Column({ space: 8 }) {
            Text('备注')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#212121')
              .alignSelf(ItemAlign.Start)

            TextArea({ placeholder: '添加备注信息（选填）', text: this.note })
              .height(120)
              .backgroundColor('#F8F9FA')
              .borderRadius(12)
              .onChange((value: string) => {
                this.note = value;
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ left: 16, right: 16 })
          .shadow({
            radius: 8,
            color: '#10000000',
            offsetY: 2
          })
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
  FormItem(indicator: IndicatorDefinition) {
    Column({ space: 8 }) {
      // 标签
      Row() {
        Text(indicator.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F1F1F')
        
        if (indicator.fullName && indicator.fullName !== indicator.name) {
          Text(`(${indicator.fullName})`)
            .fontSize(12)
            .fontColor('#9E9E9E')
            .margin({ left: 4 })
        }
        
        if (indicator.required) {
          Text('*')
            .fontSize(16)
            .fontColor('#F44336')
            .margin({ left: 4 })
        }
      }
      .width('100%')

      // 输入控件
      if (indicator.type === IndicatorType.NUMBER) {
        Row() {
          TextInput({
            placeholder: '请输入数值',
            text: (this.formData.get(indicator.id) as number)?.toString() || ''
          })
            .type(InputType.Number)
            .layoutWeight(1)
            .onChange((value: string) => {
              const numValue = value ? parseFloat(value) : 0;
              this.formData.set(indicator.id, numValue);
              this.formData = new Map(this.formData);
            })

          if (indicator.unit) {
            Text(indicator.unit)
              .fontSize(14)
              .fontColor('#757575')
              .margin({ left: 8 })
          }
        }
        .width('100%')
      } else if (indicator.type === IndicatorType.SELECT && indicator.options) {
        Row({ space: 8 }) {
          ForEach(indicator.options, (option: IndicatorOption) => {
            this.SelectButton(
              option.label,
              this.formData.get(indicator.id) === option.value,
              () => {
                this.formData.set(indicator.id, option.value);
                this.formData = new Map(this.formData);
              }
            )
          })
        }
        .width('100%')
      } else if (indicator.type === IndicatorType.TEXT) {
        TextInput({
          placeholder: `请输入${indicator.name}`,
          text: (this.formData.get(indicator.id) as string) || ''
        })
          .onChange((value: string) => {
            this.formData.set(indicator.id, value);
            this.formData = new Map(this.formData);
          })
      }

      // 参考值提示
      if (indicator.referenceMin !== undefined && indicator.referenceMax !== undefined) {
        Text(`参考范围：${indicator.referenceMin} - ${indicator.referenceMax} ${indicator.unit || ''}`)
          .fontSize(12)
          .fontColor('#9E9E9E')
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SelectButton(text: string, selected: boolean, onClick: () => void) {
    Text(text)
      .fontSize(14)
      .fontWeight(selected ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(selected ? '#FFFFFF' : (this.template?.color || '#4CAF50'))
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .backgroundColor(selected ? (this.template?.color || '#4CAF50') : '#F5F5F5')
      .borderRadius(20)
      .border({
        width: 1.5,
        color: selected ? (this.template?.color || '#4CAF50') : '#E0E0E0'
      })
      .onClick(onClick)
  }

  // 格式化日期
  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hour}:${minute}`;
  }
}

