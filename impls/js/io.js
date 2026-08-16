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
