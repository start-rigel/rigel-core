# 后端接口清单

本文档只定义当前 3 个后端服务应该提供哪些接口，以及这些接口的职责与优先级。

字段级请求/响应结构统一放在：

- `docs/api-contract.md`

## 服务列表

当前后端服务只有：

1. `rigel-jd-collector`
2. `rigel-build-engine`
3. `rigel-console`

## 1. rigel-jd-collector

### 当前必须接口

- `GET /healthz`
  - 健康检查

- `POST /api/v1/collect/search`
  - 按关键词触发一次采集

- `GET /api/v1/products`
  - 查询已采集的原始商品

### 请求示例

```bash
curl http://localhost:18081/healthz
curl -X POST http://localhost:18081/api/v1/collect/search \
  -H "Content-Type: application/json" \
  -d '{
    "keyword": "RTX 4060",
    "category": "GPU",
    "brand": "NVIDIA",
    "limit": 2,
    "persist": true
  }'
curl "http://localhost:18081/api/v1/products?category=GPU&real_only=true&limit=20"
```

### 当前建议补充接口

- `POST /api/v1/collect/by-seed`
  - 按词库项触发一次采集

- `POST /api/v1/collect/by-category`
  - 按类别批量触发采集

## 2. rigel-build-engine

### 当前必须接口

- `GET /healthz`
  - 健康检查

- `GET /api/v1/catalog/prices`
  - 返回当前型号级价格清单

- `POST /api/v1/advice/catalog`
  - 接收 `user_request + price_catalog`
  - 返回结构化推荐结果

### 请求示例

```bash
curl http://localhost:18082/healthz
curl "http://localhost:18082/api/v1/catalog/prices?use_case=gaming&build_mode=mixed&limit=20"
curl -X POST http://localhost:18082/api/v1/advice/catalog \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 6000,
    "use_case": "gaming",
    "build_mode": "mixed",
    "catalog": {
      "use_case": "gaming",
      "build_mode": "mixed",
      "items": []
    }
  }'
```

### 当前建议补充接口

- `POST /api/v1/catalog/generate`
  - 主动生成或刷新型号级价格清单

- `GET /api/v1/catalog/summary`
  - 查看当前价格清单汇总状态

## 3. rigel-console

### 当前必须接口

- `GET /healthz`
  - 健康检查

- `GET /`
  - 推荐首页

- `POST /catalog/recommend`
  - 接收页面参数
  - 调用 build-engine
  - 返回推荐结果

### 请求示例

```bash
curl http://localhost:18084/healthz
curl -X POST http://localhost:18084/catalog/recommend \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 6000,
    "use_case": "gaming",
    "build_mode": "mixed",
    "brand_preference": {
      "cpu": "amd",
      "gpu": "nvidia"
    },
    "special_requirements": ["wifi_motherboard"],
    "notes": "1080p 游戏为主"
  }'
```

### 当前必须提供的页面路由

- `GET /keywords`
  - 词库列表页

- `GET /keywords/new`
  - 新增词条页

- `GET /keywords/{id}/edit`
  - 编辑词条页

- `GET /keywords/import`
  - Excel 导入页

### 当前必须提供的词库 API

- `GET /api/v1/keyword-seeds`
  - 获取词库列表

- `GET /api/v1/keyword-seeds/{id}`
  - 获取单个词条详情

- `POST /api/v1/keyword-seeds`
  - 新增词条

- `PUT /api/v1/keyword-seeds/{id}`
  - 编辑词条

- `POST /api/v1/keyword-seeds/{id}/enable`
  - 启用词条

- `POST /api/v1/keyword-seeds/{id}/disable`
  - 停用词条

- `POST /api/v1/keyword-seeds/import`
  - 上传 Excel 并导入词库

- `GET /api/v1/keyword-seeds/template`
  - 下载 Excel 模板

- `GET /api/v1/keyword-seeds/export`
  - 导出词库 Excel

## 页面与 console 接口对应

| 页面 | 读取接口 | 操作接口 |
|---|---|---|
| `/` | 无 | `POST /catalog/recommend` |
| `/keywords` | `GET /api/v1/keyword-seeds` | `POST /api/v1/keyword-seeds/{id}/enable` `POST /api/v1/keyword-seeds/{id}/disable` `GET /api/v1/keyword-seeds/export` |
| `/keywords/new` | 无 | `POST /api/v1/keyword-seeds` |
| `/keywords/{id}/edit` | `GET /api/v1/keyword-seeds/{id}` | `PUT /api/v1/keyword-seeds/{id}` |
| `/keywords/import` | 无 | `POST /api/v1/keyword-seeds/import` `GET /api/v1/keyword-seeds/template` |

## 当前返回示例摘要

### collector `/api/v1/collect/search`

```json
{
  "job_id": "job-1",
  "mode": "mock",
  "persisted": true,
  "persisted_count": 2,
  "products": []
}
```

### build-engine `/api/v1/catalog/prices`

```json
{
  "use_case": "gaming",
  "build_mode": "mixed",
  "warnings": [],
  "items": []
}
```

### console `/catalog/recommend`

```json
{
  "catalog_item_count": 24,
  "catalog_warnings": [],
  "selection": {
    "budget": 6000,
    "use_case": "gaming",
    "build_mode": "mixed",
    "estimated_total": 4206,
    "selected_items": []
  },
  "advice": {
    "summary": "基于当前价格目录生成的采购草案。",
    "reasons": [],
    "fit_for": [],
    "risks": [],
    "upgrade_advice": [],
    "alternative_note": ""
  }
}
```

## 接口优先级

### P0 必做

#### rigel-jd-collector

- `GET /healthz`
- `POST /api/v1/collect/search`
- `GET /api/v1/products`

#### rigel-build-engine

- `GET /healthz`
- `GET /api/v1/catalog/prices`
- `POST /api/v1/advice/catalog`

#### rigel-console

- `GET /healthz`
- `GET /`
- `POST /catalog/recommend`
- `GET /api/v1/keyword-seeds`
- `GET /api/v1/keyword-seeds/{id}`
- `POST /api/v1/keyword-seeds/import`
- `GET /api/v1/keyword-seeds/template`
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
