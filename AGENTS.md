# AGENTS.md

## AI 开发守则

1. 默认只有 `rigel-console` 是公网入口；`rigel-build-engine` 与 `rigel-jd-collector` 按内网服务设计。
2. `console -> build-engine` 的高成本内部调用默认必须走服务 token，例如 `X-Rigel-Service-Token`。
3. `/admin` 与后台 API 默认按私网 / VPN 可访问设计；不要为了联调方便移除来源限制。
4. 匿名推荐链路默认必须保留：请求归一化、缓存判定、`IP + anonymous_id + device_fingerprint` 联合风控、冷却或挑战升级。
5. 只要改动了公网暴露面、鉴权方式、限流维度、挑战机制、后台访问边界或 AI 调用路径，必须同步更新共享文档和模块文档。

## 项目
Rigel 是一个基于京东硬件价格数据与 AI 分析的电脑配置推荐系统。

## 当前范围
- `rigel-core` 是共享文档、共享约束、Docker Compose、数据库初始化文件的唯一来源。
- 当前激活模块只有：
  - `rigel-core`
  - `rigel-jd-collector`
  - `rigel-build-engine`
  - `rigel-console`
- 其他仓库当前不在激活范围内，不作为当前交付目标。

## 当前默认执行规则

1. 每次修改代码前，先对当前要操作的仓库执行 `git pull`，确认基于最新代码开发。
1. 只要发生代码改动，完成后默认自动提交并推送，不额外询问用户是否提交或推送。
2. 每次 Git commit 的提交信息必须使用中文。
3. 除非用户明确要求，否则不要使用环境变量作为 Go 服务主配置源。
4. 当前工作区中的 Go 服务统一使用 `configs/config.yaml`。
5. 如果代码、接口、配置或运行方式发生变化，必须同步更新受影响模块 README 和 `rigel-core` 共享文档。
6. 如果共享规则与局部文档冲突，先修正文档冲突，再继续开发。

## 脚本执行约定

1. 修改完成后，优先通过 `rigel-core/rigel.sh` 执行验证或重启，不要长期使用零散的手写 `docker compose` 命令作为默认路径。
2. 如果修改的是 `rigel-console/frontend` 前端页面或前端静态资源，默认执行：
   - `cd /home/life/work/rigle/rigel-core && ./rigel.sh console-ui`
3. 如果修改的是单个 Go 服务后端代码，默认执行：
   - `cd /home/life/work/rigle/rigel-core && ./rigel.sh restart <service>`
4. 服务名统一使用：
   - `rigel-console`
   - `rigel-build-engine`
   - `rigel-jd-collector`
5. 如果改动影响多个服务联动、镜像构建或基础依赖，默认执行：
   - `cd /home/life/work/rigle/rigel-core && ./rigel.sh up`
   - 或 `./rigel.sh restart <多个服务>`
6. 需要查看运行状态时，默认执行：
   - `./rigel.sh ps`
   - `./rigel.sh logs <service>`
7. `rigel-tui.sh` 只是 `rigel.sh` 的交互包装；说明执行步骤时，优先写清底层实际命令 `rigel.sh`。

## 配置规则

1. 不要将真实密钥、token、签名串或私密配置提交到仓库。
2. `configs/config.yaml` 只放可提交的模板化配置或默认开发配置。
3. 如需本地真实密钥，优先使用未提交的本地覆盖文件，例如 `configs/config.local.yaml`。
4. 新配置方式落地后，要同步删除旧配置方式作为主路径的文档说明，不允许长期并存两个主配置真源。

## 当前主链路
1. 维护型号词库，支持页面管理与 Excel 导入导出
2. `rigel-jd-collector` 调用京东联盟接口并写入原始商品与价格
3. `rigel-build-engine` 将原始商品整理为型号级价格清单
4. `rigel-build-engine` 组装 `用户需求 + 价格清单` 并请求 AI API
5. `rigel-console` 展示结构化推荐结果

## 模块职责
- `rigel-jd-collector`: 京东联盟查询、原始数据入库、消费型号词库
- `rigel-build-engine`: 接收界面参数、整理硬件信息、构建 AI 请求、返回分析结果
- `rigel-console`: 最小前端、API 入口、型号词库页面管理入口

## AI 协议约束
- `console -> build-engine` 的 HTTP 请求结构，统一使用：顶层用户需求字段 + `catalog.items`
- `build-engine -> AI` 的最终 payload，统一转换为：`user_request + price_catalog`
- AI 输出必须是结构化 JSON
- 不要把原始商品明细直接整批传给 AI
- 第一版固定配件类别：
  - `cpu`
  - `gpu`
  - `motherboard`
  - `ram`
  - `ssd`
  - `psu`
  - `case`
  - `cooler`

## JD 联盟接口约束
- 当前正式采用：
  - `jd.union.open.goods.query`
  - `jd.union.open.goods.promotiongoodsinfo.query`
  - `jd.union.open.category.goods.get`
- 未来返佣链接预留：
  - `jd.union.open.promotion.common.get`
- 所有业务表统一使用 `rigel_` 前缀

## 语言规则
- 后端尽量使用 Go
- `rigel-jd-collector` 必须使用 Go
- `rigel-build-engine` 使用 Go
- `rigel-console` 后端使用 Go

## 架构规则
- Go 服务统一通过各自仓库内的 `configs/config.yaml` 提供主配置
- Docker Compose 只负责编排容器与基础依赖，不再作为 Go 服务的主配置入口
- 外部平台集成必须隔离在本地 client/adapter 后面
- 当前只考虑京东联盟，不考虑浏览器抓取
- build-engine 当前不做复杂规则引擎，重点是价格清单整理与 AI 请求
- console 不承担抓取、聚合或核心分析逻辑

## 安全规则

1. 面向公网的业务入口当前只允许是 `rigel-console`；`rigel-build-engine` 和 `rigel-jd-collector` 默认按内网服务设计，不应直接作为公网接口使用。
2. `console -> build-engine` 的内部调用默认必须走服务级鉴权，例如 `X-Rigel-Service-Token`；后续新增高成本内部接口时也要默认接入同类鉴权。
3. 后台管理入口 `/admin` 和后台 API 默认按私网 / VPN 可访问设计；如果要开放公网，必须先同步更新共享文档和模块文档，明确新的风控边界。
4. 涉及 AI 成本的接口默认必须先经过：请求归一化、缓存判定、匿名配额或限流判定，再决定是否触发真实 AI。
5. 匿名风控默认按 `IP + anonymous_id + device_fingerprint` 联合判定；不要退回成只看单一 IP 或只看 Cookie。
6. Redis 当前默认承担匿名配额、冷却、挑战放行和短期缓存；如果改成其他存储，必须保证跨实例一致性，不允许退回仅进程内存方案作为生产主路径。
7. 不要在日志、错误信息、前端响应或 README 示例里暴露真实内部 token、挑战密钥、管理口令或其他敏感安全配置。
8. 如果改动了公网暴露面、鉴权方式、限流维度、挑战机制、后台访问边界或 AI 调用路径，必须同步更新：
   - `rigel-core/AGENTS.md`
   - `rigel-core/docs/architecture.md`
   - 受影响模块的 README

## 外部接口规则

1. 外部接口开发顺序默认是：client / 错误模型 -> 字段映射 -> 真实联调收口。
2. 在未完成真实联调前，必须明确标记为 `TODO`、`MOCK` 或 `未联调验证`。
3. mock 路径必须尽量保持与真实路径一致的输出结构，不允许长期维护两套完全不同的响应格式。
4. 关键链路日志必须包含：接口方法名、错误码、采集数量、入库数量；但禁止打印真实密钥或敏感 token。

## 数据与验证规则

1. 只要修改 repository、数据模型或 SQL，就必须同步更新初始化 SQL 和共享文档。
2. 代码、SQL、README、共享文档不一致时，交付不算完成。
3. 只要能本地验证，就不要跳过验证；至少要说明验证了什么、没验证什么。
4. 外部依赖不可用时，允许先做编译级、mock 级或容器内测试验证，但要明确说明限制。

## 交付规则
1. 说明改了哪些文件
2. 说明设计选择
3. 说明如何运行
4. 对未知外部集成标记 `TODO` 或 `MOCK`
5. 每次代码、逻辑、接口、配置、架构、运行行为变化，都要同步更新文档
6. 至少更新受影响模块 README；如果影响共享层，再同步更新 `rigel-core`
7. 文档没有对齐，交付不算完成
8. 验证完成后，对实际有改动的仓库分别自动提交并推送，不额外询问
9. 不要创建空提交
