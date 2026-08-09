# AppleScript MAL 实现

Make-A-Lisp 的 AppleScript 实现，step0 → stepA 全部通过官方测试。

- 运行环境：macOS 自带 `osascript` / `osacompile`，无需安装。
- 工作分支：`applescript-ai-dev`（其余语言实现在各分支并行，互不影响）。
- 源码目录：`impls/applescript/`，单步文件形如 `stepN_name.applescript`。

## 一、几种运行方式

1. **直接跑源码（推荐日常开发，不走 make）**
   ```sh
   osascript step9_try.applescript
   ```
   每个 step 的 `on run` 通过 `loadMod` 助手加载 `types/reader/printer`：
   优先 `load script` 已编译的 `.scpt`，缺失时自动 `osacompile` 对应 `.applescript` 再加载。
   因此改完源码直接运行即可，不必先 `make`。

2. **运行依赖版编译产物**
   ```sh
   make                # 生成 stepN.scpt（运行期仍依赖 types/reader/printer.scpt）
   osascript step9_try.scpt
   ```

3. **运行无依赖单文件（standalone）**
   ```sh
   make standalone     # 生成 stepN.standalone.applescript + stepN.standalone.scpt
   osascript step9_try.standalone.applescript   # 或 .standalone.scpt
   ```
   standalone 把三个模块扁平内联进 step，零外部依赖，可单独拷贝分发。

4. **交互式 REPL**
   ```sh
   osascript step0_repl.applescript      # 或对应 .scpt
   ```

5. **一键运行（默认 stepA_mal）**
   ```sh
   ./run                    # 等价于 osascript stepA_mal.scpt（需先 make）
   STEP=step9_try ./run     # 指定 step
   ```

## 二、make 脚本用法

| 目标 | 作用 |
|------|------|
| `make` / `make all` | 构建所有 step 依赖版 `.scpt`（需先有 `types.scpt reader.scpt printer.scpt`） |
| `make standalone` | 构建所有 step 单文件版 `.standalone.applescript` + `.standalone.scpt` |
| `make standalone-src` | 仅生成合并后的 `.standalone.applescript` 源（不编译） |
| `make clean` | 删除全部 `.scpt` 与 `.standalone.*` 产物 |
| `make <step>.scpt` | 只构建单个依赖版，如 `make stepA_mal.scpt` |
| `make <step>.standalone.scpt` / `.standalone.applescript` | 只构建单个单文件版 |

> 所有 `.scpt` 与 `.standalone.*` 均为生成物，已被 `impls/.gitignore` 忽略（第 150–152 行），**不入库**；仅 `.applescript` 源、`merge.applescript`、`Makefile` 入库。

## 三、合并脚本（merge.applescript）与脚本约定

`merge.applescript` 是**纯 AppleScript** 实现的单文件合并工具（无 Python、无 shell 文本处理）：

```sh
osascript merge.applescript <stepName>    # 生成 <stepName>.standalone.applescript
```

合并策略（扁平化，顶层仅保留唯一 `use framework "Foundation"`）：
- `types` / `printer` 作为 script 对象整体内联到顶层；
- `reader` 平铺到顶层，其内部对 `types` 的引用 `typesLib` 被精确重命名为 `readerTypesLib`（注入入口名 `setTypesLib` 保留）；
- 删除 `reader` 中与 step 同名的顶层 handler（避免重复定义）；
- step 的 loader 块 `set X to my loadMod("X", scriptDir)` 改写为 `set X to me`；
- 删除 step 中仅用于外部加载的 `loadMod` / `fileExists` 助手。

**为保证合并脚本正常工作，其它脚本须遵循以下模式（语言规范之外）：**

1. **模块名 = 文件名**：`loadMod("types", …)` 期望存在 `types.applescript` / `types.scpt`。新增模块必须文件名与模块名一致。
2. **reader 须通过固定名字引用 types**：reader 内部一律用 property `typesLib` 引用 types（如 `my typesLib's Types's makeMALNil()`），并通过 `setTypesLib(lib)` 注入；合并脚本只替换 `property typesLib` / `set typesLib` / `my typesLib` 三个精确串。改名（如 `tlib`、`theTypes`）会导致合并后引用断裂。
3. **step 必须用 `loadMod` 加载模块**，不要自己写 `load script` 路径。合并脚本会删除 `loadMod` / `fileExists`，并把 `set X to my loadMod("X", dir)` 改成 `set X to me`；用别的加载方式会导致合并后缺依赖。
4. **文件顶部连续 `use` 行**：`stripUse` 会删掉各模块顶部所有 `use ` 开头行，最后统一由唯一 header 提供。模块顶部不要写会被误删的非 `use` 代码；`use` 必须连续放在最前。
5. **顶层 handler 勿与模块同名**：合并会删除 reader 中与 step 重名的 handler。反之，若 step 定义了与模块顶层助手（如 `setTypesLib`、`readStr`、`printStr`）同名的 handler，会被当成"模块的重复 handler"误删。命名请避开这些名字。
6. **保留字禁忌**：`rest` 是 AppleScript 保留字，不能作变量名（历史踩坑：错误栈 / 合并提取均会受影响）。变量名避开 `rest`、`first`、`second`、`return`、`while` 等关键字。
7. **过程定义用 `on name(...)`**：`removeTopLevelHandler` 仅识别 `on NAME(` / `to NAME(`（含带空格两种）前缀；模块 / step 顶层过程推荐 `on name(...)` 形式，避免无括号的 `on name` 块。
8. **`on run` 签名自由**：`on run()` 或 `on run(argv)` 均可，合并脚本不依赖 run 签名。

## 四、隐性约定 / 设计思考

- **loader 自动编译回退**：多 agent 并行改 `.applescript` 源时，开发者改完直接 `osascript stepX.applescript` 即可运行，不必 `make`；只在发布 / 测速时才 `make`。
- **merge 用扁平内联而非嵌套 script 对象**：AppleScript 嵌套 script 无法继承外层 `use framework "Foundation"`，`NSString` 的 `stringWithString_` 会报"不理解"，故必须扁平化，把三个模块 handler 提升至顶层同一脚本。
- **`use framework "Foundation"`**：MAL 的 string 大小写转换 / 字符处理依赖 `NSString`，故每个 step 顶部都带此声明；合并时仅保留唯一一份。
- **错误栈安全弹出 `popMalErrorStack`**：错误栈仅 1 个元素时 `items 1 thru -2` 会抛 `-1728`，故统一用此 helper（单元素清空、多元素才截断）。
- **所有 MAL 类型带 `property metaData`**：为支持 `with-meta` / `meta`；新增类型请同样加上。
- **`time-ms` 存实数**：AppleScript 整数上限约 2^31，`time-ms` 返回 ~1.7e12 超界，故存为 real。
- **测试目录为符号链接**：`impls/applescript/tests -> ../../tests`，随仓库根 `tests/` 更新。

## 五、测试

```sh
# 跑单个 step 的官方测试（依赖版 / 单文件版 / 直接源码 三种 target 均可）
python3 runtest.py --rundir impls/applescript tests/step9.mal \
  -- osascript -l AppleScript step9_try.scpt
python3 runtest.py --rundir impls/applescript tests/stepA.mal \
  -- osascript -l AppleScript stepA_mal.standalone.applescript

# step5 (TCO) 较慢，默认 20s 可能超时，按需加大：
python3 runtest.py --rundir impls/applescript tests/step5.mal \
  --timeout 120 -- osascript -l AppleScript step5_tco.scpt
```

当前进度：`step0–step9` 与 `stepA` 全部通过（step9: 158/158，stepA: 113/113）。step5 TCO 为循环实现，速度慢，仅作正确性验证，不建议用于大输入。

## 六、工作流

- 实现放在 `applescript-ai-dev` 分支；其它语言（dash / csh 等）各自分支并行。
- 建议节奏：完成一个 step + 全量回归（依赖版 / standalone / 直接源码三形态 0 失败）后提交；阶段性成果 `git push -u origin applescript-ai-dev`。
