/**
 * 通用健康数据管理器
 * 替代原有的 DataManager，支持灵活的模板系统
 */

import { preferences } from '@kit.ArkData';
import { HealthRecord, HealthRecordJSON } from '../models/DiseaseTemplate';
import { MedicineData, MedicineRecord } from '../models/MedicineData';

const PREFERENCES_NAME = 'medical_assistant_data_v2';

export class HealthDataManager {
  private static instance: HealthDataManager;
  private dataPreferences: preferences.Preferences | null = null;
  
  private constructor() {}
  
  static getInstance(): HealthDataManager {
    if (!HealthDataManager.instance) {
      HealthDataManager.instance = new HealthDataManager();
    }
    return HealthDataManager.instance;
  }
  
  async init(context: Context): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(context, PREFERENCES_NAME);
    } catch (err) {
      console.error('Failed to init preferences:', JSON.stringify(err));
    }
  }
  
  // ========== 健康记录管理 ==========
  
  /**
   * 获取指定模板的所有记录
   */
  async getHealthRecords(templateId: string, groupId?: string): Promise<HealthRecord[]> {
    try {
      const key = `health_records_${templateId}`;
      const dataStr = await this.dataPreferences?.get(key, '[]') as string;
      const jsonArray = JSON.parse(dataStr) as HealthRecordJSON[];
      const records: HealthRecord[] = jsonArray.map((json: HealthRecordJSON) => 
        HealthRecord.fromJSON(json)
      );
      
      if (groupId) {
        return records.filter((r: HealthRecord) => r.groupId === groupId);
      }
      
      return records;
    } catch (err) {
      console.error('Failed to get health records:', JSON.stringify(err));
      return [];
    }
  }
  
  /**
   * 保存健康记录
   */
  async saveHealthRecord(record: HealthRecord): Promise<void> {
    try {
      const records = await this.getHealthRecords(record.templateId);
      records.unshift(record);
      
      const jsonArray = records.map((r: HealthRecord) => r.toJSON());
      
      const key = `health_records_${record.templateId}`;
      await this.dataPreferences?.put(key, JSON.stringify(jsonArray));
      await this.dataPreferences?.flush();
    } catch (err) {
      console.error('Failed to save health record:', JSON.stringify(err));
    }
  }
  
  /**
   * 删除健康记录
   */
  async deleteHealthRecord(templateId: string, recordId: string): Promise<void> {
    try {
      const records = await this.getHealthRecords(templateId);
      const filtered = records.filter((r: HealthRecord) => r.id !== recordId);
      
      const jsonArray = filtered.map((r: HealthRecord) => r.toJSON());
      
      const key = `health_records_${templateId}`;
      await this.dataPreferences?.put(key, JSON.stringify(jsonArray));
      await this.dataPreferences?.flush();
    } catch (err) {
      console.error('Failed to delete health record:', JSON.stringify(err));
    }
  }
  
  /**
   * 获取记录统计数量
   */
  async getRecordCount(templateId: string): Promise<number> {
    const records = await this.getHealthRecords(templateId);
    return records.length;
  }
  
  // ========== 药品管理（保持不变）==========
  
  async getMedicineList(): Promise<MedicineData[]> {
    try {
      const dataStr = await this.dataPreferences?.get('medicine_list', '[]') as string;
      return JSON.parse(dataStr);
    } catch (err) {
      return [];
    }
  }
  
  async saveMedicine(data: MedicineData): Promise<void> {
    const list = await this.getMedicineList();
    const index = list.findIndex(item => item.id === data.id);
    if (index >= 0) {
      list[index] = data;
    } else {
      list.push(data);
    }
    await this.dataPreferences?.put('medicine_list', JSON.stringify(list));
    await this.dataPreferences?.flush();
  }
  
  async deleteMedicine(id: string): Promise<void> {
    const list = await this.getMedicineList();
    const filtered = list.filter(item => item.id !== id);
    await this.dataPreferences?.put('medicine_list', JSON.stringify(filtered));
    await this.dataPreferences?.flush();
  }
  
  async getMedicineRecords(date?: number): Promise<MedicineRecord[]> {
    try {
      const dataStr = await this.dataPreferences?.get('medicine_records', '[]') as string;
      const records: MedicineRecord[] = JSON.parse(dataStr);
      
      if (date) {
        const startOfDay = new Date(date).setHours(0, 0, 0, 0);
        const endOfDay = new Date(date).setHours(23, 59, 59, 999);
        return records.filter(r => r.date >= startOfDay && r.date <= endOfDay);
      }
      
      return records;
    } catch (err) {
      return [];
    }
  }
  
  async saveMedicineRecord(record: MedicineRecord): Promise<void> {
    const list = await this.getMedicineRecords();
    const index = list.findIndex(item => item.id === record.id);
    if (index >= 0) {
      list[index] = record;
    } else {
      list.push(record);
    }
    await this.dataPreferences?.put('medicine_records', JSON.stringify(list));
    await this.dataPreferences?.flush();
  }
  
  async generateTodayMedicineRecords(): Promise<void> {
    const medicines = await this.getMedicineList();
    const today = Date.now();
    const todayRecords = await this.getMedicineRecords(today);
    
    for (const medicine of medicines) {
      if (today < medicine.startDate || today > medicine.endDate) {
        continue;
      }
      
      for (const time of medicine.frequency) {
        const existingRecord = todayRecords.find(
          (r: MedicineRecord) => r.medicineId === medicine.id && r.time === time
        );
        
        if (!existingRecord) {
          const record = new MedicineRecord(
            medicine.id, 
            medicine.name, 
            time as 'morning' | 'noon' | 'evening' | 'bedtime'
          );
          await this.saveMedicineRecord(record);
        }
      }
    }
  }
}

