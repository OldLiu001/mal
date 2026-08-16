// runtime.js - Runtime detection and ES5 polyfills for multi-runtime support
// Supports: node, jscript (cscript/wscript), jsc (JScript.NET)

var RUNTIME = (function() {
    if (typeof WScript !== 'undefined') {
        return 'jscript';
    }
    if (typeof System !== 'undefined' && typeof System.Console !== 'undefined') {
        return 'jsc';
    }
    if (typeof process !== 'undefined' && process.versions && process.versions.node) {
        return 'node';
    }
    // Fallback: assume browser/unknown
    return 'unknown';
})();

// ---- ES5 Polyfills (for JScript 5.x / JSC.NET which are ES3) ----

// Array.isArray
if (typeof Array.isArray !== 'function') {
    Array.isArray = function(arg) {
        return Object.prototype.toString.call(arg) === '[object Array]';
    };
}

// Object.keys
if (typeof Object.keys !== 'function') {
    Object.keys = function(o) {
        var ret = [];
        for (var k in o) {
            if (o.hasOwnProperty(k)) {
                ret.push(k);
            }
        }
        return ret;
    };
}

// Array.prototype.map
if (typeof Array.prototype.map !== 'function') {
    Array.prototype.map = function(callback, thisArg) {
        var T, A, k;
        if (this == null) throw new TypeError(" this is null or not defined");
        var O = Object(this);
        var len = O.length >>> 0;
        if (typeof callback !== "function") throw new TypeError(callback + " is not a function");
        if (thisArg) T = thisArg;
        A = new Array(len);
        k = 0;
        while (k < len) {
            var kValue, mappedValue;
            if (k in O) {
                kValue = O[k];
                mappedValue = callback.call(T, kValue, k, O);
                A[k] = mappedValue;
            }
            k++;
        }
        return A;
    };
}

// Array.prototype.reduceRight
if (typeof Array.prototype.reduceRight !== 'function') {
    Array.prototype.reduceRight = function(callback /*, initialValue*/) {
        if (null === this || 'undefined' === typeof this) {
            throw new TypeError("Array.prototype.reduceRight called on null or undefined");
        }
        if ('function' !== typeof callback) {
            throw new TypeError(callback + " is not a function");
        }
        var t = Object(this), len = t.length >>> 0, k = len - 1, value;
        if (arguments.length >= 2) {
            value = arguments[1];
        } else {
            while (k >= 0 && !(k in t)) { k--; }
            if (k < 0) {
                throw new TypeError("Reduce of empty array with no initial value");
            }
            value = t[k--];
        }
        for (; k >= 0; k--) {
            if (k in t) {
                value = callback(value, t[k], k, t);
            }
        }
        return value;
    };
}

// Array.prototype.forEach
if (typeof Array.prototype.forEach !== 'function') {
    Array.prototype.forEach = function(callback, thisArg) {
        var T, k;
        if (this == null) throw new TypeError("this is null or not defined");
        var O = Object(this);
        var len = O.length >>> 0;
        if (typeof callback !== "function") throw new TypeError(callback + " is not a function");
        if (thisArg) T = thisArg;
        k = 0;
        while (k < len) {
            var kValue;
            if (k in O) {
                kValue = O[k];
                callback.call(T, kValue, k, O);
            }
            k++;
        }
    };
}

// Array.prototype.filter
if (typeof Array.prototype.filter !== 'function') {
    Array.prototype.filter = function(fun /*, thisArg */) {
        if (this === void 0 || this === null) throw new TypeError();
        var t = Object(this);
        var len = t.length >>> 0;
        if (typeof fun !== "function") throw new TypeError();
        var res = [];
        var thisArg = arguments.length >= 2 ? arguments[1] : void 0;
        for (var i = 0; i < len; i++) {
            if (i in t) {
                var val = t[i];
                if (fun.call(thisArg, val, i, t)) {
                    res.push(val);
                }
            }
        }
        return res;
    };
}

// Array.prototype.indexOf
if (typeof Array.prototype.indexOf !== 'function') {
    Array.prototype.indexOf = function(searchElement, fromIndex) {
        var k;
        if (this == null) throw new TypeError('"this" is null or not defined');
        var O = Object(this);
        var len = O.length >>> 0;
        if (len === 0) return -1;
        var n = +fromIndex || 0;
        if (Math.abs(n) === Infinity) n = 0;
        if (n >= len) return -1;
        k = Math.max(n >= 0 ? n : len - Math.abs(n), 0);
        while (k < len) {
            if (k in O && O[k] === searchElement) return k;
            k++;
        }
        return -1;
    };
}

// String.prototype.trim
if (typeof String.prototype.trim !== 'function') {
    String.prototype.trim = function() {
        return this.replace(/^\s+|\s+$/g, '');
    };
}

// Function.prototype.bind
if (typeof Function.prototype.bind !== 'function') {
    Function.prototype.bind = function(oThis) {
        if (typeof this !== "function") {
            throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");
        }
        var aArgs = Array.prototype.slice.call(arguments, 1),
            fToBind = this,
            fNOP = function() {},
            fBound = function() {
                return fToBind.apply(this instanceof fNOP && oThis
                    ? this
                    : oThis,
                    aArgs.concat(Array.prototype.slice.call(arguments)));
            };
        fNOP.prototype = this.prototype;
        fBound.prototype = new fNOP();
        return fBound;
    };
}

// JSON polyfill (based on Douglas Crockford's json2.js, simplified)
if (typeof JSON !== 'object') {
    JSON = {};
}
if (typeof JSON.stringify !== 'function') {
    JSON.stringify = function(value, replacer, space) {
        var i, gap = '', indent = '';
        if (typeof space === 'number') {
            for (i = 0; i < space; i += 1) { indent += ' '; }
            gap = indent;
        } else if (typeof space === 'string') {
            gap = space;
        }
        function quote(string) {
            var escapable = /[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;
            var meta = { '\b': '\\b', '\t': '\\t', '\n': '\\n', '\f': '\\f', '\r': '\\r', '"': '\\"', '\\': '\\\\' };
            escapable.lastIndex = 0;
            return escapable.test(string) ? '"' + string.replace(escapable, function(a) {
                var c = meta[a];
                return typeof c === 'string' ? c : '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
            }) + '"' : '"' + string + '"';
        }
        function str(key, holder) {
            var mind = gap, partial, value = holder[key];
            if (value && typeof value === 'object' && typeof value.toJSON === 'function') {
                value = value.toJSON(key);
            }
            if (typeof replacer === 'function') {
                value = replacer.call(holder, key, value);
            }
            switch (typeof value) {
            case 'string': return quote(value);
            case 'number': return isFinite(value) ? String(value) : 'null';
            case 'boolean':
            case 'null': return String(value);
            case 'object':
                if (!value) return 'null';
                gap += indent;
                partial = [];
                if (Object.prototype.toString.apply(value) === '[object Array]') {
                    for (i = 0; i < value.length; i += 1) {
                        partial[i] = str(i, value) || 'null';
                    }
                    return partial.length === 0 ? '[]' : gap ? '[\n' + gap + partial.join(',\n' + gap) + '\n' + mind + ']' : '[' + partial.join(',') + ']';
                }
                var k;
                if (replacer && typeof replacer === 'object') {
                    for (i in replacer) {
                        if (Object.prototype.hasOwnProperty.call(replacer, i)) {
                            var v;
                            if (typeof replacer[i] === 'string') {
                                v = str(replacer[i], value);
                                if (v) partial.push(quote(replacer[i]) + (gap ? ': ' : ':') + v);
                            }
                        }
                    }
                } else {
                    for (k in value) {
                        if (Object.prototype.hasOwnProperty.call(value, k)) {
                            v = str(k, value);
                            if (v) partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
                return partial.length === 0 ? '{}' : gap ? '{\n' + gap + partial.join(',\n' + gap) + '\n' + mind + '}' : '{' + partial.join(',') + '}';
            }
        }
        return str('', {'': value});
    };
}
if (typeof JSON.parse !== 'function') {
    JSON.parse = function(text, reviver) {
        var j;
        function walk(holder, key) {
            var k, v, value = holder[key];
            if (value && typeof value === 'object') {
                for (k in value) {
                    if (Object.prototype.hasOwnProperty.call(value, k)) {
                        v = walk(value, k);
                        if (v !== undefined) {
                            value[k] = v;
                        } else {
                            delete value[k];
                        }
                    }
                }
            }
            return reviver.call(holder, key, value);
        }
        text = String(text);
        var cx = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;
        cx.lastIndex = 0;
        if (cx.test(text)) {
            text = text.replace(cx, function(a) {
                return '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
            });
        }
        if (/^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
            j = eval('(' + text + ')');
            return typeof reviver === 'function' ? walk({'': j}, '') : j;
        }
        throw new SyntaxError('JSON.parse');
    };
}

// For Node.js, export RUNTIME
if (typeof module !== 'undefined' && module.exports) {
    module.exports.RUNTIME = RUNTIME;
}
// io.js - Unified I/O abstraction for node/jscript/jsc runtimes
// Provides: readline, println, writeErr, writeErrLine, slurp, args, exit, isMain

var IO = {};

(function() {
    // Auto-detect runtime if not already set by runtime.js
    if (typeof RUNTIME === 'undefined') {
        if (typeof WScript !== 'undefined') { RUNTIME = 'jscript'; }
        else if (typeof System !== 'undefined' && typeof System.Console !== 'undefined') { RUNTIME = 'jsc'; }
        else if (typeof process !== 'undefined' && process.versions && process.versions.node) { RUNTIME = 'node'; }
        else { RUNTIME = 'unknown'; }
    }
    if (RUNTIME === 'node') {
        var fs_node = require('fs');
        var path_node = require('path');

        IO.readline = function(prompt) {
            // Use simple synchronous readline via process.stdin
            // (ffi-napi readline is optional, fallback to simple stdin)
            if (typeof readline_sync !== 'undefined') {
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
if (typeof module !== 'undefined' && module.exports) {
    module.exports = IO;
}
// Node vs browser behavior
var types = {};
if (typeof module === 'undefined') {
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
        if (Object.keys(a).length !== Object.keys(b).length) { return false; }
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
        new_obj = obj.clone();
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
function _function(Eval, Env, ast, env, params) {
    var fn = function() {
        return Eval(ast, new Env(env, params, arguments));
    };
    fn.__meta__ = null;
    fn.__ast__ = ast;
    fn.__gen_env__ = function(args) { return new Env(env, params, args); };
    fn._ismacro_ = false;
    return fn;
}
function _function_Q(obj) { return typeof obj == "function"; }
Function.prototype.clone = function() {
    var that = this;
    var temp = function () { return that.apply(this, arguments); };
    for( key in this ) {
        temp[key] = this[key];
    }
    return temp;
};
function _fn_Q(obj) { return _function_Q(obj) && !obj._ismacro_; }
function _macro_Q(obj) { return _function_Q(obj) && !!obj._ismacro_; }


// Lists
function _list() { return Array.prototype.slice.call(arguments, 0); }
function _list_Q(obj) { return Array.isArray(obj) && !obj.__isvector__; }


// Vectors
function _vector() {
    var v = Array.prototype.slice.call(arguments, 0);
    v.__isvector__ = true;
    return v;
}
function _vector_Q(obj) { return Array.isArray(obj) && !!obj.__isvector__; }



// Hash Maps
function _hash_map() {
    if (arguments.length % 2 === 1) {
        throw new Error("Odd number of hash map arguments");
    }
    var args = [{}].concat(Array.prototype.slice.call(arguments, 0));
    return _assoc_BANG.apply(null, args);
}
function _hash_map_Q(hm) {
    return typeof hm === "object" &&
           !Array.isArray(hm) &&
           !(hm === null) &&
           !(hm instanceof Symbol) &&
           !(hm instanceof Atom);
}
function _assoc_BANG(hm) {
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
function _dissoc_BANG(hm) {
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
if (typeof module !== 'undefined') {
    var types = require('./types');
} else {
    var exports = reader;
}

function Reader(tokens) {
    // copy
    this.tokens = tokens.map(function (a) { return a; });
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
if (typeof module !== 'undefined') {
    var types = require('./types');
    var IO = require('./io');
}
// map output/print to IO.println (works across all runtimes)
printer.println = exports.println = function () {
    var args = Array.prototype.slice.call(arguments);
    IO.println(args.join(' '));
};

function _pr_str(obj, print_readably) {
    if (typeof print_readably === 'undefined') { print_readably = true; }
    var _r = print_readably;
    var ot = types._obj_type(obj);
    switch (ot) {
    case 'list':
        var ret = obj.map(function(e) { return _pr_str(e,_r); });
        return "(" + ret.join(' ') + ")";
    case 'vector':
        var ret = obj.map(function(e) { return _pr_str(e,_r); });
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
if (typeof module === 'undefined') {
    var exports = env;
}

// Env implementation
function Env(outer, binds, exprs) {
    this.data = {};
    this.outer = outer || null;

    if (binds && exprs) {
        // Returns a new Env with symbols in binds bound to
        // corresponding values in exprs
        // TODO: check types of binds and exprs and compare lengths
        for (var i=0; i<binds.length;i++) {
            if (binds[i].value === "&") {
                // variable length arguments
                this.data[binds[i+1].value] = Array.prototype.slice.call(exprs, i);
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
if (typeof module === 'undefined') {
    var exports = core;
} else {
    var types = require('./types'),
        reader = require('./reader'),
        printer = require('./printer'),
        interop = require('./interop');
    var IO = require('./io');
}

// Errors/Exceptions
function mal_throw(exc) { throw exc; }


// String functions
function pr_str() {
    return Array.prototype.map.call(arguments,function(exp) {
        return printer._pr_str(exp, true);
    }).join(" ");
}

function str() {
    return Array.prototype.map.call(arguments,function(exp) {
        return printer._pr_str(exp, false);
    }).join("");
}

function prn() {
    printer.println.apply({}, Array.prototype.map.call(arguments,function(exp) {
        return printer._pr_str(exp, true);
    }));
}

function println() {
    printer.println.apply({}, Array.prototype.map.call(arguments,function(exp) {
        return printer._pr_str(exp, false);
    }));
}

function slurp(f) {
    return IO.slurp(f);
}


// Number functions
function time_ms() { return new Date().getTime(); }


// Hash Map functions
function assoc(src_hm) {
    var hm = types._clone(src_hm);
    var args = [hm].concat(Array.prototype.slice.call(arguments, 1));
    return types._assoc_BANG.apply(null, args);
}

function dissoc(src_hm) {
    var hm = types._clone(src_hm);
    var args = [hm].concat(Array.prototype.slice.call(arguments, 1));
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

function keys(hm) { return Object.keys(hm).filter(function(k) { return k !== '__meta__' && k !== '__isvector__'; }); }
function vals(hm) { return Object.keys(hm).filter(function(k) { return k !== '__meta__' && k !== '__isvector__'; }).map(function(k) { return hm[k]; }); }


// Sequence functions
function cons(a, b) { return [a].concat(b); }

function concat(lst) {
    lst = lst || [];
    return lst.concat.apply(lst, Array.prototype.slice.call(arguments, 1));
}
function vec(lst) {
    if (types._list_Q(lst)) {
        var v = Array.prototype.slice.call(lst, 0);
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
    if (Array.isArray(s)) { return s.length; }
    else if (s === null)  { return 0; }
    else                  { return Object.keys(s).length; }
}

function conj(lst) {
    if (types._list_Q(lst)) {
        return Array.prototype.slice.call(arguments, 1).reverse().concat(lst);
    } else {
        var v = lst.concat(Array.prototype.slice.call(arguments, 1));
        v.__isvector__ = true;
        return v;
    }
}

function seq(obj) {
    if (types._list_Q(obj)) {
        return obj.length > 0 ? obj : null;
    } else if (types._vector_Q(obj)) {
        return obj.length > 0 ? Array.prototype.slice.call(obj, 0): null;
    } else if (types._string_Q(obj)) {
        return obj.length > 0 ? obj.split('') : null;
    } else if (obj === null) {
        return null;
    } else {
        throw new Error("seq: called on non-sequence");
    }
}


function apply(f) {
    var args = Array.prototype.slice.call(arguments, 1);
    return f.apply(f, args.slice(0, args.length-1).concat(args[args.length-1]));
}

function map(f, lst) {
    return lst.map(function(el){ return f(el); });
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
function swap_BANG(atm, f) {
    var args = [atm.val].concat(Array.prototype.slice.call(arguments, 2));
    atm.val = f.apply(f, args);
    return atm.val;
}

function js_eval(str) {
    return interop.js_to_mal(eval(str.toString()));
}

function js_method_call(object_method_str) {
    var args = Array.prototype.slice.call(arguments, 1),
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
if (typeof module === 'undefined') {
    var exports = interop;
}
// Determine global object across runtimes
var GLOBAL;
if (typeof global !== 'undefined') { GLOBAL = global; }
else if (typeof window !== 'undefined') { GLOBAL = window; }
else if (typeof WScript !== 'undefined') { GLOBAL = this; }
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
            if (cache.indexOf(value) !== -1) {
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
if (typeof module !== 'undefined') {
    var types = require('./types');
    var reader = require('./reader');
    var printer = require('./printer');
    var Env = require('./env').Env;
    var core = require('./core');
    var IO = require('./io');
}

// read
function READ(str) {
    return reader.read_str(str);
}

// eval
function qqLoop (acc, elt) {
    if (types._list_Q(elt) && elt.length
        && types._symbol_Q(elt[0]) && elt[0].value == 'splice-unquote') {
        return [types._symbol("concat"), elt[1], acc];
    } else {
        return [types._symbol("cons"), quasiquote (elt), acc];
    }
}
function quasiquote(ast) {
    if (types._list_Q(ast) && 0<ast.length
        && types._symbol_Q(ast[0]) && ast[0].value == 'unquote') {
        return ast[1];
    } else if (types._list_Q(ast)) {
        return ast.reduceRight(qqLoop,[]);
    } else if (types._vector_Q(ast)) {
        return [types._symbol("vec"), ast.reduceRight(qqLoop,[])];
    } else if (types._symbol_Q(ast) || types._hash_map_Q(ast)) {
        return [types._symbol("quote"), ast];
    } else {
        return ast;
    }
}

function _EVAL(ast, env) {
    while (true) {
    // Show a trace if DEBUG-EVAL is enabled.
    var dbgevalenv = env.find("DEBUG-EVAL");
    if (dbgevalenv !== null) {
        var dbgeval = env.get("DEBUG-EVAL");
        if (dbgeval !== null && dbgeval !== false)
            printer.println("EVAL:", printer._pr_str(ast, true));
    }
    // Non-list types.
    if (types._symbol_Q(ast)) {
        return env.get(ast.value);
    } else if (types._list_Q(ast)) {
        // Exit this switch.
    } else if (types._vector_Q(ast)) {
        var v = ast.map(function(a) { return EVAL(a, env); });
        v.__isvector__ = true;
        return v;
    } else if (types._hash_map_Q(ast)) {
        var new_hm = {};
        for (k in ast) {
            new_hm[k] = EVAL(ast[k], env);
        }
        return new_hm;
    } else {
        return ast;
    }
    // apply list
    if (ast.length === 0) {
        return ast;
    }

    var a0 = ast[0], a1 = ast[1], a2 = ast[2], a3 = ast[3];
    switch (a0.value) {
    case "def!":
        var res = EVAL(a2, env);
        if (!types._symbol_Q(a1)) {
            throw new Error("env.get key must be a symbol")
        }
        return env.set(a1.value, res);
    case "let*":
        var let_env = new Env(env);
        for (var i=0; i < a1.length; i+=2) {
            if (!types._symbol_Q(a1[i])) {
                throw new Error("env.get key must be a symbol")
            }
            let_env.set(a1[i].value, EVAL(a1[i+1], let_env));
        }
        ast = a2;
        env = let_env;
        break;
    case "quote":
        return a1;
    case "quasiquote":
        ast = quasiquote(a1);
        break;
    case 'defmacro!':
        var func = types._clone(EVAL(a2, env));
        func._ismacro_ = true;
        if (!types._symbol_Q(a1)) {
            throw new Error("env.get key must be a symbol")
        }
        return env.set(a1.value, func);
    case "do":
        for (var i=1; i < ast.length - 1; i++) {
            EVAL(ast[i], env);
        }
        ast = ast[ast.length-1];
        break;
    case "if":
        var cond = EVAL(a1, env);
        if (cond === null || cond === false) {
            ast = (typeof a3 !== "undefined") ? a3 : null;
        } else {
            ast = a2;
        }
        break;
    case "fn*":
        return types._function(EVAL, Env, a2, env, a1);
    default:
        var f = EVAL(a0, env);
        if (f._ismacro_) {
            ast = f.apply(f, ast.slice(1));
            break;
        }
        var args = ast.slice(1).map(function(a) { return EVAL(a, env); });
        if (f.__ast__) {
            ast = f.__ast__;
            env = f.__gen_env__(args);
        } else {
            return f.apply(f, args);
        }
    }

    }
}

function EVAL(ast, env) {
    var result = _EVAL(ast, env);
    return (typeof result !== "undefined") ? result : null;
}

// print
function PRINT(exp) {
    return printer._pr_str(exp, true);
}

// repl
var repl_env = new Env();
var rep = function(str) { return PRINT(EVAL(READ(str), repl_env)); };

// core.js: defined using javascript
for (var n in core.ns) { repl_env.set(n, core.ns[n]); }
repl_env.set('eval', function(ast) {
    return EVAL(ast, repl_env); });
repl_env.set('*ARGV*', []);

// core.mal: defined using the language itself
rep("(def! not (fn* (a) (if a false true)))");
rep("(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\nnil)\")))))");
rep("(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))");

if (typeof RUNTIME !== 'undefined') {
    if (IO.args.length > 0) {
        repl_env.set(types._symbol('*ARGV*'), IO.args.slice(1));
        rep('(load-file "' + IO.args[0].replace(/\\/g, '/') + '")');
        IO.exit(0);
    }
} else if (typeof process !== 'undefined' && process.argv.length > 2) {
    repl_env.set(types._symbol('*ARGV*'), process.argv.slice(3));
    rep('(load-file "' + process.argv[2] + '")');
    process.exit(0);
}

// repl loop
if (typeof RUNTIME !== 'undefined') {
    // jscript/jsc: always main
    while (true) {
        var line = IO.readline("user> ");
        if (line === null) { break; }
        try {
            if (line) { IO.println(rep(line)); }
        } catch (exc) {
            if (exc instanceof reader.BlankException) { continue }
            if (exc instanceof Error) { IO.writeErrLine(exc.message || exc.description || exc.toString()) }
            else { IO.writeErrLine("Error: " + printer._pr_str(exc, true)) }
        }
    }
} else if (typeof require !== 'undefined' && require.main === module) {
    // node
    while (true) {
        var line = IO.readline("user> ");
        if (line === null) { break; }
        try {
            if (line) { IO.println(rep(line)); }
        } catch (exc) {
            if (exc instanceof reader.BlankException) { continue }
            if (exc instanceof Error) { console.warn(exc.stack) }
            else { console.warn("Error: " + printer._pr_str(exc, true)) }
        }
    }
}
