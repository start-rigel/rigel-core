# Database Schema

当前数据库设计只服务于这条主链路：

`京东原始商品 -> 型号级价格信息 -> AI 推荐`

## 当前核心数据对象

### 1. 原始商品

来源：京东联盟接口。

用途：

- 保存原始标题
- 保存原始价格
- 作为后续型号整理的输入

对应表：

- `products`
- `price_snapshots`

### 2. 型号级映射

用途：

- 将原始商品标题整理为型号级信息
- 为价格清单提供统一名称

对应表：

- `parts`
- `product_part_mapping`

### 3. 型号级价格汇总

用途：

- 按型号输出当前参考价
- 为 AI 提供 `price_catalog`

对应表：

- `part_market_summary`

### 4. 任务记录

用途：

- 记录采集任务
- 记录后续处理任务

对应表：

- `jobs`

## 当前模块与表的职责归属

- `rigel-jd-collector`
  - `products`
  - `price_snapshots`
  - `jobs`

- `rigel-build-engine`
  - `parts`
  - `product_part_mapping`
  - `part_market_summary`

- `rigel-console`
  - 不直接拥有核心业务表
  - 通过服务接口读取结果

## 当前数据库设计重点

当前重点不是复杂规格库。
当前重点是：

1. 能存原始商品
2. 能存价格快照
3. 能形成型号映射
4. 能产出型号级价格清单

## 当前不作为重点的旧设计

以下方向当前不是核心：

- 复杂兼容规则表
- 复杂打分模板表
- 大量 build request / build result 历史结构

如果这些表还存在于 bootstrap SQL 中，它们属于历史遗留，不代表当前系统中心。
