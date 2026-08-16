# mal (Make a Lisp) — JavaScript 实现

本目录是 mal 语言的 JavaScript 参考实现，支持多种 JS 运行时：Node.js、JScript (cscript)、JScript.NET (jsc.exe)、以及 macOS osascript (JavaScriptCore)。

## 目录结构

```
runtime.js       运行时检测 + ES5 polyfill（node/jscript 下生效，jsc/osascript 下跳过）
io.js            统一 I/O 抽象层（readline/println/slurp/args/exit）
types.js         类型系统（Symbol/Atom/HashMap/List/Vector/Function）
reader.js        reader（tokenizer + read_form）
printer.js       printer（_pr_str）
env.js           环境（Env with outer chain）
core.js          核心 namespace（所有内置函数）
interop.js       JS 互操作（resolve_js / js_to_mal）
step0_repl.js    逐步实现 step 0~A
...
stepA_mal.js
build.sh         打包脚本（cat 合并为单文件，供 cscript/jsc 使用）
build.cmd        Windows 入口（调用 build.sh）
node_run.cmd     node 测试包装器（runtest.py 调用）
cscript_run.cmd  cscript 测试包装器
dist/            打包后的单文件输出
```

## 运行时支持

### 1. Node.js（基准运行时）

**启动方式**: `node stepA_mal.js`（或 `node run`）

**能力**: ES2024（v22），完整 `require()` 模块系统

| 特性 | 状态 |
|------|------|
| `require()` / `module.exports` | ✅ 原生 |
| `process.argv` / `process.stdin/stdout/stderr` | ✅ 原生 |
| `fs.readFileSync` | ✅ 原生 |
| `Buffer.alloc(n)` | ✅ 原生（注意：`new Buffer(n)` 已废弃） |
| `JSON` | ✅ 原生 |
| `Array.isArray` / `Object.keys` | ✅ 原生 |
| `Array.prototype.map/forEach/filter/reduce/reduceRight/indexOf` | ✅ 原生 |
| `String.prototype.trim` | ✅ 原生 |
| `Function.prototype.bind` | ✅ 原生 |
| `Function.name` | ✅ 原生 |
| 字符串索引 `str[0]` | ✅ 原生 |
| `arguments` 对象 | ✅ 原生 |
| `console.log/warn/error` | ✅ 原生 |
| `require.main === module`（isMain 检查） | ✅ 原生 |

**已知坑**: 无。Node.js 是基准运行时，所有代码默认以 Node 为目标编写，其他运行时通过条件分支适配。

---

### 2. JScript / cscript（Windows Script Host 5.x）

**启动方式**: `cscript //Nologo dist/stepA_mal.js`

**能力**: ES3 仅限。无模块系统，必须打包为单文件（`build.sh`）。

**宿主对象**: `WScript`（`.Echo` / `.StdIn` / `.StdOut` / `.StdErr` / `.Arguments` / `.Quit`），`ActiveXObject("Scripting.FileSystemObject")`

| 特性 | 状态 | 解决方案 |
|------|------|----------|
| `require()` / `module` | ❌ 不存在 | `build.sh` 打包为单文件；`typeof module === 'undefined'` 分支跳过 |
| `Array.isArray` | ❌ ES3 无 | runtime.js polyfill: `Object.prototype.toString.call(x) === '[object Array]'` |
| `Object.keys` | ❌ ES3 无 | runtime.js polyfill: `for-in` + `hasOwnProperty` |
| `Array.prototype.map/forEach/filter/reduceRight/indexOf` | ❌ ES3 无 | runtime.js polyfill（标准 ES5 算法） |
| `String.prototype.trim` | ❌ ES3 无 | runtime.js polyfill: `replace(/^\s+\|\s+$/g, '')` |
| `Function.prototype.bind` | ❌ ES3 无 | runtime.js polyfill（标准 ES5 算法） |
| `JSON` | ❌ ES3 无 | runtime.js polyfill（json2.js 风格） |
| `Function.name` | ❌ 不支持 | 用 `types._symbol_Q(obj)` 替代 `obj.constructor.name !== 'Symbol'` |
| 字符串索引 `str[0]` | ❌ ES3 不支持 | 用 `str.charAt(0)` |
| `arguments` 对象 | ✅ 支持 | 无需改动 |
| `typeof` 未声明变量 | ✅ 安全返回 `'undefined'` | 用于运行时检测 `typeof WScript !== 'undefined'` |
| `WScript.Arguments` | ⚠️ 不含脚本名 | `IO.args` 长度检查从 `> 1` 改为 `> 0` |
| 文件路径 | ⚠️ FSO 需反斜杠 | `io.js` 中 `.replace(/\//g, '\\')` |
| `console` | ❌ 不存在 | `printer.println` 统一走 `IO.println`（→ `WScript.Echo`） |
| `Buffer` | ❌ 不存在 | node 专属代码在 `RUNTIME === 'node'` 分支内，cscript 不执行 |
| `process` | ❌ 不存在 | 同上 |

**已知坑**:
1. **`match[0]` 字符串索引**: reader.js tokenize 中 `match[0]` 用于检查注释，必须改为 `match.charAt(0)`。
2. **`_clone` 中 `__meta__` 枚举污染**: 如果对非 function 类型设置 `__meta__`，`for-in` 遍历 hash-map 时会枚举出 `__meta__`。修复: 只对 function 类型设置。
3. **`printer._pr_str` 和 `core.keys`/`core.vals`** 需过滤 `__meta__` / `__isvector__` 内部属性。
4. **`node_readline.js` 依赖**: 所有 step 文件移除对 `node_readline.js` 的依赖，统一走 `IO.readline`。
5. **`runtest.py` 在 Windows 下自动追加 `.cmd`**: 所以 `cscript_run.cmd` / `node_run.cmd` 命名必须匹配。

**测试**: 877/877 全通过（11 个 step，0 失败）

---

### 3. JScript.NET / jsc.exe（.NET Framework 编译型）

**启动方式**: 先编译 `jsc.exe /out:stepA.exe dist/stepA_mal.js`，再运行 `stepA.exe`

**能力**: ES3 + .NET 扩展。**编译型**，非解释执行。

**宿主对象**: `System.Console`（`.WriteLine/Write`）、`System.IO.File`、`System.Environment`

**核心限制 — 与 cscript 有本质差异**:

| 特性 | 状态 | 说明 |
|------|------|------|
| `arguments` 对象 | ❌ **完全不存在** | JS1135 编译错误。即使 `eval()` / `new Function()` 内部也无法访问 |
| `Array.isArray` | ❌ 不可用且不可 polyfill | JS0438: 不能给内置类型添加静态方法。`typeof Array.isArray` 本身也会报 JS0438 |
| `Object.keys` | ❌ 同上 | JS0438 |
| `Array.prototype.*` 赋值 | ❌ 不可用 | JS0438: 不能修改内置类型 prototype。无法添加 `map`/`forEach` 等 |
| `JSON` | ❌ 未声明 | JS1135。`typeof JSON` 也报错。需声明 `var JSON = {};` |
| `WScript` | ❌ 未声明 | JS1135。JSC.NET 不使用 WScript 对象 |
| `process` | ❌ 未声明 | JS1135 |
| `module` / `require` | ❌ 未声明 | JS1135。`require` 还是保留字（JS1137 警告） |
| `Buffer` / `console` | ❌ 未声明 | JS1135 |
| `typeof` 未声明变量 | ⚠️ **编译时即报错** | 与 cscript 不同！JSC.NET 在编译阶段就报 JS1135，不是运行时返回 `undefined` |
| `Function.name` | ❌ 不支持 | 同 cscript |
| 字符串索引 `str[0]` | ⚠️ 待验证 | ES3 限制，可能需 `charAt(0)` |
| `set` / `get` | ⚠️ 保留字 | JS1137 警告，不影响编译但需注意 |
| `import System; import System.IO;` | ✅ 必须在文件顶部 | 提供 `System.Console` / `System.IO.File` 等 |
| 函数属性 (`fn.__ast__` 等) | ✅ 支持 | 可直接赋值和读取 |
| `apply()` | ✅ 支持 | 对普通函数和 variadic 函数都可用 |
| `...args : Object[]` | ✅ variadic 语法 | 替代 `arguments`。返回 `Object[]` 类型 |
| `Object[]` 数组方法 | ⚠️ **不支持 Array 方法** | `Object[]` 不是 JScript Array，无 `.slice()`/`.concat()`/`.map()`。需用 `_toArr()` 转为 JScript Array |
| JScript Array 原生方法 | ✅ 支持 | `.slice()` / `.concat()` / `.indexOf()` / `.join()` 可用。但 `.map()` 是否原生待确认 |
| 闭包 | ✅ 支持 | |
| `for-in` 遍历对象 | ✅ 支持 | |
| `eval()` | ✅ 支持 | 但内部不能访问 `arguments` |

**适配策略（构建时文本变换）**:
1. **`arguments` → `..._vargs : Object[]` + `_toArr(_vargs)`**: 所有使用 `arguments` 的函数签名需改为 variadic，函数体内 `arguments` 替换为转换后的 JScript Array。
2. **`Array.isArray(x)` → `_isArray(x)`**: 全局 helper 函数，替代无法 polyfill 的静态方法。
3. **`Object.keys(o)` → `_keys(o)`**: 同上。
4. **`Array.prototype.map.call(args, fn)` → `_map(_toArr(args), fn)`**: 用全局 helper 替代 prototype 方法。
5. **`Array.prototype.slice.call(arguments, n)` → `_toArr(_vargs).slice(n)`**: 先转 Array 再 slice。
6. **`typeof X`（X 为未声明全局）→ 运行时检测改用 `typeof RUNTIME !== 'undefined'`**: 避免编译时 JS1135。
7. **文件顶部**: 添加 `import System; import System.IO;`。
8. **`JSON`**: 声明 `var JSON = {};` 后使用 runtime.js 的 polyfill（但不能用 `typeof JSON` 检测，直接赋值）。
9. **polyfill 跳过**: `Array.isArray` / `Object.keys` / `Array.prototype.*` 的 `typeof` 检查和赋值在 JSC.NET 下会编译报错，需在构建时排除整个 polyfill 块。

**`_toArr` helper**（JSC.NET 专用）:
```javascript
function _toArr(args) {
    var a = [];
    for (var i = 0; i < args.length; i++) a.push(args[i]);
    return a;
}
```

**已知坑**:
1. **`typeof` 不是安全检测**: JSC.NET 在编译期就报 JS1135，不像 cscript 在运行时返回 `undefined`。所有 `typeof WScript` / `typeof process` / `typeof module` / `typeof JSON` 检查必须用 `typeof RUNTIME !== 'undefined'` 替代，或用构建时条件排除。
2. **`Object[]` 不是 Array**: `...args : Object[]` 返回的类型不支持任何 Array 方法。必须用 `_toArr()` 转换后才能 `.slice()` / `.concat()` / `.map()`。
3. **`Function.prototype.clone`**: types.js 中 `Function.prototype.clone = function() {...}` 使用了 `arguments`，需改为 variadic + `_toArr`。
4. **`types._function`**: 内部 `var fn = function() { return Eval(ast, new Env(env, params, arguments)); }` 使用了 `arguments`，需改为 variadic。
5. **`types._list` / `_vector` / `_hash_map` / `_assoc_BANG` / `_dissoc_BANG`**: 全部使用 `arguments`，需改为 variadic。
6. **`core.js` 中所有 variadic 函数**: `pr_str` / `str` / `prn` / `println` / `assoc` / `dissoc` / `concat` / `conj` / `apply` / `swap_BANG` / `js_method_call` 全部使用 `arguments`。
7. **`runtime.js` 中 polyfill 使用 `arguments`**: `reduceRight` / `filter` / `bind` 的 polyfill 内部使用 `arguments`。但这些 polyfill 在 JSC.NET 下应被排除（因为不能给 prototype 赋值）。

**状态**: 适配进行中。io.js 已有 jsc 分支（`System.Console` / `System.IO.File`），但源文件尚未完成 JSC.NET 兼容改造。

---

### 4. osascript / JavaScriptCore（macOS 原生）

**启动方式**: `osascript -l JavaScript dist/stepA_mal.js`

**能力**: ES6+（现代 JavaScriptCore，支持 `let`/`const`/箭头函数/解构/`class`/`Promise`/`Symbol` 等）

**宿主对象**: ObjC 桥接（`$.NSString` / `$.NSFileHandle` / `$.NSTask` 等），`console`（→ stderr），`printf`

| 特性 | 状态 | 说明 |
|------|------|------|
| `require()` / `module.exports` | ❌ 不存在 | 打包为单文件（`build.sh`） |
| `process` / `__dirname` | ❌ 不存在 | 用 ObjC 桥接替代 |
| `JSON` | ✅ 原生 | |
| `Array.isArray` / `Object.keys` | ✅ 原生 | ES5+ |
| `Array.prototype.*` 全套 | ✅ 原生 | ES5+ |
| `String.prototype.trim` / `Function.prototype.bind` | ✅ 原生 | |
| `Function.name` | ✅ 原生 | |
| 字符串索引 `str[0]` | ✅ 原生 | |
| `arguments` 对象 | ✅ 原生 | |
| `typeof` 未声明变量 | ✅ 安全返回 `undefined` | |
| `console.log` | ✅ 可用 | 输出到 stderr |
| 标准输入 readline | ⚠️ 需要 ObjC 桥接 | 无内置 readline。可用 `$.NSFileHandle.fileHandleWithStandardInput` + `$.NSData` 读取，或 `$.NSTask` 调 `/usr/bin/read` |
| 文件读取 slurp | ⚠️ 需要 ObjC 桥接 | `$.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null)` |
| 命令行参数 args | ⚠️ 不可直接获取 | osascript 不向 JS 传递 argv。变通: 用 shell 包装脚本，将参数写入临时文件或通过环境变量传递 |
| `exit(code)` | ⚠️ | `$.exit(code)` 或抛异常 |
| `isMain` | ⚠️ | osascript 总是直接执行脚本，`isMain` 恒为 `true` |

**适配策略（预估）**:
1. **I/O**: io.js 添加 `osascript` 分支，用 ObjC 桥接实现 `readline` / `println` / `slurp`。
2. **readline 实现**: 
   ```javascript
   IO.readline = function(prompt) {
       printf(prompt);
       var stdin = $.NSFileHandle.fileHandleWithStandardInput;
       var data = stdin.availableData;
       if (data.length === 0) return null; // EOF
       var line = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;
       return line.replace(/\n$/, '');
   };
   ```
3. **slurp 实现**:
   ```javascript
   IO.slurp = function(f) {
       var err = $();
       var content = $.NSString.stringWithContentsOfFileEncodingError(f, $.NSUTF8StringEncoding, err);
       if (err[0]) throw new Error("File error: " + err[0]);
       return content.js;
   };
   ```
4. **println**: `console.log(s)` 或 `printf(s + '\n')`
5. **args**: 无直接方案。可用 shell 脚本包装: `osascript -l JavaScript -e "$(cat script.js)" arg1 arg2`，参数通过 `$.NSProcessInfo.processInfo.arguments` 获取（包含 osascript 自身路径）。
6. **polyfill 跳过**: runtime.js 的 polyfill 对 osascript 无害（`typeof Array.isArray !== 'function'` 为 false，不执行），但可优化为直接跳过。
7. **运行时检测**: `typeof console !== 'undefined' && typeof $ !== 'undefined'` → `RUNTIME = 'osascript'`。

**已知坑（预估）**:
1. **`console.log` 输出到 stderr**: osascript 的 `console.log` 默认写 stderr，可能导致 runtest.py 匹配 stdout 失败。需改用 `printf()` 写 stdout。
2. **ObjC 桥接的 `.js` 属性**: `$.NSString` 返回的是 ObjC 对象，需用 `.js` 属性转为 JavaScript 字符串。
3. **同步 readline**: `availableData` 是同步阻塞读取，直到收到数据。需注意 EOF 检测。
4. **UTF-8 编码**: 文件读取和 stdout 输出需显式指定 UTF-8。
5. **`eval` 可用但受限**: osascript 的 `eval` 可以执行 JS 代码，但无法访问 `arguments`（实际上 JSCore 支持 `arguments`，所以这不是问题）。
6. **`$.NSProcessInfo.processInfo.arguments`**: 包含 `osascript`、`-l`、`JavaScript`、脚本路径等参数，需要偏移截取实际参数。

**状态**: 预设计阶段。io.js 尚未添加 osascript 分支。以上为基于 JavaScriptCore 文档的预估方案，需在 macOS 上实际验证。

---

## 运行时检测逻辑

`runtime.js` 中的检测顺序（首个匹配生效）:

```
1. typeof WScript !== 'undefined'          → 'jscript' (cscript/wscript)
2. typeof System !== 'undefined' && 
   typeof System.Console !== 'undefined'    → 'jsc' (JScript.NET)
3. typeof process !== 'undefined' && 
   process.versions && process.versions.node → 'node' (Node.js)
4. fallback                                  → 'unknown'
```

**注意**: JSC.NET 中 `typeof WScript` / `typeof System` 会编译报错（JS1135），因此 JSC.NET 构建时需要不同的检测策略（构建时注入 `RUNTIME = 'jsc'`）。

**osascript 检测（待添加）**:
```
typeof $ !== 'undefined' && typeof console !== 'undefined' → 'osascript'
```

## 构建方式

### Node.js
直接运行多文件，无需打包:
```bash
node stepA_mal.js
```

### JScript (cscript) / osascript
打包为单文件:
```bash
bash build.sh stepA_mal    # → dist/stepA_mal.js
```

打包顺序: `runtime.js io.js types.js reader.js printer.js env.js core.js interop.js <step>.js`

### JScript.NET (jsc.exe)
需要额外的构建时文本变换（开发中）:
```bash
# 预期流程（尚未实现）:
bash build.sh --jsc stepA_mal   # → dist/jsc_stepA_mal.js（JSC 兼容版）
jsc.exe /out:stepA_mal.exe dist/jsc_stepA_mal.js
./stepA_mal.exe
```

## 测试

```bash
# Node.js
python runtest.py --no-pty --start-timeout 30 --test-timeout 30 \
  --rundir "impls/js" "impls/tests/stepA_mal.mal" \
  -- "impls/js/node_run" "stepA_mal.js"

# JScript (cscript)
python runtest.py --no-pty --start-timeout 30 --test-timeout 30 \
  --rundir "impls/js" "impls/tests/stepA_mal.mal" \
  -- "impls/js/cscript_run" "stepA_mal.js"

# JScript.NET (jsc) — 待实现
# osascript — 待实现
```

`--rundir` 必须设为 `impls/js`，否则 `slurp` / `load-file` 的相对路径 `../tests/` 找不到文件。

## 各运行时对比总览

| 特性 | Node.js | JScript (cscript) | JScript.NET (jsc) | osascript (JSCore) |
|------|---------|--------------------|--------------------|--------------------|
| ES 版本 | ES2024 | ES3 | ES3+.NET | ES6+ |
| 执行方式 | 解释执行 | 解释执行 | **编译执行** | 解释执行 |
| 模块系统 | `require()` | ❌ 单文件 | ❌ 单文件 | ❌ 单文件 |
| `arguments` | ✅ | ✅ | ❌ | ✅ |
| `Array.isArray` | ✅ | polyfill | ❌ 需 helper | ✅ |
| `Object.keys` | ✅ | polyfill | ❌ 需 helper | ✅ |
| `Array.prototype.map` 等 | ✅ | polyfill | ❌ 需 helper | ✅ |
| `JSON` | ✅ | polyfill | ❌ 需 polyfill | ✅ |
| `Function.name` | ✅ | ❌ | ❌ | ✅ |
| `str[0]` 索引 | ✅ | ❌ 用 `charAt` | ⚠️ 待验证 | ✅ |
| 函数属性 | ✅ | ✅ | ✅ | ✅ |
| `apply()` | ✅ | ✅ | ✅ | ✅ |
| `typeof` 未声明变量 | ✅ 安全 | ✅ 安全 | ❌ **编译报错** | ✅ 安全 |
| stdin readline | `fs.readSync` | `WScript.StdIn` | `System.Console.ReadLine` | ObjC `$.NSFileHandle` |
| 文件读取 | `fs.readFileSync` | `FileSystemObject` | `System.IO.File.ReadAllText` | `$.NSString` |
| 命令行参数 | `process.argv.slice(2)` | `WScript.Arguments` | `System.Environment.GetCommandLineArgs()` | `$.NSProcessInfo` |
| exit | `process.exit()` | `WScript.Quit()` | `System.Environment.Exit()` | `$.exit()` |
| 测试通过 | ✅ 877/877 | ✅ 877/877 | 🔧 适配中 | 📋 预设计 |
