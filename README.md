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

## 项目核心逻辑

这个项目的核心，不是页面，也不是单纯调用 AI。

当前真正的核心逻辑是：

1. 从京东联盟获取原始硬件商品与价格
2. 把杂乱商品整理成可用的型号级价格清单
3. 把用户需求和这份价格清单一起交给 AI
4. 返回一份有价格依据的装机推荐结果

一句话定义：

`基于真实硬件价格数据，为用户快速生成一份有价格依据的装机建议`

对当前产品来说，真正的核心能力是：

`型号级价格清单 + 基于它的 AI 装机推荐`

当前对外产品名称：

- `给我装机吧`

当前对外站点域名规划：

- `givezj8.cn`

当前前端页面要求：

- 支持中文 / English 切换
- 页面语言切换应优先在前端本地完成，不额外增加后端语言接口
- 用户默认无需注册登录即可使用推荐功能
- AI 成本控制优先通过匿名配额、缓存复用、风险挑战与服务端限流完成
- 前台用户页面与后台管理页面必须分离
- 后台管理页面必须登录后访问

当前安全边界要求：

- 默认只有 `rigel-console` 作为公网入口
- `rigel-build-engine` 与 `rigel-jd-collector` 按内网服务设计
- `console -> build-engine` 默认走内部服务 token 鉴权
- 后台 `/admin` 默认只允许私网 / VPN 来源访问
- 后台登录态必须使用服务端 session，修改类接口默认要求 CSRF 校验
- 词库管理必须以 PostgreSQL `rigel_keyword_seeds` 为真源

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

- 读取已维护的型号词库
- 根据后台调度配置每日定时调用京东联盟接口查询商品
- 保存原始商品与价格快照
- 整理标准型号并写入每日价格快照

### `rigel-build-engine`

- 接收来自界面的用户参数
- 读取当前硬件价格数据
- 对外 HTTP 接口接收顶层用户字段 + `catalog.items`
- 对内统一转换为 `user_request + price_catalog` 后再请求 AI
- 组装 AI 输入并请求 AI API
- 返回结构化推荐结果

### `rigel-console`

- 提供最小前端页面和 API 入口
- 提供前台推荐页面
- 提供后台管理页面、登录入口和 JD 定时采集配置页面
- 展示推荐结果

## 当前最小可交付

第一版只要求稳定完成：

1. Excel 导入型号词库
2. 京东联盟按后台配置的每日时间拿到商品与价格
3. 数据入库并生成每日型号价格快照
4. build-engine 读取当前价格数据并请求 AI 返回结构化推荐
5. 前台页面展示推荐结果
6. 后台页面登录后管理词库与 JD 定时采集配置

同时要求：

7. 不登录即可使用前台推荐功能
8. 后台管理功能必须登录
9. 不允许前端直接无限制消耗 AI token
10. 对重复请求优先返回缓存结果
11. 对异常请求逐级限流，而不是默认增加注册门槛

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

## 数据库迁移说明

- `db/init/001_init.sql` 只在数据库首次初始化时自动执行。
- 对已运行环境，结构调整需要新增增量脚本并手动执行。
- 当前新增了 `db/init/003_migrate_part_market_summary_snapshot.sql`，用于把旧版 `rigel_part_market_summary` 迁移到 `snapshot_date` 维度。

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
2. 每次修改代码前，先对当前仓库执行 `git pull`，确保基于最新远程代码开发。
3. 每次代码、逻辑、接口、配置、架构、运行行为变更，都必须在同一轮同步更新相关文档。
4. 至少更新受影响模块 README；如果影响共享架构、共享流程、共享数据模型、部署或工作区约定，还要同步更新 `rigel-core`。
5. 文档未对齐，交付不算完成。
6. 本工作区当前聚焦：`京东数据 -> 型号级价格清单 -> AI 推荐输出`。

## 如何启动

```bash
cd /Users/mac-mini/work/private/rigel/rigel-core
./rigel.sh up
```

终端交互模式：

```bash
./rigel-tui.sh
```

支持：

- 方向键 / `j` `k` 移动
- `Space` 选择服务
- `Enter` 确认
- `b` 返回上一步
- `q` 退出

首页提供单独菜单项：

- `一键启动全部服务`
- `一键停止全部服务`

常用命令：

```bash
./rigel.sh up
./rigel.sh ps
./rigel.sh console-ui
./rigel.sh logs rigel-console
./rigel.sh restart rigel-build-engine
./rigel.sh down
```

## 近期部署约束（2026-03）

- `rigel-build-engine` 不再映射宿主机端口，仅在 Docker 内部网络提供服务。
- 后台系统设置接口新增内部鉴权头：
  - 请求头：`X-Rigel-Admin-Token`
  - 环境变量：`RIGEL_BUILD_ENGINE_ADMIN_TOKEN`
  - token 约束：至少 24 位，必须通过密钥管理或环境变量注入，禁止默认值
- console 通过内部网络访问 build-engine：`http://rigel-build-engine:18082`

前端界面更新快捷命令：

```bash
./rigel.sh console-ui
```

它会自动执行：

1. 检查 `rigel-console/frontend` 依赖
2. 必要时安装依赖
3. 执行前端构建
4. 重启 `rigel-console`

脚本默认管理当前激活服务：

- `postgres`
- `redis`
- `rigel-jd-collector`
- `rigel-build-engine`
- `rigel-console`

如果需要单独指定配置文件路径，可在容器外直接运行：

```bash
cd /Users/mac-mini/work/private/rigel/rigel-jd-collector
go run ./cmd/server -config ./configs/config.yaml
```

健康检查：

- `http://localhost:18081/healthz`
- `http://localhost:18084/healthz`
