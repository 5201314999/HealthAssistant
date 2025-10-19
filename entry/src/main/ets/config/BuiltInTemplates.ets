/**
 * 内置疾病模板配置
 */

import { DiseaseTemplate, IndicatorGroup, IndicatorDefinition, IndicatorType } from '../models/DiseaseTemplate';

// 创建甲亢管理模板
function createThyroidTemplate(): DiseaseTemplate {
  const template = new DiseaseTemplate('thyroid', '甲亢管理', '#4CAF50');
  template.description = '记录甲状腺功能指标';
  template.icon = 'sys.media.ohos_ic_public_health';
  
  // 甲功三项
  const threeItems = new IndicatorGroup('three', '甲功三项', '基础甲状腺功能检查');
  
  const tsh = new IndicatorDefinition('tsh', 'TSH', '促甲状腺激素');
  tsh.type = IndicatorType.NUMBER;
  tsh.unit = 'mIU/L';
  tsh.referenceMin = 0.27;
  tsh.referenceMax = 4.2;
  tsh.warningLevels = [
    { level: 'normal', min: 0.27, max: 4.2, label: '正常' },
    { level: 'warning', label: '异常' }
  ];
  
  const ft3 = new IndicatorDefinition('ft3', 'FT3', '游离三碘甲状腺原氨酸');
  ft3.type = IndicatorType.NUMBER;
  ft3.unit = 'pmol/L';
  ft3.referenceMin = 3.1;
  ft3.referenceMax = 6.8;
  ft3.warningLevels = [
    { level: 'normal', min: 3.1, max: 6.8, label: '正常' },
    { level: 'warning', label: '异常' }
  ];
  
  const ft4 = new IndicatorDefinition('ft4', 'FT4', '游离甲状腺素');
  ft4.type = IndicatorType.NUMBER;
  ft4.unit = 'pmol/L';
  ft4.referenceMin = 12;
  ft4.referenceMax = 22;
  ft4.warningLevels = [
    { level: 'normal', min: 12, max: 22, label: '正常' },
    { level: 'warning', label: '异常' }
  ];
  
  threeItems.indicators = [tsh, ft3, ft4];
  
  // 甲功五项（包含三项+额外两项）
  const fiveItems = new IndicatorGroup('five', '甲功五项', '完整甲状腺功能检查');
  
  const tt3 = new IndicatorDefinition('tt3', 'TT3', '总三碘甲状腺原氨酸');
  tt3.type = IndicatorType.NUMBER;
  tt3.unit = 'nmol/L';
  tt3.referenceMin = 1.3;
  tt3.referenceMax = 3.1;
  tt3.warningLevels = [
    { level: 'normal', min: 1.3, max: 3.1, label: '正常' },
    { level: 'warning', label: '异常' }
  ];
  
  const tt4 = new IndicatorDefinition('tt4', 'TT4', '总甲状腺素');
  tt4.type = IndicatorType.NUMBER;
  tt4.unit = 'nmol/L';
  tt4.referenceMin = 66;
  tt4.referenceMax = 181;
  tt4.warningLevels = [
    { level: 'normal', min: 66, max: 181, label: '正常' },
    { level: 'warning', label: '异常' }
  ];
  
  fiveItems.indicators = [tsh, ft3, ft4, tt3, tt4];
  
  template.indicatorGroups = [threeItems, fiveItems];
  
  return template;
}

// 创建糖尿病管理模板
function createDiabetesTemplate(): DiseaseTemplate {
  const template = new DiseaseTemplate('diabetes', '糖尿病', '#FFA726');
  template.description = '记录血糖与糖化指标';
  template.icon = 'sys.media.ohos_ic_public_health';
  
  // 血糖监测
  const glucose = new IndicatorGroup('glucose', '血糖监测', '日常血糖值记录');
  
  const glucoseType = new IndicatorDefinition('type', '测量时间', '血糖测量时间点');
  glucoseType.type = IndicatorType.SELECT;
  glucoseType.options = [
    { label: '空腹血糖', value: 'fasting' },
    { label: '餐后2小时', value: 'postprandial' },
    { label: '睡前血糖', value: 'bedtime' },
    { label: '随机血糖', value: 'random' }
  ];
  
  const glucoseValue = new IndicatorDefinition('glucose', '血糖值', '血糖浓度');
  glucoseValue.type = IndicatorType.NUMBER;
  glucoseValue.unit = 'mmol/L';
  glucoseValue.warningLevels = [
    { level: 'normal', max: 6.1, label: '正常（空腹）' },
    { level: 'warning', min: 6.1, max: 7.0, label: '空腹血糖受损' },
    { level: 'danger', min: 7.0, label: '糖尿病范围' }
  ];
  
  glucose.indicators = [glucoseType, glucoseValue];
  
  // 糖化血红蛋白
  const hba1c = new IndicatorGroup('hba1c', '糖化血红蛋白', '反映近3个月平均血糖水平');
  
  const hba1cValue = new IndicatorDefinition('value', 'HbA1c', '糖化血红蛋白');
  hba1cValue.type = IndicatorType.NUMBER;
  hba1cValue.unit = '%';
  hba1cValue.referenceMin = 0;
  hba1cValue.referenceMax = 6.0;
  hba1cValue.warningLevels = [
    { level: 'normal', max: 6.0, label: '正常' },
    { level: 'warning', min: 6.0, max: 7.0, label: '控制目标' },
    { level: 'danger', min: 7.0, label: '需改善' }
  ];
  
  hba1c.indicators = [hba1cValue];
  
  template.indicatorGroups = [glucose, hba1c];
  
  return template;
}

// 创建高血压管理模板
function createHypertensionTemplate(): DiseaseTemplate {
  const template = new DiseaseTemplate('hypertension', '高血压', '#EF5350');
  template.description = '记录血压数据';
  template.icon = 'sys.media.ohos_ic_public_health';
  
  // 血压监测
  const bloodPressure = new IndicatorGroup('blood_pressure', '血压监测', '日常血压值记录');
  
  const systolic = new IndicatorDefinition('systolic', '收缩压', '高压');
  systolic.type = IndicatorType.NUMBER;
  systolic.unit = 'mmHg';
  systolic.referenceMin = 90;
  systolic.referenceMax = 120;
  systolic.warningLevels = [
    { level: 'normal', min: 90, max: 120, label: '正常' },
    { level: 'warning', min: 120, max: 140, label: '正常高值' },
    { level: 'danger', min: 140, label: '高血压' }
  ];
  
  const diastolic = new IndicatorDefinition('diastolic', '舒张压', '低压');
  diastolic.type = IndicatorType.NUMBER;
  diastolic.unit = 'mmHg';
  diastolic.referenceMin = 60;
  diastolic.referenceMax = 80;
  diastolic.warningLevels = [
    { level: 'normal', min: 60, max: 80, label: '正常' },
    { level: 'warning', min: 80, max: 90, label: '正常高值' },
    { level: 'danger', min: 90, label: '高血压' }
  ];
  
  bloodPressure.indicators = [systolic, diastolic];
  
  template.indicatorGroups = [bloodPressure];
  
  return template;
}

// 导出所有内置模板
export class BuiltInTemplates {
  private static templates: DiseaseTemplate[] = [];
  
  private static init(): void {
    if (BuiltInTemplates.templates.length === 0) {
      BuiltInTemplates.templates = [
        createHypertensionTemplate(),
        createDiabetesTemplate(),
        createThyroidTemplate()
      ];
    }
  }
  
  static getAllTemplates(): DiseaseTemplate[] {
    BuiltInTemplates.init();
    return BuiltInTemplates.templates;
  }
  
  static getTemplateById(id: string): DiseaseTemplate | null {
    BuiltInTemplates.init();
    return BuiltInTemplates.templates.find((t: DiseaseTemplate) => t.id === id) ||null;
  }
  
  // 添加自定义模板（未来扩展）
  static addCustomTemplate(template: DiseaseTemplate): void {
    BuiltInTemplates.init();
    const index = BuiltInTemplates.templates.findIndex((t: DiseaseTemplate) => t.id === template.id);
    if (index >= 0) {
      BuiltInTemplates.templates[index] = template;
    } else {
      BuiltInTemplates.templates.push(template);
    }
  }
}

