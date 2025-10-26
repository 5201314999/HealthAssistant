/**
 * 添加就诊记录页面
 */

import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { HealthRecordDatabase } from '../../utils/HealthRecordDatabase';
import { DiseaseTemplate, IndicatorGroup, HealthRecord, IndicatorDefinition, IndicatorType } from '../../models/DiseaseTemplate';
import { BuiltInTemplates } from '../../config/BuiltInTemplates';



interface TemplateShow {
  value: string;
  text:string;
}
@Entry
@Component
struct AddMedicalRecordPage {
  @State templates: DiseaseTemplate[] = [];
  @State selectedTemplateId: string = '';
  @State selectedIndex:number=0;
  @State visitDate: number = Date.now();
  @State hospital: string = '';
  @State doctor: string = '';
  @State diagnosis: string = '';
  @State treatment: string = '';
  @State notes: string = '';

  aboutToAppear() {
    // 获取所有活跃的疾病模板
    this.loadActiveTemplates();
  }

  async loadActiveTemplates() {
    const db = HealthRecordDatabase.getInstance();
    const allTemplates = BuiltInTemplates.getAllTemplates();
    this.templates = [];
    
    for (const template of allTemplates) {
      const count = await db.getRecordCount(template.id);
      if (count > 0) {
        this.templates.push(template);
      }
    }
  }

  // 显示日期选择器
  showDatePicker() {
    this.getUIContext().showDatePickerDialog({
      start: new Date('1900-1-1'),
      end: new Date(),
      selected: new Date(this.visitDate),
      onDateAccept: (value) => {
        this.visitDate = value.getTime();
      }
    });
  }

  async saveMedicalRecord() {
    // 验证必填项
    if (!this.selectedTemplateId) {
      promptAction.showToast({ message: '请选择疾病类型' });
      return;
    }
    
    if (!this.hospital) {
      promptAction.showToast({ message: '请输入就诊医院' });
      return;
    }
    
    if (!this.diagnosis) {
      promptAction.showToast({ message: '请输入诊断结果' });
      return;
    }
    
    if (!this.treatment) {
      promptAction.showToast({ message: '请输入治疗方案' });
      return;
    }

    // 创建就诊记录
    const record = new HealthRecord(this.selectedTemplateId, 'medical_record');
    record.hospital = this.hospital;
    record.doctor = this.doctor;
    record.checkTime = this.visitDate;
    record.setIndicator('diagnosis', this.diagnosis);
    record.setIndicator('treatment', this.treatment);
    record.note = this.notes;

    await HealthRecordDatabase.getInstance().saveHealthRecord(record);
    promptAction.showToast({ message: '保存成功' });
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

        Text('添加就诊记录')
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
          // 表单
          Column({ space: 16 }) {
            // 疾病类型
            Column({ space: 8 }) {
              Row() {
                Text('疾病类型')
                  .fontSize(16)
                  .fontColor('#212121')
                
                Text('*')
                  .fontSize(16)
                  .fontColor('#F44336')
                  .margin({ left: 4 })
              }
              .width('100%')
              
              if (this.templates.length > 0) {
                Select(this.templates.map(t => ({ value: t.id, text: t.name } as TemplateShow)))
                  .selected(this.selectedIndex)
                  .value(this.getSelectedTemplateName())
                  .font({ size: 16 })
                  .backgroundColor('#F5F5F5')
                  .borderRadius(8)
                  .onSelect((index: number) => {
                    this.selectedTemplateId = this.templates[index].id;
                    this.selectedIndex=index
                  })
              } else {
                Text('暂无疾病，请先添加疾病')
                  .fontSize(14)
                  .fontColor('#757575')
              }
            }
            .width('100%')

            // 就诊日期
            Column({ space: 8 }) {
              Row() {
                Text('就诊日期')
                  .fontSize(16)
                  .fontColor('#212121')
                
                Text('*')
                  .fontSize(16)
                  .fontColor('#F44336')
                  .margin({ left: 4 })
              }
              .width('100%')
              
              Row() {
                Text(this.formatDate(this.visitDate))
                  .fontSize(16)
                  .fontColor('#212121')
                  .layoutWeight(1)
                
                Text('选择日期')
                  .fontSize(14)
                  .fontColor($r('app.color.primary'))
                  .onClick(() => {
                    this.showDatePicker();
                  })
              }
              .width('100%')
              .height(48)
              .padding({ left: 12, right: 12 })
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
            }
            .width('100%')

            // 就诊医院
            Column({ space: 8 }) {
              Row() {
                Text('就诊医院')
                  .fontSize(16)
                  .fontColor('#212121')
                
                Text('*')
                  .fontSize(16)
                  .fontColor('#F44336')
                  .margin({ left: 4 })
              }
              .width('100%')
              
              TextInput({
                placeholder: '请输入医院名称',
                text: this.hospital
              })
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.hospital = value;
                })
            }
            .width('100%')

            // 主治医生
            Column({ space: 8 }) {
              Row() {
                Text('主治医生')
                  .fontSize(16)
                  .fontColor('#212121')
              }.width('100%')
              
              TextInput({
                placeholder: '请输入医生姓名',
                text: this.doctor
              })
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.doctor = value;
                })
            }
            .width('100%')

            // 诊断结果
            Column({ space: 8 }) {
              Row() {
                Text('诊断结果')
                  .fontSize(16)
                  .fontColor('#212121')
                
                Text('*')
                  .fontSize(16)
                  .fontColor('#F44336')
                  .margin({ left: 4 })
              }
              .width('100%')
              
              TextArea({
                placeholder: '请输入诊断结果',
                text: this.diagnosis
              })
                .height(100)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.diagnosis = value;
                })
            }
            .width('100%')

            // 治疗方案
            Column({ space: 8 }) {
              Row() {
                Text('治疗方案')
                  .fontSize(16)
                  .fontColor('#212121')
                
                Text('*')
                  .fontSize(16)
                  .fontColor('#F44336')
                  .margin({ left: 4 })
              }
              .width('100%')
              
              TextArea({
                placeholder: '请输入治疗方案',
                text: this.treatment
              })
                .height(100)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.treatment = value;
                })
            }
            .width('100%')

            // 备注
            Column({ space: 8 }) {
              Row() {
                Text('备注')
                  .fontSize(16)
                  .fontColor('#212121')
              }.width('100%')
              
              TextArea({
                placeholder: '其他需要记录的信息',
                text: this.notes
              })
                .height(100)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.notes = value;
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .margin({ left: 16, right: 16, top: 16 })
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
          .backgroundColor($r('app.color.primary'))
          .borderRadius(24)
          .onClick(() => {
            this.saveMedicalRecord();
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

  getSelectedTemplateName(): string {
    const template = this.templates.find(t => t.id === this.selectedTemplateId);
    return template ? template.name : '请选择疾病';
  }

  // 格式化日期
  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
}
