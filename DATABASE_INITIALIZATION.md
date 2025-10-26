# 数据库初始化流程

## 概述
HealthAssistant 使用两种数据持久化方案：
1. **RDB（关系型数据库）**: 存储健康记录、药品数据等结构化业务数据
2. **Preferences**: 存储用户偏好等简单键值对数据

## 初始化流程

### 1. 应用启动阶段 (EntryAbility)

```typescript
// entry/src/main/ets/entryability/EntryAbility.ets
onWindowStageCreate(windowStage: window.WindowStage): void {
  // 在显示UI前初始化数据管理器
  this.initializeDataManager();
  
  // 加载主页面
  windowStage.loadContent('pages/common/MainPage', callback);
}

private async initializeDataManager(): Promise<void> {
  try {
    // 1. 首先初始化 RDB 数据库（必须先初始化，因为后续业务数据依赖它）
    await HealthRecordDatabase.getInstance().init(this.context);
    
    // 2. 再初始化 Preferences 管理器
    await UserPreferenceManager.getInstance().init(this.context);
  } catch (err) {
    hilog.error(DOMAIN, 'testTag', 'Failed to initialize: %{public}s', JSON.stringify(err));
  }
}
```

### 2. RDB 初始化详细流程

```typescript
// entry/src/main/ets/utils/HealthRecordDatabase.ets

async init(context: Context): Promise<void> {
  if (this.isInitialized) return;  // 已初始化则直接返回
  if (this.initPromise) return this.initPromise;  // 初始化中则等待
  
  this.initPromise = this._performInit(context);
  await this.initPromise;
}

private async _performInit(context: Context): Promise<void> {
  return new Promise((resolve, reject) => {
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'medical_assistant.db',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      isReadOnly: false
    };
    
    // 使用回调方式获取 RdbStore 实例
    relationalStore.getRdbStore(context, STORE_CONFIG, async (err, store) => {
      if (err) {
        reject(err);
        return;
      }
      
      // 处理数据库就绪（版本检查、表创建等）
      await this._handleStoreReady(store);
      this.rdbStore = store;
      this.isInitialized = true;
      resolve();
    });
  });
}

private async _handleStoreReady(store: relationalStore.RdbStore): Promise<void> {
  const currentVersion = store.version;
  
  if (currentVersion === 0) {
    // 首次创建数据库
    await this._createTables(store);
    store.version = DB_VERSION;
  } else if (currentVersion < DB_VERSION) {
    // 数据库升级
    await this._upgradeDatabase(store, currentVersion, DB_VERSION);
    store.version = DB_VERSION;
  }
}

private async _createTables(store: relationalStore.RdbStore): Promise<void> {
  // 创建以下表：
  // 1. health_records - 健康记录表
  // 2. active_disease_templates - 激活疾病模板表
  // 3. medicine_data - 药品信息表
  // 4. medicine_records - 用药记录表
  
  await store.executeSql(DatabaseSchema.HEALTH_RECORDS_SQL);
  await store.executeSql(DatabaseSchema.HEALTH_RECORDS_INDEX_SQL);
  await store.executeSql(DatabaseSchema.ACTIVE_DISEASE_TEMPLATES_SQL);
  await store.executeSql(DatabaseSchema.MEDICINE_DATA_SQL);
  await store.executeSql(DatabaseSchema.MEDICINE_RECORDS_SQL);
  await store.executeSql(DatabaseSchema.MEDICINE_RECORDS_INDEX_SQL);
}
```

### 3. Preferences 初始化

```typescript
// entry/src/main/ets/utils/dataPreference.ets

async init(context: Context): Promise<void> {
  if (this.isInitialized) return;
  if (this.initPromise) return this.initPromise;
  
  this.initPromise = this._performInit(context);
  await this.initPromise;
}

private async _performInit(context: Context): Promise<void> {
  try {
    this.dataPreferences = await preferences.getPreferences(
      context,
      'user_preferences'
    );
    this.isInitialized = true;
  } catch (err) {
    throw err;
  }
}
```

## 数据库表结构

### 表 1: active_disease_templates（激活的疾病模板）
```sql
CREATE TABLE active_disease_templates (
  template_id TEXT PRIMARY KEY,
  template_name TEXT NOT NULL,
  activated_at INTEGER NOT NULL,
  is_deleted INTEGER DEFAULT 0,
  deleted_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
```

### 表 2: health_records（健康记录）
```sql
CREATE TABLE health_records (
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
```

### 表 3: medicine_data（药品信息）
```sql
CREATE TABLE medicine_data (
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
```

### 表 4: medicine_records（用药记录）
```sql
CREATE TABLE medicine_records (
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
```

## 关键设计点

### ✅ 初始化顺序
1. 先初始化 RDB（业务数据基础）
2. 再初始化 Preferences（用户偏好）

### ✅ 单例模式
- HealthRecordDatabase：确保全局只有一个 RDB 实例
- UserPreferenceManager：确保全局只有一个 Preferences 实例

### ✅ 防止重复初始化
```typescript
if (this.isInitialized) return;
if (this.initPromise) return this.initPromise;
```

### ✅ 数据库版本管理
- 支持透明升级
- 自动建表（版本 0 时）
- 灵活的升级路径

### ✅ 错误处理
- init 方法不会抛异常，而是返回 Promise reject
- checkInitialized 确保后续操作前数据库已初始化

## 使用示例

### 在任何业务代码中使用数据库
```typescript
// 自动获取已初始化的实例
const db = HealthRecordDatabase.getInstance();

// 保存健康记录
await db.saveHealthRecord(record);

// 查询健康记录
const records = await db.getHealthRecords('hypertension');

// 获取激活的疾病
const activeTemplates = await db.getActiveDiseaseTemplates();
```

## 常见问题

### Q: 为什么会报"数据库未初始化"？
A: 确保在使用数据库前，已在 EntryAbility 中调用了 init 方法。

### Q: 可以在应用运行中重新初始化数据库吗？
A: 不建议。HealthRecordDatabase 使用单例模式，一旦初始化就应该保持不变。

### Q: Preferences 和 RDB 的选择标准是什么？
A: 
- Preferences: 简单键值对数据（用户偏好、设置等）
- RDB: 结构化、关系复杂的数据（健康记录、药品等）

### Q: 如何处理数据库升级？
A: 在 _upgradeToVersion 方法中添加升级逻辑，数据库版本号自动递增。
