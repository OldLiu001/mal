//******************************************************************************
// MAL - step 2 - eval
//******************************************************************************
// This file is automatically generated from templates/step.swift. Rather than
// editing it directly, it's probably better to edit templates/step.swift and
// regenerate this file. Otherwise, your change might be lost if/when someone
// else performs that process.
//******************************************************************************

import Foundation

// Parse the string into an AST.
//
private func READ(str: String) throws -> MalVal {
    return try read_str(str)
}

// Perform a simple evaluation of the `ast` object. If it's a symbol,
// dereference it and return its value. If it's a collection, call EVAL on all
// elements (or just the values, in the case of the hashmap). Otherwise, return
// the object unchanged.
//
private func eval_ast(ast: MalVal, _ env: Environment) throws -> MalVal {
    if let symbol = as_symbolQ(ast) {
        guard let val = env.get(symbol) else {
            try throw_error("'\(symbol)' not found")    // Specific text needed to match MAL unit tests
        }
        return val
    }
    if let list = as_listQ(ast) {
        var result = [MalVal]()
        result.reserveCapacity(Int(list.count))
        for item in list {
            let eval = try EVAL(item, env)
            result.append(eval)
        }
        return make_list(result)
    }
    if let vec = as_vectorQ(ast) {
        var result = [MalVal]()
        result.reserveCapacity(Int(vec.count))
        for item in vec {
            let eval = try EVAL(item, env)
            result.append(eval)
        }
        return make_vector(result)
    }
    if let hash = as_hashmapQ(ast) {
        var result = [MalVal]()
        result.reserveCapacity(Int(hash.count) * 2)
        for (k, v) in hash {
            let new_v = try EVAL(v, env)
            result.append(k)
            result.append(new_v)
        }
        return make_hashmap(result)
    }
    return ast
}

// Walk the AST and completely evaluate it, handling macro expansions, special
// forms and function calls.
//
private func EVAL(ast: MalVal, _ env: Environment) throws -> MalVal {

        if !is_list(ast) {

            // Not a list -- just evaluate and return.

            let answer = try eval_ast(ast, env)
            return answer
        }

        // Special handling if it's a list.

        let list = as_list(ast)

        if list.isEmpty {
            return ast
        }

        // Standard list to be applied. Evaluate all the elements first.

        let eval = try eval_ast(ast, env)

        // The result had better be a list and better be non-empty.

        let eval_list = as_list(eval)
        if eval_list.isEmpty {
            return eval
        }

        // Get the first element of the list and execute it.

        let first = eval_list.first()
        let rest = as_sequence(eval_list.rest())

        if let fn = as_builtinQ(first) {
            let answer = try fn.apply(rest)
            return answer
        }

        // The first element wasn't a function to be executed. Return an
        // error saying so.

        try throw_error("first list item does not evaluate to a function: \(first)")
}

// Convert the value into a human-readable string for printing.
//
private func PRINT(exp: MalVal) -> String {
    return pr_str(exp, true)
}

// Perform the READ and EVAL steps. Useful for when you don't care about the
// printable result.
//
private func RE(text: String, _ env: Environment) -> MalVal? {
    if !text.isEmpty {
        do {
            let ast = try READ(text)
            do {
                return try EVAL(ast, env)
            } catch let error as MalException {
                print("Error evaluating input: \(error)")
            } catch {
                print("Error evaluating input: \(error)")
            }
        } catch let error as MalException {
            print("Error parsing input: \(error)")
        } catch {
            print("Error parsing input: \(error)")
        }
    }
    return nil
}

// Perform the full READ/EVAL/PRINT, returning a printable string.
//
private func REP(text: String, _ env: Environment) -> String? {
    let exp = RE(text, env)
    if exp == nil { return nil }
    return PRINT(exp!)
}

// Perform the full REPL.
//
private func REPL(env: Environment) {
    while true {
        if let text = _readline("user> ") {
            if let output = REP(text, env) {
                print("\(output)")
            }
        } else {
            print("")
            break
        }
    }
}

func main() {
    let env = Environment(outer: nil)

    load_history_file()
    load_builtins(env)

    REPL(env)

    save_history_file()
}
