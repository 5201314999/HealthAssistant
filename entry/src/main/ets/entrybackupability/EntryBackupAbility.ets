import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';

const DOMAIN = 0x0000;
const TAG = 'EntryBackupAbility';

/**
 * 备份恢复扩展能力
 * 
 * 功能说明：
 * 1. 当用户通过系统设置执行备份时，会自动调用 onBackup()
 * 2. 当用户通过系统设置执行恢复时，会自动调用 onRestore()
 * 3. 默认会备份应用的数据目录（databases、preferences等）
 * 
 * 使用方式：
 * - 用户在系统"设置 > 系统和更新 > 备份和恢复"中操作
 * - 或通过华为云备份自动备份
 * 
 * 注意事项：
 * - 卸载应用后，备份数据仍保留在系统中
 * - 重新安装应用后，系统会提示是否恢复数据
 * - 只有在同一台设备或登录同一华为账号的设备上才能恢复
 */
export default class EntryBackupAbility extends BackupExtensionAbility {
  /**
   * 系统执行备份时回调
   * 默认会备份应用数据目录下的所有文件
   */
  async onBackup() {
    hilog.info(DOMAIN, TAG, '========== 开始备份应用数据 ==========');
    
    try {
      // 记录备份时间
      const backupTime = new Date().toLocaleString('zh-CN');
      hilog.info(DOMAIN, TAG, '备份时间: %{public}s', backupTime);
      
      // 默认会自动备份以下内容：
      // 1. databases/ 目录（RDB数据库）
      // 2. preferences/ 目录（用户配置）
      // 3. files/ 目录（应用文件）
      
      hilog.info(DOMAIN, TAG, '✅ 备份内容包括：');
      hilog.info(DOMAIN, TAG, '  - 健康记录数据库（health_records.db）');
      hilog.info(DOMAIN, TAG, '  - 用户配置文件（preferences）');
      hilog.info(DOMAIN, TAG, '  - 药品和用药记录');
      
      hilog.info(DOMAIN, TAG, '========== 备份完成 ==========');
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 备份失败: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 系统执行恢复时回调
   * 会在应用启动前恢复备份的数据
   * 
   * @param bundleVersion 备份时的应用版本信息
   */
  async onRestore(bundleVersion: BundleVersion) {
    hilog.info(DOMAIN, TAG, '========== 开始恢复应用数据 ==========');
    
    try {
      hilog.info(DOMAIN, TAG, '备份版本信息:');
      hilog.info(DOMAIN, TAG, '  - 版本号: %{public}d', bundleVersion.code);
      hilog.info(DOMAIN, TAG, '  - 版本名: %{public}s', bundleVersion.name);
      
      // 系统会自动恢复备份的文件到应用数据目录
      // 这里可以添加数据迁移逻辑（如果数据库结构有变化）
      
      hilog.info(DOMAIN, TAG, '✅ 恢复内容包括：');
      hilog.info(DOMAIN, TAG, '  - 健康记录数据库');
      hilog.info(DOMAIN, TAG, '  - 用户配置');
      hilog.info(DOMAIN, TAG, '  - 药品和用药记录');
      
      hilog.info(DOMAIN, TAG, '========== 恢复完成 ==========');
      hilog.info(DOMAIN, TAG, '⚠️ 应用将在下次启动时加载恢复的数据');
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 恢复失败: %{public}s', JSON.stringify(err));
    }
  }
}