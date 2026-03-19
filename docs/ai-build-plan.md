# 接入 Cloudflare Gateway AI 生成装机方案

## 摘要

基于已申请的 Cloudflare AI Gateway + OpenRouter 接口，把当前“本地模板化推荐”升级为“AI 优先，fallback 保底”的整机推荐链路。

最终目标：

- `console /catalog/recommend` 对外返回整机推荐结果，结构对齐参考仓库
- `build-engine` 使用 Cloudflare Gateway 调用 `openai/gpt-5.4-nano`
- 传给 AI 时，每个部件类别最多传 N 个型号，N 为后台系统设置中的全局值，默认 `5`
- 后台新增独立“系统设置”页，持久化管理 AI 运行配置和 N 值
- 完成重启、测试数据生成，并用 MCP 做后台设置页和前台整链路验证

## 重要安全说明

当前 AI 密钥已经在聊天中明文出现，应视为已暴露。正式实现前应旋转：

- `cf-aig-authorization` token
- `Authorization` bearer token

系统实现中仍按“读时脱敏、写时覆盖”设计，但现有密钥建议立即更换。

## AI 接口基线

默认使用以下 upstream：

- Base URL: `https://gateway.ai.cloudflare.com/v1/d894508e3ebe33462d2d6ac0254ba3ea/rigel/openrouter/v1/chat/completions`
- Model: `openai/gpt-5.4-nano`

请求协议：

- Header:
  - `Content-Type: application/json`
  - `cf-aig-authorization: Bearer <gateway_token>`
  - `Authorization: Bearer <api_token>`
- Body:
  - `model`
  - `messages`

## 数据与配置模型

### 新增系统设置表

在 `rigel-core/db/init/001_init.sql` 中新增 `rigel_system_settings` 表，建议结构：

- `id`
- `setting_key`，唯一
- `value_json`
- `created_at`
- `updated_at`

### 至少存储两类设置

#### 1. `ai_runtime`

字段：

- `base_url`
- `gateway_token`
- `api_token`
- `model`
- `timeout_seconds`
- `enabled`

#### 2. `catalog_ai_limits`

字段：

- `max_models_per_category`
- 默认值 `5`

### 配置优先级

建议优先级：

1. 数据库系统设置
2. 环境变量默认值
3. 无配置时走本地 fallback

### 环境变量兜底

保留并支持：

- `RIGEL_AI_BASE_URL`
- `RIGEL_AI_GATEWAY_TOKEN`
- `RIGEL_AI_TOKEN`
- `RIGEL_AI_MODEL`
- `RIGEL_AI_TIMEOUT`

## 后台系统设置页

### 新增页面

新增独立后台页：

- `/admin/settings`

### 新增 API

- `GET /admin/api/v1/settings/system`
- `PUT /admin/api/v1/settings/system`

### 页面内容

至少支持编辑：

- AI Base URL
- AI Gateway Token
- AI API Token
- AI Model
- AI Timeout
- 每类型号上限 `max_models_per_category`

### 敏感字段策略

采用“读时脱敏，改时覆盖”：

- 读取时仅返回：
  - 是否已配置
  - 脱敏占位
- 更新时：
  - 非空值覆盖旧值
  - 空字符串默认表示“不修改”
  - 如需清空密钥，建议显式清空动作或布尔字段

### 后台导航

在现有后台导航中新增“系统设置”入口，和关键词管理同级。

## build-engine 改造

### 配置层

扩展 `rigel-build-engine/internal/config/config.go`：

- `AIBaseURL`
- `AIGatewayToken`
- `AIToken`
- `AIModel`
- `AITimeout`

同时加入系统设置读取能力。

### 服务初始化

在 `cmd/server/main.go` 中注入：

- 系统设置 repository / service
- AI client
- advice service

### 保留并升级 `/api/v1/advice/catalog`

保留现有接口，但内部改为：

1. 若 AI 可用，优先调用 AI 生成 advisory
2. 若 AI 不可用或返回异常，回退本地模板

### 新增 `/api/v1/recommend/build`

新增整机推荐主接口：

- `POST /api/v1/recommend/build`

输入延续当前前台请求：

- `budget`
- `use_case`
- `build_mode`
- `notes`

处理流程：

1. 生成价格目录
2. 按部件类别分组
3. 每类仅保留前 N 个型号传给 AI
4. AI 输出整机规划 JSON
5. 用当前采集商品做候选匹配
6. 生成最终用户可读 advice
7. 返回整机推荐结果

## 传给 AI 的 catalog 规则

### 型号截断规则

- 以“型号聚合后”的结果为单位裁剪
- 每个部件类别最多 `max_models_per_category` 个型号
- `max_models_per_category` 为全局配置，不按类别分别配置
- 排序采用当前 catalog 结果顺序后截断

### 每个型号传给 AI 的字段

至少包含：

- `category`
- `model`
- `display_name`
- `sample_count`
- `min_price`
- `max_price`
- `avg_price`
- `median_price`

可附带：

- `normalized_key`
- `source_platforms`

### Prompt 约束

Prompt 必须要求：

- 仅返回 JSON
- 固定字段名
- 覆盖所有应有部件类别
- 优先满足预算约束
- 说明选型理由、风险、升级建议
- 即使缺件，也必须返回缺失项而不是省略类别

## 对外接口形态

### build-engine 返回结构

`POST /api/v1/recommend/build` 至少返回：

- `provider`
- `fallback_used`
- `request`
- `summary`
- `estimated_total`
- `within_budget`
- `warnings`
- `build_items`
- `advice`

### `build_items` 每项至少包含

- `category`
- `target_model`
- `selection_reason`
- `price_basis`
- `confidence`
- `recommended_product`
- `candidate_products`
- `missing`
- `reason`
- `suggested_keyword`

## console 改造

### buildengine client

`rigel-console/internal/client/buildengine` 改为调用：

- `POST /api/v1/recommend/build`

### 模型层

`rigel-console/internal/domain/model` 引入整机推荐响应结构，替换当前 `CatalogRecommendationResponse`

### 业务层

`rigel-console/internal/service/console`：

- 保留匿名配额与缓存逻辑
- 缓存值切换为整机推荐响应
- `/catalog/recommend` 继续作为前台入口，但返回整机推荐结构

### 前台页面

首页结果区改为展示：

- AI 总结
- 预计总价
- 是否在预算内
- 每个部件的目标型号
- 推荐商品
- 候选商品
- 风险
- 升级建议

## 测试数据生成

基于当前 `rigel_*` 表结构，生成一批非 mock 测试数据，至少覆盖：

- CPU
- GPU
- MB
- RAM
- SSD
- PSU
- CASE
- COOLER

要求：

- 每类至少 2-3 个型号
- 每个型号至少 2-3 条商品与价格样本
- `raw_payload.mock` 不写或为 `false`
- 数据写入：
  - `rigel_products`
  - `rigel_price_snapshots`
  - 必要时补 `rigel_keyword_seeds`

## 自动化测试

### build-engine

至少补以下测试：

- 系统设置与环境变量优先级
- chat-completions 请求头/body 组装
- AI JSON 响应解析
- AI 超时 / 非 JSON / 4xx / 5xx fallback
- 每类最多 N 个型号裁剪
- AI 输入包含 `min/max/avg/median`
- `/api/v1/recommend/build` 正常返回整机推荐结构

### console

至少补以下测试：

- `/catalog/recommend` 代理新接口成功
- 上游错误透传
- 后台系统设置脱敏与覆盖更新
- 新响应模型序列化/反序列化

## MCP 联调

实施完成后用 MCP 做三段验证：

1. 后台 `/admin/settings`
   - 可查看当前配置状态
   - 可修改 `max_models_per_category`
   - 可修改 `model / timeout / token`
   - 读取时密钥脱敏

2. 前台 `/catalog/recommend`
   - 返回整机推荐结构
   - 页面能正确展示总价、预算状态、配件项、候选商品和 AI 文案

3. Fallback 验证
   - 故意填错 token 或 base URL
   - 接口仍返回 fallback 结果
   - warning 中明确标记 fallback

## 项目收尾

完成后需要：

- 重建并重启 Docker Compose
- 根据当前表结构导入测试数据
- 用 MCP 完成后台与前台联调
- 同步更新：
  - `rigel-build-engine/README.md`
  - `rigel-console/README.md`
  - `rigel-core/README.md`
  - 必要时补充 `rigel-core/docs/` 文档

## 默认假设

- 使用 Cloudflare Gateway 作为默认 AI upstream
- 默认模型 `openai/gpt-5.4-nano`
- 默认 timeout `25s`
- 每类传给 AI 的型号上限为全局值，默认 `5`
- 后台系统设置页为独立入口 `/admin/settings`
- 敏感配置采用“读时脱敏，改时覆盖”
- 对外推荐接口对齐参考仓库整机推荐结构
