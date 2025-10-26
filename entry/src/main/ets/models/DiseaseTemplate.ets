/**
 * 疾病模板系统
 * 支持灵活配置各种慢性病助手模板
 */

// 选项接口
export interface IndicatorOption {
  label: string;
  value: string;
}

// 警戒级别接口
export interface WarningLevel {
  level: 'normal' | 'warning' | 'danger';
  min?: number;
  max?: number;
  label: string;
}

// 激活的疾病模板接口（从数据库返回）
export interface IDiseaseTemplate {
  templateId: string;
  templateName: string;
  activatedAt: number;
  isDeleted?: boolean;
  deletedAt?: number | null;
}

// 健康记录JSON接口
export interface HealthRecordJSON {
  id: string;
  templateId: string;
  groupId: string;
  date: number;
  indicators: Record<string, number | string>;
  note: string;
  hospital?: string;
  doctor?: string;
  checkTime?: number;
}

// 指标类型
export enum IndicatorType {
  NUMBER = 'number', // 数值型
  SELECT = 'select', // 选择型
  TEXT = 'text' // 文本型
}


// 指标定义
export class IndicatorDefinition {
  id: string = ''; // 指标唯一ID
  name: string = ''; // 指标显示名称
  fullName: string = ''; // 指标完整名称
  type: IndicatorType = IndicatorType.NUMBER; // 指标类型
  unit: string = ''; // 单位
  required: boolean = true; // 是否必填

  // 参考值范围（用于数值型）
  referenceMin?: number;
  referenceMax?: number;
  // 选项列表（用于选择型）
  options?: IndicatorOption[];
  // 警戒值配置
  warningLevels?: WarningLevel[];

  constructor(id: string, name: string, fullName: string) {
    this.id = id;
    this.name = name;
    this.fullName = fullName;
  }
}

// 指标组（用于组织多个相关指标）
export class IndicatorGroup {
  id: string = ''; // 组ID
  name: string = ''; // 组名称
  description: string = ''; // 组描述
  indicators: IndicatorDefinition[] = []; // 指标列表

  constructor(id: string, name: string, description: string = '') {
    this.id = id;
    this.name = name;
    this.description = description;
  }
}

// 疾病模板
export class DiseaseTemplate {
  id: string = ''; // 模板唯一ID
  name: string = ''; // 模板名称
  icon: string = ''; // 图标资源
  color: string = ''; // 主题颜色
  description: string = ''; // 描述信息
  indicatorGroups: IndicatorGroup[] = []; // 指标组列表

  constructor(id: string, name: string, color: string) {
    this.id = id;
    this.name = name;
    this.color = color;
  }

  // 获取所有指标
  getAllIndicators(): IndicatorDefinition[] {
    const indicators: IndicatorDefinition[] = [];
    this.indicatorGroups.forEach(group => {
      indicators.push(...group.indicators);
    });
    return indicators;
  }

  // 根据ID获取指标
  getIndicatorById(id: string): IndicatorDefinition | undefined {
    return this.getAllIndicators().find(ind => ind.id === id);
  }
}

// 健康记录（通用数据模型）
export class HealthRecord {
  id: string = ''; // 记录ID
  templateId: string = ''; // 所属模板ID
  groupId: string = ''; // 所属指标组ID
  date: number = 0; // 记录时间
  indicators: Record<string, number | string> = {}; // 指标数据（键值对对象）
  note: string = ''; // 备注
  hospital: string = ''; // 医院名称
  doctor: string = ''; // 医生姓名
  checkTime: number = 0; // 检查时间（可以与记录时间不同）

  constructor(templateId: string, groupId: string = '') {
    this.id = Date.now().toString() + Math.random().toString(36).substr(2, 9);
    this.templateId = templateId;
    this.groupId = groupId;
    this.date = Date.now();
    this.checkTime = Date.now();
  }
  
  // 设置指标值
  setIndicator(key: string, value: number | string): void {
    this.indicators[key] = value;
  }
  
  // 获取指标值
  getIndicator(key: string): number | string | undefined {
    return this.indicators[key];
  }
  
  // 转换为可序列化的对象（用于存储）
  toJSON(): HealthRecordJSON {
    const indicatorsObj: Record<string, number | string> = {};
    Object.keys(this.indicators).forEach((key: string) => {
      indicatorsObj[key] = this.indicators[key];
    });
    
    const json: HealthRecordJSON = {
      id: this.id,
      templateId: this.templateId,
      groupId: this.groupId,
      date: this.date,
      indicators: indicatorsObj,
      note: this.note,
      hospital: this.hospital,
      doctor: this.doctor,
      checkTime: this.checkTime
    };
    
    return json;
  }
  
  // 从 JSON 恢复
  static fromJSON(json: HealthRecordJSON): HealthRecord {
    const record = new HealthRecord(json.templateId, json.groupId);
    record.id = json.id;
    record.date = json.date;
    record.note = json.note;
    record.hospital = json.hospital || '';
    record.doctor = json.doctor || '';
    record.checkTime = json.checkTime || json.date;
    
    const indicators = json.indicators;
    Object.keys(indicators).forEach((key: string) => {
      record.setIndicator(key, indicators[key]);
    });
    
    return record;
  }
}

