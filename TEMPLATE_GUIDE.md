# 疾病模板扩展指南

## 📖 概述

本应用采用**灵活的模板系统**架构，您可以轻松添加新的慢性病管理模板，无需修改页面代码。

## 🏗️ 架构优势

### ✅ 新架构（模板系统）

- **一套页面适配所有疾病** - `DiseaseManagePage` + `DataEntryPage`
- **动态表单生成** - 根据配置自动生成录入界面
- **统一数据模型** - `HealthRecord` 存储所有类型的健康数据
- **易于扩展** - 只需配置新模板，无需写代码

### ❌ 旧架构（已废弃）

- ~~每个疾病需要独立的页面~~
- ~~硬编码表单字段~~
- ~~重复的代码~~
- ~~难以维护~~

## 🎯 添加新模板的步骤

### 示例：添加"高血压管理"模板

#### 1. 在 `BuiltInTemplates.ets` 中创建模板函数

```typescript
// 创建高血压管理模板
function createHypertensionTemplate(): DiseaseTemplate {
  const template = new DiseaseTemplate("hypertension", "高血压管理", "#E91E63");
  template.description = "记录血压与心率指标";
  template.icon = "sys.media.ohos_ic_public_health";

  // 血压监测组
  const bloodPressure = new IndicatorGroup("bp", "血压监测", "日常血压记录");

  // 收缩压
  const systolic = new IndicatorDefinition("systolic", "收缩压", "高压");
  systolic.type = IndicatorType.NUMBER;
  systolic.unit = "mmHg";
  systolic.referenceMin = 90;
  systolic.referenceMax = 120;
  systolic.warningLevels = [
    { level: "normal", min: 90, max: 120, label: "正常" },
    { level: "warning", min: 120, max: 140, label: "偏高" },
    { level: "danger", min: 140, label: "高血压" },
  ];

  // 舒张压
  const diastolic = new IndicatorDefinition("diastolic", "舒张压", "低压");
  diastolic.type = IndicatorType.NUMBER;
  diastolic.unit = "mmHg";
  diastolic.referenceMin = 60;
  diastolic.referenceMax = 80;
  diastolic.warningLevels = [
    { level: "normal", min: 60, max: 80, label: "正常" },
    { level: "warning", min: 80, max: 90, label: "偏高" },
    { level: "danger", min: 90, label: "高血压" },
  ];

  // 心率
  const heartRate = new IndicatorDefinition(
    "heartRate",
    "心率",
    "每分钟心跳次数"
  );
  heartRate.type = IndicatorType.NUMBER;
  heartRate.unit = "次/分";
  heartRate.referenceMin = 60;
  heartRate.referenceMax = 100;
  heartRate.required = false; // 可选指标

  bloodPressure.indicators = [systolic, diastolic, heartRate];

  template.indicatorGroups = [bloodPressure];

  return template;
}
```

#### 2. 注册模板到系统

在 `BuiltInTemplates` 类的 `init()` 方法中添加：

```typescript
static init(): void {
  if (this.templates.length === 0) {
    this.templates = [
      createThyroidTemplate(),      // 甲亢
      createDiabetesTemplate(),     // 糖尿病
      createHypertensionTemplate()  // 👈 新增高血压
    ];
  }
}
```

#### 3. 完成！🎉

就这么简单！新的高血压管理模板会自动出现在首页，点击即可使用。

## 📝 指标类型详解

### 1. **NUMBER（数值型）**

用于数值型指标，如血压、血糖等。

```typescript
const indicator = new IndicatorDefinition("glucose", "血糖", "血糖浓度");
indicator.type = IndicatorType.NUMBER;
indicator.unit = "mmol/L";
indicator.referenceMin = 3.9;
indicator.referenceMax = 6.1;
```

### 2. **SELECT（选择型）**

用于固定选项，如时间点、类型等。

```typescript
const indicator = new IndicatorDefinition("time", "测量时间", "血压测量时间点");
indicator.type = IndicatorType.SELECT;
indicator.options = [
  { label: "早晨", value: "morning" },
  { label: "中午", value: "noon" },
  { label: "晚上", value: "evening" },
];
```

### 3. **TEXT（文本型）**

用于文本输入，如症状描述等。

```typescript
const indicator = new IndicatorDefinition("symptom", "症状", "自觉症状");
indicator.type = IndicatorType.TEXT;
indicator.required = false;
```

## 🎨 警戒级别配置

通过 `warningLevels` 配置指标的健康等级：

```typescript
indicator.warningLevels = [
  {
    level: "normal", // 正常 - 绿色
    min: 90,
    max: 120,
    label: "正常范围",
  },
  {
    level: "warning", // 警告 - 橙色
    min: 120,
    max: 140,
    label: "需注意",
  },
  {
    level: "danger", // 危险 - 红色
    min: 140, // 只设置 min 表示 >= 140
    label: "高危",
  },
];
```

系统会自动根据数值所在范围显示对应颜色。

## 🔍 多指标组示例

一个模板可以包含多个指标组，如甲亢模板包含"三项"和"五项"：

```typescript
const template = new DiseaseTemplate("thyroid", "甲亢管理", "#4CAF50");

// 指标组1：甲功三项
const threeItems = new IndicatorGroup("three", "甲功三项", "基础检查");
threeItems.indicators = [tsh, ft3, ft4];

// 指标组2：甲功五项
const fiveItems = new IndicatorGroup("five", "甲功五项", "完整检查");
fiveItems.indicators = [tsh, ft3, ft4, tt3, tt4];

template.indicatorGroups = [threeItems, fiveItems];
```

页面会自动生成 Tab 切换，录入时也会显示对应的按钮。

## 📊 数据存储说明

所有健康记录使用统一的 `HealthRecord` 模型：

```typescript
{
  id: "1234567890abc",
  templateId: "hypertension",     // 模板ID
  groupId: "bp",                   // 指标组ID
  date: 1699999999999,             // 记录时间
  indicators: {                    // 指标数据
    "systolic": 125,
    "diastolic": 82,
    "heartRate": 78
  },
  note: "运动后测量"                 // 备注
}
```

数据按 `templateId` 分类存储在本地 Preferences 中：

- `health_records_thyroid` - 甲亢数据
- `health_records_diabetes` - 糖尿病数据
- `health_records_hypertension` - 高血压数据

## 🚀 更多扩展可能

### 1. 高血脂管理

```typescript
指标：总胆固醇、甘油三酯、高密度脂蛋白、低密度脂蛋白
```

### 2. 哮喘管理

```typescript
指标：峰流速值、发作次数、用药情况
```

### 3. 痛风管理

```typescript
指标：尿酸、关节疼痛评分、发作频率
```

### 4. 心脏病管理

```typescript
指标：心电图、心肌酶、B型钠尿肽
```

### 5. 肾病管理

```typescript
指标：肌酐、尿素氮、尿蛋白、肾小球滤过率
```

## 💡 最佳实践

1. **指标命名**

   - ID 使用驼峰命名：`systolicPressure`
   - 显示名称简洁：`收缩压`
   - 全称说明清楚：`收缩压（高压）`

2. **参考值设置**

   - 基于医学标准设置参考范围
   - 警戒级别分级明确（正常/警告/危险）

3. **指标分组**

   - 相关指标归为一组
   - 组名清晰易懂
   - 添加组描述说明用途

4. **可选指标**

   - 非必填指标设置 `required: false`
   - 让用户选择性填写

5. **颜色选择**
   - 每个模板使用不同的主题色
   - 建议使用 Material Design 配色

## 🔧 调试技巧

### 查看存储的数据

```typescript
// 在 DevEco Studio 控制台查看
const records = await HealthDataManager.getInstance().getHealthRecords(
  "hypertension"
);
console.log("高血压记录:", JSON.stringify(records));
```

### 清除测试数据

可以在应用设置中清除应用数据，或使用以下代码：

```typescript
// 临时调试代码
await preferences.deletePreferences(context, "medical_assistant_data_v2");
```

## 📚 相关文件

- `models/DiseaseTemplate.ets` - 模板系统核心定义
- `config/BuiltInTemplates.ets` - 内置模板配置
- `utils/HealthDataManager.ets` - 数据管理
- `pages/DiseaseManagePage.ets` - 通用管理页面
- `pages/DataEntryPage.ets` - 通用录入页面

## ❓ 常见问题

**Q: 可以动态添加模板吗（不重新编译）？**  
A: 当前内置模板需要编译。未来可以扩展支持从服务器或配置文件加载自定义模板。

**Q: 可以修改已有模板吗？**  
A: 可以，只需修改对应的创建函数即可。但注意历史数据的兼容性。

**Q: 支持图片或附件吗？**  
A: 当前版本不支持。可以扩展 `IndicatorType` 添加 `IMAGE` 或 `FILE` 类型。

**Q: 可以导出数据吗？**  
A: 当前版本未实现。可以扩展添加 JSON/CSV 导出功能。

---

有任何问题或建议，欢迎提出！💪
