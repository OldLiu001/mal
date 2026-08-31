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
