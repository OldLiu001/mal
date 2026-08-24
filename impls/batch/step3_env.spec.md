# step3_env.bat 的 spec（MAL step3 环境：def!/let*/符号/外层 env）

> 本文件与同名源码双向同步：改代码必须同步本文件，改本文件必须落实到代码。

## 用途

`step3_env.bat` 是 MAL batch 的 **step3 env 主实现**：在 step1（读/打）与 step2（eval）之上
加环境域 —— 含 `def!`/`let*` 内建、外层 env 复制、符号大小写敏感解析与 Arithmetic 运算
（+ - * /）。提供 `MAIN_ReadAll` 批量读 stdin 的 READALL 模式，供 `_runall.py` 回归网关驱动。

## 对外接口

| 项 | 说明 |
|---|---|
| 入口 | `step3_env.bat [READALL]`；无 READALL 走交互 REPL 循环，有则读全部 stdin 逐行 REP |
| `MAIN_REP Mal` | 读→eval→打完一站式；`MAIN ReadAll` 批量驱动即靠它 |
| `MAIN_Eval ObjMal Env ->` | Mal 求值：MalSym（查 env）/MalLst（调 fn）/MalVec/MalMap（逐项 eval）|
| `MAIN_MDef/MLet` | def! / let* 内建，绑定写入 env 的 `Item[Key]` 并维护 `RawKeys` |
| `MAIN_EncKey Val -> Enc` | 符号→环境键编码（小写字母后追 `0`，其余追 `1`，`!`→`$E`）|
| `MAIN_EnvCopyOuter Env NewEnv` | 把外层 env 的键值复制进新 env，并让新 env 自持完整 `RawKeys` |

## 边界与异常用例

| 用例 | 行为 |
|---|---|
| 符号未定义 | 抛 `Exception: Symbol '<x>' not found`，`%??%` 置 `_G.ERR.Type=Exception` |
| `def!`/`let*` 参数个数≠3 或 key 非符号 | `%??%` 报 Invalid arguments/type |
| 绑定表元素奇数 | 报 binding list 无效 |
| 嵌套 let*（`(let* (z 2) (let* (q 9) a))`） | 内层经 EnvCopyOuter 复制到全局 `a`，返回 4（本 commit 修复）|
| 大小写敏感 | `mynum`/`MYNUM` 各自独立，不互相覆盖 |
| 读入含 `;>>>` 指令行（测试文件元数据） | 本 bat 不做特判；由 `_runall.py` 在喂入前剔除 |

## 依赖与影响面

- 依赖：`nsutil`（NS Set/Get/New）、`types`（Mal 构造）、`reader`/`printer`/`io`/`str`、`util` Invoke。
- env 表示为 NSBody：`Count`/`Item[key].(Count,Item[1].Key,Value)` + `RawKeyCount`/`RawKeys`。
- 影响面：仅 step3 主文件；改动以官方 `step3_env.mal` 全量 `PASS=38/38`+`_check` 回归为守门。

## 变更记录

- 2026-08-24：修复嵌套 let* 外层 env 失序查找。EnvCopyOuter 现在为每个 let* env **自持一份全新
  RawKeys**（含已拷贝外层键），MLet 再把本地绑定追加；修掉 `:MAIN_ENV`/MAIN EncKey 编码问题。
  代价：每 let* 多分配键表 + N 次 Key 写入，全量墙时 ~270s→~408s，列为 #3/#4 待优化点。