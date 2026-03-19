# 后端接口清单

本文档只定义当前 3 个后端服务应该提供哪些接口，以及这些接口的职责与优先级。

字段级请求/响应结构统一放在：

- `docs/api-contract.md`

## 服务列表

当前后端服务只有：

1. `rigel-jd-collector`
2. `rigel-build-engine`
3. `rigel-console`

## 匿名用户访问规则

当前产品默认允许匿名使用，不强制登录。
但所有会触发 AI 成本的接口，都必须遵守以下规则：

- 请求先按参数归一化后计算缓存键
- 命中缓存时直接返回，不重新调用 AI
- 按 `IP + anonymous_id + device_fingerprint` 做联合限流
- 短时间重复提交只执行一次
- 超出软额度时返回友好冷却提示
- 明显异常流量才升级验证码或挑战页

当前不允许前端直接持有 AI token，也不允许前端绕过 `rigel-console` 直接请求 AI。

## 后台管理访问规则

后台管理接口不属于匿名能力。
凡是涉及词库维护、导入导出、采集触发、系统配置的接口，当前都必须满足：

- 必须登录后访问
- 必须与前台推荐接口分组隔离
- 默认不对匿名用户开放

当前建议后台路由统一使用 `/admin` 前缀，后台 API 统一使用 `/admin/api/v1` 前缀。

## 1. rigel-jd-collector

### 当前必须接口

- `GET /healthz`
  - 健康检查

- `GET /api/v1/admin/schedule`
  - 读取当前 JD 定时采集配置

- `PUT /api/v1/admin/schedule`
  - 更新当前 JD 定时采集配置

- `POST /api/v1/collect/search`
  - 按关键词触发一次采集

- `GET /api/v1/products`
  - 查询已采集的原始商品

### 当前内置调度能力

- 没有调度配置时，不启动定时采集
- 配置存在但 `enabled=false` 时，不启动定时采集
- 按后台配置的每日时间执行采集
- 按后台配置的请求间隔逐个关键词请求京东联盟接口
- 在采集后写入：
  - `rigel_products`
  - `rigel_price_snapshots`
  - `rigel_parts`
  - `rigel_product_part_mapping`
  - `rigel_part_market_summary`
  - `rigel_jobs`

### 请求示例

```bash
curl http://localhost:18081/healthz
curl http://localhost:18081/api/v1/admin/schedule
curl -X PUT http://localhost:18081/api/v1/admin/schedule \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "schedule_time": "03:00",
    "request_interval_seconds": 3,
    "query_limit": 5
  }'
curl -X POST http://localhost:18081/api/v1/collect/search \
  -H "Content-Type: application/json" \
  -d '{
    "keyword": "RTX 4060",
    "category": "GPU",
    "brand": "NVIDIA",
    "limit": 2,
    "persist": true
  }'
curl "http://localhost:18081/api/v1/products?category=GPU&self_operated_only=true&real_only=true&limit=20"
```

## 2. rigel-build-engine

### 当前必须接口

- `GET /healthz`
  - 健康检查

- `GET /api/v1/catalog/prices`
  - 返回当前型号级价格清单

- `POST /api/v1/advice/catalog`
  - 接收顶层用户需求字段和 `catalog.items` 价格目录
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

- `GET /api/v1/session/anonymous`
  - 获取或刷新匿名会话信息
  - 返回当前匿名配额、冷却状态、挑战状态

- `POST /catalog/recommend`
  - 接收页面参数
  - 调用 build-engine
  - 返回推荐结果

- `GET /admin/login`
  - 后台登录页

- `POST /admin/login`
  - 提交后台登录凭证

- `POST /admin/logout`
  - 退出后台登录态

- `GET /admin/api/v1/jd/schedule`
  - 获取 JD 定时采集配置

- `PUT /admin/api/v1/jd/schedule`
  - 更新 JD 定时采集配置

### 请求示例

```bash
curl http://localhost:18084/healthz
curl http://localhost:18084/api/v1/session/anonymous
curl -X POST http://localhost:18084/catalog/recommend \
  -H "Content-Type: application/json" \
  -H "X-Anonymous-Id: anon-demo-1" \
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
curl -X POST http://localhost:18084/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "******"
  }'
```

### 当前匿名保护要求

#### `GET /api/v1/session/anonymous`

用于：

- 首次访问时签发匿名会话
- 返回匿名使用状态
- 让前端决定是否展示冷却或挑战提示

示例响应：

```json
{
  "anonymous_id": "anon_01HXYZ...",
  "cooldown_seconds": 0,
  "remaining_ai_requests": 5,
  "challenge_required": false
}
```

#### `POST /catalog/recommend`

当前处理顺序必须是：

1. 校验匿名会话
2. 检查风险状态
3. 归一化请求参数
4. 查询缓存
5. 检查短期幂等锁
6. 检查匿名配额
7. 必要时再调用 build-engine 的 AI 路径

当命中冷却时，建议返回：

- HTTP `429`
- 结构化冷却信息

示例响应：

```json
{
  "error": {
    "code": "rate_limited",
    "message": "请求过于频繁，请稍后再试。",
    "cooldown_seconds": 60
  }
}
```

### 当前必须提供的页面路由

- `GET /admin/login`
  - 后台登录页

- `GET /admin`
  - 后台首页

- `GET /admin/keywords`
  - 词库列表页

- `GET /admin/keywords/new`
  - 新增词条页

- `GET /admin/keywords/{id}/edit`
  - 编辑词条页

- `GET /admin/keywords/import`
  - Excel 导入页

- `GET /admin/jd-schedule`
  - JD 定时采集配置页

### 当前必须提供的词库 API

- `GET /admin/api/v1/keyword-seeds`
  - 获取词库列表

- `GET /admin/api/v1/keyword-seeds/{id}`
  - 获取单个词条详情

- `POST /admin/api/v1/keyword-seeds`
  - 新增词条

- `PUT /admin/api/v1/keyword-seeds/{id}`
  - 编辑词条

- `POST /admin/api/v1/keyword-seeds/{id}/enable`
  - 启用词条

- `POST /admin/api/v1/keyword-seeds/{id}/disable`
  - 停用词条

- `POST /admin/api/v1/keyword-seeds/import`
  - 上传 Excel 并导入词库

- `GET /admin/api/v1/keyword-seeds/template`
  - 下载 Excel 模板

- `GET /admin/api/v1/keyword-seeds/export`
  - 导出词库 Excel

- `GET /admin/api/v1/jd/schedule`
  - 获取 JD 定时采集配置

- `PUT /admin/api/v1/jd/schedule`
  - 更新 JD 定时采集配置

## 页面与 console 接口对应

| 页面 | 读取接口 | 操作接口 |
|---|---|---|
| `/` | `GET /api/v1/session/anonymous` | `POST /catalog/recommend` |
| `/admin/login` | 无 | `POST /admin/login` |
| `/admin/keywords` | `GET /admin/api/v1/keyword-seeds` | `POST /admin/api/v1/keyword-seeds/{id}/enable` `POST /admin/api/v1/keyword-seeds/{id}/disable` `GET /admin/api/v1/keyword-seeds/export` |
| `/admin/keywords/new` | 无 | `POST /admin/api/v1/keyword-seeds` |
| `/admin/keywords/{id}/edit` | `GET /admin/api/v1/keyword-seeds/{id}` | `PUT /admin/api/v1/keyword-seeds/{id}` |
| `/admin/keywords/import` | 无 | `POST /admin/api/v1/keyword-seeds/import` `GET /admin/api/v1/keyword-seeds/template` |
| `/admin/jd-schedule` | `GET /admin/api/v1/jd/schedule` | `PUT /admin/api/v1/jd/schedule` |

## 当前返回示例摘要

### collector `/api/v1/collect/search`

```json
{
  "job_id": "job-1",
  "mode": "union",
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
  "request_status": {
    "cache_hit": true,
    "remaining_ai_requests": 4,
    "cooldown_seconds": 0
  },
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
- `GET /admin/api/v1/keyword-seeds`
- `GET /admin/api/v1/keyword-seeds/{id}`
- `POST /admin/api/v1/keyword-seeds/import`
- `GET /admin/api/v1/keyword-seeds/template`
- `GET /admin/api/v1/keyword-seeds/export`
- `POST /admin/api/v1/keyword-seeds`
- `PUT /admin/api/v1/keyword-seeds/{id}`
- `POST /admin/api/v1/keyword-seeds/{id}/enable`
- `POST /admin/api/v1/keyword-seeds/{id}/disable`

### P1 后补

- 按词库项采集
- 按类别批量采集
- 价格清单手动刷新
- 导入历史查看
