/**
 * 就诊记录详情页面
 */

import router from '@ohos.router';
import { promptAction, AlertDialog } from '@kit.ArkUI';
import { HealthDataManager } from '../../utils/HealthDataManager';
import { BuiltInTemplates } from '../../config/BuiltInTemplates';
import { DiseaseTemplate, HealthRecord } from '../../models/DiseaseTemplate';

@Entry
@Component
struct MedicalRecordDetailPage {
  @State record: HealthRecord | null = null;
  @State template: DiseaseTemplate | null = null;
  @State isLoading: boolean = true;
  
  private templateId: string = '';
  private recordId: string = '';

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    this.templateId = params['templateId'] || '';
    this.recordId = params['recordId'] || '';
    
    if (!this.templateId || !this.recordId) {
      promptAction.showToast({ message: '参数错误' });
      router.back();
      return;
    }
    
    // 加载模板
    this.template = BuiltInTemplates.getTemplateById(this.templateId);
    
    // 加载记录
    await this.loadRecord();
  }

  async loadRecord() {
    this.isLoading = true;
    
    // 获取所有记录
    const records = await HealthDataManager.getInstance().getHealthRecords(this.templateId, 'medical_record');
    
    // 查找指定ID的记录
    this.record = records.find(r => r.id === this.recordId) || null;
    
    this.isLoading = false;
    
    if (!this.record) {
      promptAction.showToast({ message: '未找到记录' });
      router.back();
    }
  }

  // 删除记录
  showDeleteConfirmDialog() {
    this.getUIContext().showAlertDialog({
      title: '删除记录',
      message: '确定要删除这条就诊记录吗？删除后无法恢复。',
      primaryButton: {
        value: '取消',
        action: () => {
          // 取消操作
        }
      },
      secondaryButton: {
        value: '删除',
        action: async () => {
          if (this.record) {
            await HealthDataManager.getInstance().deleteHealthRecord(this.templateId, this.record.id);
            promptAction.showToast({ message: '删除成功' });
            router.back();
          }
        }
      }
    });
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

        Text('就诊记录详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 删除按钮
        Image($r('app.media.delete'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.showDeleteConfirmDialog();
          })
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
      } else if (this.record && this.template) {
        // 显示记录详情
        Scroll() {
          Column({ space: 16 }) {
            // 疾病和日期信息
            Row() {
              // 疾病标签
              Text(this.template.name)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .backgroundColor(this.template.color)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
              
              // 日期
              Text(this.formatDate(this.record.date))
                .fontSize(14)
                .fontColor('#9E9E9E')
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16 })
            
            // 医院和医生信息卡片
            Column({ space: 12 }) {
              Text('就诊信息')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#212121')
                .alignSelf(ItemAlign.Start)
              
              // 医院
              Column({ space: 4 }) {
                Text('就诊医院')
                  .fontSize(14)
                  .fontColor('#757575')
                
                Text(this.record.hospital || '未填写')
                  .fontSize(16)
                  .fontColor('#212121')
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              
              // 医生
              Column({ space: 4 }) {
                Text('主治医生')
                  .fontSize(14)
                  .fontColor('#757575')
                
                Text(this.record.doctor || '未填写')
                  .fontSize(16)
                  .fontColor('#212121')
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              
              // 就诊时间
              Column({ space: 4 }) {
                Text('就诊时间')
                  .fontSize(14)
                  .fontColor('#757575')
                
                Text(this.formatDateTime(this.record.checkTime))
                  .fontSize(16)
                  .fontColor('#212121')
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .margin({ left: 16, right: 16 })
            
            // 诊断和治疗信息卡片
            Column({ space: 12 }) {
              Text('诊断与治疗')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#212121')
                .alignSelf(ItemAlign.Start)
              
              // 诊断结果
              Column({ space: 4 }) {
                Text('诊断结果')
                  .fontSize(14)
                  .fontColor('#757575')
                
                Text(this.record.getIndicator('diagnosis') as string || '未填写')
                  .fontSize(16)
                  .fontColor('#212121')
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              
              // 治疗方案
              Column({ space: 4 }) {
                Text('治疗方案')
                  .fontSize(14)
                  .fontColor('#757575')
                
                Text(this.record.getIndicator('treatment') as string || '未填写')
                  .fontSize(16)
                  .fontColor('#212121')
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .margin({ left: 16, right: 16 })
            
            // 备注信息卡片
            if (this.record.note) {
              Column({ space: 12 }) {
                Text('备注')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#212121')
                  .alignSelf(ItemAlign.Start)
                
                Text(this.record.note)
                  .fontSize(16)
                  .fontColor('#212121')
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .margin({ left: 16, right: 16 })
            }
          }
          .width('100%')
          .padding({ bottom: 20 })
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hour}:${minute}`;
  }
}
