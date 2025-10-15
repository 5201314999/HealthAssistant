# v3.0.0 升级指南

## 概述

v3.0.0 是一个重大更新版本，基于设计稿对整个应用进行了全面重构。主要变化包括：

1. **全新的导航架构** - 底部 Tab 导航替代原有的单页面导航
2. **重新设计的首页** - 健康概览和今日用药双 Tab 视图
3. **新增高血压管理模板** - 支持血压数据录入和监测
4. **个人中心页面** - 全新的用户信息和统计展示
5. **用药管理页面重构** - 优化的用药提醒和管理界面

## 主要变化

### 1. 应用架构变化

#### 旧架构

```
Index.ets (首页)
├── 甲亢管理
├── 糖尿病管理
└── 用药管理
```

#### 新架构

```
MainPage.ets (主导航)
├── HomePage.ets (首页 - Tab 1)
│   ├── 健康概览
│   └── 今日用药
├── MedicineTabPage.ets (用药 - Tab 2)
│   ├── 用药提醒
│   └── 我的用药
└── ProfilePage.ets (我的 - Tab 3)
```

### 2. 页面文件变化

#### 新增文件

- `pages/MainPage.ets` - 主导航页面（入口）
- `pages/HomePage.ets` - 新版首页
- `pages/MedicineTabPage.ets` - 用药 Tab 页
- `pages/ProfilePage.ets` - 个人中心页

#### 保留文件（继续使用）

- `pages/DiseaseManagePage.ets` - 疾病管理页
- `pages/DataEntryPage.ets` - 数据录入页
- `pages/AddMedicinePage.ets` - 添加药品页

#### 旧文件（已不再使用作为主入口）

- `pages/Index.ets` - 旧版首页（保留但不作为主入口）
- `pages/MedicineManagePage.ets` - 旧版用药管理（已被 MedicineTabPage 替代）

### 3. 数据模型变化

#### HealthDataManager 新增方法

```typescript
// 获取最新的健康记录
async getLatestHealthRecord(templateId: string, groupId?: string): Promise<HealthRecord | null>

// 获取所有有数据的疾病模板ID
async getActiveDiseaseTemplates(): Promise<string[]>
```

### 4. 模板配置变化

#### 新增高血压模板

```typescript
// config/BuiltInTemplates.ets
function createHypertensionTemplate(): DiseaseTemplate;
```

#### 模板顺序调整

```typescript
// 旧顺序
[createThyroidTemplate(), createDiabetesTemplate()][
  // 新顺序
  (createHypertensionTemplate(),
  createDiabetesTemplate(),
  createThyroidTemplate())
];
```

#### 颜色调整

- 糖尿病：`#2196F3` → `#FFA726`（蓝色改为橙色）

### 5. 启动页面变化

#### EntryAbility.ets

```typescript
// 旧版
windowStage.loadContent('pages/Index', ...)

// 新版
windowStage.loadContent('pages/MainPage', ...)
```

## 功能对照表

| 旧版本功能          | 新版本位置      | 变化说明             |
| ------------------- | --------------- | -------------------- |
| 首页 - 疾病列表     | 首页 - 健康概览 | 新增健康数据展示卡片 |
| 首页 - 用药提醒     | 首页 - 今日用药 | 优化为独立 Tab 视图  |
| 用药管理 - 今日用药 | 用药 - 用药提醒 | 新增进度环形图       |
| 用药管理 - 药品列表 | 用药 - 我的用药 | 优化布局和交互       |
| 无                  | 我的 - 个人中心 | 全新页面             |

## 设计系统变化

### 颜色主题

#### 主题色

- **旧版**: 各模块独立颜色
- **新版**: 统一主题色 `#4A90E2`（蓝色）

#### 模块颜色

| 模块   | 旧版      | 新版      |
| ------ | --------- | --------- |
| 甲亢   | `#4CAF50` | `#4CAF50` |
| 糖尿病 | `#2196F3` | `#FFA726` |
| 高血压 | -         | `#EF5350` |
| 用药   | `#FF9800` | -         |

### UI 组件

#### 导航栏

- **旧版**: 顶部返回按钮 + 标题
- **新版**: 底部 Tab 导航（常驻）

#### 卡片设计

- **旧版**: 圆角 12px，单一背景色
- **新版**: 圆角 12-16px，阴影效果，层次分明

#### 按钮样式

- **旧版**: 矩形或圆角矩形
- **新版**: 圆角 24px（胶囊形）

## 数据兼容性

### 完全兼容

所有旧版本的数据格式完全兼容，无需迁移：

- ✅ 健康记录数据
- ✅ 用药数据
- ✅ 用药记录

### 数据存储键

```
health_records_thyroid      // 甲亢（兼容）
health_records_diabetes     // 糖尿病（兼容）
health_records_hypertension // 高血压（新增）
medicine_list               // 药品列表（兼容）
medicine_records            // 用药记录（兼容）
```

## 用户体验变化

### 导航方式

#### 旧版

1. 首页 → 点击疾病卡片 → 疾病管理页
2. 首页 → 点击用药管理 → 用药管理页

#### 新版

1. 首页（底部 Tab 1）→ 健康概览/今日用药切换
2. 用药（底部 Tab 2）→ 用药提醒/我的用药切换
3. 我的（底部 Tab 3）→ 个人中心

### 操作流程优化

#### 查看健康数据

- **旧版**: 首页 → 选择疾病 → 查看列表
- **新版**: 首页 → 健康概览（直接显示最新数据）

#### 用药打卡

- **旧版**: 首页 → 用药管理 → 今日用药 → 打卡
- **新版**:
  - 首页 → 今日用药 Tab → 打卡
  - 或 用药 Tab → 用药提醒 → 打卡

#### 添加药品

- **旧版**: 首页 → 用药管理 → 药品列表 → 添加
- **新版**: 用药 Tab → 我的用药 → 添加

## 开发者注意事项

### 1. 路由配置

确保 `main_pages.json` 包含所有新页面：

```json
{
  "src": [
    "pages/MainPage",
    "pages/HomePage",
    "pages/MedicineTabPage",
    "pages/ProfilePage",
    ...
  ]
}
```

### 2. 启动页面

确保 `EntryAbility.ets` 加载 MainPage：

```typescript
windowStage.loadContent('pages/MainPage', ...)
```

### 3. 组件导出

新页面都使用 `@Component export struct` 而非 `@Entry`：

- HomePage
- MedicineTabPage
- ProfilePage

只有 MainPage 使用 `@Entry @Component struct`。

### 4. 状态管理

各 Tab 页面有独立的 `aboutToAppear()` 生命周期，注意：

- 数据加载时机
- 状态更新触发

## 测试建议

### 1. 功能测试

- [ ] 首页健康概览数据展示
- [ ] 首页今日用药列表和打卡
- [ ] 用药提醒页面进度显示
- [ ] 我的用药页面药品管理
- [ ] 个人中心统计数据
- [ ] 底部 Tab 切换流畅性

### 2. 数据测试

- [ ] 旧数据正常显示
- [ ] 新增高血压数据正常保存
- [ ] 各疾病模板数据互不干扰

### 3. UI 测试

- [ ] 各页面布局正常
- [ ] 颜色主题一致
- [ ] 图标显示正常
- [ ] 动画效果流畅

## 常见问题

### Q1: 升级后看不到首页内容？

**A**: 请确保 `EntryAbility.ets` 中加载的是 `pages/MainPage` 而不是 `pages/Index`。

### Q2: 底部导航不显示？

**A**: 检查 `MainPage.ets` 是否正确配置为 `@Entry` 组件。

### Q3: 旧数据不见了？

**A**: v3.0.0 完全兼容旧数据，检查 `HealthDataManager` 初始化是否正常。

### Q4: 添加药品后没有显示？

**A**: 检查是否在 `MedicineTabPage` 的 `aboutToAppear()` 中加载了数据。

### Q5: 健康数据不显示？

**A**: 首页只显示有记录的疾病数据，确保已录入相应的健康记录。

## 回滚方案

如果需要回滚到旧版本：

1. 恢复 `EntryAbility.ets`:

   ```typescript
   windowStage.loadContent('pages/Index', ...)
   ```

2. 数据无需处理（完全兼容）

3. 如需删除新文件：
   - 删除 `pages/MainPage.ets`
   - 删除 `pages/HomePage.ets`
   - 删除 `pages/MedicineTabPage.ets`
   - 删除 `pages/ProfilePage.ets`

## 总结

v3.0.0 是一次以用户体验为核心的重大升级：

✅ **优点**

- 更直观的导航结构
- 更丰富的信息展示
- 更流畅的操作体验
- 完整的个人中心

✅ **兼容性**

- 100% 数据兼容
- 所有核心功能保留
- 平滑升级，无需迁移

✅ **可扩展性**

- 新增高血压模板
- 为更多疾病模板预留空间
- 统一的设计语言

---

**升级建议**: 强烈建议升级到 v3.0.0，体验全新设计！

**技术支持**: 如有问题，请查阅 [README.md](README.md) 或 [CHANGELOG.md](CHANGELOG.md)
