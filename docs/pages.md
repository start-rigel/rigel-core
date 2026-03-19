# 页面清单

本文档定义当前第一版产品需要有哪些页面，以及每个页面的职责、依赖接口和返回结果。

## 页面目标

当前页面只服务于两件事情：

1. 前台用户提交推荐请求并查看结果
2. 后台管理员维护型号词库

当前不做复杂运营面板，不做多角色权限系统。

当前站点与前端统一要求：

- 对外域名使用 `givezj8.cn`
- 页面前端统一使用 React 渲染，由 `rigel-console` 以嵌入式静态资源方式提供
- 第一版页面支持中文 / English 切换
- 语言切换由前端本地状态控制，默认不依赖后端单独提供国际化接口
- 用户默认无需登录即可直接使用推荐功能
- 对高成本 AI 请求采用匿名配额、缓存复用与风险挑战，不增加默认注册门槛
- 后台管理页面必须登录后访问
- 前台用户页面与后台管理页面不能混在同一个导航入口

## 页面列表

### 1. 前台推荐首页

路径：

- `/`

页面职责：

- 接收用户输入
- 提交推荐请求
- 展示结构化推荐结果
- 提供中英文切换
- 在不登录的前提下完成匿名使用
- 展示冷却、缓存命中和风险挑战状态

页面字段：

- `budget`
- `use_case`
- `build_mode`
- `brand_preference.cpu`
- `brand_preference.gpu`
- `special_requirements`
- `notes`

提交接口：

- `GET /api/v1/session/anonymous`
- `POST /catalog/recommend`

结果展示字段：

- `catalog_item_count`
- `selection.estimated_total`
- `selection.selected_items`
- `selection.warnings`
- `advice.summary`
- `advice.reasons`
- `advice.risks`

页面交互示例：

1. 用户打开首页，页面先调用 `GET /api/v1/session/anonymous`
2. 用户输入 `budget=6000`、`use_case=gaming`
3. 用户选择 `cpu=amd`、`gpu=nvidia`
4. 页面调用 `POST /catalog/recommend`
5. 若命中缓存则直接展示结果
6. 若进入短冷却则提示稍后再试
7. 页面展示 `selection.selected_items` 和 `advice.summary`

示例请求体：

```json
{
  "budget": 6000,
  "use_case": "gaming",
  "build_mode": "mixed",
  "brand_preference": {
    "cpu": "amd",
    "gpu": "nvidia"
  },
  "special_requirements": ["wifi_motherboard"],
  "notes": "1080p 游戏为主"
}
```

示例结果块：

```json
{
  "request_status": {
    "cache_hit": true,
    "remaining_ai_requests": 4,
    "cooldown_seconds": 0
  },
  "catalog_item_count": 24,
  "selection": {
    "estimated_total": 4206,
    "selected_items": [
      {
        "category": "CPU",
        "display_name": "AMD 7500f",
        "selected_price": 899
      }
    ]
  },
  "advice": {
    "summary": "基于当前价格目录，这份 gaming 采购草案总价约 4206 元。"
  }
}
```

首页还应具备以下匿名保护交互：

- 页面首次打开时静默获取匿名会话
- 同一按钮连续点击时前端先做短时间防抖
- 命中缓存时提示“已返回最近结果”
- 命中冷却时显示剩余秒数
- 命中挑战状态时跳转或弹出挑战组件

### 2. 后台登录页

路径：

- `/admin/login`

页面职责：

- 接收后台管理员账号密码
- 建立后台登录态
- 拒绝匿名访问后台管理页

提交接口：

- `POST /admin/login`

登录成功后跳转：

- `/admin`

### 3. 型号词库列表页

该页面属于后台管理页面，必须登录后访问。

路径：

- `/admin/keywords`

页面职责：

- 查看当前型号词库
- 按类别筛选
- 按品牌筛选
- 搜索关键词
- 启用/停用词条
- 进入新增页、编辑页、导入页
- 触发导出
- 提供中英文切换

读取接口：

- `GET /admin/api/v1/keyword-seeds`

操作接口：

- `POST /admin/api/v1/keyword-seeds/{id}/enable`
- `POST /admin/api/v1/keyword-seeds/{id}/disable`
- `GET /admin/api/v1/keyword-seeds/export`

页面展示字段：

- `id`
- `category`
- `keyword`
- `canonical_model`
- `brand`
- `aliases`
- `priority`
- `enabled`
- `notes`
- `updated_at`

页面展示示例：

| id | category | keyword | canonical_model | brand | enabled | updated_at |
|---|---|---|---|---|---|---|
| seed-1 | cpu | Ryzen 5 7500F | Ryzen 5 7500F | AMD | true | 2026-03-18T10:00:00+08:00 |
| seed-2 | gpu | RTX 4060 | RTX 4060 | NVIDIA | true | 2026-03-18T10:00:00+08:00 |

### 4. 型号词库新增页

该页面属于后台管理页面，必须登录后访问。

路径：

- `/admin/keywords/new`

页面职责：

- 新增词条
- 提供中英文切换

提交接口：

- `POST /admin/api/v1/keyword-seeds`

表单字段：

- `category`
- `keyword`
- `canonical_model`
- `brand`
- `aliases`
- `priority`
- `enabled`
- `notes`

示例表单值：

```json
{
  "category": "cpu",
  "keyword": "Ryzen 5 7500F",
  "canonical_model": "Ryzen 5 7500F",
  "brand": "AMD",
  "aliases": ["7500F", "AMD 7500F"],
  "priority": 100,
  "enabled": true,
  "notes": "主流游戏 CPU"
}
```

### 5. 型号词库编辑页

该页面属于后台管理页面，必须登录后访问。

路径：

- `/admin/keywords/{id}/edit`

页面职责：

- 加载单个词条
- 编辑词条
- 提供中英文切换

读取接口：

- `GET /admin/api/v1/keyword-seeds/{id}`

提交接口：

- `PUT /admin/api/v1/keyword-seeds/{id}`

表单字段：

- `category`
- `keyword`
- `canonical_model`
- `brand`
- `aliases`
- `priority`
- `enabled`
- `notes`

示例编辑流程：

1. 打开 `/admin/keywords/seed-1/edit`
2. 页面先请求 `GET /admin/api/v1/keyword-seeds/seed-1`
3. 用户把 `priority` 从 `90` 改到 `100`
4. 提交 `PUT /admin/api/v1/keyword-seeds/seed-1`

### 6. Excel 导入页

该页面属于后台管理页面，必须登录后访问。

路径：

- `/admin/keywords/import`

页面职责：

- 上传 Excel 文件
- 查看导入结果
- 查看错误明细
- 下载模板
- 提供中英文切换

接口：

- `POST /admin/api/v1/keyword-seeds/import`
- `GET /admin/api/v1/keyword-seeds/template`

页面功能：

- 下载模板
- 上传文件
- 展示导入成功数
- 展示导入失败数
- 展示错误行与错误原因
- 展示导入生成的 `job_id`

示例结果：

```json
{
  "job_id": "job-123",
  "imported_count": 20,
  "failed_count": 2,
  "errors": [
    {
      "row": 7,
      "message": "category is invalid"
    }
  ]
}
```

### 6. Excel 导出动作

路径：

- `/admin/keywords/export`

页面职责：

- 导出当前词库为 Excel

接口：

- `GET /admin/api/v1/keyword-seeds/export`

第一版可以不单独做页面，允许在词库列表页提供一个导出按钮。

## 页面与接口对应关系

| 页面 | 读取接口 | 操作接口 |
|---|---|---|
| `/` | 无 | `POST /catalog/recommend` |
| `/admin/keywords` | `GET /admin/api/v1/keyword-seeds` | `POST /admin/api/v1/keyword-seeds/{id}/enable` `POST /admin/api/v1/keyword-seeds/{id}/disable` `GET /admin/api/v1/keyword-seeds/export` |
| `/admin/keywords/new` | 无 | `POST /admin/api/v1/keyword-seeds` |
| `/admin/keywords/{id}/edit` | `GET /admin/api/v1/keyword-seeds/{id}` | `PUT /admin/api/v1/keyword-seeds/{id}` |
| `/admin/keywords/import` | 无 | `POST /admin/api/v1/keyword-seeds/import` `GET /admin/api/v1/keyword-seeds/template` |

## 当前不做的页面

当前明确不做：

- 用户登录页
- 复杂后台首页
- 采集任务监控大盘
- 佣金统计页
- 订单结算页
- 多平台配置页

## 当前页面优先级

### P0

- 推荐首页
- 型号词库列表页
- 型号词库新增页
- 型号词库编辑页
- Excel 导入功能
- Excel 导出功能

### P1

- 词库导入历史页
- JD 原始商品查看页

当前先不把 P1 页面纳入第一版必须交付。
