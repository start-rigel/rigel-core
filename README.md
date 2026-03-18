# Rigel Core

`rigel-core` 是当前工作区的共享文档与共享运行配置中心。

工作区根目录 `/Users/mac-mini/work/private/rigel` 不是 Git 仓库。
所有共享文档、约束、Compose 编排和数据库初始化文件统一放在 `rigel-core`。

当前三个 Go 服务统一改为读取各自仓库中的 YAML 配置文件：

- `rigel-jd-collector/configs/config.yaml`
- `rigel-build-engine/configs/config.yaml`
- `rigel-console/configs/config.yaml`

## 项目总览

Rigel 当前是一个最小可用的电脑配置推荐系统。

当前只围绕这一条主链路工作：

`京东商品数据 -> 型号级价格清单 -> AI 分析 -> 页面展示`

当前对外站点域名规划：

- `givezj8.cn`

当前前端页面要求：

- 支持中文 / English 切换
- 页面语言切换应优先在前端本地完成，不额外增加后端语言接口
- 用户默认无需注册登录即可使用推荐功能
- AI 成本控制优先通过匿名配额、缓存复用、风险挑战与服务端限流完成
- 前台用户页面与后台管理页面必须分离
- 后台管理页面必须登录后访问

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

- 调用京东联盟接口搜索商品
- 读取已维护的型号词库
- 保存原始商品与价格快照

### `rigel-build-engine`

- 接收来自界面的用户参数
- 整理型号级价格清单
- 组装 AI 输入并请求 AI API
- 返回结构化推荐结果

### `rigel-console`

- 提供最小前端页面和 API 入口
- 提供前台推荐页面
- 提供后台管理页面和登录入口
- 展示推荐结果

## 当前最小可交付

第一版只要求稳定完成：

1. Excel 导入型号词库
2. 京东联盟拿到商品与价格
3. 数据入库
4. build-engine 整理出型号级价格清单
5. build-engine 请求 AI 并返回结构化推荐
6. 前台页面展示推荐结果
7. 后台页面登录后管理词库

同时要求：

8. 不登录即可使用前台推荐功能
9. 后台管理功能必须登录
10. 不允许前端直接无限制消耗 AI token
11. 对重复请求优先返回缓存结果
12. 对异常请求逐级限流，而不是默认增加注册门槛

## 文档索引

### 核心文档

- 业务说明：`电脑配置平台项目方案文档.md`
- 架构说明：`docs/architecture.md`
- 数据库设计：`docs/database-schema.md`

### 详细规范

- Excel 模板规范：`docs/excel-template.md`
- 京东字段映射：`docs/jd-field-mapping.md`
- API 契约：`docs/api-contract.md`
- 页面清单：`docs/pages.md`
- 后端接口清单：`docs/backend-apis.md`

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
│   │   ├── database-schema.md
│   │   ├── excel-template.md
│   │   ├── jd-field-mapping.md
│   │   ├── api-contract.md
│   │   ├── pages.md
│   │   └── backend-apis.md
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
cd /home/life/work/rigle/rigel-core
docker compose up --build
```

如果需要单独指定配置文件路径，可在容器外直接运行：

```bash
cd /home/life/work/rigle/rigel-jd-collector
go run ./cmd/server -config ./configs/config.yaml
```

健康检查：

- `http://localhost:18081/healthz`
- `http://localhost:18082/healthz`
- `http://localhost:18084/healthz`
