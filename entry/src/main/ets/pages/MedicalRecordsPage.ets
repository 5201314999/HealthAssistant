/**
 * 历史就诊记录页面
 */

import router from '@ohos.router';
import { HealthDataManager } from '../utils/HealthDataManager';
import { BuiltInTemplates } from '../config/BuiltInTemplates';
import { DiseaseTemplate, HealthRecord } from '../models/DiseaseTemplate';

@Entry
@Component
struct MedicalRecordsPage {
  @State records: HealthRecord[] = [];
  @State isLoading: boolean = true;
  @State templateMap: Map<string, DiseaseTemplate> = new Map();

  async aboutToAppear() {
    // 加载所有模板
    const templates = BuiltInTemplates.getAllTemplates();
    templates.forEach(template => {
      this.templateMap.set(template.id, template);
    });
    
    // 加载所有就诊记录
    await this.loadAllMedicalRecords();
  }

  async loadAllMedicalRecords() {
    this.isLoading = true;
    
    // 获取活跃的疾病模板
    const activeTemplateIds = await HealthDataManager.getInstance().getActiveDiseaseTemplates();
    
    // 获取所有模板的就诊记录
    let allRecords: HealthRecord[] = [];
    for (const templateId of activeTemplateIds) {
      const records = await HealthDataManager.getInstance().getHealthRecords(templateId, 'medical_record');
      allRecords = allRecords.concat(records);
    }
    
    // 按日期降序排序
    allRecords.sort((a, b) => b.date - a.date);
    
    this.records = allRecords;
    this.isLoading = false;
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

        Text('历史就诊记录')
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

      if (this.isLoading) {
        // 加载中
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color($r('app.color.primary'))
          
          Text('加载中...')
            .fontSize(14)
            .fontColor('#757575')
            .margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.records.length === 0) {
        // 无记录
        Column() {
          Image($r('app.media.calendar'))
            .width(80)
            .height(80)
            .fillColor('#BDBDBD')
            .margin({ top: 100 })
          
          Text('暂无就诊记录')
            .fontSize(16)
            .fontColor('#9E9E9E')
            .margin({ top: 16 })
          
          Text('添加就诊记录后会显示在这里')
            .fontSize(14)
            .fontColor('#BDBDBD')
            .margin({ top: 8 })
          
          Button('添加就诊记录')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.primary'))
            .width(200)
            .height(44)
            .margin({ top: 24 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/AddMedicalRecordPage'
              });
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 显示记录列表
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.records, (record: HealthRecord) => {
              this.RecordCard(record);
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 16 })
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  RecordCard(record: HealthRecord) {
    Column({ space: 12 }) {
      // 头部信息
      Row() {
        // 疾病标签
        Text(this.getTemplateName(record.templateId))
          .fontSize(12)
          .fontColor('#FFFFFF')
          .backgroundColor(this.getTemplateColor(record.templateId))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(4)
        
        // 日期
        Text(this.formatDate(record.date))
          .fontSize(12)
          .fontColor('#9E9E9E')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      
      // 医院和医生信息
      Row() {
        Column({ space: 4 }) {
          Text(record.hospital || '未知医院')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#212121')
          
          if (record.doctor) {
            Text(`主治医生: ${record.doctor}`)
              .fontSize(14)
              .fontColor('#757575')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      
      // 分隔线
      Divider()
        .strokeWidth(1)
        .color('#EEEEEE')
      
      // 诊断和治疗信息
      Column({ space: 8 }) {
        // 诊断结果
        Column({ space: 4 }) {
          Text('诊断结果')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#757575')
          
          Text(record.getIndicator('diagnosis') as string || '无诊断信息')
            .fontSize(15)
            .fontColor('#212121')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        
        // 治疗方案
        Column({ space: 4 }) {
          Text('治疗方案')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#757575')
          
          Text(record.getIndicator('treatment') as string || '无治疗方案')
            .fontSize(15)
            .fontColor('#212121')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        
        // 备注信息
        if (record.note) {
          Column({ space: 4 }) {
            Text('备注')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#757575')
            
            Text(record.note)
              .fontSize(15)
              .fontColor('#212121')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      // 点击查看详情
      router.pushUrl({
        url: 'pages/MedicalRecordDetailPage',
        params: { 
          templateId: record.templateId,
          recordId: record.id
        }
      });
    })
  }

  getTemplateName(templateId: string): string {
    return this.templateMap.get(templateId)?.name || '未知疾病';
  }

  getTemplateColor(templateId: string): ResourceColor {
    return this.templateMap.get(templateId)?.color || '#9E9E9E';
  }

  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
}
