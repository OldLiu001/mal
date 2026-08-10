# AppleScript MAL 实现

Make-A-Lisp 的 AppleScript 实现（step0 → stepA）。运行环境：macOS 自带 `osascript` / `osacompile`，无需安装。

## 架构

### 模块划分

| 模块 | 角色 | 依赖注入方式 |
|------|------|--------------|
| `types.applescript` | MAL 类型构造器（`script Types` 对象） | step 通过 `typesLib's Types's makeXxx(...)` 调用 |
| `reader.applescript` | 词法/语法分析 | 内部 property `typesLib`，经 `setTypesLib(lib)` 注入 |
| `printer.applescript` | 打印（`script Printer` 对象） | 直接调用 `printerLib's Printer's pr_str(...)` |
| `core.applescript` | 稳定核心函数库（算术/比较/打印/相等/map/quote/io） | 四个 property 经 `inject(types, reader, printer, replEnv)` 注入 |
| `stepN_name.applescript` | 解释器本体：`dispatchCore`（分发表）+ `evalMAL`（求值器）+ `Env` + 函数工厂 | — |

**职责边界**：`core` 只放跨 step 完全稳定、且不引用 step 顶层 handler 的实现；`dispatchCore` / `evalMAL` / `Env` 等渐进增长结构必须留在 step 内。core 中凡涉及 `dispatchCore` 的 handler（如 `withMetaHelper`）也留在 step。

### 三种运行形态

```
applescript 源 (.applescript)  ──osascript──▶ 直接运行（loadMod 自动编译回退）
        │
        ├─ osacompile ──▶ 依赖版 .scpt（运行期 load script 四个模块 .scpt）
        │
        └─ merge.applescript ──▶ .standalone.applescript ──osacompile──▶ .standalone.scpt
                                  （四模块扁平内联，零外部依赖，可单独分发）
```

- `impls/applescript/tests -> ../../tests` 为符号链接，随仓库根测试更新。
- 所有 `.scpt` 与 `.standalone.*` 均为生成物，不入库（见 `impls/.gitignore`）。

## 启动脚本用法

```sh
# 直接跑源码（推荐日常开发，改完即跑，不必先 make）
osascript step9_try.applescript

# 一键运行（默认 stepA_mal，需先 make）
./run
STEP=step9_try ./run

# make 目标
make                  # 依赖版 .scpt（需先有 types/reader/printer/core.scpt）
make standalone       # 单文件版 .standalone.applescript + .scpt
make standalone-src   # 仅合并源 .standalone.applescript
make clean            # 删除全部生成物
make <step>.scpt      # 单个依赖版，如 make stepA_mal.scpt
```

## 设计约束 / 隐性约定

以下约束大多无法从语言规范推断，改代码前必须理解：

### 合并与模块加载

1. **模块名 = 文件名**：`loadMod("types", …)` 期望存在同名 `.applescript` / `.scpt`。新增模块必须文件名与模块名一致。
2. **reader 须通过固定名字引用 types**：内部一律用 property `typesLib`（如 `my typesLib's Types's makeMALNil()`），经 `setTypesLib(lib)` 注入；合并脚本只替换 `property typesLib` / `set typesLib` / `my typesLib` 三个精确串。改名会导致合并后引用断裂。
3. **core 须通过 `inject(types, reader, printer, replEnv)` 注入依赖**：内部 property 名固定为 `typesLib` / `readerLib` / `printerLib` / `replEnvGlobal`（合并时重命名为 `core*Lib` 前缀以避开 step 顶层同名 property）；step 加载 core 后必须调用 `coreLib's inject(...)`。
4. **step 必须用 `loadMod` 加载模块**，不要自己写 `load script` 路径。合并脚本会删除 `loadMod` / `fileExists`，并把 `set X to my loadMod("X", dir)` 改成 `set X to me`；用别的加载方式会导致 standalone 缺依赖。
5. **顶层 handler 勿与模块同名**：合并会删除 reader/core 中与 step 重名、core 中与 reader 重名的 handler。若 step 定义了与模块顶层助手同名的 handler（如 `setTypesLib`、`inject`、`readStr`、`printStr`），会被当成"模块的重复 handler"误删。
6. **文件顶部连续 `use` 行**：`stripUse` 删掉各模块顶部所有 `use ` 开头行，合并后统一由唯一 header 提供。`use` 必须连续放在最前，模块顶部不要写会被误删的非 `use` 代码。
7. **过程定义用 `on name(...)`**：`removeTopLevelHandler` 仅识别 `on NAME(` / `to NAME(`（含带空格）前缀。避免无括号的 `on name` 块。
8. **`on run` 签名自由**：`on run()` 或 `on run(argv)` 均可，合并脚本不依赖 run 签名。

### 语言与运行时踩坑

9. **merge 必须用扁平内联而非嵌套 script 对象**：AppleScript 嵌套 script 无法继承外层 `use framework "Foundation"`，`NSString` 的 `stringWithString_` 会报"不理解"。因此模块 handler 必须平铺到顶层同一脚本。
10. **`use framework "Foundation"`**：字符串大小写转换 / 正则分词 / 文件读写 / 标准 I/O 均依赖 Foundation。这是 macOS 系统框架，不是第三方依赖。
11. **保留字禁忌**：`rest` 是 AppleScript 保留字，不能作变量名（错误栈 / 合并提取均会受影响）。避开 `rest`、`first`、`second`、`return`、`while` 等关键字。
12. **错误栈安全弹出 `popMalErrorStack`**：错误栈仅 1 个元素时 `items 1 thru -2` 会抛 `-1728`，必须用此 helper（单元素清空、多元素才截断）。
13. **所有 MAL 类型带 `property metaData`**：为支持 `with-meta` / `meta`；新增类型必须加上。
14. **`time-ms` 存实数**：AppleScript 整数上限约 2^31，`time-ms` 返回 ~1.7e12 超界，故存为 real。
15. **loader 自动编译回退**：多 agent 并行改源码时，改完直接 `osascript stepX.applescript` 即可运行（优先 `load script` 已编译 `.scpt`，缺失时临时 `osacompile`）。只在发布 / 测速时才 `make`。
16. **`malEqual` 的 map 比较必须无序**：早期 step 曾用有序比较（`{a 1 b 2}` ≠ `{b 2 a 1}`），与规范不符；core 中统一为无序版本，改动时勿回退。
