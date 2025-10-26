import router from '@ohos.router';
import { UserPreferenceManager } from '../../utils/DataPreference';
import { HealthRecordDatabase } from '../../utils/HealthRecordDatabase';
import { BuiltInTemplates } from '../../config/BuiltInTemplates';
import { DiseaseTemplate } from '../../models/DiseaseTemplate';
import { HealthRecord } from '../../models/DiseaseTemplate';
import { MedicineRecord } from '../../models/MedicineData';
interface BloodPressure {
  systolic: number;
  diastolic: number;
}
@Entry
@Component
export struct HomePage {
  @State currentTab: number = 0;
  @State diseaseCount: number = 0;
  @State latestBloodPressure: BloodPressure | null = null;
  @State latestGlucose: number | null = null;
  @State templates: DiseaseTemplate[] = [];
  @State templateCounts: Map<string, number> = new Map();
  @State todayMedicineRecords: MedicineRecord[] = [];
  @State activeTemplates: string[] = [];

  async aboutToAppear() {
    await this.loadData();
  }

  onPageShow() {
    // 页面显示时重新加载数据，确保返回首页时显示最新的疾病列表
    this.loadData();
  }

  async loadData() {
    const db = HealthRecordDatabase.getInstance();
    
    // 加载模板列表
    this.templates = BuiltInTemplates.getAllTemplates();
    
    // 获取已激活的疾病模板
    const activeTemplatesFromDB = await db.getActiveDiseaseTemplates();
    this.activeTemplates = activeTemplatesFromDB.map((t) => t.templateId);
    
    // 加载每个模板的记录数
    for (const template of this.templates) {
      const count = await db.getRecordCount(template.id);
      this.templateCounts.set(template.id, count);
    }
    console.log('this.activeTemplates=======:', this.activeTemplates)
    
    // 计算疾病数量
    this.diseaseCount = this.activeTemplates.length;
    
    // 加载最新血压数据
    const latestBP = await db.getLatestHealthRecord('hypertension', 'blood_pressure');
    if (latestBP) {
      const systolic = latestBP.getIndicator('systolic') as number;
      const diastolic = latestBP.getIndicator('diastolic') as number;
      this.latestBloodPressure = { systolic, diastolic };
    }
    
    // 加载最新血糖数据
    const latestDiabetes = await db.getLatestHealthRecord('diabetes', 'glucose');
    if (latestDiabetes) {
      this.latestGlucose = latestDiabetes.getIndicator('glucose') as number;
    }
    
    // 加载今日用药记录
    this.todayMedicineRecords = await db.getMedicineRecords(Date.now() - 24 * 60 * 60 * 1000, Date.now());
    
    // 触发UI更新
    this.templateCounts = new Map(this.templateCounts);
  }

  build() {
    Column() {
      // 顶部标题区域
      Column() {
        Row() {
          // Logo
          Row() {
            // Image($r('app.media.heart'))
            //   .width(32)
            //   .height(32)
            //   .fillColor('#FFFFFF')
            // SymbolGlyph({ symbol: $r('app.media.heart') })
            //   .fontSize(24)
            //   .fontWeight(600)
            //   .renderMode(SymbolRenderMode.SINGLE)
            //   .foregroundColor(Color.Blue)
          }
          .width(60)
          .height(60)
          .borderRadius(30)
          .backgroundColor($r('app.color.primary'))
          .justifyContent(FlexAlign.Center)
          .margin({ right: 16 })

          Column({ space: 4 }) {
            Text('慢性病助手')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')

            Text('智能健康管理专家')
              .fontSize(13)
              .fontColor('#757575')
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20, bottom: 16 })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')

      // Tab切换按钮
      Row({ space: 12 }) {
        Button(this.currentTab === 0 ? '健康概览' : '健康概览')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentTab === 0 ? '#FFFFFF' : '#757575')
          .backgroundColor(this.currentTab === 0 ? $r('app.color.primary') : '#F5F5F5')
          .layoutWeight(1)
          .height(48)
          .borderRadius(24)
          .onClick(() => {
            this.currentTab = 0;
          })

        Button(this.currentTab === 1 ? '今日用药' : '今日用药')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentTab === 1 ? '#FFFFFF' : '#757575')
          .backgroundColor(this.currentTab === 1 ? $r('app.color.primary') : '#F5F5F5')
          .layoutWeight(1)
          .height(48)
          .borderRadius(24)
          .onClick(() => {
            this.currentTab = 1;
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      // 内容区域
      if (this.currentTab === 0) {
        this.HealthOverviewContent()
      } else {
        this.TodayMedicineContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  @Builder
  HealthOverviewContent() {
    Scroll() {
      Column({ space: 16 }) {
        // 健康状态概览卡片
        Column({ space: 16 }) {
          Column({ space: 4 }) {
            Text('健康状态概览')
              .textAlign(TextAlign.Center)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')
              .width('100%')
              .margin({ bottom: 8 })
            Text(`正在管理 ${this.diseaseCount} 种慢性病`)
              .fontSize(14)
              .fontColor('#757575')
              .width('100%')
              .textAlign(TextAlign.Center)
          }
          .width('100%')

          // 健康数据展示
          Row({ space: 12 }) {
            // 收缩压
            Column({ space: 4 }) {
              Text('收缩压')
                .fontSize(13)
                .fontColor('#757575')

              Text(this.latestBloodPressure ? `${this.latestBloodPressure.systolic}` : '--')
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor('#212121')

              Text('mmHg')
                .fontSize(12)
                .fontColor('#9E9E9E')
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor('#FAFAFA')
            .borderRadius(12)

            // 舒张压
            Column({ space: 4 }) {
              Text('舒张压')
                .fontSize(13)
                .fontColor('#757575')

              Text(this.latestBloodPressure ? `${this.latestBloodPressure.diastolic}` : '--')
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor('#212121')

              Text('mmHg')
                .fontSize(12)
                .fontColor('#9E9E9E')
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor('#FAFAFA')
            .borderRadius(12)

            // 血糖
            Column({ space: 4 }) {
              Text('血糖')
                .fontSize(13)
                .fontColor('#757575')

              Text(this.latestGlucose ? `${this.latestGlucose.toFixed(1)}` : '--')
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor('#212121')

              Text('mmol/L')
                .fontSize(12)
                .fontColor('#9E9E9E')
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor('#FAFAFA')
            .borderRadius(12)
          }
          .width('100%')

          // 查看历史就诊记录按钮
          Button({ type: ButtonType.Normal }) {
            Row({ space: 6 }) {
              Image($r('app.media.trending_up'))
                .width(20)
                .height(20)
                .fillColor($r('app.color.primary'))

              Text('查看历史就诊记录')
                .fontSize(14)
                .fontColor($r('app.color.primary'))
            }
          }
          .width('100%')
          .height(44)
          .backgroundColor('#F0F7FF')
          .borderRadius(8)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/medical/MedicalRecordsPage'
            });
          })
        }
        .padding(20)
        .backgroundColor('#eff6ff')
        .borderRadius(16)
        .margin({ left: 16, right: 16, top: 12 })

        // 添加疾病和就诊记录按钮
        Row({ space: 12 }) {
          // 添加疾病按钮
          Button() {
            Column({ space: 8 }) {
              Image($r('app.media.plus'))
                .width(24)
                .height(24)
                .fillColor('#4CAF50')

              Text('添加疾病')
                .fontSize(14)
                .fontColor('#212121')
            }
            .alignItems(HorizontalAlign.Center)
          }
          .height(100)
          .layoutWeight(1)
          .backgroundColor('#F5F5F5')
          .borderRadius(6)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/disease/AddDiseasePage'
            });
          })

          // 添加就诊记录按钮
          Button() {
            Column({ space: 8 }) {
              Image($r('app.media.calendar'))
                .width(24)
                .height(24)
                .fillColor('#2196F3')

              Text('添加就诊记录')
                .fontSize(14)
                .fontColor('#212121')
            }
            .alignItems(HorizontalAlign.Center)
          }
          .height(100)
          .layoutWeight(1)
          .backgroundColor('#F5F5F5')
          .borderRadius(6)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/medical/AddMedicalRecordPage'
            });
          })
        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 8,
          bottom: 8
        })

        // 疾病列表
        Column({ space: 12 }) {
          ForEach(this.templates, (template: DiseaseTemplate) => {
            // 显示已激活的疾病模板，无论是否有记录
            if (this.activeTemplates.includes(template.id)) {
              this.DiseaseCard(template, this.templateCounts.get(template.id) || 0);
            }
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .width('100%')
      .constraintSize({ minHeight: '100%' })
    }
    .layoutWeight(1)
  }

  @Builder
  TodayMedicineContent() {
    if (this.todayMedicineRecords.length === 0) {
      Column() {
        Text('💊')
          .fontSize(80)
          .margin({ top: 100 })

        Text('今日暂无用药记录')
          .fontSize(16)
          .fontColor('#9E9E9E')
          .margin({ top: 16 })

        Text('添加药品后会自动生成用药记录')
          .fontSize(14)
          .fontColor('#BDBDBD')
          .margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
    } else {
      Scroll() {
        Column({ space: 12 }) {
          // 今日进度卡片
          Column({ space: 12 }) {
            Row() {
              Text('今日进度')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#757575')
                .layoutWeight(1)

              Text(`${this.getTakenCount()}/${this.todayMedicineRecords.length}`)
                .fontSize(14)
                .fontColor('#4CAF50')
            }
            .width('100%')

            Progress({
              value: this.getTakenCount(),
              total: this.todayMedicineRecords.length,
              type: ProgressType.Linear
            })
            .width('100%')
            .color('#4CAF50')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 12 })

          // 用药记录列表
          Column({ space: 8 }) {
            ForEach(this.todayMedicineRecords, (record: MedicineRecord) => {
              this.MedicineRecordCard(record);
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
  }

  @Builder
  DiseaseCard(template: DiseaseTemplate, count: number) {
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

        Text(`已记录 ${count} 次`)
          .fontSize(13)
          .fontColor('#9E9E9E')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 日期
      Text(this.getLatestDateSync(template.id))
        .fontSize(12)
        .fontColor('#BDBDBD')
        .margin({ right: 8 })

      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(20)
        .height(20)
        .fillColor('#BDBDBD')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/disease/DiseaseManagePage',
        params: { templateId: template.id }
      });
    })
  }

  @Builder
  MedicineRecordCard(record: MedicineRecord) {
    Row() {
      Checkbox()
        .select(record.taken)
        .onChange(async (value: boolean) => {
          record.taken = value;
          record.takenTime = value ? Date.now() : 0;
          await HealthRecordDatabase.getInstance().saveMedicineRecord(record);
          await this.loadData();
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
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
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

  getTakenCount(): number {
    return this.todayMedicineRecords.filter(r => r.taken).length;
  }

  getLatestDateSync(templateId: string): string {
    // 同步方法，返回默认值
    return '--';
  }

  async getLatestDate(templateId: string): Promise<string> {
    try {
      const latestRecord = await HealthRecordDatabase.getInstance().getLatestHealthRecord(templateId);
      if (latestRecord) {
        const date = new Date(latestRecord.date);
        return `${date.getMonth() + 1}/${date.getDate()}`;
      }
      return '--';
    } catch (err) {
      return '--';
    }
  }
}

