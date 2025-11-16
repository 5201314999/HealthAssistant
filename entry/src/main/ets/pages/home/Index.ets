import router from '@ohos.router';
import { HealthRecordDatabase } from '../../utils/HealthRecordDatabase';
import { BuiltInTemplates } from '../../config/BuiltInTemplates';
import { DiseaseTemplate } from '../../models/DiseaseTemplate';
import { MedicineRecord } from '../../models/MedicineData';

@Entry
@Component
struct Index {
  @State templates: DiseaseTemplate[] = [];
  @State templateCounts: Map<string, number> = new Map();
  @State medicineCount: number = 0;
  @State todayMedicineCount: number = 0;
  @State cardScales: Map<string, number> = new Map(); // 卡片缩放动画状态

  async aboutToAppear() {
    // 初始化数据管理器
    await HealthRecordDatabase.getInstance().init(getContext(this));

    // 加载模板列表
    this.templates = BuiltInTemplates.getAllTemplates();

    // 加载统计数据
    await this.loadStatistics();

    // 生成今日用药记录
    await HealthRecordDatabase.getInstance().generateTodayMedicineRecords();
  }

  onPageShow() {
    this.loadStatistics();
  }

  async loadStatistics() {
    // 加载各模板的记录数量
    for (const template of this.templates) {
      const count = await HealthRecordDatabase.getInstance().getRecordCount(template.id);
      this.templateCounts.set(template.id, count);
    }

    // 加载用药数据
    const medicineList = await HealthRecordDatabase.getInstance().getMedicineList();
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStart = today.getTime();
    const todayEnd = todayStart + 24 * 60 * 60 * 1000 - 1;
    const todayRecords = await HealthRecordDatabase.getInstance().getMedicineRecords(todayStart, todayEnd);

    this.medicineCount = medicineList.length;
    this.todayMedicineCount = todayRecords.filter(r => !r.taken).length;

    // 触发UI更新
    this.templateCounts = new Map(this.templateCounts);
  }

  build() {
    Column() {
      // 美化标题栏 - 添加渐变背景
      Row() {
        Column() {
          Text("慢性病助手")
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')

          Text('您的健康管理专家')
            .fontSize(12)
            .fontColor('#E0F7FA')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 引导按钮
        Text('📖')
          .fontSize(24)
          .onClick(() => {
            router.pushUrl({ url: 'pages/common/GuidePage' });
          })
      }
      .width('100%')
      .height(100)
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .linearGradient({
        angle: 135,
        colors: [[0x4CAF50, 0.0], [0x2E7D32, 1.0]]
      })

      Scroll() {
        Column({ space: 20 }) {
          // 今日提醒卡片 - 美化版
          if (this.todayMedicineCount > 0) {
            Column() {
              Row() {
                Text('⏰')
                  .fontSize(28)

                Column({ space: 4 }) {
                  Text(`您有 ${this.todayMedicineCount} 次用药待打卡`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#E65100')

                  Text('按时服药，健康生活')
                    .fontSize(12)
                    .fontColor('#FB8C00')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: 12 })

                Text('去查看 →')
                  .fontSize(14)
                  .fontColor('#FF6F00')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              .padding(16)
            }
            .width('100%')
            .margin({ left: 16, right: 16, top: 16 })
            .linearGradient({
              angle: 90,
              colors: [[0xFFE0B2, 0.0], [0xFFCC80, 1.0]]
            })
            .borderRadius(16)
            .shadow({
              radius: 12,
              color: '#30FF9800',
              offsetY: 4
            })
            .onClick(() => {
              router.pushUrl({ url: 'pages/medicine/MedicineManagePage' });
            })
          }

          // 慢性病助手区域
          Column({ space: 12 }) {
            Text('慢性病助手')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .alignSelf(ItemAlign.Start)

            // 动态生成疾病模板卡片
            ForEach(this.templates, (template: DiseaseTemplate) => {
              this.ManageCard(
                template.name,
                template.description,
                template.color,
                this.templateCounts.get(template.id) || 0,
                () => {
                  router.pushUrl({
                    url: 'pages/disease/DiseaseManagePage',
                    params: { templateId: template.id }
                  });
                }
              )
            })
          }
          .width('100%')
          .padding(16)

          // 用药管理区域
          Column({ space: 12 }) {
            Text('用药管理')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .alignSelf(ItemAlign.Start)

            this.ManageCard(
              '用药提醒',
              '管理日常用药与提醒',
              '#FF9800',
              this.medicineCount,
              () => {
                router.pushUrl({ url: 'pages/medicine/MedicineManagePage' });
              }
            )
          }
          .width('100%')
          .padding(16)
        }
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ManageCard(
    title: string,
    subtitle: string,
    color: string,
    count: number,
    onClick: () => void
  ) {
    Column() {
      Row({ space: 12 }) {
        // 图标区域 - 渐变背景
        Row() {
          Text(title.charAt(0))
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width(56)
        .height(56)
        .borderRadius(16)
        .linearGradient({
          angle: 135,
          colors: [[color, 0.0], [this.darkenColor(color as string), 1.0]]
        })
        .justifyContent(FlexAlign.Center)
        .shadow({
          radius: 8,
          color: `${color}40`,
          offsetY: 2
        })

        // 内容区域
        Column({ space: 4 }) {
          Text(title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')

          Text(subtitle)
            .fontSize(13)
            .fontColor('#757575')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 统计区域
        Column({ space: 4 }) {
          Text(`${count}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(color)

          Text('条记录')
            .fontSize(11)
            .fontColor('#9E9E9E')
        }
        .padding({ left: 12, right: 4 })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: '#15000000',
      offsetY: 4
    })
    .scale({
      x: this.cardScales.get(title) || 1,
      y: this.cardScales.get(title) || 1
    })
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.cardScales.set(title, 0.97);
        this.cardScales = new Map(this.cardScales);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.cardScales.set(title, 1);
        this.cardScales = new Map(this.cardScales);
      }
    })
    .onClick(onClick)
  }

  // 颜色加深辅助方法
  darkenColor(color: string): string {
    // 简单的颜色加深处理
    const colors: Record<string, string> = {
      '#3b82f6': '#1E53F5',
      '#2196F3': '#1565C0',
      '#FF9800': '#E65100',
      '#F44336': '#C62828',
      '#9C27B0': '#6A1B9A'
    };
    return colors[color] || color;
  }
}