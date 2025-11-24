# 数据持久化方案指南

## 📋 概述

本应用提供三种数据持久化方案，确保用户数据在卸载后仍能恢复。

---

## ✅ 方案一：系统备份恢复（已实现，推荐）

### 工作原理

- 利用鸿蒙系统的 `BackupExtensionAbility`
- 系统会自动备份应用的数据目录
- 卸载后备份数据仍保留在系统中
- 重新安装时可选择恢复数据

### 备份内容

- ✅ 健康记录数据库（health_records.db）
- ✅ 用户配置文件（preferences）
- ✅ 所有药品和用药记录
- ✅ 疾病管理数据

### 用户操作方式

#### 备份数据

1. 打开系统"设置"
2. 进入"系统和更新" > "备份和恢复"
3. 选择"本地备份"或"云备份"
4. 勾选"慢性病助手"应用
5. 点击"备份"

#### 恢复数据

1. 重新安装应用后
2. 打开系统"设置" > "备份和恢复"
3. 选择之前的备份
4. 勾选"慢性病助手"
5. 点击"恢复"
6. 重新启动应用

### 优势

- ✅ 零开发成本，系统自动处理
- ✅ 支持云备份（需登录华为账号）
- ✅ 数据加密，安全可靠
- ✅ 跨设备恢复（通过华为云）

### 局限性

- ⚠️ 需要用户手动操作
- ⚠️ 仅限鸿蒙/华为设备
- ⚠️ 云备份需要网络和华为账号

---

## 🔄 方案二：数据导出/导入功能（建议实现）

### 实现思路

添加手动导出/导入功能，让用户完全控制数据。

### 实现步骤

#### 1. 添加数据导出功能

```typescript
// 在 HealthRecordDatabase.ets 中添加
async exportData(): Promise<string> {
  try {
    // 导出所有数据为 JSON
    const data = {
      version: '1.0.0',
      exportTime: Date.now(),
      medicines: await this.getMedicineList(),
      medicineRecords: await this.getMedicineRecords(),
      // 其他数据...
    };

    // 转换为 JSON 字符串
    return JSON.stringify(data, null, 2);
  } catch (err) {
    throw new Error('数据导出失败');
  }
}

// 保存到文件
async saveDataToFile(data: string): Promise<void> {
  const context = getContext(this);
  const filesDir = context.filesDir;
  const fileName = `health_backup_${Date.now()}.json`;
  const filePath = `${filesDir}/${fileName}`;

  const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
  fs.writeSync(file.fd, data);
  fs.closeSync(file);

  // 提示用户文件位置
  return filePath;
}
```

#### 2. 添加数据导入功能

```typescript
async importData(jsonData: string): Promise<void> {
  try {
    const data = JSON.parse(jsonData);

    // 验证数据版本
    if (data.version !== '1.0.0') {
      throw new Error('数据版本不兼容');
    }

    // 导入药品数据
    for (const medicine of data.medicines) {
      await this.saveMedicine(medicine);
    }

    // 导入用药记录
    for (const record of data.medicineRecords) {
      await this.saveMedicineRecord(record);
    }

    console.log('数据导入成功');
  } catch (err) {
    throw new Error('数据导入失败: ' + err.message);
  }
}
```

#### 3. 在设置页面添加 UI

```typescript
// ProfilePage.ets 中添加
Button("导出数据").onClick(async () => {
  try {
    const data = await HealthRecordDatabase.getInstance().exportData();
    const filePath = await this.saveDataToFile(data);
    promptAction.showToast({
      message: `数据已导出到: ${filePath}`,
      duration: 3000,
    });
  } catch (err) {
    promptAction.showToast({ message: "导出失败" });
  }
});

Button("导入数据").onClick(async () => {
  // 显示文件选择器
  // 读取文件内容
  // 调用 importData
});
```

### 优势

- ✅ 用户完全控制数据
- ✅ 可跨平台使用
- ✅ 可通过任何方式传输（微信、邮件等）
- ✅ 数据格式透明，方便迁移

---

## ☁️ 方案三：云端同步（高级方案）

### 实现思路

将数据同步到云服务器，实现多端同步和永久存储。

### 实现步骤

#### 1. 选择云服务

- 华为云 CloudDB（推荐）
- 华为云对象存储
- 自建服务器

#### 2. 数据同步逻辑

```typescript
class CloudSyncService {
  // 上传数据到云端
  async syncToCloud(): Promise<void> {
    const data = await HealthRecordDatabase.getInstance().exportData();
    // 调用云服务 API
    await cloudDB.upsert("health_data", {
      userId: this.getUserId(),
      data: data,
      updateTime: Date.now(),
    });
  }

  // 从云端下载数据
  async syncFromCloud(): Promise<void> {
    const cloudData = await cloudDB.query("health_data", {
      userId: this.getUserId(),
    });

    if (cloudData && cloudData.updateTime > this.getLocalUpdateTime()) {
      await HealthRecordDatabase.getInstance().importData(cloudData.data);
    }
  }

  // 自动同步
  startAutoSync(): void {
    setInterval(() => {
      this.syncToCloud();
    }, 5 * 60 * 1000); // 每5分钟同步一次
  }
}
```

### 优势

- ✅ 自动备份，无需用户操作
- ✅ 多设备同步
- ✅ 数据永久保存
- ✅ 可实现协作功能

### 局限性

- ⚠️ 需要服务器成本
- ⚠️ 需要用户注册/登录
- ⚠️ 需要网络连接
- ⚠️ 隐私和安全考虑

---

## 📊 方案对比

| 特性     | 系统备份    | 导出/导入   | 云端同步    |
| -------- | ----------- | ----------- | ----------- |
| 实现难度 | ⭐ 简单     | ⭐⭐ 中等   | ⭐⭐⭐ 复杂 |
| 用户操作 | 手动        | 手动        | 自动        |
| 跨设备   | ✅ 华为生态 | ✅ 任意设备 | ✅ 任意设备 |
| 成本     | 免费        | 免费        | 需服务器    |
| 可靠性   | 高          | 中          | 高          |
| 隐私性   | 高          | 高          | 需考虑      |

---

## 🎯 推荐方案组合

### 基础版（当前已实现）

✅ **方案一：系统备份**

- 零开发成本
- 满足大部分用户需求

### 进阶版（建议）

✅ **方案一 + 方案二**

- 系统备份作为默认方案
- 导出/导入作为备选方案
- 覆盖更多使用场景

### 专业版（可选）

✅ **方案一 + 方案二 + 方案三**

- 提供完整的数据保障
- 支持多端同步
- 适合重度用户

---

## 📱 用户指引

### 如何避免数据丢失？

#### 方式 1：使用系统备份（推荐）

1. 定期在"设置 > 备份和恢复"中备份应用
2. 启用华为云自动备份
3. 卸载前确认已备份

#### 方式 2：手动导出（实现后）

1. 在应用的"我的 > 数据管理"中导出数据
2. 将导出文件保存到安全位置
3. 重装后通过"导入数据"恢复

---

## 🔧 技术细节

### 系统备份的文件路径

```
/data/app/el2/{userId}/database/{bundleName}/
  ├── rdb/
  │   └── health_records.db    # 主数据库
  ├── preferences/
  │   └── user_prefs           # 用户配置
  └── files/                    # 其他文件
```

### 备份触发时机

- 用户在系统设置中手动备份
- 华为云自动备份（如果已启用）
- 设备迁移时

### 恢复时机

- 应用重新安装后首次启动前
- 用户在系统设置中手动恢复

---

## ⚠️ 注意事项

1. **数据安全**

   - 系统备份已加密
   - 导出的 JSON 文件包含敏感信息，需妥善保管

2. **版本兼容**

   - 跨版本恢复时可能需要数据迁移
   - 建议在备份数据中记录版本号

3. **用户提示**
   - 在应用首次启动时提示用户启用备份
   - 在卸载前提醒用户备份数据

---

## 📝 后续优化建议

1. ✅ **完善系统备份**（已完成）

   - 添加详细的日志记录
   - 实现数据版本迁移

2. 🔄 **实现导出/导入**

   - 添加数据导出按钮
   - 实现文件选择和导入
   - 支持分享导出文件

3. ☁️ **考虑云端同步**

   - 评估用户需求
   - 选择合适的云服务
   - 设计同步策略

4. 📱 **用户教育**
   - 添加备份引导页
   - 在设置中添加备份说明
   - 定期提醒用户备份
