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
