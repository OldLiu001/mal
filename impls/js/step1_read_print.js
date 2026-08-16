if (typeof module !== 'undefined') {
    var types = require('./types');
    var reader = require('./reader');
    var printer = require('./printer');
    var IO = require('./io');
}

// read
function READ(str) {
    return reader.read_str(str);
}

// eval
function EVAL(ast, env) {
    return ast;
}

// print
function PRINT(exp) {
    return printer._pr_str(exp, true);
}

// repl
var re = function(str) { return EVAL(READ(str), {}); };
var rep = function(str) { return PRINT(EVAL(READ(str), {})); };

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
