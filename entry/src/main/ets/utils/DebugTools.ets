/**
 * 调试工具类
 * 提供数据库重置、数据清空等调试功能
 */

import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { ErrorUtils } from './ErrorUtil';

const TAG = 'DebugTools';
const DOMAIN = 0x0000;

export class DebugTools {
  private static instance: DebugTools;

  private constructor() {}

  static getInstance(): DebugTools {
    if (!DebugTools.instance) {
      DebugTools.instance = new DebugTools();
    }
    return DebugTools.instance;
  }

  /**
   * 重置RDB数据库
   * 删除所有表中的数据但保留表结构
   */
  async resetRdbDatabase(context: Context): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Starting RDB database reset');
      
      const STORE_CONFIG: relationalStore.StoreConfig = {
        name: 'medical_assistant.db',
        securityLevel: relationalStore.SecurityLevel.S1,
        encrypt: true,
        isReadOnly: false
      };

      return new Promise((resolve, reject) => {
        relationalStore.getRdbStore(context, STORE_CONFIG, async (err, store) => {
          if (err) {
            hilog.error(DOMAIN, TAG, 'Failed to get RDB store:%{public}s', JSON.stringify(err));
            reject(err);
            return;
          }

          try {
            // 清空所有表
            await store.executeSql('DELETE FROM health_records');
            hilog.info(DOMAIN, TAG, 'Cleared health_records table');
            
            await store.executeSql('DELETE FROM active_disease_templates');
            hilog.info(DOMAIN, TAG, 'Cleared active_disease_templates table');
            
            await store.executeSql('DELETE FROM medicine_data');
            hilog.info(DOMAIN, TAG, 'Cleared medicine_data table');
            
            await store.executeSql('DELETE FROM medicine_records');
            hilog.info(DOMAIN, TAG, 'Cleared medicine_records table');

            hilog.info(DOMAIN, TAG, 'RDB database reset completed successfully');
            resolve();
          } catch (e) {
            hilog.error(DOMAIN, TAG, 'Error clearing tables:%{public}s', JSON.stringify(e));
            reject(e);
          }
        });
      });
    } catch (err) {
      const e = ErrorUtils.toError(err)
      hilog.error(DOMAIN, TAG, 'RDB reset failed:%{public}s', JSON.stringify(e));
      throw e;
    }
  }

  /**
   * 删除RDB数据库文件（完全重置）
   */
  async deleteRdbDatabase(context: Context): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Starting RDB database deletion');
      
      const STORE_CONFIG: relationalStore.StoreConfig = {
        name: 'medical_assistant.db',
        securityLevel: relationalStore.SecurityLevel.S1,
        encrypt: true,
        isReadOnly: false
      };

      // 删除数据库
      await relationalStore.deleteRdbStore(context, 'medical_assistant.db');
      hilog.info(DOMAIN, TAG, 'RDB database deleted successfully');
    } catch (err) {
      const e =ErrorUtils.toError(err)
      hilog.error(DOMAIN, TAG, 'RDB deletion failed:%{public}s', JSON.stringify(e));
      throw e;
    }
  }

  /**
   * 重置Preferences数据
   */
  async resetPreferences(context: Context): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Starting Preferences reset');
      
      const prefs = await preferences.getPreferences(context, 'medical_assistant_preferences');
      await prefs.clear();
      await prefs.flush();
      
      hilog.info(DOMAIN, TAG, 'Preferences reset completed successfully');
    } catch (err) {
      const e = ErrorUtils.toError(err)
      hilog.error(DOMAIN, TAG, 'Preferences reset failed:%{public}s', JSON.stringify(e));
      throw e;
    }
  }

  /**
   * 删除Preferences数据文件
   */
  async deletePreferences(context: Context): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Starting Preferences deletion');
      
      await preferences.deletePreferences(context, 'medical_assistant_preferences');
      
      hilog.info(DOMAIN, TAG, 'Preferences deleted successfully');
    } catch (err) {
      const e = ErrorUtils.toError(err)
      hilog.error(DOMAIN, TAG, 'Preferences deletion failed:%{public}s', JSON.stringify(e));
      throw e;
    }
  }

  /**
   * 完全重置所有数据
   */
  async resetAllData(context: Context): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Starting complete data reset');
      
      // 先重置RDB数据库
      await this.resetRdbDatabase(context);
      
      // 再重置Preferences
      await this.resetPreferences(context);
      
      hilog.info(DOMAIN, TAG, 'Complete data reset finished successfully');
    } catch (err) {
      const e =ErrorUtils.toError(err)
      hilog.error(DOMAIN, TAG, 'Complete data reset failed:%{public}s', JSON.stringify(e));
      throw e;
    }
  }

  /**
   * 获取数据库统计信息
   */
  async getDatabaseStats(context: Context): Promise<Record<string, number>> {
    try {
      const STORE_CONFIG: relationalStore.StoreConfig = {
        name: 'medical_assistant.db',
        securityLevel: relationalStore.SecurityLevel.S1,
        encrypt: true,
        isReadOnly: false
      };

      const stats: Record<string, number> = {};

      return new Promise((resolve, reject) => {
        relationalStore.getRdbStore(context, STORE_CONFIG, async (err, store) => {
          if (err) {
            reject(err);
            return;
          }

          try {
            // 获取各表的记录数
            const tables = [
              'health_records',
              'active_disease_templates',
              'medicine_data',
              'medicine_records'
            ];

            for (const table of tables) {
              const sql = `SELECT COUNT(*) as count FROM ${table}`;
              const resultSet = await store.querySql(sql);
              if (resultSet.goToFirstRow()) {
                const count = resultSet.getLong(resultSet.getColumnIndex('count'));
                stats[table] = Number(count);
              }
              resultSet.close();
            }

            hilog.info(DOMAIN, TAG, 'Database stats retrieved: %{public}s', JSON.stringify(stats));
            resolve(stats);
          } catch (e) {
            hilog.error(DOMAIN, TAG, 'Error getting stats:%{public}s', JSON.stringify(e));
            reject(e);
          }
        });
      });
    } catch (err) {
      const e = ErrorUtils.toError(err)
      hilog.error(DOMAIN, TAG, 'Get database stats failed:%{public}s', JSON.stringify(e));
      throw e;
    }
  }

  /**
   * 导出数据库数据为JSON（用于备份）
   */
  async exportDatabaseData(context: Context): Promise<string> {
    try {
      hilog.info(DOMAIN, TAG, 'Starting database export');
      
      const STORE_CONFIG: relationalStore.StoreConfig = {
        name: 'medical_assistant.db',
        securityLevel: relationalStore.SecurityLevel.S1,
        encrypt: true,
        isReadOnly: false
      };

      return new Promise((resolve, reject) => {
        relationalStore.getRdbStore(context, STORE_CONFIG, async (err, store) => {
          if (err) {
            reject(err);
            return;
          }

          try {
            const exportData: Record<string, Array<Record<string, Object|null>>> = {};

            // 导出所有表
            const tables = [
              'health_records',
              'active_disease_templates',
              'medicine_data',
              'medicine_records'
            ];

            for (const table of tables) {
              const sql = `SELECT * FROM ${table}`;
              const resultSet = await store.querySql(sql);
              const rows: Array<Record<string, Object|null>> = [];

              while (resultSet.goToNextRow()) {
                const row: Record<string, Object|null> = {};
                const columnCount = resultSet.columnCount;
                
                for (let i = 0; i < columnCount; i++) {
                  const columnName = resultSet.getColumnName(i);
                  try {
                    row[columnName] = resultSet.getString(i);
                  } catch {
                    row[columnName] = null;
                  }
                }
                rows.push(row);
              }
              
              exportData[table] = rows;
              resultSet.close();
            }

            const jsonStr = JSON.stringify(exportData, null, 2);
            hilog.info(DOMAIN, TAG, 'Database export completed successfully');
            resolve(jsonStr);
          } catch (e) {
            hilog.error(DOMAIN, TAG, 'Error exporting data:%{public}s', JSON.stringify(e));
            reject(e);
          }
        });
      });
    } catch (err) {
      const e = ErrorUtils.toError(err)
      hilog.error(DOMAIN, TAG, 'Database export failed:%{public}s', JSON.stringify(e));
      throw e;
    }
  }
}
