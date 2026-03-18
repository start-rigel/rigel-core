# 后端接口清单

本文档定义当前 3 个后端服务应该对外提供哪些接口。

## 服务列表

当前后端服务只有：

1. `rigel-jd-collector`
2. `rigel-build-engine`
3. `rigel-console`

## 1. rigel-jd-collector

职责：

- 消费型号词库
- 调用京东联盟接口搜索商品
- 保存原始商品与价格快照

### 当前必须接口

#### `GET /healthz`

用途：

- 健康检查

#### `POST /api/v1/collect/search`

用途：

- 按关键词触发一次采集

建议请求体：

```json
{
  "keyword": "RTX 4060",
  "category": "gpu",
  "limit": 20,
  "persist": true
}
```

建议响应体：

```json
{
  "keyword": "RTX 4060",
  "category": "gpu",
  "count": 20,
  "persisted": true,
  "persisted_count": 20
}
```

#### `GET /api/v1/products`

用途：

- 查询已采集的原始商品

建议查询参数：

- `keyword`
- `category`
- `limit`

### 当前建议补充接口

#### `POST /api/v1/collect/by-seed`

用途：

- 按词库项触发一次采集

建议请求体：

```json
{
  "keyword_seed_id": "seed-123"
}
```

#### `POST /api/v1/collect/by-category`

用途：

- 按类别批量触发采集

建议请求体：

```json
{
  "category": "gpu",
  "limit_per_keyword": 20
}
```

## 2. rigel-build-engine

职责：

- 读取原始商品
- 整理型号级价格清单
- 构造 AI 输入
- 请求 AI API
- 返回结构化推荐结果

### 当前必须接口

#### `GET /healthz`

用途：

- 健康检查

#### `GET /api/v1/catalog/prices`

用途：

- 返回当前型号级价格清单

建议查询参数：

- `usage`
- `limit`

建议响应体：

```json
{
  "items": [
    {
      "category": "gpu",
      "model": "RTX 4060",
      "price": 2399,
      "price_min": 2299,
      "price_max": 2499,
      "sample_count": 8
    }
  ]
}
```

#### `POST /api/v1/advice/catalog`

用途：

- 接收 `user_request + price_catalog`
- 返回结构化推荐结果

建议请求体：

```json
{
  "user_request": {
    "budget": 6000,
    "usage": "gaming"
  },
  "price_catalog": {
    "gpu": [
      {
        "model": "RTX 4060",
        "price": 2399,
        "sample_count": 8
      }
    ]
  }
}
```

建议响应体：

```json
{
  "summary": "推荐一套 6000 元左右的 1080p 游戏配置",
  "parts": [],
  "total_price": 5980,
  "reasoning": [],
  "alternatives": [],
  "warnings": []
}
```

### 当前建议补充接口

#### `POST /api/v1/catalog/generate`

用途：

- 主动生成或刷新型号级价格清单

#### `GET /api/v1/catalog/summary`

用途：

- 查看当前价格清单汇总状态

## 3. rigel-console

职责：

- 最小页面入口
- 型号词库管理入口
- 调用 `rigel-build-engine`
- 展示推荐结果

### 当前必须接口

#### `GET /healthz`

用途：

- 健康检查

#### `GET /`

用途：

- 推荐首页

#### `POST /catalog/recommend`

用途：

- 接收页面参数
- 调 build-engine
- 返回推荐结果

建议请求体：

```json
{
  "budget": 6000,
  "usage": "gaming",
  "brand_preference": {
    "cpu": "amd",
    "gpu": "nvidia"
  },
  "special_requirements": [],
  "notes": "1080p游戏为主"
}
```

### 当前必须提供的词库页面接口

#### `GET /keywords`

用途：

- 词库列表页

#### `GET /keywords/new`

用途：

- 新增词条页

#### `GET /keywords/{id}/edit`

用途：

- 编辑词条页

#### `GET /keywords/import`

用途：

- Excel 导入页

#### `POST /api/v1/keyword-seeds/import`

用途：

- 上传 Excel 并导入词库

#### `GET /api/v1/keyword-seeds/export`

用途：

- 导出词库 Excel

#### `GET /api/v1/keyword-seeds`

用途：

- 获取词库列表

#### `POST /api/v1/keyword-seeds`

用途：

- 新增词条

#### `PUT /api/v1/keyword-seeds/{id}`

用途：

- 编辑词条

#### `POST /api/v1/keyword-seeds/{id}/enable`

用途：

- 启用词条

#### `POST /api/v1/keyword-seeds/{id}/disable`

用途：

- 停用词条

## 当前接口优先级

### P0 必做

- `rigel-jd-collector`
  - `GET /healthz`
  - `POST /api/v1/collect/search`
  - `GET /api/v1/products`

- `rigel-build-engine`
  - `GET /healthz`
  - `GET /api/v1/catalog/prices`
  - `POST /api/v1/advice/catalog`

- `rigel-console`
  - `GET /healthz`
  - `GET /`
  - `POST /catalog/recommend`
  - `GET /api/v1/keyword-seeds`
  - `POST /api/v1/keyword-seeds/import`
  - `GET /api/v1/keyword-seeds/export`
  - `POST /api/v1/keyword-seeds`
  - `PUT /api/v1/keyword-seeds/{id}`
  - `POST /api/v1/keyword-seeds/{id}/enable`
  - `POST /api/v1/keyword-seeds/{id}/disable`

### P1 后补

- 按词库项采集
- 按类别批量采集
- 价格清单手动刷新
- 导入历史查看
