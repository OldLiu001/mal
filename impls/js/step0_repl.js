if (typeof module !== 'undefined') {
    var printer = require('./printer');
    var IO = require('./io');
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
