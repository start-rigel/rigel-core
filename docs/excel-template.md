# Excel 模板规范

本文档定义当前型号词库的 Excel 导入导出规范。

## 目标

Excel 文件用于维护当前系统的型号词库。

这些词库数据会被 `rigel-jd-collector` 读取，用于调用京东联盟接口搜索商品。

## 文件用途

支持两类操作：

1. 批量导入型号词库
2. 批量导出当前型号词库

当前业务侧只支持 Excel，不支持 CSV 或 JSON 作为批量导入格式。

## 工作表要求

- 第一版默认只使用第一个工作表
- 第一行必须是表头
- 表头字段必须使用固定英文名

## 表头字段

| 字段名 | 必填 | 说明 |
|---|---|---|
| `category` | 是 | 配件类别 |
| `keyword` | 是 | 京东联盟主搜索词 |
| `canonical_model` | 是 | 标准型号名 |
| `brand` | 否 | 品牌 |
| `aliases` | 否 | 别名，多个值用英文逗号分隔 |
| `priority` | 否 | 优先级，数字越大越优先 |
| `enabled` | 否 | 是否启用，默认 `true` |
| `notes` | 否 | 备注 |

## 字段规则

### `category`

只允许以下值：

- `cpu`
- `gpu`
- `motherboard`
- `ram`
- `ssd`
- `psu`
- `case`
- `cooler`

### `keyword`

要求：

- 非空
- 用于京东联盟主搜索
- 应尽量是主流搜索词

示例：

- `Ryzen 5 7500F`
- `RTX 4060`
- `B650M`
- `DDR5 6000 32G`

### `canonical_model`

要求：

- 非空
- 用作系统内统一型号名
- 同类商品最终应收敛到这里

### `brand`

可选。

示例：

- `AMD`
- `Intel`
- `NVIDIA`
- `Kingston`

### `aliases`

规则：

- 多个值使用英文逗号分隔
- 导入后转为数组

示例：

```text
7500F,AMD 7500F
```

### `priority`

规则：

- 可为空
- 默认为 `100`
- 建议为整数

### `enabled`

规则：

- 可为空
- 默认为 `true`
- 支持值建议统一为：
  - `true`
  - `false`

### `notes`

可选备注字段。

## 示例

| category | keyword | canonical_model | brand | aliases | priority | enabled | notes |
|---|---|---|---|---|---:|---|---|
| cpu | Ryzen 5 7500F | Ryzen 5 7500F | AMD | 7500F,AMD 7500F | 100 | true | 主流游戏 CPU |
| gpu | RTX 4060 | RTX 4060 | NVIDIA | 4060 | 100 | true | 1080p 主流显卡 |
| motherboard | B650M | B650M |  | B650 | 90 | true | AM5 主流主板 |
| ram | DDR5 6000 32G | DDR5 6000 32G |  | 32GB DDR5 6000 | 90 | true | |

## 导入校验规则

导入时至少校验：

1. 表头必须存在
2. `category` 必须在允许枚举内
3. `keyword` 不可为空
4. `canonical_model` 不可为空
5. 同一类别下 `keyword` 不应重复
6. `priority` 如果存在，必须可转为数字
7. `enabled` 如果存在，必须可解析为布尔值

## 导入结果处理建议

导入后建议：

- 写入 `rigel_keyword_seeds`
- 记录导入任务到 `rigel_jobs`
- 返回导入成功数、失败数、错误明细
