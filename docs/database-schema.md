# Database Schema

当前数据库设计只服务于这条主链路：

`京东原始商品 -> 型号级价格信息 -> AI 推荐`

## 命名规则

所有业务表统一使用 `rigel_` 前缀。

## 当前核心表

### 1. `rigel_keyword_seeds`

用途：

- 存型号词库
- 存 Excel 导入结果
- 为 JD 搜索提供关键词来源

建议字段：

- `id`
- `category`
- `keyword`
- `canonical_model`
- `brand`
- `aliases_json`
- `priority`
- `enabled`
- `notes`
- `created_at`
- `updated_at`

### 2. `rigel_parts`

用途：

- 存 build-engine 归一后的标准型号实体
- 为价格汇总和推荐结果提供稳定主键

当前字段：

- `id`
- `category`
- `brand`
- `series`
- `model`
- `display_name`
- `normalized_key`
- `generation`
- `msrp`
- `release_year`
- `lifecycle_status`
- `source_confidence`
- `alias_keywords`
- `created_at`
- `updated_at`

### 3. `rigel_products`

用途：

- 存京东联盟原始商品
- 保留原始商品追溯信息

当前字段：

- `id`
- `source_platform`
- `external_id`
- `sku_id`
- `title`
- `subtitle`
- `url`
- `image_url`
- `shop_name`
- `shop_type`
- `seller_name`
- `region`
- `price`
- `currency`
- `availability`
- `attributes`
- `raw_payload`
- `first_seen_at`
- `last_seen_at`
- `created_at`
- `updated_at`

### 4. `rigel_price_snapshots`

用途：

- 存价格快照
- 保留每日价格变化痕迹

当前字段：

- `id`
- `product_id`
- `source_platform`
- `captured_at`
- `price`
- `in_stock`
- `metadata`

### 5. `rigel_product_part_mapping`

用途：

- 将原始商品映射到标准型号

当前字段：

- `id`
- `product_id`
- `part_id`
- `keyword_seed_id`
- `mapping_status`
- `match_confidence`
- `matched_by`
- `candidate_display_name`
- `reason`
- `created_at`
- `updated_at`

### 6. `rigel_part_market_summary`

用途：

- 形成型号级价格清单
- 为 AI 提供 `price_catalog`

当前字段：

- `id`
- `part_id`
- `source_platform`
- `sample_count`
- `latest_price`
- `median_price`
- `p25_price`
- `p75_price`
- `min_price`
- `max_price`
- `window_days`
- `last_collected_at`
- `created_at`
- `updated_at`

### 7. `rigel_jobs`

用途：

- 记录采集、导入、汇总任务

当前字段：

- `id`
- `job_type`
- `status`
- `source_platform`
- `payload`
- `result`
- `scheduled_at`
- `started_at`
- `finished_at`
- `retry_count`
- `error_message`
- `created_at`
- `updated_at`

## 当前模块与表的职责归属

- `rigel-jd-collector`
  - `rigel_products`
  - `rigel_price_snapshots`
  - `rigel_jobs`

- `rigel-build-engine`
  - `rigel_parts`
  - `rigel_keyword_seeds` 的消费与映射预留
  - `rigel_product_part_mapping`
  - `rigel_part_market_summary`

- `rigel-console`
  - 页面管理和服务调用
  - 不直接拥有核心业务表

## 当前数据库设计重点

当前重点不是复杂规格库。
当前重点是：

1. 能存型号词库
2. 能存原始商品
3. 能存价格快照
4. 能形成标准型号实体与映射
5. 能产出型号级价格清单
6. 能为未来返佣链接预留原始 payload

## 当前不作为重点的旧设计

当前 bootstrap SQL 已经移除了旧的：

- 兼容规则表
- 打分模板表
- 旧 build request / build result 历史结构
- 闲鱼 / 浏览器抓取相关枚举与表
