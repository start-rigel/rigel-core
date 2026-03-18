# Rigel Core

`rigel-core` 是当前工作区的共享文档与共享运行配置中心。

工作区根目录 `/Users/mac-mini/work/private/rigel` 不是 Git 仓库。
所有共享文档、约束、Compose 编排和数据库初始化文件统一放在 `rigel-core`。

## 项目目标

Rigel 当前要做的是一个最小可用的电脑配置推荐系统。

系统只围绕一条主链路工作：

1. 从京东联盟获取电脑配件商品与价格
2. 将原始商品标题整理为型号级硬件信息
3. 形成当前可用的硬件价格清单
4. 接收用户需求
5. 将 `用户需求 + 价格清单` 交给 AI 分析
6. 返回结构化推荐结果并在页面展示

当前一句话主线：

`京东商品数据 -> 型号级价格清单 -> AI 分析 -> 页面展示`

## 当前范围

当前只保留 3 个激活业务模块：

1. `rigel-jd-collector`
2. `rigel-build-engine`
3. `rigel-console`

共享仓库：

- `rigel-core`

当前不纳入范围：

- 闲鱼
- 浏览器抓取京东
- 独立 AI 服务
- 复杂规则引擎
- 复杂后台系统
- 多平台联合推荐

## 模块职责

### `rigel-jd-collector`

职责：

- 调用京东联盟接口搜索商品
- 读取已维护的型号词库
- 保存原始商品与价格快照
- 为后续价格清单整理提供原始数据

不负责：

- 价格清单整理
- AI 请求构建
- 页面展示

### `rigel-build-engine`

职责：

- 接收来自界面的用户参数
- 读取当前硬件原始数据
- 整理出型号级价格清单
- 组装 AI 输入
- 请求 AI API
- 返回结构化推荐结果

不负责：

- 直接抓取外部平台
- 承担前端页面

### `rigel-console`

职责：

- 提供最小前端页面和 API 入口
- 接收用户输入
- 调用 `rigel-build-engine`
- 展示推荐结果
- 提供型号词库的页面管理入口

不负责：

- 直接做数据抓取
- 直接做核心分析决策

## 型号词库规范

型号词库是当前 JD 搜索的唯一关键词来源。

维护方式：

- 页面手动新增/编辑
- Excel 批量导入
- Excel 批量导出
- 启用/停用

当前不使用 CSV 或 JSON 作为业务侧批量导入格式。

### 词库字段

- `category`
- `keyword`
- `canonical_model`
- `brand`
- `aliases`
- `priority`
- `enabled`
- `notes`

### 当前类别枚举

- `cpu`
- `gpu`
- `motherboard`
- `ram`
- `ssd`
- `psu`
- `case`
- `cooler`

## AI 输入规范

AI 输入固定由两部分组成：

1. `user_request`
2. `price_catalog`

### `user_request`

```json
{
  "budget": 6000,
  "usage": "gaming",
  "brand_preference": {
    "cpu": "amd",
    "gpu": "nvidia"
  },
  "special_requirements": [
    "wifi_motherboard",
    "low_noise"
  ],
  "notes": "1080p游戏为主"
}
```

字段要求：

- `budget`: 必填，人民币整数或数字
- `usage`: 必填，当前约定值为 `gaming | office | design | streaming | general`
- `brand_preference`: 可选，包含 `cpu` 与 `gpu`
- `special_requirements`: 可选，字符串数组
- `notes`: 可选，补充说明

### `price_catalog`

`price_catalog` 按配件类别分组，第一版固定 8 类：

- `cpu`
- `gpu`
- `motherboard`
- `ram`
- `ssd`
- `psu`
- `case`
- `cooler`

示例：

```json
{
  "cpu": [
    {
      "model": "Ryzen 5 7500F",
      "price": 899,
      "price_min": 859,
      "price_max": 959,
      "sample_count": 6
    }
  ],
  "gpu": [
    {
      "model": "RTX 4060",
      "price": 2399,
      "price_min": 2299,
      "price_max": 2499,
      "sample_count": 8
    }
  ]
}
```

每个型号对象字段：

- `model`: 必填，型号级名称
- `price`: 必填，当前参考价
- `price_min`: 可选，样本最低价
- `price_max`: 可选，样本最高价
- `sample_count`: 可选，样本数

### 不传给 AI 的内容

当前不传：

- 原始商品标题列表
- 商品链接
- 店铺名
- 图片
- 数据库内部 ID
- 复杂规格参数明细

当前只传型号级价格信息。

## AI 输出规范

AI 必须返回结构化结果：

```json
{
  "summary": "推荐一套 6000 元左右的 1080p 游戏配置",
  "parts": [
    {
      "category": "cpu",
      "model": "Ryzen 5 7500F",
      "price": 899,
      "reason": "当前预算内性价比较高"
    }
  ],
  "total_price": 5980,
  "reasoning": [
    "整体预算优先保证显卡性能"
  ],
  "alternatives": [
    "如果更重视生产力，可以考虑 Intel 平台"
  ],
  "warnings": [
    "当前价格可能随京东活动波动"
  ]
}
```

字段要求：

- `summary`: 必填，一句话总结
- `parts`: 必填，推荐配件列表
- `total_price`: 必填，总价
- `reasoning`: 必填，推荐理由数组
- `alternatives`: 可选，备选说明
- `warnings`: 可选，风险提示

`parts` 每项必须包含：

- `category`
- `model`
- `price`
- `reason`

## 京东联盟接口规范

当前 JD 模块正式采用以下接口：

### 1. `jd.union.open.goods.query`

用途：

- 按型号关键词搜索商品
- 作为原始商品采集主入口

当前至少要获取：

- `skuId`
- `title`
- `product_url`
- `image_url`
- `price`
- `shop_name`
- `brand_name`
- `category_info`
- `commission_rate`
- `is_promotable`
- `coupon_info`
- `raw_payload`

### 2. `jd.union.open.goods.promotiongoodsinfo.query`

用途：

- 按 `skuId` 补商品详情和推广信息
- 补全搜索结果里的关键字段

当前至少要获取：

- `skuId`
- `title`
- `product_url`
- `image_url`
- `price`
- `commission_rate`
- `coupon_info`
- `promotion_status`
- `raw_payload`

### 3. `jd.union.open.category.goods.get`

用途：

- 获取商品类目树
- 支撑词库分类和页面筛选

当前至少要获取：

- `category_id`
- `category_name`
- `parent_category_id`
- `level`
- `raw_payload`

### 4. 预留：`jd.union.open.promotion.common.get`

用途：

- 生成推广链接

当前阶段：

- 第一版先不做页面返佣链接功能
- 但商品层和配置层要为它预留字段

## 统一表结构命名

所有业务表统一使用 `rigel_` 前缀。

当前第一版核心表：

- `rigel_keyword_seeds`
- `rigel_products`
- `rigel_price_snapshots`
- `rigel_product_part_mapping`
- `rigel_part_market_summary`
- `rigel_jobs`

### 表职责

- `rigel_keyword_seeds`: 型号词库与 Excel 导入结果
- `rigel_products`: 京东原始商品
- `rigel_price_snapshots`: 价格快照
- `rigel_product_part_mapping`: 原始商品到标准型号映射
- `rigel_part_market_summary`: 型号级价格清单汇总
- `rigel_jobs`: 采集、导入、汇总任务记录

## 当前最小可交付

第一版只要求稳定完成这件事：

1. Excel 导入型号词库
2. 京东联盟拿到商品与价格
3. 数据入库
4. build-engine 整理出型号级价格清单
5. console 接收预算和用途
6. build-engine 请求 AI 并返回结构化推荐
7. 页面展示结果

## Workspace Layout

```text
rigel/
├── rigel-core/
│   ├── README.md
│   ├── AGENTS.md
│   ├── .env.example
│   ├── docker-compose.yml
│   ├── db/
│   │   └── init/
│   │       └── 001_init.sql
│   ├── docs/
│   │   ├── architecture.md
│   │   └── database-schema.md
│   └── 电脑配置平台项目方案文档.md
├── rigel-build-engine/
├── rigel-console/
└── rigel-jd-collector/
```

## 强约束

1. `rigel-core` 是共享文档、共享约束、Compose 和数据库初始化的唯一来源。
2. 每次代码、逻辑、接口、配置、架构、运行行为变更，都必须在同一轮同步更新相关文档。
3. 至少更新受影响模块 README；如果影响共享架构、共享流程、共享数据模型、部署或工作区约定，还要同步更新 `rigel-core`。
4. 文档未对齐，交付不算完成。
5. 本工作区当前聚焦：`京东数据 -> 型号级价格清单 -> AI 推荐输出`。

## 如何启动

```bash
cd /Users/mac-mini/work/private/rigel/rigel-core
docker compose up --build
```

健康检查：

- `http://localhost:18081/healthz`
- `http://localhost:18082/healthz`
- `http://localhost:18084/healthz`
