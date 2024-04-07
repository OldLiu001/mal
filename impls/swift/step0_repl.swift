//******************************************************************************
// MAL - step 0 - repl
//******************************************************************************
// This file is automatically generated from templates/step.swift. Rather than
// editing it directly, it's probably better to edit templates/step.swift and
// regenerate this file. Otherwise, your change might be lost if/when someone
// else performs that process.
//******************************************************************************

import Foundation

// Parse the string into an AST.
//
private func READ(str: String) -> String {
    return str
}

// Walk the AST and completely evaluate it, handling macro expansions, special
// forms and function calls.
//
private func EVAL(ast: String) -> String {
    return ast
}

// Convert the value into a human-readable string for printing.
//
private func PRINT(exp: String) -> String {
    return exp
}

// Perform the READ and EVAL steps. Useful for when you don't care about the
// printable result.
//
private func RE(text: String) -> String {
    let ast = READ(text)
    let exp = EVAL(ast)
    return exp
}

// Perform the full READ/EVAL/PRINT, returning a printable string.
//
private func REP(text: String) -> String {
    let exp = RE(text)
    return PRINT(exp)
}

// Perform the full REPL.
//
private func REPL() {
    while true {
        if let text = _readline("user> ") {
            print("\(REP(text))")
        } else {
            print("")
            break
        }
    }
}

func main() {
    load_history_file()
    REPL()
    save_history_file()
}
