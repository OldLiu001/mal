import System;
import System.IO;
// Test basic ES3 features
var arr = [1,2,3];
var mapped = [];
for (var i = 0; i < arr.length; i++) { mapped.push(arr[i] * 2); }
Console.WriteLine("mapped: " + mapped.join(","));

// Test StdIn
Console.Write("input> ");
var line = Console.ReadLine();
Console.WriteLine("echo: " + line);

// Test File read
try {
    var content = File.ReadAllText("test_jsc.js");
    Console.WriteLine("file length: " + content.length);
} catch(e) {
    Console.WriteLine("file err: " + e);
}
