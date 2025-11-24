import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HealthRecordDatabase } from '../../utils/HealthRecordDatabase';
import { BuiltInTemplates } from '../../config/BuiltInTemplates';
import { DiseaseTemplate } from '../../models/DiseaseTemplate';
import { MedicineRecord } from '../../models/MedicineData';

const TAG = 'HomePage';
const DOMAIN = 0x0000;

interface BloodPressure {
  systolic: number;
  diastolic: number;
}

interface IndicatorItem {
  name: string;
  value: string | number;
  unit?: string;
}

interface HealthIndicator {
  diseaseId: string;
  diseaseName: string;
  diseaseColor: string;
  indicators: IndicatorItem[];
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
  @State healthIndicators: HealthIndicator[] = []; // Swiper 数据源
  private indicatorSwiperController: SwiperController = new SwiperController(); // Swiper 控制器
  @State diseaseIndicators: Map<string, IndicatorItem[]> = new Map(); // 存储每个疾病的核心指标
  @State swiperIndex:number=0
  @Watch('onRefreshKeyChanged') @Prop refreshKey: number = 0; // 刷新触发器

  async aboutToAppear() {
    console.log('HomePage aboutToAppear')
    await this.loadData();
    hilog.debug(DOMAIN, TAG, 'HomePage aboutToAppear');
  }

  // 监听 refreshKey 变化，触发刷新
  async onRefreshKeyChanged() {
    if (this.refreshKey > 0) {
      console.log('HomePage refreshKey changed, reloading data');
      await this.loadData();
    }
  }

  async loadData() {
    hilog.info(DOMAIN, TAG, 'LoadData start');
    const db = HealthRecordDatabase.getInstance();
    
    // 加载模板列表
    this.templates = BuiltInTemplates.getAllTemplates();
    hilog.info(DOMAIN, TAG, 'Loaded templates count222:%{public}d', this.templates.length);
    
    // 获取已激活的疾病模板
    const activeTemplatesFromDB = await db.getActiveDiseaseTemplates();
    this.activeTemplates = activeTemplatesFromDB.map((t) => t.templateId);
    hilog.info(DOMAIN, TAG, 'Active templates count:%{public}d', this.activeTemplates.length);
    
    // 计算疾病数量（从激活的疾病模板获取）
    this.diseaseCount = this.activeTemplates.length;
    console.log('this.diseaseCount:', this.diseaseCount)
    
    // 加载每个模板的记录数和核心指标
    this.diseaseIndicators.clear();
    for (const template of this.templates) {
      const count = await db.getRecordCount(template.id);
      this.templateCounts.set(template.id, count);
      
      // 加载该疾病的核心指标（最多3个）
      await this.loadDiseaseIndicators(template, db);
    }
    
    // 加载 Swiper 数据：每个激活疾病的最近诊疗记录指标
    await this.loadHealthIndicators(db);
    
    // 加载最新血压数据
    const latestBP = await db.getLatestHealthRecord('hypertension', 'blood_pressure');
    if (latestBP) {
      const systolic = latestBP.getIndicator('systolic') as number;
      const diastolic = latestBP.getIndicator('diastolic') as number;
      this.latestBloodPressure = { systolic, diastolic };
      hilog.debug(DOMAIN, TAG, 'Latest blood pressure - systolic:%{public}d, diastolic:%{public}d', systolic, diastolic);
    }
    
    // 加载最新血糖数据
    const latestDiabetes = await db.getLatestHealthRecord('diabetes', 'glucose');
    if (latestDiabetes) {
      this.latestGlucose = latestDiabetes.getIndicator('glucose') as number;
      hilog.debug(DOMAIN, TAG, 'Latest glucose:%{public}f', this.latestGlucose as number);
    }
    
    // 加载今日用药记录（今天00:00:00到23:59:59）
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStart = today.getTime();
    const todayEnd = todayStart + 24 * 60 * 60 * 1000 - 1;
    this.todayMedicineRecords = await db.getMedicineRecords(todayStart, todayEnd);
    hilog.info(DOMAIN, TAG, 'Today medicine records count:%{public}d', this.todayMedicineRecords.length);
    
    // 触发UI更新
    this.templateCounts = new Map(this.templateCounts);
    this.activeTemplates = [...this.activeTemplates];
    this.diseaseIndicators = new Map(this.diseaseIndicators);
    this.healthIndicators = [...this.healthIndicators];
    hilog.debug(DOMAIN, TAG, 'LoadData completed');
  }

  private async loadDiseaseIndicators(template: DiseaseTemplate, db: HealthRecordDatabase): Promise<void> {
    try {
      const indicators: IndicatorItem[] = [];
      
      // 获取该疾病的第一组指标定义（最多前3个）
      if (template.indicatorGroups.length > 0) {
        const firstGroup = template.indicatorGroups[0];
        const indicatorDefs = firstGroup.indicators.slice(0, 3); // 只取前3个指标
        
        // 获取每个指标的最新值
        for (const indicatorDef of indicatorDefs) {
          try {
            const latestRecord = await db.getLatestHealthRecord(template.id, firstGroup.id);
            if (latestRecord) {
              const value = latestRecord.getIndicator(indicatorDef.id);
              if (value !== undefined) {
                indicators.push({
                  name: indicatorDef.name,
                  value: value,
                  unit: indicatorDef.unit
                });
                hilog.debug(DOMAIN, TAG, 'Loaded indicator: %{public}s=%{public}s', indicatorDef.name, String(value));
              }
            }
          } catch (err) {
            const error = err as Error;
            hilog.warn(DOMAIN, TAG, 'Failed to load indicator %{public}s: %{public}s', indicatorDef.name, error.message);
          }
        }
      }
      
      if (indicators.length > 0) {
        this.diseaseIndicators.set(template.id, indicators);
        hilog.info(DOMAIN, TAG, 'Loaded %{public}d indicators for disease: %{public}s', indicators.length, template.name);
      }
    } catch (err) {
      const error = err as Error;
      hilog.error(DOMAIN, TAG, 'Failed to load disease indicators for %{public}s: %{public}s', template.name, error.message);
    }
  }

  private async loadHealthIndicators(db: HealthRecordDatabase): Promise<void> {
    try {
      this.healthIndicators = [];
      
      // 默认单位
      const defaultUnits: Record<string, string> = {
        'systolic': 'mmHg',
        'diastolic': 'mmHg',
        'glucose': 'mmol/L'
      };
      
      // 为每个激活的疾病加载最近的诊疗记录
      for (const templateId of this.activeTemplates) {
        const template = this.templates.find(t => t.id === templateId);
        if (!template) continue;
        
        try {
          // 提取最多3个默认指标
          const indicators: IndicatorItem[] = [];
          
          // 对于高血压，从 blood_pressure 组获取数据
          if (templateId === 'hypertension') {
            const latestRecord = await db.getLatestHealthRecord(templateId, 'blood_pressure');
            if (latestRecord) {
              const systolic = latestRecord.getIndicator('systolic');
              const diastolic = latestRecord.getIndicator('diastolic');
              
              if (systolic !== undefined) {
                indicators.push({
                  name: '收缩压',
                  value: systolic,
                  unit: defaultUnits['systolic']
                });
              }
              if (diastolic !== undefined) {
                indicators.push({
                  name: '舒张压',
                  value: diastolic,
                  unit: defaultUnits['diastolic']
                });
              }
            }
            // 如果没有数据，显示占位符
            if (indicators.length === 0) {
              indicators.push(
                { name: '收缩压', value: '--', unit: defaultUnits['systolic'] },
                { name: '舒张压', value: '--', unit: defaultUnits['diastolic'] }
              );
            }
          }
          // 对于糖尿病，从 glucose 组获取数据
          else if (templateId === 'diabetes') {
            const latestRecord = await db.getLatestHealthRecord(templateId, 'glucose');
            if (latestRecord) {
              const glucose = latestRecord.getIndicator('glucose');
              if (glucose !== undefined) {
                indicators.push({
                  name: '血糖',
                  value: glucose,
                  unit: defaultUnits['glucose']
                });
              }
            }
            // 如果没有数据，显示占位符
            if (indicators.length === 0) {
              indicators.push({
                name: '血糖',
                value: '--',
                unit: defaultUnits['glucose']
              });
            }
          }
          // 其他疾病：从第一组指标中取前3个
          else {
            if (template.indicatorGroups.length > 0) {
              const firstGroup = template.indicatorGroups[0];
              // 先尝试从第一组获取数据
              let latestRecord = await db.getLatestHealthRecord(templateId, firstGroup.id);
              // 如果第一组没有数据，尝试不指定groupId获取任意记录
              if (!latestRecord) {
                latestRecord = await db.getLatestHealthRecord(templateId);
              }
              
              if (latestRecord) {
                for (const indicatorDef of firstGroup.indicators.slice(0, 3)) {
                  const value = latestRecord.getIndicator(indicatorDef.id);
                  if (value !== undefined) {
                    indicators.push({
                      name: indicatorDef.name,
                      value: value,
                      unit: indicatorDef.unit
                    });
                  }
                }
              }
              
              // 如果没有数据，显示占位符
              if (indicators.length === 0) {
                for (const indicatorDef of firstGroup.indicators.slice(0, 3)) {
                  indicators.push({
                    name: indicatorDef.name,
                    value: '--',
                    unit: indicatorDef.unit
                  });
                }
              }
            }
          }
          
          // 添加到列表（无论是否有真实数据）
          this.healthIndicators.push({
            diseaseId: templateId,
            diseaseName: template.name,
            diseaseColor: template.color,
            indicators: indicators
          });
          hilog.info(DOMAIN, TAG, 'Loaded health indicators for: %{public}s, count: %{public}d', template.name, indicators.length);
        } catch (err) {
          const error = err as Error;
          hilog.warn(DOMAIN, TAG, 'Failed to load indicators for %{public}s: %{public}s', templateId, error.message);
        }
      }
      
      hilog.info(DOMAIN, TAG, 'Loaded %{public}d health indicator sets', this.healthIndicators.length);
    } catch (err) {
      const error = err as Error;
      hilog.error(DOMAIN, TAG, 'Failed to load health indicators: %{public}s', error.message);
    }
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
            Text('󰀡').fontSize(28).fontColor(Color.White)
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

          // Swiper 健康数据展示
          if (this.healthIndicators.length > 0) {
            Column() {
              Swiper(this.indicatorSwiperController) {
                ForEach(this.healthIndicators, (item: HealthIndicator) => {
                  this.HealthIndicatorCard(item);
                })
              }
              .index(0)
              .autoPlay(false)
              .duration(300)
              .curve(Curve.Linear)
              .onChange((index: number) => {
                this.swiperIndex=index
              })
              .height(160)
              .margin({ left: 16, right: 16 })
              .indicator(false)
              .loop(true)
              .cachedCount(1)
              .disableSwipe(false)

              // 指示器
              if (this.healthIndicators.length > 1) {
                Row({ space: 6 }) {
                  ForEach(this.healthIndicators, (_: HealthIndicator, index: number) => {
                    Circle()
                      .width(8)
                      .height(8)
                      .fill(index === this.swiperIndex ? $r('app.color.primary') : '#BDBDBD')
                  })
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding({ top: 12 })
              }
            }
            .width('100%')
          } else {
            Column({ space: 12 }) {
              Image($r('app.media.no_data'))
              .width(48)
              .height(48)

              Text('暂无健康数据')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#757575')

              Text('添加疾病后可查看健康指标')
                .fontSize(13)
                .fontColor('#BDBDBD')
            }
            .width('100%')
            .height(180)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 16, right: 16 })
          }

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
        .borderRadius(8)
        .margin({ left: 16, right: 16, top: 12 })

        // 添加疾病和就诊记录按钮
        Row({ space: 12 }) {
          Button({type: ButtonType.Normal}) {
            Column({ space: 12 }) {
              Row() {
                // Image($r('app.media.plus'))
                //   .width(28)
                //   .height(28)
                //   .fillColor($r('app.color.primary'))

                Text('󰀵')
                .fontSize(28)
                .fontColor($r('app.color.primary'))
              }
              .width(64)
              .height(64)
              .borderRadius(16)
              .backgroundColor('#E3F2FD')
              .justifyContent(FlexAlign.Center)

              Text('添加疾病')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#212121')
            }
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 20, bottom: 20 })
          }
          .height(160)
          .layoutWeight(1)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.08)', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/disease/AddDiseasePage'
            });
          })

          Button({type: ButtonType.Normal}) {
            Column({ space: 12 }) {
              Row() {
                Image($r('app.media.calendar'))
                  .width(28)
                  .height(28)
                  .fillColor($r('app.color.primary'))
              }
              .width(64)
              .height(64)
              .borderRadius(16)
              .backgroundColor('#E3F2FD')
              .justifyContent(FlexAlign.Center)

              Text('添加就诊记录')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#212121')
            }
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 20, bottom: 20 })
          }
          .height(160)
          .layoutWeight(1)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.08)', offsetX: 0, offsetY: 2 })
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
        if (this.activeTemplates.length > 0) {
          Column({ space: 12 }) {
            ForEach(this.templates, (template: DiseaseTemplate) => {
              if (this.activeTemplates.includes(template.id)) {
                this.DiseaseCard(template, this.templateCounts.get(template.id) || 0);
              }
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        } else {
          Column() {
            Text('󰖿')
              .fontSize(30)
              .margin({ top: 40, bottom: 16 })

            Text('还未添加任何疾病')
              .fontSize(16)
              .fontColor('#9E9E9E')
              .margin({ bottom: 8 })

            Text('点击上方"添加疾病"开始管理您的慢性病')
              .fontSize(13)
              .fontColor('#BDBDBD')
              .textAlign(TextAlign.Center)
              .padding({ left: 20, right: 20 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 16, right: 16, top: 40, bottom: 40 })
        }
      }
      .width('100%')
    }
    .layoutWeight(1)
    .backgroundColor('#F5F5F5')
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .friction(0.6)
  }

  @Builder
  HealthIndicatorCard(item: HealthIndicator) {
    Column({ space: 12 }) {
      // 疾病标题
      Row() {
        Text(item.diseaseName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')
          .layoutWeight(1)

        Text('最近记录')
          .fontSize(12)
          .fontColor('#BDBDBD')
      }
      .width('100%')

      // 指标数据
      Row({ space: 12 }) {
        ForEach(item.indicators, (indicator: IndicatorItem) => {
          Column({ space: 4 }) {
            Text(indicator.name)
              .fontSize(12)
              .fontColor('#757575')

            Text(`${indicator.value}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')

            if (indicator.unit) {
              Text(indicator.unit)
                .fontSize(11)
                .fontColor('#9E9E9E')
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  TodayMedicineContent() {
    if (this.todayMedicineRecords.length === 0) {
      Column() {
      //   Text('💊')
      //     .fontSize(80)
      //     .margin({ top: 100 })
        Image($r('app.media.pill'))
          .width(60)
          .height(60)
          .borderRadius(20)
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
                .fontColor($r('app.color.primary'))
            }
            .width('100%')

            Progress({
              value: this.getTakenCount(),
              total: this.todayMedicineRecords.length,
              type: ProgressType.Linear
            })
            .width('100%')
            .color($r('app.color.primary'))
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
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .friction(0.6)
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
          .fillColor($r('app.color.primary'))
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

