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

### 2. `rigel_products`

用途：

- 存京东联盟原始商品
- 保留原始商品追溯信息

建议字段：

- `id`
- `source_platform`
- `external_id`
- `title`
- `brand_name`
- `shop_name`
- `category_name`
- `product_url`
- `image_url`
- `price`
- `commission_rate`
- `is_promotable`
- `coupon_info`
- `raw_payload`
- `created_at`
- `updated_at`

### 3. `rigel_price_snapshots`

用途：

- 存价格快照
- 保留每日价格变化痕迹

建议字段：

- `id`
- `product_id`
- `captured_at`
- `price`
- `currency`
- `raw_payload`
- `created_at`

### 4. `rigel_product_part_mapping`

用途：

- 将原始商品映射到标准型号

建议字段：

- `id`
- `product_id`
- `keyword_seed_id`
- `canonical_model`
- `match_confidence`
- `match_source`
- `created_at`
- `updated_at`

### 5. `rigel_part_market_summary`

用途：

- 形成型号级价格清单
- 为 AI 提供 `price_catalog`

建议字段：

- `id`
- `category`
- `canonical_model`
- `source_platform`
- `sample_count`
- `avg_price`
- `median_price`
- `min_price`
- `max_price`
- `summary_date`
- `created_at`
- `updated_at`

### 6. `rigel_jobs`

用途：

- 记录采集、导入、汇总任务

建议字段：

- `id`
- `job_type`
- `status`
- `payload`
- `result_summary`
- `started_at`
- `finished_at`
- `created_at`
- `updated_at`

## 当前模块与表的职责归属

- `rigel-jd-collector`
  - `rigel_products`
  - `rigel_price_snapshots`
  - `rigel_jobs`

- `rigel-build-engine`
  - `rigel_keyword_seeds` 的消费与映射使用
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
4. 能形成型号映射
5. 能产出型号级价格清单
6. 能为未来返佣链接预留商品基础字段

## 当前不作为重点的旧设计

以下方向当前不是核心：

- 复杂兼容规则表
- 复杂打分模板表
- 大量 build request / build result 历史结构

如果这些表还存在于 bootstrap SQL 中，它们属于历史遗留，不代表当前系统中心。
