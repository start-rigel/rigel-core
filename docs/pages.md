# 页面清单

本文档定义当前第一版产品需要有哪些页面，以及每个页面的职责、依赖接口和返回结果。

## 页面目标

当前页面只服务于两件事情：

1. 维护型号词库
2. 提交推荐请求并查看结果

当前不做复杂后台系统，不做运营面板，不做多角色权限系统。

当前站点与前端统一要求：

- 对外域名使用 `givezj8.cn`
- 第一版页面支持中文 / English 切换
- 语言切换由前端本地状态控制，默认不依赖后端单独提供国际化接口

## 页面列表

### 1. 推荐首页

路径：

- `/`

页面职责：

- 接收用户输入
- 提交推荐请求
- 展示结构化推荐结果
- 提供中英文切换

页面字段：

- `budget`
- `usage`
- `brand_preference.cpu`
- `brand_preference.gpu`
- `special_requirements`
- `notes`

提交接口：

- `POST /catalog/recommend`

结果展示字段：

- `summary`
- `parts`
- `total_price`
- `reasoning`
- `alternatives`
- `warnings`

### 2. 型号词库列表页

路径：

- `/keywords`

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

- `GET /api/v1/keyword-seeds`

操作接口：

- `POST /api/v1/keyword-seeds/{id}/enable`
- `POST /api/v1/keyword-seeds/{id}/disable`
- `GET /api/v1/keyword-seeds/export`

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

### 3. 型号词库新增页

路径：

- `/keywords/new`

页面职责：

- 新增词条
- 提供中英文切换

提交接口：

- `POST /api/v1/keyword-seeds`

表单字段：

- `category`
- `keyword`
- `canonical_model`
- `brand`
- `aliases`
- `priority`
- `enabled`
- `notes`

### 4. 型号词库编辑页

路径：

- `/keywords/{id}/edit`

页面职责：

- 加载单个词条
- 编辑词条
- 提供中英文切换

读取接口：

- `GET /api/v1/keyword-seeds/{id}`

提交接口：

- `PUT /api/v1/keyword-seeds/{id}`

表单字段：

- `category`
- `keyword`
- `canonical_model`
- `brand`
- `aliases`
- `priority`
- `enabled`
- `notes`

### 5. Excel 导入页

路径：

- `/keywords/import`

页面职责：

- 上传 Excel 文件
- 查看导入结果
- 查看错误明细
- 下载模板
- 提供中英文切换

接口：

- `POST /api/v1/keyword-seeds/import`
- `GET /api/v1/keyword-seeds/template`

页面功能：

- 下载模板
- 上传文件
- 展示导入成功数
- 展示导入失败数
- 展示错误行与错误原因
- 展示导入生成的 `job_id`

### 6. Excel 导出动作

路径：

- `/keywords/export`

页面职责：

- 导出当前词库为 Excel

接口：

- `GET /api/v1/keyword-seeds/export`

第一版可以不单独做页面，允许在词库列表页提供一个导出按钮。

## 页面与接口对应关系

| 页面 | 读取接口 | 操作接口 |
|---|---|---|
| `/` | 无 | `POST /catalog/recommend` |
| `/keywords` | `GET /api/v1/keyword-seeds` | `POST /api/v1/keyword-seeds/{id}/enable` `POST /api/v1/keyword-seeds/{id}/disable` `GET /api/v1/keyword-seeds/export` |
| `/keywords/new` | 无 | `POST /api/v1/keyword-seeds` |
| `/keywords/{id}/edit` | `GET /api/v1/keyword-seeds/{id}` | `PUT /api/v1/keyword-seeds/{id}` |
| `/keywords/import` | 无 | `POST /api/v1/keyword-seeds/import` `GET /api/v1/keyword-seeds/template` |

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
