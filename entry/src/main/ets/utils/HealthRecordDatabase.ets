

import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { HealthRecord,IDiseaseTemplate } from '../models/DiseaseTemplate';
import { MedicineData, MedicineRecord } from '../models/MedicineData';
import { ErrorUtils } from './ErrorUtil'

const DB_NAME = 'medical_assistant.db';
const DB_VERSION = 1;

/**
 * 数据库表定义
 */
export class DatabaseSchema {
  // 健康记录表
  static readonly HEALTH_RECORDS_TABLE = 'health_records';
  static readonly HEALTH_RECORDS_SQL = `
    CREATE TABLE IF NOT EXISTS ${this.HEALTH_RECORDS_TABLE} (
      id TEXT PRIMARY KEY,
      template_id TEXT NOT NULL,
      group_id TEXT NOT NULL,
      date INTEGER NOT NULL,
      check_time INTEGER NOT NULL,
      indicators TEXT NOT NULL,
      note TEXT,
      hospital TEXT,
      doctor TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  `;

  // 健康记录索引
  static readonly HEALTH_RECORDS_INDEX_SQL = `
    CREATE INDEX IF NOT EXISTS idx_health_template_date 
    ON ${this.HEALTH_RECORDS_TABLE}(template_id, date DESC)
  `;

  // 活跃疾病模板表（用于管理用户激活的疾病类型，支持软删除）
  static readonly ACTIVE_DISEASE_TEMPLATES_TABLE = 'active_disease_templates';
  static readonly ACTIVE_DISEASE_TEMPLATES_SQL = `
    CREATE TABLE IF NOT EXISTS ${this.ACTIVE_DISEASE_TEMPLATES_TABLE} (
      template_id TEXT PRIMARY KEY,
      template_name TEXT NOT NULL,
      activated_at INTEGER NOT NULL,
      is_deleted INTEGER DEFAULT 0,
      deleted_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  `;

  // 药品信息表
  static readonly MEDICINE_DATA_TABLE = 'medicine_data';
  static readonly MEDICINE_DATA_SQL = `
    CREATE TABLE IF NOT EXISTS ${this.MEDICINE_DATA_TABLE} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      specification TEXT,
      dosage TEXT,
      frequency TEXT NOT NULL,
      reminder_times TEXT NOT NULL,
      start_date INTEGER NOT NULL,
      end_date INTEGER NOT NULL,
      stock INTEGER,
      note TEXT,
      reminder_enabled INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  `;

  // 用药记录表
  static readonly MEDICINE_RECORDS_TABLE = 'medicine_records';
  static readonly MEDICINE_RECORDS_SQL = `
    CREATE TABLE IF NOT EXISTS ${this.MEDICINE_RECORDS_TABLE} (
      id TEXT PRIMARY KEY,
      medicine_id TEXT NOT NULL,
      medicine_name TEXT NOT NULL,
      date INTEGER NOT NULL,
      time TEXT NOT NULL,
      taken INTEGER DEFAULT 0,
      taken_time INTEGER,
      note TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  `;

  // 用药记录索引
  static readonly MEDICINE_RECORDS_INDEX_SQL = `
    CREATE INDEX IF NOT EXISTS idx_medicine_date 
    ON ${this.MEDICINE_RECORDS_TABLE}(medicine_id, date)
  `;
}

export class HealthRecordDatabase {
  private static instance: HealthRecordDatabase;
  private rdbStore: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;
  private initPromise: Promise<void> | null = null;

  private constructor() {}

  static getInstance(): HealthRecordDatabase {
    if (!HealthRecordDatabase.instance) {
      HealthRecordDatabase.instance = new HealthRecordDatabase();
    }
    return HealthRecordDatabase.instance;
  }

  /**
   * 初始化RDB存储
   * @param context 应用上下文
   */
  async init(context: Context): Promise<void> {
    if (this.isInitialized) return;
    if (this.initPromise) return this.initPromise;

    this.initPromise = this._performInit(context);
    await this.initPromise;
  }

  private async _performInit(context: Context): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        // 完整的数据库配置对象
        const STORE_CONFIG: relationalStore.StoreConfig = {
          // 数据库文件名
          name: DB_NAME,
          // 数据库安全级别
          securityLevel: relationalStore.SecurityLevel.S1,
          // 数据库是否加密
          encrypt: true,
          // 可选参数，数据库自定义路径。默认在本应用沙箱目录下创建
          // customDir: 'health_data',
          // 可选参数，指定数据库是否以只读方式打开
          isReadOnly: false
        };

        // 使用回调方式获取RdbStore实例
        relationalStore.getRdbStore(context, STORE_CONFIG, async (err, store) => {
          if (err) {
            console.error('[HealthRecordDatabase] 获取RdbStore失败:', `Code:${err.code}, message:${err.message}`);
            this.isInitialized = false;
            reject(err);
            return;
          }

          console.info('[HealthRecordDatabase] 成功获取RdbStore');
          this._handleStoreReady(store).then(() => {
            this.rdbStore = store;
            this.isInitialized = true;
            console.info('[HealthRecordDatabase] 数据库初始化成功');
            resolve();
          }).catch((err:BusinessError) => {
            console.error('[HealthRecordDatabase] 初始化失败:', JSON.stringify(err));
            this.isInitialized = false;
            reject(err);
          });
        });
      } catch (e) {
        const err = e as BusinessError;
        console.error('[HealthRecordDatabase] 初始化异常:', JSON.stringify(err));
        this.isInitialized = false;
        reject(err);
      }
    });
  }

  /**
   * 处理数据库就绪，包括版本检查和表创建
   */
  private async _handleStoreReady(store: relationalStore.RdbStore): Promise<void> {
    try {
      // 获取当前数据库版本
      let storeVersion = store.version;
      console.info('[HealthRecordDatabase] 当前数据库版本:', storeVersion);

      // 版本为0表示首次创建数据库
      if (storeVersion === 0) {
        await this._createTables(store);
        store.version = DB_VERSION;
        console.info('[HealthRecordDatabase] 首次创建数据库，版本设置为:', DB_VERSION);
      } else if (storeVersion < DB_VERSION) {
        // 处理升级逻辑
        await this._upgradeDatabase(store, storeVersion, DB_VERSION);
        store.version = DB_VERSION;
      }
    } catch (err) {
      // console.error('[HealthRecordDatabase] 处理数据库失败:', JSON.stringify(err));
      // throw err;
      const error = err instanceof Error ? err : new Error(`初始化失败: ${String(err)}`);
      console.error('[HealthRecordDatabase] 处理数据库失败:', JSON.stringify(error));
      throw error; // 确保抛出标准错误
    }
  }

  /**
   * 创建所有表结构
   */
  private async _createTables(store: relationalStore.RdbStore): Promise<void> {
    try {
      // 创建健康记录表
      await store.executeSql(DatabaseSchema.HEALTH_RECORDS_SQL);
      console.info('[HealthRecordDatabase] 健康记录表创建成功');

      // 创建索引
      await store.executeSql(DatabaseSchema.HEALTH_RECORDS_INDEX_SQL);
      console.info('[HealthRecordDatabase] 健康记录索引创建成功');

      // 创建活跃疾病模板表
      await store.executeSql(DatabaseSchema.ACTIVE_DISEASE_TEMPLATES_SQL);
      console.info('[HealthRecordDatabase] 活跃疾病模板表创建成功');

      // 创建药品信息表
      await store.executeSql(DatabaseSchema.MEDICINE_DATA_SQL);
      console.info('[HealthRecordDatabase] 药品信息表创建成功');

      // 创建用药记录表
      await store.executeSql(DatabaseSchema.MEDICINE_RECORDS_SQL);
      console.info('[HealthRecordDatabase] 用药记录表创建成功');

      // 创建用药记录索引
      await store.executeSql(DatabaseSchema.MEDICINE_RECORDS_INDEX_SQL);
      console.info('[HealthRecordDatabase] 用药记录索引创建成功');
    } catch (err) {
      const error = ErrorUtils.toError(err);
      console.error('[HealthRecordDatabase] 创建表失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 处理数据库升级
   */
  private async _upgradeDatabase(store: relationalStore.RdbStore, currentVersion: number, targetVersion: number): Promise<void> {
    try {
      console.info('[HealthRecordDatabase] 开始数据库升级: ' + currentVersion + ' -> ' + targetVersion);

      // 根据版本号执行相应的升级逻辑
      for (let version = currentVersion; version < targetVersion; version++) {
        await this._upgradeToVersion(store, version + 1);
      }

      console.info('[HealthRecordDatabase] 数据库升级完成');
    } catch (err) {
      const error = ErrorUtils.toError(err);
      console.error('[HealthRecordDatabase] 数据库升级失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 升级到指定版本
   */
  private async _upgradeToVersion(store: relationalStore.RdbStore, targetVersion: number): Promise<void> {
    try {
      switch (targetVersion) {
        case 1:
          // 版本1: 创建基础表结构
          await this._createTables(store);
          console.info('[HealthRecordDatabase] 升级到版本1成功');
          break;
        // 后续版本升级可在此添加
        default:
          console.warn('[HealthRecordDatabase] 未知的数据库版本:', targetVersion);
      }
    } catch (err) {
      const error = ErrorUtils.toError(err);
      console.error('[HealthRecordDatabase] 升级到版本' + targetVersion + '失败:', JSON.stringify(error));
      throw error;
    }
  }

  private checkInitialized(): void {
    if (!this.isInitialized || !this.rdbStore) {
      throw new Error('[HealthRecordDatabase] 数据库未初始化，请先调用init()方法');
    }
  }

  // ========== 健康记录操作 ==========

  /**
   * 保存健康记录
   */
  async saveHealthRecord(record: HealthRecord): Promise<void> {
    try {
      this.checkInitialized();
      
      const values: relationalStore.ValuesBucket = {
        id: record.id,
        template_id: record.templateId,
        group_id: record.groupId,
        date: record.date,
        check_time: record.checkTime,
        indicators: JSON.stringify(record.indicators),
        note: record.note,
        hospital: record.hospital,
        doctor: record.doctor,
        created_at: Date.now(),
        updated_at: Date.now()
      };

      await this.rdbStore!.insert(DatabaseSchema.HEALTH_RECORDS_TABLE, values);
      console.info('[HealthRecordDatabase] 健康记录已保存:', record.id);
    } catch (err) {
      const error = ErrorUtils.toError(err);
      console.error('[HealthRecordDatabase] 保存健康记录失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 获取健康记录（按模板和日期范围）
   */
  async getHealthRecords(
    templateId: string,
    groupId?: string,
    startDate?: number,
    endDate?: number
  ): Promise<HealthRecord[]> {
    try {
      this.checkInitialized();

      let sql = `SELECT * FROM ${DatabaseSchema.HEALTH_RECORDS_TABLE} WHERE template_id = ?`;
      const params: string[] = [templateId];

      if (groupId) {
        sql += ` AND group_id = ?`;
        params.push(groupId);
      }

      if (startDate && endDate) {
        sql += ` AND date BETWEEN ? AND ?`;
        params.push(startDate.toString(), endDate.toString());
      }

      sql += ` ORDER BY date DESC`;

      const resultSet = await this.rdbStore!.querySql(sql, params);
      const records: HealthRecord[] = [];

      while (resultSet.goToNextRow()) {
        const record = this._mapRowToHealthRecord(resultSet);
        if (record) records.push(record);
      }

      resultSet.close();
      return records;
    } catch (err) {
      console.error('[HealthRecordDatabase] 获取健康记录失败:', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 删除健康记录
   */
  async deleteHealthRecord(recordId: string): Promise<void> {
    try {
      this.checkInitialized();

      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.HEALTH_RECORDS_TABLE);
      predicates.equalTo('id', recordId);

      await this.rdbStore!.delete(predicates);
      console.info('[HealthRecordDatabase] 健康记录已删除:', recordId);
    } catch (err) {
      const error = ErrorUtils.toError(err);
      console.error('[HealthRecordDatabase] 删除健康记录失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 获取最新的健康记录
   */
  async getLatestHealthRecord(
    templateId: string,
    groupId?: string
  ): Promise<HealthRecord | null> {
    try {
      const records = await this.getHealthRecords(templateId, groupId);
      return records.length > 0 ? records[0] : null;
    } catch (err) {
      console.error('[HealthRecordDatabase] 获取最新健康记录失败:', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 获取记录数量
   */
  async getRecordCount(templateId: string): Promise<number> {
    try {
      this.checkInitialized();

      const sql = `SELECT COUNT(*) as count FROM ${DatabaseSchema.HEALTH_RECORDS_TABLE} WHERE template_id = ?`;
      const resultSet = await this.rdbStore!.querySql(sql, [templateId]);
      
      if (resultSet.goToFirstRow()) {
        const count = resultSet.getLong(resultSet.getColumnIndex('count'));
        resultSet.close();
        return Number(count);
      }
      
      resultSet.close();
      return 0;
    } catch (err) {
      console.error('[HealthRecordDatabase] 获取记录数量失败:', JSON.stringify(err));
      return 0;
    }
  }

  // ========== 活跃疾病模板操作 ==========

  /**
   * 激活疾病模板
   */
  async activateDiseaseTemplate(templateId: string, templateName: string): Promise<void> {
    try {
      this.checkInitialized();

      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.ACTIVE_DISEASE_TEMPLATES_TABLE);
      predicates.equalTo('template_id', templateId);
      const resultSet = await this.rdbStore!.query(predicates);

      if (resultSet.rowCount > 0) {
        // 更新
        const values: relationalStore.ValuesBucket = {
          template_name: templateName,
          activated_at: Date.now(),
          updated_at: Date.now()
        };
        await this.rdbStore!.update(values, predicates);
        console.info('[HealthRecordDatabase] 疾病模板已激活:', templateId);
      } else {
        // 插入
        const values: relationalStore.ValuesBucket = {
          template_id: templateId,
          template_name: templateName,
          activated_at: Date.now(),
          created_at: Date.now(),
          updated_at: Date.now()
        };
        await this.rdbStore!.insert(DatabaseSchema.ACTIVE_DISEASE_TEMPLATES_TABLE, values);
        console.info('[HealthRecordDatabase] 疾病模板已激活:', templateId);
      }
      resultSet.close();
    } catch (err) {
      const error = ErrorUtils.toError(err);
      console.error('[HealthRecordDatabase] 激活疾病模板失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 获取所有激活的疾病模板
   */
  async getActiveDiseaseTemplates(): Promise<IDiseaseTemplate[]> {
    try {
      this.checkInitialized();

      const sql = `SELECT * FROM ${DatabaseSchema.ACTIVE_DISEASE_TEMPLATES_TABLE} WHERE is_deleted = 0 ORDER BY activated_at DESC`;
      const resultSet = await this.rdbStore!.querySql(sql);
      const templates: IDiseaseTemplate[] = [];

      while (resultSet.goToNextRow()) {
        const template = this._mapRowToActiveDiseaseTemplate(resultSet);
        if (template) templates.push(template);
      }

      resultSet.close();
      return templates;
    } catch (err) {
      console.error('[HealthRecordDatabase] 获取激活疾病模板失败:', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 删除激活的疾病模板（软删除）
   */
  async deleteActiveDiseaseTemplate(templateId: string): Promise<void> {
    try {
      this.checkInitialized();

      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.ACTIVE_DISEASE_TEMPLATES_TABLE);
      predicates.equalTo('template_id', templateId);

      const values: relationalStore.ValuesBucket = {
        is_deleted: 1,
        deleted_at: Date.now()
      };
      await this.rdbStore!.update(values, predicates);
      console.info('[HealthRecordDatabase] 激活疾病模板已删除:', templateId);
    } catch (err) {
      const error = ErrorUtils.toError(err);
      console.error('[HealthRecordDatabase] 删除激活疾病模板失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 恢复已删除的疾病模板
   */
  async restoreActiveDiseaseTemplate(templateId: string): Promise<void> {
    try {
      this.checkInitialized();

      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.ACTIVE_DISEASE_TEMPLATES_TABLE);
      predicates.equalTo('template_id', templateId);
      predicates.equalTo('is_deleted', 1);

      const values: relationalStore.ValuesBucket = {
        is_deleted: 0,
        deleted_at: null
      };
      await this.rdbStore!.update(values, predicates);
      console.info('[HealthRecordDatabase] 激活疾病模板已恢复:', templateId);
    } catch (err) {
      const error = ErrorUtils.toError(err);
      console.error('[HealthRecordDatabase] 恢复激活疾病模板失败:', JSON.stringify(error));
      throw error;
    }
  }

  // ========== 药品管理操作 ==========

  /**
   * 保存药品信息
   */
  async saveMedicine(data: MedicineData): Promise<void> {
    try {
      this.checkInitialized();

      const values: relationalStore.ValuesBucket = {
        id: data.id,
        name: data.name,
        specification: data.specification,
        dosage: data.dosage,
        frequency: JSON.stringify(data.frequency),
        reminder_times: JSON.stringify(data.reminderTimes),
        start_date: data.startDate,
        end_date: data.endDate,
        stock: data.stock,
        note: data.note,
        reminder_enabled: data.reminderEnabled ? 1 : 0,
        created_at: Date.now(),
        updated_at: Date.now()
      };

      // 检查是否已存在（更新或插入）
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.MEDICINE_DATA_TABLE);
      predicates.equalTo('id', data.id);
      const resultSet = await this.rdbStore!.query(predicates);
      
      if (resultSet.rowCount>0) {
        // 更新
        values.updated_at = Date.now();
        await this.rdbStore!.update(values, predicates);
        console.info('[HealthRecordDatabase] 药品信息已更新:', data.id);
      } else {
        // 插入
        await this.rdbStore!.insert(DatabaseSchema.MEDICINE_DATA_TABLE, values);
        console.info('[HealthRecordDatabase] 药品信息已保存:', data.id);
      }
      resultSet.close();
    } catch (err) {
      const error = ErrorUtils.toError(err);
      console.error('[HealthRecordDatabase] 保存药品信息失败:', JSON.stringify(error));
      throw error;
    }
  }

  /**
   * 获取所有药品
   */
  async getMedicineList(): Promise<MedicineData[]> {
    try {
      this.checkInitialized();

      const sql = `SELECT * FROM ${DatabaseSchema.MEDICINE_DATA_TABLE} ORDER BY created_at DESC`;
      const resultSet = await this.rdbStore!.querySql(sql);
      const medicines: MedicineData[] = [];

      while (resultSet.goToNextRow()) {
        const medicine = this._mapRowToMedicine(resultSet);
        if (medicine) medicines.push(medicine);
      }

      resultSet.close();
      return medicines;
    } catch (err) {
      console.error('[HealthRecordDatabase] 获取药品列表失败:', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 删除药品
   */
  async deleteMedicine(id: string): Promise<void> {
    try {
      this.checkInitialized();

      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.MEDICINE_DATA_TABLE);
      predicates.equalTo('id', id);

      await this.rdbStore!.delete(predicates);
      console.info('[HealthRecordDatabase] 药品已删除:', id);
    } catch (err) {
      const error = ErrorUtils.toError(err);
      console.error('[HealthRecordDatabase] 删除药品失败:', JSON.stringify(error));
      throw error;
    }
  }

  // ========== 用药记录操作 ==========

  /**
   * 保存用药记录
   */
  async saveMedicineRecord(record: MedicineRecord): Promise<void> {
    try {
      this.checkInitialized();

      const values: relationalStore.ValuesBucket = {
        id: record.id,
        medicine_id: record.medicineId,
        medicine_name: record.medicineName,
        date: record.date,
        time: record.time,
        taken: record.taken ? 1 : 0,
        taken_time: record.takenTime,
        note: record.note,
        created_at: Date.now(),
        updated_at: Date.now()
      };

      // 检查是否已存在（更新或插入）
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.MEDICINE_RECORDS_TABLE);
      predicates.equalTo('id', record.id);
      const resultSet = await this.rdbStore!.query(predicates);

      if (resultSet.rowCount > 0) {
        await this.rdbStore!.update(values, predicates);
      } else {
        await this.rdbStore!.insert(DatabaseSchema.MEDICINE_RECORDS_TABLE, values);
      }

      resultSet.close();
      console.info('[HealthRecordDatabase] 用药记录已保存:', record.id);
    } catch (err) {
      const e = ErrorUtils.toError(err)
      console.error('[HealthRecordDatabase] 保存用药记录失败:', JSON.stringify(e));
      throw e;
    }
  }

  /**
   * 获取用药记录（按日期范围）
   */
  async getMedicineRecords(startDate?: number, endDate?: number): Promise<MedicineRecord[]> {
    try {
      this.checkInitialized();

      let sql = `SELECT * FROM ${DatabaseSchema.MEDICINE_RECORDS_TABLE}`;
      const params: string[] = [];

      if (startDate && endDate) {
        sql += ` WHERE date BETWEEN ? AND ?`;
        params.push(startDate.toString(), endDate.toString());
      }

      sql += ` ORDER BY date DESC`;

      const resultSet = await this.rdbStore!.querySql(sql, params);
      const records: MedicineRecord[] = [];

      while (resultSet.goToNextRow()) {
        const record = this._mapRowToMedicineRecord(resultSet);
        if (record) records.push(record);
      }

      resultSet.close();
      return records;
    } catch (err) {
      console.error('[HealthRecordDatabase] 获取用药记录失败:', JSON.stringify(err));
      return [];
    }
  }

  // ========== 私有辅助方法 ==========

  private _mapRowToHealthRecord(resultSet: relationalStore.ResultSet): HealthRecord | null {
    try {
      const templateId = resultSet.getString(resultSet.getColumnIndex('template_id'));
      const groupId = resultSet.getString(resultSet.getColumnIndex('group_id'));
      const record = new HealthRecord(templateId, groupId);

      record.id = resultSet.getString(resultSet.getColumnIndex('id'));
      record.date = resultSet.getLong(resultSet.getColumnIndex('date'));
      record.checkTime = resultSet.getLong(resultSet.getColumnIndex('check_time'));
      record.note = resultSet.getString(resultSet.getColumnIndex('note'));
      record.hospital = resultSet.getString(resultSet.getColumnIndex('hospital'));
      record.doctor = resultSet.getString(resultSet.getColumnIndex('doctor'));

      const indicatorsStr = resultSet.getString(resultSet.getColumnIndex('indicators'));
      const indicators = JSON.parse(indicatorsStr) as Record<string,string|number>;
      record.indicators=indicators
      return record;
    } catch (err) {
      const e= err as BusinessError
      console.error('[HealthRecordDatabase] 映射健康记录失败:', JSON.stringify(e));
      return null;
    }
  }

  private _mapRowToActiveDiseaseTemplate(resultSet: relationalStore.ResultSet): IDiseaseTemplate | null {
    try {
      const templateId = resultSet.getString(resultSet.getColumnIndex('template_id'));
      const templateName = resultSet.getString(resultSet.getColumnIndex('template_name'));
      const activatedAt = resultSet.getLong(resultSet.getColumnIndex('activated_at'));
      const isDeleted = resultSet.getLong(resultSet.getColumnIndex('is_deleted')) === 1;
      const deletedAt = resultSet.getLong(resultSet.getColumnIndex('deleted_at'));

      return { templateId, templateName, activatedAt, isDeleted, deletedAt };
    } catch (err) {
      console.error('[HealthRecordDatabase] 映射活跃疾病模板失败:', JSON.stringify(err));
      return null;
    }
  }

  private _mapRowToMedicine(resultSet: relationalStore.ResultSet): MedicineData | null {
    try {
      const medicine = new MedicineData();
      medicine.id = resultSet.getString(resultSet.getColumnIndex('id'));
      medicine.name = resultSet.getString(resultSet.getColumnIndex('name'));
      medicine.specification = resultSet.getString(resultSet.getColumnIndex('specification'));
      medicine.dosage = resultSet.getString(resultSet.getColumnIndex('dosage'));
      medicine.frequency = JSON.parse(resultSet.getString(resultSet.getColumnIndex('frequency')));
      medicine.reminderTimes = JSON.parse(resultSet.getString(resultSet.getColumnIndex('reminder_times')));
      medicine.startDate = resultSet.getLong(resultSet.getColumnIndex('start_date'));
      medicine.endDate = resultSet.getLong(resultSet.getColumnIndex('end_date'));
      medicine.stock = resultSet.getLong(resultSet.getColumnIndex('stock'));
      medicine.note = resultSet.getString(resultSet.getColumnIndex('note'));
      medicine.reminderEnabled = resultSet.getLong(resultSet.getColumnIndex('reminder_enabled')) === 1;

      return medicine;
    } catch (err) {
      console.error('[HealthRecordDatabase] 映射药品数据失败:', JSON.stringify(err));
      return null;
    }
  }

  private _mapRowToMedicineRecord(resultSet: relationalStore.ResultSet): MedicineRecord | null {
    try {
      const medicineId = resultSet.getString(resultSet.getColumnIndex('medicine_id'));
      const medicineName = resultSet.getString(resultSet.getColumnIndex('medicine_name'));
      const time = resultSet.getString(resultSet.getColumnIndex('time')) as 'morning' | 'noon' | 'evening' | 'bedtime';
      const record = new MedicineRecord(medicineId, medicineName, time);

      record.id = resultSet.getString(resultSet.getColumnIndex('id'));
      record.date = resultSet.getLong(resultSet.getColumnIndex('date'));
      record.taken = resultSet.getLong(resultSet.getColumnIndex('taken')) === 1;
      record.takenTime = resultSet.getLong(resultSet.getColumnIndex('taken_time'));
      record.note = resultSet.getString(resultSet.getColumnIndex('note'));

      return record;
    } catch (err) {
      console.error('[HealthRecordDatabase] 映射用药记录失败:', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 为所有活跃药品生成今日的用药记录
   */
  async generateTodayMedicineRecords(): Promise<void> {
    try {
      this.checkInitialized();

      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const todayTimestamp = today.getTime();

      // 获取所有药品
      const medicines = await this.getMedicineList();

      // 为每个药品生成今日记录
      for (const medicine of medicines) {
        // 检查药品是否在有效期内
        if (medicine.startDate <= todayTimestamp && todayTimestamp < medicine.endDate) {
          // 为每个服用时间创建记录
          for (const timeSlot of medicine.frequency) {
            const recordId = medicine.id + '_' + todayTimestamp + '_' + timeSlot;
            
            // 检查是否已存在今日记录
            const predicates = new relationalStore.RdbPredicates(DatabaseSchema.MEDICINE_RECORDS_TABLE);
            predicates.equalTo('id', recordId);
            const resultSet = await this.rdbStore!.query(predicates);
            
            if (resultSet.rowCount=== 0) {
              // 创建新记录
              const record = new MedicineRecord(medicine.id, medicine.name, timeSlot as 'morning' | 'noon' | 'evening' | 'bedtime');
              record.id = recordId;
              record.date = todayTimestamp;
              
              await this.saveMedicineRecord(record);
            }
            resultSet.close();
          }
        }
      }

      console.info('[HealthRecordDatabase] 今日用药记录已生成');
    } catch (err) {
      console.error('[HealthRecordDatabase] 生成今日用药记录失败:', JSON.stringify(err));
      // 不抛出异常，避免影响主流程
    }
  }
}
