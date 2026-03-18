# 页面清单

本文档定义当前第一版产品需要有哪些页面，以及每个页面的职责。

## 页面目标

当前页面只服务于两件事情：

1. 维护型号词库
2. 提交推荐请求并查看结果

当前不做复杂后台系统，不做运营面板，不做多角色权限系统。

## 页面列表

### 1. 推荐首页

路径建议：

- `/`

页面职责：

- 接收用户输入
- 提交推荐请求
- 展示结构化推荐结果

页面字段建议：

- `budget`
- `usage`
- `brand_preference.cpu`
- `brand_preference.gpu`
- `special_requirements`
- `notes`

页面展示内容建议：

- 推荐摘要 `summary`
- 推荐配件列表 `parts`
- 总价 `total_price`
- 推荐理由 `reasoning`
- 备选说明 `alternatives`
- 风险提示 `warnings`

### 2. 型号词库列表页

路径建议：

- `/keywords`

页面职责：

- 查看当前型号词库
- 按类别筛选
- 按品牌筛选
- 搜索关键词
- 启用/停用词条

页面展示字段建议：

- `category`
- `keyword`
- `canonical_model`
- `brand`
- `aliases`
- `priority`
- `enabled`
- `notes`
- `updated_at`

### 3. 型号词库新增/编辑页

路径建议：

- `/keywords/new`
- `/keywords/{id}/edit`

页面职责：

- 新增词条
- 编辑词条

表单字段：

- `category`
- `keyword`
- `canonical_model`
- `brand`
- `aliases`
- `priority`
- `enabled`
- `notes`

### 4. Excel 导入页

路径建议：

- `/keywords/import`

页面职责：

- 上传 Excel 文件
- 查看导入结果
- 查看错误明细

页面功能：

- 下载模板
- 上传文件
- 展示导入成功数
- 展示导入失败数
- 展示错误行与错误原因

### 5. Excel 导出页或导出动作

路径建议：

- `/keywords/export`

页面职责：

- 导出当前词库为 Excel

第一版可以不单独做页面，允许在词库列表页提供一个导出按钮。

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
- 型号词库新增/编辑页
- Excel 导入功能
- Excel 导出功能

### P1

- 词库导入历史页
- JD 原始商品查看页

当前先不把 P1 页面纳入第一版必须交付。
