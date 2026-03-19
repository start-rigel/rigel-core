# API 契约规范

本文档定义当前前后端与核心服务之间的主要字段约定。

## 1. 词库列表接口

建议接口：

- `GET /api/v1/keyword-seeds`

### 请求示例

```text
GET /api/v1/keyword-seeds?category=cpu&brand=AMD&keyword=7500F&enabled=true&page=1&page_size=20
```

### 响应示例

```json
{
  "items": [
    {
      "id": "seed-1",
      "category": "cpu",
      "keyword": "Ryzen 5 7500F",
      "canonical_model": "Ryzen 5 7500F",
      "brand": "AMD",
      "aliases": ["7500F", "AMD 7500F"],
      "priority": 100,
      "enabled": true,
      "notes": "主流游戏 CPU",
      "updated_at": "2026-03-18T10:00:00+08:00"
    }
  ],
  "page": 1,
  "page_size": 20,
  "total": 1
}
```

## 2. 单个词条详情接口

建议接口：

- `GET /api/v1/keyword-seeds/{id}`

### 响应示例

```json
{
  "id": "seed-1",
  "category": "cpu",
  "keyword": "Ryzen 5 7500F",
  "canonical_model": "Ryzen 5 7500F",
  "brand": "AMD",
  "aliases": ["7500F", "AMD 7500F"],
  "priority": 100,
  "enabled": true,
  "notes": "主流游戏 CPU",
  "created_at": "2026-03-18T09:00:00+08:00",
  "updated_at": "2026-03-18T10:00:00+08:00"
}
```

## 3. 新增或编辑词条接口

建议接口：

- `POST /api/v1/keyword-seeds`
- `PUT /api/v1/keyword-seeds/{id}`

### 请求体

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

### 字段说明

| 字段 | 必填 | 说明 |
|---|---|---|
| `category` | 是 | 配件类别 |
| `keyword` | 是 | 主搜索词 |
| `canonical_model` | 是 | 标准型号名 |
| `brand` | 否 | 品牌 |
| `aliases` | 否 | 别名数组 |
| `priority` | 否 | 采集优先级 |
| `enabled` | 是 | 是否启用 |
| `notes` | 否 | 备注 |

## 4. 词库导入接口

当前目标：

- 支持页面上传 Excel
- 导入 `rigel_keyword_seeds`

### 建议请求

```json
{
  "file_name": "keyword_seeds.xlsx"
}
```

实际上传方式建议使用文件上传，不直接走纯 JSON。

HTTP 示例：

```bash
curl -X POST http://localhost:18084/api/v1/keyword-seeds/import \
  -F "file=@keyword_seeds.xlsx"
```

### 建议响应

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

## 5. console 推荐请求

建议接口：

- `POST /catalog/recommend`

### 请求体

```json
{
  "budget": 6000,
  "use_case": "gaming",
  "build_mode": "mixed",
  "brand_preference": {
    "cpu": "amd",
    "gpu": "nvidia"
  },
  "special_requirements": [
    "wifi_motherboard"
  ],
  "notes": "1080p游戏为主"
}
```

### 字段说明

| 字段 | 必填 | 说明 |
|---|---|---|
| `budget` | 是 | 预算 |
| `use_case` | 是 | 使用场景 |
| `build_mode` | 否 | 装机场景：`new_only`、`used_only`、`mixed` |
| `brand_preference` | 否 | 品牌偏好 |
| `special_requirements` | 否 | 特殊要求 |
| `notes` | 否 | 补充说明 |

### 响应示例

```json
{
  "catalog_item_count": 24,
  "catalog_warnings": [],
  "selection": {
    "budget": 6000,
    "use_case": "gaming",
    "build_mode": "mixed",
    "estimated_total": 4206,
    "warnings": [
      "当前价格目录缺少这些类别的数据：MB、PSU、CASE、COOLER。"
    ],
    "selected_items": [
      {
        "category": "CPU",
        "display_name": "AMD 7500f",
        "normalized_key": "cpu-7500f",
        "sample_count": 3,
        "selected_price": 899,
        "median_price": 899,
        "source_platforms": ["jd"],
        "reasons": [
          "当前类别按 1200 元目标预算挑选了更接近中位价的型号。"
        ]
      }
    ]
  },
  "advice": {
    "summary": "基于当前价格目录，这份 gaming 采购草案总价约 4206 元。",
    "reasons": [
      "草案总价约 4206 元，优先参考了各型号的中位价和样本量。"
    ],
    "fit_for": ["1080p/2K 主流游戏场景"],
    "risks": ["价格目录会随平台活动和库存变化波动。"],
    "upgrade_advice": ["如果游戏库会持续变大，优先把 SSD 升到 2TB。"],
    "alternative_note": "如果你更看重品牌或静音，可以再生成一版草案。"
  }
}
```

## 6. console -> build-engine 推荐请求

### 请求体

```json
{
  "budget": 6000,
  "use_case": "gaming",
  "build_mode": "mixed",
  "catalog": {
    "use_case": "gaming",
    "build_mode": "mixed",
    "warnings": [],
    "items": [
      {
        "category": "CPU",
        "brand": "AMD",
        "model": "7500f",
        "display_name": "AMD 7500f",
        "normalized_key": "cpu-7500f",
        "sample_count": 3,
        "avg_price": 899,
        "median_price": 899,
        "min_price": 859,
        "max_price": 939,
        "platforms": ["jd"]
      }
    ]
  }
}
```

说明：

- 当前 build-engine 的 `POST /api/v1/advice/catalog` 对外直接接收 `budget`、`use_case`、`build_mode` 和整份 `catalog`
- 这里定义的是服务 HTTP 契约，不是最终发给 AI 的 payload

## 7. build-engine -> AI 最终 payload

### 请求体

```json
{
  "user_request": {
    "budget": 6000,
    "use_case": "gaming",
    "build_mode": "mixed",
    "brand_preference": {
      "cpu": "amd",
      "gpu": "nvidia"
    },
    "special_requirements": [
      "wifi_motherboard"
    ],
    "notes": "1080p游戏为主"
  },
  "price_catalog": {
    "cpu": [
      {
        "model": "7500f",
        "display_name": "AMD 7500f",
        "avg_price": 899,
        "median_price": 899,
        "min_price": 859,
        "max_price": 939,
        "sample_count": 3
      }
    ],
    "gpu": [
      {
        "model": "rtx 4060",
        "display_name": "NVIDIA rtx 4060",
        "avg_price": 2399,
        "median_price": 2399,
        "min_price": 2299,
        "max_price": 2499,
        "sample_count": 4
      }
    ]
  }
}
```

说明：

- `build-engine` 对外接口继续使用顶层用户字段 + `catalog.items`
- 真正发给 AI 前，`build-engine` 必须先把 catalog 重组为按类别分组的 `price_catalog`
- 这一层才是 AI 协议真源

## 8. build-engine 推荐响应

### 响应体

```json
{
  "provider": "local",
  "fallback_used": true,
  "selection": {
    "budget": 6000,
    "use_case": "gaming",
    "build_mode": "mixed",
    "estimated_total": 4206,
    "warnings": [
      "当前价格目录缺少这些类别的数据：MB、PSU、CASE、COOLER。"
    ],
    "selected_items": [
      {
        "category": "CPU",
        "display_name": "AMD 7500f",
        "normalized_key": "cpu-7500f",
        "sample_count": 3,
        "selected_price": 899,
        "median_price": 899,
        "source_platforms": ["jd"],
        "reasons": [
          "当前类别按 1200 元目标预算挑选了更接近中位价的型号。"
        ]
      }
    ]
  },
  "advisory": {
    "summary": "基于当前价格目录，这份 gaming 采购草案总价约 4206 元。",
    "reasons": [
      "草案总价约 4206 元，优先参考了各型号的中位价和样本量。"
    ],
    "fit_for": ["1080p/2K 主流游戏场景"],
    "risks": ["价格目录会随平台活动和库存变化波动。"],
    "upgrade_advice": ["如果游戏库会持续变大，优先把 SSD 升到 2TB。"],
    "alternative_note": "如果你更看重品牌或静音，可以再生成一版草案。"
  }
}
```

### 字段说明

| 字段 | 必填 | 说明 |
|---|---|---|
| `provider` | 是 | 当前推荐提供方，例如 `local` |
| `fallback_used` | 是 | 是否走本地模板化回退路径 |
| `selection` | 是 | 从价格目录中挑选出的采购草案 |
| `advisory` | 是 | 面向页面展示的说明块 |

### `selection.selected_items` 字段说明

| 字段 | 必填 | 说明 |
|---|---|---|
| `category` | 是 | 配件类别 |
| `display_name` | 是 | 展示名 |
| `normalized_key` | 是 | 归一化型号键 |
| `selected_price` | 是 | 当前选择价格 |
| `reasons` | 否 | 选择理由列表 |
