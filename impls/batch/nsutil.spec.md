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
1b. **内部自调用同进程化（本版新增）**：nsutil.bat 内对自家函数（`HasField`/`IsValidNS`/`IsNSMeta`/
   `CloneMeta`/`CloneBody`/`Free`/`FreeNSBody`/`IndirectGet`）一律改 `call :NSUTIL_*`（同进程标签跳转），
   取代原 `call NSUTIL :NSUTIL_*`（跨文件＝新起 cmd.exe 子进程）。各函数参数互不冲突靠「显式唯一
   命名 `_T.<FN>.` 前缀」即弃用 .for-var 域的设计保证，同进程调用安全。一个 `NSUTIL_Set` 扇出的
   HasField+IsValidNS×2+CloneMeta 等原本各再起一个子进程，现收敛进当前实例，实测 step1 密集表单
   快 ~10%（18.72s→16.84s），官方 121/121 无回归。`%{% NSUTIL AssertValid* %}%` 等 FAST 下为 rem 的
   断言保持不变；`IndirectGet` 本就是 `call :`。**#9 补全（同批提交）**将同进程化扩到 nsutil
   全部内部调用点（`AssertValidNS`/`AssertValidNSBody` ×10、`HasField`/`IsValidNS` ×2、`IsNSBody`、
   `Free`/`FreeNSBody`、`IsNSMeta`/`CloneMeta` 等，共 11 处），nsutil 内部自此**零跨文件自调用**——
   `Set` 尾部与 `CloneBody`/`FreeNSBody`/`Free` 等写/释放热路径不再发子进程。配合 impls/batch 全
   .bat CRLF 统一（cmd 对 LF 大括号块解析错乱，git 以 autocrlf 归一），官方 step1 121/121 双重 PASS 无回归。
1c. **对象宏与 init 链全路径化（#7，本版新增）**：非 PACKED 下宏 `{n/{c/{g/{s` 与 `NSUTIL_Init` 内
   `call UTIL :UTIL_Init` 改为 `call "%~dp0…bat" :…`。`%~dp0` 在该 set/call 语句内（`%~0`=本文件 nsutil.bat）
   展开为运行时绝对路径，调用点直接可用、不坠宏调用点 `%~0` 错位坑。PACKED 分支 `call :NSUTIL_*` 不变。
   要求各模块与 nsutil.bat 同目录。实测 step1 121/121，随 #7 壁钟 128.7s 验证通过。
2. **写时复制**：`NSUTIL_Set` 当 `RefCnt>1`（被共享）时先 `CloneBody` 深拷贝出独立 Body 再写，
   复用旧值若为 NS 则释放。字段多时每次写都 O(字段数) 深拷贝——这是主要 GC 放大器（优化点 #3）。
2b. **同值短路前置（#3 首片，本版新增）**：`NSUTIL_Set` 把 `HasField`+当前字段值判等提前到 `CloneBody`
   深拷贝之前——新值与现值相同则直接返回，不触发 COW 深拷贝（原实现先克隆重指再做判等，白白深拷贝）。
   Free 步在 COW 之后**重新读当前（重指后）Body 的字段值**再释放，语义与原「释放新 Body 中旧引用」一致，
   避免了移到浅读旧 Body 引用会误伤仍被旧 Body 持有的 Meta 的问题。改字段名 `_T.AB.OldVal`→`_T.AB.CurVal`。
   实测 step1 121/121、step2 16/16 通过，wall 无回退。
3. **句柄即值**：NS 变量存的是 Meta 句柄字符串（如 `_G.NS[5]`），`!NSVar!.Target`/`!NSVar!.Type`
   是指向 Body/元数据的隐式函数。
4. `NSUTIL_IndirectGet` 的 `call set` 双层解析是按动态名的唯一可靠读取方式（`%![VarName]!%`）。
5. **环境规模动态受限（本版新增）**：`NSUTIL_Init` 在未预置 `_G.NSMAX` 时默认设为 8000（可被外部
   `set _G.NSMAX=…` 覆盖，适配不同机器，见 readme §0 准则4）；`NSUTIL_New` 每次分配前用
   `if !_G.NSP! geq !_G.NSMAX!` 校验，超限立即 `Fatal` 终止而非继续膨胀。每次 New 消耗 2 个 NSP 槽
   （NSBody+NSMeta），默认 8000 约容纳 4000 个活跃对象。该守卫为后续"小对象内联/行数换变量"
   可能引入的更多局部变量提供兜底。抛错语句内不可含圆括号（否则提前闭合 `if` 块，readme 坑5）。

## 边界与异常用例

| 用例名 | 输入 | 预期行为/结果 |
|---|---|---|
| 读已存在字段 | `{g %%.NS Field Out %}` | Out = 字段值 |
| 读不存在字段 | `Out` 有旧值 | Out 保持不变（新快路径经 `if defined` 守卫实现） |
| 写共享 Body | RefCnt>1 | 先 CloneBody，原持者不受影响，新 Body 写入 |
| 写已存在 NS 字段 | 旧值为 NS | 旧值被 Free，新值按 CloneMeta 入表 |
| 释放最后引用 | RefCnt 归 0 | 递归释放 Body 与其嵌套 NS，两级句柄置空 |
| 未初始化调用 | 未 `NSUTIL_Init` | 记录并继续（FAST 下为 rem），不崩溃 |
| 超过 NSMAX | 设 `_G.NSMAX=4` 后连开 2 个 NS | 第 3 次 `NSUTIL_New` 时 NSP 达 4，触发 Fatal 并 exit=1 |