# util.bat 的 spec（UTIL 基础设施）

> 本文件与同名源码双向同步：改代码必须同步本文件，改本文件必须落实到代码。

## 用途

util.bat 是 MAL batch 实现的**调度与返回值交接核心**：定义全局初始化、函数调用分发 `UTIL_Invoke`、
返回值交接 `UTIL_SetRet`/`UTIL_GetRet`、错误抛出 `UTIL_Throw`、拷贝 `UTIL_Copy`、致命 `UTIL_Fatal`。
它以一组宏（`{%`/`%}`/`%->%`/`%<-%`/`%?%`/`%??%`/`%?|%`/`%&%`/`%?`/`?}`/`-|` 等）被全库模块调用，
是「宏分发 + 多模块跨文件调用」架构的枢纽，也是性能热点集中地。

## 对外接口

| 名称 | 签名/格式 | 说明 |
|---|---|---|
| `UTIL_Init` | `call UTIL :UTIL_Init Main` | 初始化：登记 Main、赋宏、设 `_G.LEVEL/_G.RET/_G.ERR`、清 `_T`。幂等 |
| `UTIL_Invoke` | `call UTIL :UTIL_Invoke ModName Fn args...` | 分发调用 `ModName_Fn`：进入推 LEVEL、退出做 NS GC 与 `_L[level]` 清栈 |
| `UTIL_SetRet` | `call UTIL :UTIL_SetRet Var` | 把 `Var` 的值写入 `_G.RET`（NSMeta 时做跨层句柄迁移记账） |
| `UTIL_GetRet` | `call UTIL :UTIL_GetRet Var` | 把 `_G.RET` 读入 `Var`，随后清 `_G.RET`（出错时忽略） |
| `UTIL_Throw` | `call UTIL :UTIL_Throw Msg [Type]` | 置 `_G.ERR`，记录错误类型与带 TRACE 的消息 |
| `UTIL_Copy` | `call UTIL :UTIL_Copy From To` | `set "To=!From!"` 简单值拷贝 |
| `UTIL_Fatal` | `call UTIL :UTIL_Fatal Msg` | 打印致命信息并 `exit 1` |

## 关键行为与约束

1. **返回值交接是双端模式**：被调函数末尾 `%<-% Var`（=SetRet）写 `_G.RET`；调用方 `... %->% Out`（=GetRet）
   读走并清空。`UTIL_GetRet` 在 `_G.ERR` 已置时不写 Out（错误被吞，交由调用方 `%?%` 分支处理）。
2. **性能约束（本版）**：GetRet 用 `set "%~1=!_G.RET!"` 内联直写，不再嵌套 `UTIL_Invoke`/`UTIL_Copy`
   子调用；GetRet/SetRet 退出不再做 O(环境变量表规模) 的 `for /f set "_T"` 全量清扫。`_T.*` 为固定短名、
   每次使用前必先赋值再读，残留无功能影响。实测真 step1 12 个 form 从 13.49s→10.39s(~23%)，官方
   step1_read_print 120/120 通过、0 失败，行为等价。
3. `_G.SKIPTHIS/_G.DOTHIS`：按 `_G.FAST` 决定校验语句是否编译为 `rem`（FAST 下跳过错位校验，保性能）。
4. `UTIL_Invoke` 非 PACKED 走跨文件 `call ModName :Fn`；PACKED 走同文件 `call :Fn`，省子进程（见 OPTIMIZATION.md #1）。
5. NS GC：Invoke 退出在 `if defined _G.NSUTIL` 下经临时文件枚举释放当前 LEVEL 命名空间，是后续优化靶点（#2）。

## 边界与异常用例

| 用例名 | 输入 | 预期行为/结果 |
|---|---|---|
| GetRet 成功后读取 | 函数 SetRet(X)，调用方 GetRet(Y) | `Y` 得 X，`_G.RET` 清空 |
| GetRet 出错时忽略 | `_G.ERR` 已置后 GetRet(Y) | `Y` 不变，`_G.RET` 清空 |
| SetRet 非 NS 值 | 返回普通 Mal | `_G.RET` = 该值，无层记账 |
| SetRet NSMeta 值 | 返回本层创建的 NS | 若本层已建，迁移到上一层并记账；否则仅返回 |
| Invoke 双向推弹 LEVEL | 嵌套调用 | 进出各加减 LEVEL，退出清 `_L[level]` 与 `_T` |
| 未初始化调用 GetRet/SetRet | 任一下标 | 仅记录并继续（FAST 下为 rem），不崩溃 |