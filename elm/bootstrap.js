var readline = require('./node_readline');

// The first two arguments are: 'node' and 'bootstrap.js'
// The third argument is the name of the Elm module to load.
var args = process.argv.slice(2);
var mod = require('./' + args[0]);

var app = mod.Main.worker({
    args: args.slice(1)
});

// Hook up the output and readLine ports of the app.
app.ports.output.subscribe(function(line) {
    console.log(line);
});

app.ports.readLine.subscribe(function(prompt) {
    var line = readline.readline(prompt);
    app.ports.input.send(line);
});
