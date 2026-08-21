# nsutil.bat 的 spec（NS 命名空间对象模型）

> 本文件与同名源码双向同步：改代码必须同步本文件，改本文件必须落实到代码。

## 用途

nsutil.bat 提供 MAL batch 实现的**对象内存模型**：一切 Mal 值（原子、列表、符号、函数等）都以
「命名空间 NS」形式存在——每个对象占两个句柄：`NSMeta`（对外句柄，`Type`=NSMeta，记录 `Target`→body）
与 `NSBody`（数据本体，`Type`=NSBody，持有 `RefCnt`、`Data.Key[...]`/`Data.Value[...]` 字段表）。
用引用计数 + 写时复制（COW）管理生命周期，跨函数以句柄值传递，由 UTIL 的 LEVEL 记账驱动 GC。

## 对外接口

| 名称 | 签名/格式 | 说明 |
|---|---|---|
| `NSUTIL_Init` | `call NSUTIL :NSUTIL_Init Main` | 初始化并定义宏 `{n`/`{c`/`{g`/`{s` |
| `NSUTIL_New` | `{n %%.NSVar %}` | 新建一 Meta+Body 对，`NSVar`=Meta 句柄值 |
| `NSUTIL_Clone` | `{c %%.From %%.To %}` | 克隆（分 Meta/共享 Body/深拷贝 COW） |
| `NSUTIL_Get` | `{g %%.NS Field %%.Out %}` | 读取字段值到 Out（不存在则不写，缓存等价） |
| `NSUTIL_Set` | `{s %%.NS Field Value %}` | 写字段；共享 Body 时先 CloneBody 深拷贝再写 |
| `NSUTIL_Free` | `call NSUTIL :NSUTIL_Free %%.NS` | 释放句柄，RefCnt--，为 0 时释放 Body 及嵌套 NS |
| 谓词 | `IsNSMeta`/`IsNSBody`/`IsValidNS`/`HasField` | 类型与有效性探测 |
| `NSUTIL_IndirectGet` | `call :NSUTIL_IndirectGet VarName Out` | 经 `call set` 读取动态命名的变量值 |

## 关键行为与约束

1. **字段读快路径（本版）**：`NSUTIL_Get` 用内联 `if defined !%%.ValName!` 守卫替代原先的
   `call :NSUTIL_HasField` + `%->%` 交接——HasField 的结果在 `{g` 宏路径下从未被使用（Get 本就经
   `NSUTIL_IndirectGet` 直写 Val），故那次跨文件子调用是纯冗余。新逻辑保持「字段不存在则不写 Out」
   语义等价，剪掉每次字段读的一次跨文件子进程。`NSUTIL_Get`/`NSUTIL_Set` 内读取
   `Target`/`RefCnt`/`OldVal`/`NewBody` 等动态名一律用 `call set` 间接读取，替代 `%&%` 跨文件 Copy
   子调用（每处省一次跨文件 call）。
2. **写时复制**：`NSUTIL_Set` 当 `RefCnt>1`（被共享）时先 `CloneBody` 深拷贝出独立 Body 再写，
   复用旧值若为 NS 则释放。字段多时每次写都 O(字段数) 深拷贝——这是主要 GC 放大器（优化点 #3）。
3. **句柄即值**：NS 变量存的是 Meta 句柄字符串（如 `_G.NS[5]`），`!NSVar!.Target`/`!NSVar!.Type`
   是指向 Body/元数据的隐式函数。
4. `NSUTIL_IndirectGet` 的 `call set` 双层解析是按动态名的唯一可靠读取方式（`%![VarName]!%`）。

## 边界与异常用例

| 用例名 | 输入 | 预期行为/结果 |
|---|---|---|
| 读已存在字段 | `{g %%.NS Field Out %}` | Out = 字段值 |
| 读不存在字段 | `Out` 有旧值 | Out 保持不变（新快路径经 `if defined` 守卫实现） |
| 写共享 Body | RefCnt>1 | 先 CloneBody，原持者不受影响，新 Body 写入 |
| 写已存在 NS 字段 | 旧值为 NS | 旧值被 Free，新值按 CloneMeta 入表 |
| 释放最后引用 | RefCnt 归 0 | 递归释放 Body 与其嵌套 NS，两级句柄置空 |
| 未初始化调用 | 未 `NSUTIL_Init` | 记录并继续（FAST 下为 rem），不崩溃 |