# 京东联盟字段映射规范

本文档定义京东联盟接口字段与 Rigel 本地字段的映射方向。

## 当前正式使用的接口

1. `jd.union.open.goods.query`
2. `jd.union.open.goods.promotiongoodsinfo.query`
3. `jd.union.open.category.goods.get`

未来返佣预留：

4. `jd.union.open.promotion.common.get`

## 总体原则

- 京东联盟原始返回统一保存在 `raw_payload`
- 本地表优先保留当前业务真正会用到的字段
- 一时用不到但未来返佣可能需要的字段，可以先放在 `raw_payload` 或预留列

## 接口 1：`jd.union.open.goods.query`

### 用途

- 按型号关键词搜索商品
- 作为原始商品采集主入口

### 建议映射

| 京东联盟字段 | 本地字段 | 目标表 | 说明 |
|---|---|---|---|
| `skuId` | `external_id` | `rigel_products` | 京东商品唯一标识 |
| `goodsName` / `skuName` / 标题字段 | `title` | `rigel_products` | 商品标题 |
| `materialUrl` / 商品链接字段 | `product_url` | `rigel_products` | 商品落地页 |
| `imageUrl` / 图片字段 | `image_url` | `rigel_products` | 商品主图 |
| `price` / 单价字段 | `price` | `rigel_products` | 当前价格 |
| `brandName` | `brand_name` | `rigel_products` | 品牌名 |
| `shopName` | `shop_name` | `rigel_products` | 店铺名 |
| `categoryInfo` / 类目字段 | `category_name` | `rigel_products` | 可先做扁平化类目名 |
| `commissionShare` / 佣金比例字段 | `commission_rate` | `rigel_products` | 返佣预留 |
| `couponInfo` | `coupon_info` | `rigel_products` | 优惠信息 |
| `isJdSale` / 可推广状态相关字段 | `is_promotable` | `rigel_products` | 先按布尔化处理 |
| 整体响应对象 | `raw_payload` | `rigel_products` | 原始追溯 |

### 同步写入价格快照

每次采集都应追加一条价格快照：

| 来源 | 本地字段 | 目标表 |
|---|---|---|
| 当前商品价格 | `price` | `rigel_price_snapshots` |
| 当前采集时间 | `captured_at` | `rigel_price_snapshots` |
| 固定 `CNY` | `currency` | `rigel_price_snapshots` |
| 整体响应对象 | `raw_payload` | `rigel_price_snapshots` |

## 接口 2：`jd.union.open.goods.promotiongoodsinfo.query`

### 用途

- 按 `skuId` 补商品详情和推广信息
- 补全 `goods.query` 搜索结果中不稳定的字段

### 建议映射

| 京东联盟字段 | 本地字段 | 目标表 | 说明 |
|---|---|---|---|
| `skuId` | `external_id` | `rigel_products` | 作为关联主键 |
| 标题字段 | `title` | `rigel_products` | 可覆盖或补全 |
| 商品链接字段 | `product_url` | `rigel_products` | 可覆盖或补全 |
| 图片字段 | `image_url` | `rigel_products` | 可覆盖或补全 |
| 价格字段 | `price` | `rigel_products` | 刷新当前价格 |
| 佣金比例字段 | `commission_rate` | `rigel_products` | 返佣预留 |
| 优惠券字段 | `coupon_info` | `rigel_products` | 补全优惠信息 |
| 推广状态字段 | `is_promotable` | `rigel_products` | 刷新可推广状态 |
| 整体响应对象 | `raw_payload` | `rigel_products` | 原始追溯 |

## 接口 3：`jd.union.open.category.goods.get`

### 用途

- 获取商品类目树
- 支撑后台筛选和类目映射

### 当前处理建议

第一版可以有两种处理方式：

1. 只把原始类目结果留在 `raw_payload` 级别，不单独落表
2. 新增类目表后再正式落库

如果新增类目表，建议表名：

- `rigel_categories`

建议字段：

- `external_id`
- `name`
- `parent_external_id`
- `level`
- `source_platform`
- `raw_payload`

## 接口 4：`jd.union.open.promotion.common.get`

### 用途

- 未来生成推广链接

### 当前阶段要求

- 第一版不在页面展示返佣链接
- 但现在就要保证：
  - 商品主键稳定
  - 商品链接已落库
  - `commission_rate` 等推广基础字段已预留

## 本地表字段总结

### `rigel_products`

建议最少字段：

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

### `rigel_price_snapshots`

建议最少字段：

- `id`
- `product_id`
- `captured_at`
- `price`
- `currency`
- `raw_payload`
- `created_at`
