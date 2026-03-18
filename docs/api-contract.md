# API 契约规范

本文档定义当前前后端与核心服务之间的主要字段约定。

## 1. 词库列表接口

### 请求示例

```json
{
  "category": "cpu",
  "brand": "AMD",
  "keyword": "7500F",
  "enabled": true,
  "page": 1,
  "page_size": 20
}
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

## 5. console -> build-engine 推荐请求

### 请求体

```json
{
  "budget": 6000,
  "usage": "gaming",
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
| `usage` | 是 | 使用场景 |
| `brand_preference` | 否 | 品牌偏好 |
| `special_requirements` | 否 | 特殊要求 |
| `notes` | 否 | 补充说明 |

## 6. build-engine 内部 AI 输入

### 请求体

```json
{
  "user_request": {
    "budget": 6000,
    "usage": "gaming",
    "brand_preference": {
      "cpu": "amd",
      "gpu": "nvidia"
    },
    "special_requirements": [],
    "notes": "1080p游戏为主"
  },
  "price_catalog": {
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
    ],
    "motherboard": [],
    "ram": [],
    "ssd": [],
    "psu": [],
    "case": [],
    "cooler": []
  }
}
```

## 7. build-engine -> console 推荐响应

### 响应体

```json
{
  "summary": "推荐一套 6000 元左右的 1080p 游戏配置",
  "parts": [
    {
      "category": "cpu",
      "model": "Ryzen 5 7500F",
      "price": 899,
      "reason": "当前预算内性价比较高"
    },
    {
      "category": "gpu",
      "model": "RTX 4060",
      "price": 2399,
      "reason": "适合1080p主流游戏"
    }
  ],
  "total_price": 5980,
  "reasoning": [
    "整体预算优先保证显卡性能",
    "AMD 平台当前价格更合适"
  ],
  "alternatives": [
    "如果更重视生产力，可以考虑 Intel 平台"
  ],
  "warnings": [
    "当前价格可能随京东活动波动"
  ]
}
```

### 字段说明

| 字段 | 必填 | 说明 |
|---|---|---|
| `summary` | 是 | 一句话总结 |
| `parts` | 是 | 推荐配件列表 |
| `total_price` | 是 | 总价 |
| `reasoning` | 是 | 推荐理由 |
| `alternatives` | 否 | 备选说明 |
| `warnings` | 否 | 风险提示 |

### `parts` 字段说明

| 字段 | 必填 | 说明 |
|---|---|---|
| `category` | 是 | 配件类别 |
| `model` | 是 | 型号 |
| `price` | 是 | 当前参考价 |
| `reason` | 是 | 选择理由 |
