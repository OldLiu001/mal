import System;
import System.IO;

// ---- Stubs for undeclared globals (prevent JS1135 compile errors) ----
var WScript = null;
var process = null;
var module = null;
var console = null;
var Buffer = null;
var readline_sync = null;
var global = null;
var window = null;
var ActiveXObject = null;
var exports = null;
function __noop__() { return {}; }


function _cloneFn(fn, ..._vargs : Object[]) {
    var arguments = [fn].concat(_toArr(_vargs));

    var temp = function(..._vargs : Object[]) {
        var arguments = _toArr(_vargs);
        return fn.apply(this, arguments);
    };
    for (var key in fn) {
        temp[key] = fn[key];
    }
    return temp;
}] = fn[key];
    }
    return temp;
}
// runtime_jsc.js - JSC.NET (JScript.NET) specific runtime
// This file REPLACES runtime.js in JSC builds.
// It provides:
//   1. import System declarations (must be at file top)
//   2. RUNTIME constant
//   3. Global helper functions to replace unavailable Array/Object methods
//   4. Global helper functions to replace arguments object
//   5. JSON polyfill (as global var, not typeof check)
//
// JSC.NET limitations addressed:
//   - arguments object: completely unavailable (JS1135 compile error)
//   - Array.isArray / Object.keys: cannot assign to built-in types (JS0438)
//   - Array.prototype.map/forEach/filter/reduce/reduceRight/indexOf:
//     cannot assign (JS0438), and native ones return "TypeError: function expected"
//   - typeof on undeclared globals: compile-time error (JS1135)
//   - JSON: undeclared (JS1135)
//
// NOTE: The `import System; import System.IO;` lines must be the VERY FIRST
// lines of the output file. The build script ensures this.

// -- These will be at file top (build script prepends them) --
// import System;
// import System.IO;

var RUNTIME = 'jsc';

// ---- Helper: convert Object[] (from variadic ...args) to JScript Array ----
function _toArr(args) {
    var a = [];
    for (var i = 0; i < args.length; i++) a.push(args[i]);
    return a;
}

// ---- Helper: convert Object[] to JScript Array with offset ----
function _toArrFrom(args, start) {
    var a = [];
    for (var i = start; i < args.length; i++) a.push(args[i]);
    return a;
}

// ---- Array.isArray replacement ----
function _isArray(arg) {
    return Object.prototype.toString.call(arg) === '[object Array]';
}

// ---- Object.keys replacement ----
function _keys(o) {
    var ret = [];
    for (var k in o) {
        if (o.hasOwnProperty(k)) {
            ret.push(k);
        }
    }
    return ret;
}

// ---- Array.prototype.map replacement ----
function _map(arr, callback, thisArg) {
    var ret = [];
    for (var i = 0; i < arr.length; i++) {
        ret.push(callback.call(thisArg, arr[i], i, arr));
    }
    return ret;
}

// ---- Array.prototype.forEach replacement ----
function _forEach(arr, callback, thisArg) {
    for (var i = 0; i < arr.length; i++) {
        callback.call(thisArg, arr[i], i, arr);
    }
}

// ---- Array.prototype.filter replacement ----
function _filter(arr, callback, thisArg) {
    var ret = [];
    for (var i = 0; i < arr.length; i++) {
        if (callback.call(thisArg, arr[i], i, arr)) {
            ret.push(arr[i]);
        }
    }
    return ret;
}

// ---- Array.prototype.reduce replacement ----
function _reduce(arr, callback, initialValue) {
    var hasInit = initialValue !== undefined;
    var acc = hasInit ? initialValue : arr[0];
    var start = hasInit ? 0 : 1;
    for (var i = start; i < arr.length; i++) {
        acc = callback(acc, arr[i], i, arr);
    }
    return acc;
}

// ---- Array.prototype.reduceRight replacement ----
function _reduceRight(arr, callback, initialValue) {
    var hasInit = initialValue !== undefined;
    var acc = hasInit ? initialValue : arr[arr.length - 1];
    var start = hasInit ? arr.length - 1 : arr.length - 2;
    for (var i = start; i >= 0; i--) {
        acc = callback(acc, arr[i], i, arr);
    }
    return acc;
}

// ---- Array.prototype.indexOf replacement ----
function _indexOf(arr, searchElement, fromIndex) {
    fromIndex = fromIndex || 0;
    for (var i = fromIndex; i < arr.length; i++) {
        if (arr[i] === searchElement) return i;
    }
    return -1;
}

// ---- String.prototype.trim replacement ----
function _trim(s) {
    return s.replace(/^\s+/, '').replace(/\s+$/, '');
}

// ---- JSON polyfill (JSC.NET has no JSON object) ----
var JSON = {};
JSON.stringify = function(value, replacer, space) {
    // Simplified JSON.stringify for mal's needs
    function esc(s) {
        var r = '';
        for (var i = 0; i < s.length; i++) {
            var c = s.charAt(i);
            if (c === '\\') r += '\\\\';
            else if (c === '"') r += '\\"';
            else if (c === '\n') r += '\\n';
            else if (c === '\r') r += '\\r';
            else if (c === '\t') r += '\\t';
            else if (c.charCodeAt(0) < 32) r += '\\u' + ('0000' + c.charCodeAt(0).toString(16)).slice(-4);
            else r += c;
        }
        return r;
    }
    function ser(v) {
        if (v === null) return 'null';
        if (v === true) return 'true';
        if (v === false) return 'false';
        if (typeof v === 'number') return v.toString();
        if (typeof v === 'string') return '"' + esc(v) + '"';
        if (_isArray(v)) {
            var items = [];
            for (var i = 0; i < v.length; i++) items.push(ser(v[i]));
            return '[' + items.join(',') + ']';
        }
        // Object
        var pairs = [];
        for (var k in v) {
            if (v.hasOwnProperty(k)) {
                pairs.push('"' + esc(k) + '":' + ser(v[k]));
            }
        }
        return '{' + pairs.join(',') + '}';
    }
    return ser(value);
};
JSON.parse = function(text) {
    // JSC.NET supports eval, so we can use it for JSON parsing
    // This is not safe for untrusted input but mal doesn't need that
    return eval('(' + text + ')');
};

// ---- Function.prototype.bind replacement ----
// JSC.NET doesn't support Function.prototype.bind assignment (JS0438)
// We provide a global helper instead
function _bind(fn, thisArg, ..._vargs : Object[]) {
    var presetArgs = _toArr(_vargs);
    return function(..._innerArgs : Object[]) {
        var args = presetArgs.concat(_toArr(_innerArgs));
        return fn.apply(thisArg, args);
    };
}

// io.js - Unified I/O abstraction for node/jscript/jsc runtimes
// Provides: readline, println, writeErr, writeErrLine, slurp, args, exit, isMain

var IO = {};

(function() {
    // Auto-detect runtime if not already set by runtime.js

    if (RUNTIME === 'node') {
        var fs_node = __noop__('fs');
        var path_node = __noop__('path');

        IO.readline = function(prompt) {
            // Use simple synchronous readline via process.stdin
            // (ffi-napi readline is optional, fallback to simple stdin)
            if (false) {
                return readline_sync(prompt);
            }
            // Fallback: read a line synchronously from stdin
            process.stdout.write(prompt);
            var line = '';
            var b = Buffer.alloc(1);
            while (true) {
                var n = fs_node.readSync(0, b, 0, 1);
                if (n === 0) { return null; }
                var ch = b.toString('utf8');
                if (ch === '\n') { break; }
                if (ch === '\r') { continue; }
                line += ch;
            }
            return line;
        };

        IO.println = function(s) {
            console.log(s);
        };

        IO.writeErr = function(s) {
            process.stderr.write(s);
        };

        IO.writeErrLine = function(s) {
            process.stderr.write(s + '\n');
        };

        IO.slurp = function(f) {
            return fs_node.readFileSync(f, 'utf-8');
        };

        IO.args = process.argv.slice(2);

        IO.exit = function(code) {
            process.exit(code);
        };

        IO.isMain = function(filename) {
            return require.main === module;
        };

    } else if (RUNTIME === 'jscript') {
        // JScript (cscript/wscript) I/O via WScript
        IO.readline = function(prompt) {
            WScript.StdOut.Write(prompt);
            if (WScript.StdIn.AtEndOfStream) {
                return null;
            }
            return WScript.StdIn.ReadLine();
        };

        IO.println = function(s) {
            WScript.Echo(s);
        };

        IO.writeErr = function(s) {
            WScript.StdErr.Write(s);
        };

        IO.writeErrLine = function(s) {
            WScript.StdErr.WriteLine(s);
        };

        IO.slurp = function(f) {
            var fso = new ActiveXObject("Scripting.FileSystemObject");
            // Convert forward slashes to backslashes for Windows paths
            var winPath = f.replace(/\//g, "\\");
            if (!fso.FileExists(winPath)) {
                throw new Error("File not found: " + f);
            }
            var file = fso.OpenTextFile(winPath, 1); // 1 = ForReading
            var content = file.ReadAll();
            file.Close();
            return content;
        };

        IO.args = (function() {
            var args = [];
            for (var i = 0; i < WScript.Arguments.Length; i++) {
                args.push(WScript.Arguments(i));
            }
            return args;
        })();

        IO.exit = function(code) {
            WScript.Quit(code);
        };

        IO.isMain = function() {
            // In cscript, the script is always the main module
            return true;
        };

    } else if (RUNTIME === 'jsc') {
        // JScript.NET I/O via System.Console and System.IO
        IO.readline = function(prompt) {
            System.Console.Write(prompt);
            var line = System.Console.ReadLine();
            // ReadLine returns null at EOF
            return line;
        };

        IO.println = function(s) {
            System.Console.WriteLine(s);
        };

        IO.writeErr = function(s) {
            System.Console.Error.Write(s);
        };

        IO.writeErrLine = function(s) {
            System.Console.Error.WriteLine(s);
        };

        IO.slurp = function(f) {
            var winPath = f.replace(/\//g, "\\");
            return System.IO.File.ReadAllText(winPath);
        };

        IO.args = (function() {
            var cmdArgs = System.Environment.GetCommandLineArgs();
            var args = [];
            // cmdArgs[0] is the exe path, skip it
            for (var i = 1; i < cmdArgs.Length; i++) {
                args.push(cmdArgs[i]);
            }
            return args;
        })();

        IO.exit = function(code) {
            System.Environment.Exit(code);
        };

        IO.isMain = function() {
            return true;
        };

    } else {
        // Unknown runtime - minimal stubs
        IO.readline = function(prompt) { return null; };
        IO.println = function(s) { print(s); };
        IO.writeErr = function(s) {};
        IO.writeErrLine = function(s) {};
        IO.slurp = function(f) { throw new Error("slurp not supported"); };
        IO.args = [];
        IO.exit = function(code) {};
        IO.isMain = function() { return true; };
    }
})();

// Export for node
if (RUNTIME === 'node' && module.exports) {
    module.exports = IO;
}

// Node vs browser behavior
var types = {};
if (RUNTIME !== 'node') {
    var exports = types;
}

// General functions

function _obj_type(obj) {
    if      (_symbol_Q(obj)) {   return 'symbol'; }
    else if (_list_Q(obj)) {     return 'list'; }
    else if (_vector_Q(obj)) {   return 'vector'; }
    else if (_hash_map_Q(obj)) { return 'hash-map'; }
    else if (_nil_Q(obj)) {      return 'nil'; }
    else if (_true_Q(obj)) {     return 'true'; }
    else if (_false_Q(obj)) {    return 'false'; }
    else if (_atom_Q(obj)) {     return 'atom'; }
    else {
        switch (typeof(obj)) {
        case 'number':   return 'number';
        case 'function': return 'function';
        case 'string': return obj.charAt(0) == '\u029e' ? 'keyword' : 'string';
        default: throw new Error("Unknown type '" + typeof(obj) + "'");
        }
    }
}

function _sequential_Q(lst) { return _list_Q(lst) || _vector_Q(lst); }


function _equal_Q (a, b) {
    var ota = _obj_type(a), otb = _obj_type(b);
    if (!(ota === otb || (_sequential_Q(a) && _sequential_Q(b)))) {
        return false;
    }
    switch (ota) {
    case 'symbol': return a.value === b.value;
    case 'list':
    case 'vector':
        if (a.length !== b.length) { return false; }
        for (var i=0; i<a.length; i++) {
            if (! _equal_Q(a[i], b[i])) { return false; }
        }
        return true;
    case 'hash-map':
        if (_keys(a).length !== _keys(b).length) { return false; }
        for (var k in a) {
            if (! _equal_Q(a[k], b[k])) { return false; }
        }
        return true;
    default:
        return a === b;
    }
}


function _clone (obj) {
    var new_obj;
    switch (_obj_type(obj)) {
    case 'list':
        new_obj = obj.slice(0);
        break;
    case 'vector':
        new_obj = obj.slice(0);
        new_obj.__isvector__ = true;
        break;
    case 'hash-map':
        new_obj = {};
        for (var k in obj) {
            if (obj.hasOwnProperty(k)) { new_obj[k] = obj[k]; }
        }
        break;
    case 'function':
        new_obj = _cloneFn(obj);
        break;
    default:
        throw new Error("clone of non-collection: " + _obj_type(obj));
    }
    // Use direct assignment instead of Object.defineProperty for ES3 compat
    // Only set __meta__ for functions (with-meta is used on functions)
    if (_obj_type(new_obj) === 'function' && new_obj.__meta__ === undefined) {
        new_obj.__meta__ = null;
    }
    return new_obj;
}


// Scalars
function _nil_Q(a) { return a === null ? true : false; }
function _true_Q(a) { return a === true ? true : false; }
function _false_Q(a) { return a === false ? true : false; }
function _number_Q(obj) { return typeof obj === 'number'; }
function _string_Q(obj) {
    return typeof obj === 'string' && obj.charAt(0) !== '\u029e';
}


// Symbols
function Symbol(name) {
    this.value = name;
    return this;
}
Symbol.prototype.toString = function() { return this.value; }
function _symbol(name) { return new Symbol(name); }
function _symbol_Q(obj) { return obj instanceof Symbol; }


// Keywords
function _keyword(obj) {
    if (typeof obj === 'string' && obj.charAt(0) === '\u029e') {
        return obj;
    } else {
        return "\u029e" + obj;
    }
}
function _keyword_Q(obj) {
    return typeof obj === 'string' && obj.charAt(0) === '\u029e';
}


// Functions
function _function(Eval, Env, ast, env, params, ..._vargs : Object[]) {
    var arguments = [Eval, Env, ast, env, params].concat(_toArr(_vargs));

    var fn = function() {
        return Eval(ast, new Env(env, params, arguments));
    };
    fn.__meta__ = null;
    fn.__ast__ = ast;
    fn.__gen_env__ = function(args) { return new Env(env, params, args); };
    fn._ismacro_ = false;
    return fn;
}ams, args); };
    fn._ismacro_ = false;
    return fn;
}
function _function_Q(obj) { return typeof obj == "function"; }

function _fn_Q(obj) { return _function_Q(obj) && !obj._ismacro_; }
function _macro_Q(obj) { return _function_Q(obj) && !!obj._ismacro_; }


// Lists
function _list(..._vargs : Object[]) {
    var arguments = _toArr(_vargs);
 return arguments.slice(0; }
function _list_Q(obj) { return _isArray(obj) && !obj.__isvector__; }


// Vectors
function _vector(..._vargs : Object[]) {
    var arguments = _toArr(_vargs);

    var v = arguments.slice(0;
    v.__isvector__ = true;
    return v;
}
function _vector_Q(obj) { return _isArray(obj) && !!obj.__isvector__; }



// Hash Maps
function _hash_map(..._vargs : Object[]) {
    var arguments = _toArr(_vargs);

    if (arguments.length % 2 === 1) {
        throw new Error("Odd number of hash map arguments");
    }
    var args = [{}].concat(arguments.slice(0);
    return _assoc_BANG.apply(null, args);
}
function _hash_map_Q(hm) {
    return typeof hm === "object" &&
           !_isArray(hm) &&
           !(hm === null) &&
           !(hm instanceof Symbol) &&
           !(hm instanceof Atom);
}
function _assoc_BANG(hm, ..._vargs : Object[]) {
    var arguments = [hm].concat(_toArr(_vargs));

    if (arguments.length % 2 !== 1) {
        throw new Error("Odd number of assoc arguments");
    }
    for (var i=1; i<arguments.length; i+=2) {
        var ktoken = arguments[i],
            vtoken = arguments[i+1];
        if (typeof ktoken !== "string") {
            throw new Error("expected hash-map key string, got: " + (typeof ktoken));
        }
        hm[ktoken] = vtoken;
    }
    return hm;
}
function _dissoc_BANG(hm, ..._vargs : Object[]) {
    var arguments = [hm].concat(_toArr(_vargs));

    for (var i=1; i<arguments.length; i++) {
        var ktoken = arguments[i];
        delete hm[ktoken];
    }
    return hm;
}


// Atoms
function Atom(val) { this.val = val; }
function _atom(val) { return new Atom(val); }
function _atom_Q(atm) { return atm instanceof Atom; }


// Exports
exports._obj_type = types._obj_type = _obj_type;
exports._sequential_Q = types._sequential_Q = _sequential_Q;
exports._equal_Q = types._equal_Q = _equal_Q;
exports._clone = types._clone = _clone;
exports._nil_Q = types._nil_Q = _nil_Q;
exports._true_Q = types._true_Q = _true_Q;
exports._false_Q = types._false_Q = _false_Q;
exports._number_Q = types._number_Q = _number_Q;
exports._string_Q = types._string_Q = _string_Q;
exports._symbol = types._symbol = _symbol;
exports._symbol_Q = types._symbol_Q = _symbol_Q;
exports._keyword = types._keyword = _keyword;
exports._keyword_Q = types._keyword_Q = _keyword_Q;
exports._function = types._function = _function;
exports._function_Q = types._function_Q = _function_Q;
exports._fn_Q = types._fn_Q = _fn_Q;
exports._macro_Q = types._macro_Q = _macro_Q;
exports._list = types._list = _list;
exports._list_Q = types._list_Q = _list_Q;
exports._vector = types._vector = _vector;
exports._vector_Q = types._vector_Q = _vector_Q;
exports._hash_map = types._hash_map = _hash_map;
exports._hash_map_Q = types._hash_map_Q = _hash_map_Q;
exports._assoc_BANG = types._assoc_BANG = _assoc_BANG;
exports._dissoc_BANG = types._dissoc_BANG = _dissoc_BANG;
exports._atom = types._atom = _atom;
exports._atom_Q = types._atom_Q = _atom_Q;

// Node vs browser behavior
var reader = {};
if (RUNTIME === 'node') {
    var types = __noop__('./types');
} else {
    var exports = reader;
}

function Reader(tokens) {
    // copy
    this.tokens = _map(tokens, function (a) { return a; });
    this.position = 0;
}
Reader.prototype.next = function() { return this.tokens[this.position++]; }
Reader.prototype.peek = function() { return this.tokens[this.position]; }

function tokenize(str) {
    var re = /[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"?|;.*|[^\s\[\]{}('"`,;)]*)/g;
    var results = [];
    while ((match = re.exec(str)[1]) != '') {
        if (match.charAt(0) === ';') { continue; }
        results.push(match);
    }
    return results;
}

function read_atom (reader) {
    var token = reader.next();
    //console.log("read_atom:", token);
    if (token.match(/^-?[0-9]+$/)) {
        return parseInt(token,10)        // integer
    } else if (token.match(/^-?[0-9][0-9.]*$/)) {
        return parseFloat(token);     // float
    } else if (token.match(/^"(?:\\.|[^\\"])*"$/)) {
        return token.slice(1,token.length-1) 
            .replace(/\\(.)/g, function (_, c) { return c === "n" ? "\n" : c})
    } else if (token.charAt(0) === "\"") {
            throw new Error("expected '\"', got EOF");
    } else if (token.charAt(0) === ":") {
        return types._keyword(token.slice(1));
    } else if (token === "nil") {
        return null;
    } else if (token === "true") {
        return true;
    } else if (token === "false") {
        return false;
    } else {
        return types._symbol(token); // symbol
    }
}

// read list of tokens
function read_list(reader, start, end) {
    start = start || '(';
    end = end || ')';
    var ast = [];
    var token = reader.next();
    if (token !== start) {
        throw new Error("expected '" + start + "'");
    }
    while ((token = reader.peek()) !== end) {
        if (!token) {
            throw new Error("expected '" + end + "', got EOF");
        }
        ast.push(read_form(reader));
    }
    reader.next();
    return ast;
}

// read vector of tokens
function read_vector(reader) {
    var lst = read_list(reader, '[', ']');
    return types._vector.apply(null, lst);
}

// read hash-map key/value pairs
function read_hash_map(reader) {
    var lst = read_list(reader, '{', '}');
    return types._hash_map.apply(null, lst);
}

function read_form(reader) {
    var token = reader.peek();
    switch (token) {
    // reader macros/transforms
    case ';': return null; // Ignore comments
    case '\'': reader.next();
               return [types._symbol('quote'), read_form(reader)];
    case '`': reader.next();
              return [types._symbol('quasiquote'), read_form(reader)];
    case '~': reader.next();
              return [types._symbol('unquote'), read_form(reader)];
    case '~@': reader.next();
               return [types._symbol('splice-unquote'), read_form(reader)];
    case '^': reader.next();
              var meta = read_form(reader);
              return [types._symbol('with-meta'), read_form(reader), meta];
    case '@': reader.next();
              return [types._symbol('deref'), read_form(reader)];

    // list
    case ')': throw new Error("unexpected ')'");
    case '(': return read_list(reader);

    // vector
    case ']': throw new Error("unexpected ']'");
    case '[': return read_vector(reader);

    // hash-map
    case '}': throw new Error("unexpected '}'");
    case '{': return read_hash_map(reader);

    // atom
    default:  return read_atom(reader);
    }
}

function BlankException(msg) {
}

function read_str(str) {
    var tokens = tokenize(str);
    if (tokens.length === 0) { throw new BlankException(); }
    return read_form(new Reader(tokens))
}

exports.Reader = reader.Reader = Reader;
exports.BlankException = reader.BlankException = BlankException;
exports.tokenize = reader.tokenize = tokenize;
exports.read_form = reader.read_form = read_form;
exports.read_str = reader.read_str = read_str;

// Node vs browser behavior
var printer = {};
if (RUNTIME === 'node') {
    var types = __noop__('./types');
    var IO = __noop__('./io');
}
// map output/print to IO.println (works across all runtimes)
printer.println = exports.println = function(..._vargs : Object[]) {
    var arguments = _toArr(_vargs);

    var args = arguments);
    IO.println(args.join(' '));
};

function _pr_str(obj.slice(print_readably {
    if (typeof print_readably === 'undefined') { print_readably = true; }
    var _r = print_readably;
    var ot = types._obj_type(obj);
    switch (ot) {
    case 'list':
        var ret = _map(obj, function(e) { return _pr_str(e,_r); });
        return "(" + ret.join(' ') + ")";
    case 'vector':
        var ret = _map(obj, function(e) { return _pr_str(e,_r); });
        return "[" + ret.join(' ') + "]";
    case 'hash-map':
        var ret = [];
        for (var k in obj) {
            if (k === '__meta__' || k === '__isvector__') { continue; }
            ret.push(_pr_str(k,_r), _pr_str(obj[k],_r));
        }
        return "{" + ret.join(' ') + "}";
    case 'string':
        if (obj.charAt(0) === '\u029e') {
            return ':' + obj.slice(1);
        } else if (_r) {
            return '"' + obj.replace(/\\/g, "\\\\")
                .replace(/"/g, '\\"')
                .replace(/\n/g, "\\n") + '"'; // string
        } else {
            return obj;
        }
    case 'keyword':
        return ':' + obj.slice(1);
    case 'nil':
        return "nil";
    case 'atom':
        return "(atom " + _pr_str(obj.val,_r) + ")";
    default:
        return obj.toString();
    }
}

exports._pr_str = printer._pr_str = _pr_str;


// Node vs browser behavior
var env = {};
if (RUNTIME !== 'node') {
    var exports = env;
}

// Env implementation
function Env(outer, binds, exprs, ..._vargs : Object[]) {
    var arguments = [outer, binds, exprs].concat(_toArr(_vargs));

    this.data = {};
    this.outer = outer || null;

    if (binds && exprs) {
        // Returns a new Env with symbols in binds bound to
        // corresponding values in exprs
        // TODO: check types of binds and exprs and compare lengths
        for (var i=0; i<binds.length;i++) {
            if (binds[i].value === "&") {
                // variable length arguments
                this.data[binds[i+1].value] = exprs.slice(i;
                break;
            } else {
                this.data[binds[i].value] = exprs[i];
            }
        }
    }
    return this;
}
Env.prototype.find = function (key) {
    if (key in this.data) { return this; }
    else if (this.outer) {  return this.outer.find(key); }
    else { return null; }
};
Env.prototype.set = function(key, value) {
    this.data[key] = value;
    return value;
};
Env.prototype.get = function(key) {
    var env = this.find(key);
    if (!env) { throw new Error("'" + key + "' not found"); }
    return env.data[key];
};

exports.Env = env.Env = Env;

// Node vs browser behavior
var core = {};
if (RUNTIME !== 'node') {
    var exports = core;
} else {
    var types = __noop__('./types'),
        reader = __noop__('./reader'),
        printer = __noop__('./printer'),
        interop = __noop__('./interop');
    var IO = __noop__('./io');
}

// Errors/Exceptions
function mal_throw(exc) { throw exc; }


// String functions
function pr_str(..._vargs : Object[]) {
    var arguments = _toArr(_vargs);

    return _map(arguments, function(exp) {
        return printer._pr_str(exp, true);
    }).join(" ");
}

function str(..._vargs : Object[]) {
    var arguments = _toArr(_vargs);

    return _map(arguments, function(exp) {
        return printer._pr_str(exp, false);
    }).join("");
}

function prn(..._vargs : Object[]) {
    var arguments = _toArr(_vargs);

    printer.println.apply({}, _map(arguments, function(exp) {
        return printer._pr_str(exp, true);
    }));
}

function println(..._vargs : Object[]) {
    var arguments = _toArr(_vargs);

    printer.println.apply({}, _map(arguments, function(exp) {
        return printer._pr_str(exp, false);
    }));
}

function slurp(f) {
    return IO.slurp(f);
}


// Number functions
function time_ms() { return new Date().getTime(); }


// Hash Map functions
function assoc(src_hm, ..._vargs : Object[]) {
    var arguments = [src_hm].concat(_toArr(_vargs));

    var hm = types._clone(src_hm);
    var args = [hm].concat(arguments.slice(1);
    return types._assoc_BANG.apply(null, args);
}

function dissoc(src_hm, ..._vargs : Object[]) {
    var arguments = [src_hm].concat(_toArr(_vargs));

    var hm = types._clone(src_hm);
    var args = [hm].concat(arguments.slice(1);
    return types._dissoc_BANG.apply(null, args);
}

function get(hm, key) {
    if (hm != null && key in hm) {
        return hm[key];
    } else {
        return null;
    }
}

function contains_Q(hm, key) {
    if (key in hm) { return true; } else { return false; }
}

function keys(hm) { return _filter(_keys(hm), function(k) { return k !== '__meta__' && k !== '__isvector__'; }); }
function vals(hm) { return _map(_filter(_keys(hm), function(k) { return k !== '__meta__' && k !== '__isvector__'; }), function(k) { return hm[k]; }); }


// Sequence functions
function cons(a, b) { return [a].concat(b); }

function concat(lst, ..._vargs : Object[]) {
    var arguments = [lst].concat(_toArr(_vargs));

    lst = lst || [];
    return lst.concat.apply(lst, arguments.slice(1);
}
function vec(lst) {
    if (types._list_Q(lst)) {
        var v = lst.slice(0;
        v.__isvector__ = true;
        return v;
    } else {
        return lst;
    }
}

function nth(lst, idx) {
    if (idx < lst.length) { return lst[idx]; }
    else                  { throw new Error("nth: index out of range"); }
}

function first(lst) { return (lst === null) ? null : lst[0]; }

function rest(lst) { return (lst == null) ? [] : lst.slice(1); }

function empty_Q(lst) { return lst.length === 0; }

function count(s) {
    if (_isArray(s)) { return s.length; }
    else if (s === null)  { return 0; }
    else                  { return _keys(s).length; }
}

function conj(lst, ..._vargs : Object[]) {
    var arguments = [lst].concat(_toArr(_vargs));

    if (types._list_Q(lst)) {
        return arguments.slice(1.reverse().concat(lst);
    } else {
        var v = lst.concat(arguments.slice(1);
        v.__isvector__ = true;
        return v;
    }
}

function seq(obj) {
    if (types._list_Q(obj)) {
        return obj.length > 0 ? obj : null;
    } else if (types._vector_Q(obj)) {
        return obj.length > 0 ? obj.slice(0: null;
    } else if (types._string_Q(obj)) {
        return obj.length > 0 ? obj.split('') : null;
    } else if (obj === null) {
        return null;
    } else {
        throw new Error("seq: called on non-sequence");
    }
}


function apply(f, ..._vargs : Object[]) {
    var arguments = [f].concat(_toArr(_vargs));

    var args = arguments.slice(1;
    return f.apply(f, args.slice(0, args.length-1).concat(args[args.length-1]));
}

function map(f, lst) {
    return _map(lst, function(el){ return f(el); });
}


// Metadata functions
function with_meta(obj, m) {
    var new_obj = types._clone(obj);
    new_obj.__meta__ = m;
    return new_obj;
}

function meta(obj) {
    // TODO: support symbols and atoms
    if ((!types._sequential_Q(obj)) &&
        (!(types._hash_map_Q(obj))) &&
        (!(types._function_Q(obj)))) {
        throw new Error("attempt to get metadata from: " + types._obj_type(obj));
    }
    return obj.__meta__;
}


// Atom functions
function deref(atm) { return atm.val; }
function reset_BANG(atm, val) { return atm.val = val; }
function swap_BANG(atm, f, ..._vargs : Object[]) {
    var arguments = [atm, f].concat(_toArr(_vargs));

    var args = [atm.val].concat(arguments.slice(2);
    atm.val = f.apply(f, args);
    return atm.val;
}

function js_eval(str) {
    return interop.js_to_mal(eval(str.toString()));
}

function js_method_call(object_method_str, ..._vargs : Object[]) {
    var arguments = [object_method_str].concat(_toArr(_vargs));

    var args = arguments.slice(1,
        r = interop.resolve_js(object_method_str),
        obj = r[0], f = r[1];
    var res = f.apply(obj, args);
    return interop.js_to_mal(res);
}

// types.ns is namespace of type functions
var ns = {'type': types._obj_type,
          '=': types._equal_Q,
          'throw': mal_throw,
          'nil?': types._nil_Q,
          'true?': types._true_Q,
          'false?': types._false_Q,
          'number?': types._number_Q,
          'string?': types._string_Q,
          'symbol': types._symbol,
          'symbol?': types._symbol_Q,
          'keyword': types._keyword,
          'keyword?': types._keyword_Q,
          'fn?': types._fn_Q,
          'macro?': types._macro_Q,

          'pr-str': pr_str,
          'str': str,
          'prn': prn,
          'println': println,
          'readline': IO.readline,
          'read-string': reader.read_str,
          'slurp': slurp,
          '<'  : function(a,b){return a<b;},
          '<=' : function(a,b){return a<=b;},
          '>'  : function(a,b){return a>b;},
          '>=' : function(a,b){return a>=b;},
          '+'  : function(a,b){return a+b;},
          '-'  : function(a,b){return a-b;},
          '*'  : function(a,b){return a*b;},
          '/'  : function(a,b){return a/b;},
          "time-ms": time_ms,

          'list': types._list,
          'list?': types._list_Q,
          'vector': types._vector,
          'vector?': types._vector_Q,
          'hash-map': types._hash_map,
          'map?': types._hash_map_Q,
          'assoc': assoc,
          'dissoc': dissoc,
          'get': get,
          'contains?': contains_Q,
          'keys': keys,
          'vals': vals,

          'sequential?': types._sequential_Q,
          'cons': cons,
          'concat': concat,
          'vec': vec,
          'nth': nth,
          'first': first,
          'rest': rest,
          'empty?': empty_Q,
          'count': count,
          'apply': apply,
          'map': map,

          'conj': conj,
          'seq': seq,

          'with-meta': with_meta,
          'meta': meta,
          'atom': types._atom,
          'atom?': types._atom_Q,
          "deref": deref,
          "reset!": reset_BANG,
          "swap!": swap_BANG,

          'js-eval': js_eval,
          '.': js_method_call
};

exports.ns = core.ns = ns;

// Node vs browser behavior
var interop = {};
if (RUNTIME !== 'node') {
    var exports = interop;
}
// Determine global object across runtimes
var GLOBAL;
if (RUNTIME === 'node') { GLOBAL = global; }
else if (false) { GLOBAL = window; }
else if (RUNTIME === 'jscript') { GLOBAL = this; }
else if (typeof System !== 'undefined') { GLOBAL = this; }
else { GLOBAL = this; }

function resolve_js(str) {
    if (str.match(/\./)) {
        var re = /^(.*)\.[^\.]*$/,
            match = re.exec(str);
        return [eval(match[1]), eval(str)];
    } else {
        return [GLOBAL, eval(str)];
    }
}

function js_to_mal(obj) {
    if (obj === null || obj === undefined) {
        return null;
    }
    var cache = [];
    var str = JSON.stringify(obj, function(key, value) {
        if (typeof value === 'object' && value !== null) {
            if (_indexOf(cache, value) !== -1) {
                // Circular reference found, discard key
                return;
            }
            // Store value in our collection
            cache.push(value);
        }
        return value;
    });
    cache = null; // Enable garbage collection
    return JSON.parse(str);
}

exports.resolve_js = interop.resolve_js = resolve_js;
exports.js_to_mal = interop.js_to_mal = js_to_mal;

if (RUNTIME === 'node') {
    var printer = __noop__('./printer');
    var IO = __noop__('./io');
}

// read
function READ(str) {
    return str;
}

// eval
function EVAL(ast, env) {
    return ast;
}

// print
function PRINT(exp) {
    return exp;
}

// repl
var rep = function(str) { return PRINT(EVAL(READ(str), {})); };

// repl loop
if (typeof RUNTIME !== 'undefined') {
    // jscript/jsc: always main
    while (true) {
        var line = IO.readline("user> ");
        if (line === null) { break; }
        if (line) { IO.println(rep(line)); }
    }
} else if (typeof require !== 'undefined' && require.main === module) {
    // node
    while (true) {
        var line = IO.readline("user> ");
        if (line === null) { break; }
        if (line) { IO.println(rep(line)); }
    }
}
