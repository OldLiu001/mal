//******************************************************************************
// MAL - step A - mal
//******************************************************************************
// This file is automatically generated from templates/step.swift. Rather than
// editing it directly, it's probably better to edit templates/step.swift and
// regenerate this file. Otherwise, your change might be lost if/when someone
// else performs that process.
//******************************************************************************

import Foundation

// The number of times EVAL has been entered recursively. We keep track of this
// so that we can protect against overrunning the stack.
//
private var EVAL_level = 0

// The maximum number of times we let EVAL recurse before throwing an exception.
// Testing puts this at some place between 1800 and 1900. Let's keep it at 500
// for safety's sake.
//
private let EVAL_leval_max = 500

// Control whether or not tail-call optimization (TCO) is enabled. We want it
// `true` most of the time, but may disable it for debugging purposes (it's
// easier to get a meaningful backtrace that way).
//
private let TCO = true

// Control whether or not we emit debugging statements in EVAL.
//
private let DEBUG_EVAL = false

// String used to prefix information logged in EVAL. Increasing lengths of the
// string are used the more EVAL is recursed.
//
private let INDENT_TEMPLATE = "|----|----|----|----|----|----|----|----|" +
    "----|----|----|----|----|----|----|----|----|----|----|" +
    "----|----|----|----|----|----|----|----|----|----|----|" +
    "----|----|----|----|----|----|----|----|----|----|----|" +
    "----|----|----|----|----|----|----|----|----|----|----|" +
    "----|----|----|----|----|----|----|----|----|----|----|" +
    "----|----|----|----|----|----|----|----|----|----|----|" +
    "----|----|----|----|----|----|----|----|----|----|----|" +
    "----|----|----|----|----|----|----|----|----|----|----|" +
    "----|----|----|----|----|----|----|----|----|----|----|" +
    "----|----|----|----|----|----|----|----|----|----|----|"

// Holds the prefix of INDENT_TEMPLATE used for actual logging.
//
private var indent = String()

// Symbols used in this module.
//
private let kValArgv          = make_symbol("*ARGV*")
private let kValCatch         = make_symbol("catch*")
private let kValConcat        = make_symbol("concat")
private let kValCons          = make_symbol("cons")
private let kValDef           = make_symbol("def!")
private let kValDefMacro      = make_symbol("defmacro!")
private let kValDo            = make_symbol("do")
private let kValEval          = make_symbol("eval")
private let kValFn            = make_symbol("fn*")
private let kValIf            = make_symbol("if")
private let kValLet           = make_symbol("let*")
private let kValMacroExpand   = make_symbol("macroexpand")
private let kValQuasiQuote    = make_symbol("quasiquote")
private let kValQuote         = make_symbol("quote")
private let kValSpliceUnquote = make_symbol("splice-unquote")
private let kValUnquote       = make_symbol("unquote")
private let kValTry           = make_symbol("try*")

private let kSymbolArgv          = as_symbol(kValArgv)
private let kSymbolCatch         = as_symbol(kValCatch)
private let kSymbolConcat        = as_symbol(kValConcat)
private let kSymbolCons          = as_symbol(kValCons)
private let kSymbolDef           = as_symbol(kValDef)
private let kSymbolDefMacro      = as_symbol(kValDefMacro)
private let kSymbolDo            = as_symbol(kValDo)
private let kSymbolEval          = as_symbol(kValEval)
private let kSymbolFn            = as_symbol(kValFn)
private let kSymbolIf            = as_symbol(kValIf)
private let kSymbolLet           = as_symbol(kValLet)
private let kSymbolMacroExpand   = as_symbol(kValMacroExpand)
private let kSymbolQuasiQuote    = as_symbol(kValQuasiQuote)
private let kSymbolQuote         = as_symbol(kValQuote)
private let kSymbolSpliceUnquote = as_symbol(kValSpliceUnquote)
private let kSymbolUnquote       = as_symbol(kValUnquote)
private let kSymbolTry           = as_symbol(kValTry)

func substring(s: String, _ begin: Int, _ end: Int) -> String {
    return s[s.startIndex.advancedBy(begin) ..< s.startIndex.advancedBy(end)]
}

// Parse the string into an AST.
//
private func READ(str: String) throws -> MalVal {
    return try read_str(str)
}

// Return whether or not `val` is a non-empty list.
//
private func is_pair(val: MalVal) -> Bool {
    if let seq = as_sequenceQ(val) {
        return !seq.isEmpty
    }
    return false
}

// Expand macros for as long as the expression looks like a macro invocation.
//
private func macroexpand(var ast: MalVal, _ env: Environment) throws -> MalVal {
    while true {
        if  let ast_as_list = as_listQ(ast) where !ast_as_list.isEmpty,
            let macro_name = as_symbolQ(ast_as_list.first()),
            let obj = env.get(macro_name),
            let macro = as_macroQ(obj)
        {
            let new_env = Environment(outer: macro.env)
            let rest = as_sequence(ast_as_list.rest())
            let _ = try new_env.set_bindings(macro.args, with_exprs: rest)
            ast = try EVAL(macro.body, new_env)
            continue
        }
        return ast
    }
}

// Evaluate `quasiquote`, possibly recursing in the process.
//
// As with quote, unquote, and splice-unquote, quasiquote takes a single
// parameter, typically a list. In the general case, this list is processed
// recursively as:
//
//  (quasiquote (first rest...)) -> (cons (quasiquote first) (quasiquote rest))
//
// In the processing of the parameter passed to it, quasiquote handles three
// special cases:
//
//  *   If the parameter is an atom or an empty list, the following expression
//      is formed and returned for evaluation:
//
//          (quasiquote atom-or-empty-list) -> (quote atom-or-empty-list)
//
//  *   If the first element of the non-empty list is the symbol "unquote"
//      followed by a second item, the second item is returned as-is:
//
//          (quasiquote (unquote fred)) -> fred
//
//  *   If the first element of the non-empty list is another list containing
//      the symbol "splice-unquote" followed by a list, that list is catenated
//      with the quasiquoted result of the remaining items in the non-empty
//      parent list:
//
//          (quasiquote (splice-unquote list) rest...) -> (items-from-list items-from-quasiquote(rest...))
//
// Note the inconsistent handling between "quote" and "splice-quote". The former
// is handled when this function is handed a list that starts with "quote",
// whereas the latter is handled when this function is handled a list whose
// first element is a list that starts with "splice-quote". The handling of the
// latter is forced by the need to incorporate the results of (splice-quote
// list) with the remaining items of the list containing that splice-quote
// expression. However, it's not clear to me why the handling of "unquote" is
// not handled similarly, for consistency's sake.
//
private func quasiquote(qq_arg: MalVal) throws -> MalVal {

    // If the argument is an atom or empty list:
    //
    // Return: (quote <argument>)

    if !is_pair(qq_arg) {
        return make_list_from(kValQuote, qq_arg)
    }

    // The argument is a non-empty list -- that is (item rest...)

    // If the first item from the list is a symbol and it's "unquote" -- that
    // is, (unquote item ignored...):
    //
    // Return: item

    let qq_list = as_sequence(qq_arg)
    if let sym = as_symbolQ(qq_list.first()) where sym == kSymbolUnquote {
        return qq_list.count >= 2 ? try! qq_list.nth(1) : make_nil()
    }

    // If the first item from the list is itself a non-empty list starting with
    // "splice-unquote"-- that is, ((splice-unquote item ignored...) rest...):
    //
    // Return: (concat item quasiquote(rest...))

    if is_pair(qq_list.first()) {
        let qq_list_item0 = as_sequence(qq_list.first())
        if let sym = as_symbolQ(qq_list_item0.first()) where sym == kSymbolSpliceUnquote {
            let result = try quasiquote(qq_list.rest())
            return make_list_from(kValConcat, try! qq_list_item0.nth(1), result)
        }
    }

    // General case: (item rest...):
    //
    // Return: (cons (quasiquote item) (quasiquote (rest...))

    let first = try quasiquote(qq_list.first())
    let rest = try quasiquote(qq_list.rest())
    return make_list_from(kValCons, first, rest)
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

private enum TCOVal {
    case NoResult
    case Return(MalVal)
    case Continue(MalVal, Environment)

    init() { self = .NoResult }
    init(_ result: MalVal) { self = .Return(result) }
    init(_ ast: MalVal, _ env: Environment) { self = .Continue(ast, env) }
}

// EVALuate "def!" and "defmacro!".
//
private func eval_def(list: MalSequence, _ env: Environment) throws -> TCOVal {
    guard list.count == 3 else {
        try throw_error("expected 2 arguments to def!, got \(list.count - 1)")
    }
    let arg0 = try! list.nth(0)
    let arg1 = try! list.nth(1)
    let arg2 = try! list.nth(2)
    guard let sym = as_symbolQ(arg1) else {
        try throw_error("expected symbol for first argument to def!")
    }
    var value = try EVAL(arg2, env)
    if as_symbol(arg0) == kSymbolDefMacro {
        guard let closure = as_closureQ(value) else {
            try throw_error("expected closure, got \(value)")
        }
        value = make_macro(closure)
    }
    return TCOVal(env.set(sym, value))
}

// EVALuate "let*".
//
private func eval_let(list: MalSequence, _ env: Environment) throws -> TCOVal {
    guard list.count == 3 else {
        try throw_error("expected 2 arguments to let*, got \(list.count - 1)")
    }
    let arg1 = try! list.nth(1)
    let arg2 = try! list.nth(2)
    guard let bindings = as_sequenceQ(arg1) else {
        try throw_error("expected list for first argument to let*")
    }
    guard bindings.count % 2 == 0 else {
        try throw_error("expected even number of elements in bindings to let*, got \(bindings.count)")
    }
    let new_env = Environment(outer: env)
    for var index: MalIntType = 0; index < bindings.count; index += 2 {
        let binding_name = try! bindings.nth(index)
        let binding_value = try! bindings.nth(index + 1)
        guard let binding_symbol = as_symbolQ(binding_name) else {
            try throw_error("expected symbol for first element in binding pair")
        }
        let evaluated_value = try EVAL(binding_value, new_env)
        new_env.set(binding_symbol, evaluated_value)
    }
    if TCO {
        return TCOVal(arg2, new_env)
    }
    return TCOVal(try EVAL(arg2, new_env))
}

// EVALuate "do".
//
private func eval_do(list: MalSequence, _ env: Environment) throws -> TCOVal {
    if TCO {
        let _ = try eval_ast(list.range_from(1, to: list.count-1), env)
        return TCOVal(list.last(), env)
    }

    let evaluated_ast = try eval_ast(list.rest(), env)
    let evaluated_seq = as_sequence(evaluated_ast)
    return TCOVal(evaluated_seq.last())
}

// EVALuate "if".
//
private func eval_if(list: MalSequence, _ env: Environment) throws -> TCOVal {
    guard list.count >= 3 else {
        try throw_error("expected at least 2 arguments to if, got \(list.count - 1)")
    }
    let cond_result = try EVAL(try! list.nth(1), env)
    var new_ast: MalVal
    if is_truthy(cond_result) {
        new_ast = try! list.nth(2)
    } else if list.count == 4 {
        new_ast = try! list.nth(3)
    } else {
        return TCOVal(make_nil())
    }
    if TCO {
        return TCOVal(new_ast, env)
    }
    return TCOVal(try EVAL(new_ast, env))
}

// EVALuate "fn*".
//
private func eval_fn(list: MalSequence, _ env: Environment) throws -> TCOVal {
    guard list.count == 3 else {
        try throw_error("expected 2 arguments to fn*, got \(list.count - 1)")
    }
    guard let seq = as_sequenceQ(try! list.nth(1)) else {
        try throw_error("expected list or vector for first argument to fn*")
    }
    return TCOVal(make_closure((eval: EVAL, args: seq, body: try! list.nth(2), env: env)))
}

// EVALuate "quote".
//
private func eval_quote(list: MalSequence, _ env: Environment) throws -> TCOVal {
    if list.count >= 2 {
        return TCOVal(try! list.nth(1))
    }
    return TCOVal(make_nil())
}

// EVALuate "quasiquote".
//
private func eval_quasiquote(list: MalSequence, _ env: Environment) throws -> TCOVal {
    guard list.count >= 2 else {
        try throw_error("Expected non-nil parameter to 'quasiquote'")
    }
    if TCO {
        return TCOVal(try quasiquote(try! list.nth(1)), env)
    }
    return TCOVal(try EVAL(try quasiquote(try! list.nth(1)), env))
}

// EVALuate "macroexpand".
//
private func eval_macroexpand(list: MalSequence, _ env: Environment) throws -> TCOVal {
    guard list.count >= 2 else {
        try throw_error("Expected parameter to 'macroexpand'")
    }
    return TCOVal(try macroexpand(try! list.nth(1), env))
}

// EVALuate "try*" (and "catch*").
//
private func eval_try(list: MalSequence, _ env: Environment) throws -> TCOVal {
    // This is a subset of the Clojure try/catch:
    //
    //      (try* expr (catch exception-name expr))

    guard list.count >= 2 else {
        try throw_error("try*: no body parameter")
    }

    do {
        return TCOVal(try EVAL(try! list.nth(1), env))
    } catch let error as MalException {
        guard list.count >= 3,
            let catch_list = as_sequenceQ(try! list.nth(2)) where catch_list.count >= 3,
            let _ = as_symbolQ(try! catch_list.nth(0)) else
        {
            throw error // No catch parameter
        }
        let catch_name = try! catch_list.nth(1)
        let catch_expr = try! catch_list.nth(2)
        let catch_env = Environment(outer: env)
        try catch_env.set_bindings(as_sequence(make_list_from(catch_name)),
                with_exprs: as_sequence(make_list_from(error.exception)))
        return TCOVal(try EVAL(catch_expr, catch_env))
    }
}

// Walk the AST and completely evaluate it, handling macro expansions, special
// forms and function calls.
//
private func EVAL(var ast: MalVal, var _ env: Environment) throws -> MalVal {
    EVAL_level++
    defer { EVAL_level-- }
    guard EVAL_level <= EVAL_leval_max else {
        try throw_error("Recursing too many levels (> \(EVAL_leval_max))")
    }

    if DEBUG_EVAL {
        indent = substring(INDENT_TEMPLATE, 0, EVAL_level)
    }

    while true {
        if DEBUG_EVAL { print("\(indent)>   \(ast)") }

        if !is_list(ast) {

            // Not a list -- just evaluate and return.

            let answer = try eval_ast(ast, env)
            if DEBUG_EVAL { print("\(indent)>>> \(answer)") }
            return answer
        }

        // Special handling if it's a list.

        var list = as_list(ast)
        ast = try macroexpand(ast, env)
        if !is_list(ast) {

            // Not a list -- just evaluate and return.

            let answer = try eval_ast(ast, env)
            if DEBUG_EVAL { print("\(indent)>>> \(answer)") }
            return answer
        }
        list = as_list(ast)

        if DEBUG_EVAL { print("\(indent)>.  \(list)") }

        if list.isEmpty {
            return ast
        }

        // Check for special forms, where we want to check the operation
        // before evaluating all of the parameters.

        let arg0 = list.first()
        if let fn_symbol = as_symbolQ(arg0) {
            let res: TCOVal

            switch fn_symbol {
                case kSymbolDef:            res = try eval_def(list, env)
                case kSymbolDefMacro:       res = try eval_def(list, env)
                case kSymbolLet:            res = try eval_let(list, env)
                case kSymbolDo:             res = try eval_do(list, env)
                case kSymbolIf:             res = try eval_if(list, env)
                case kSymbolFn:             res = try eval_fn(list, env)
                case kSymbolQuote:          res = try eval_quote(list, env)
                case kSymbolQuasiQuote:     res = try eval_quasiquote(list, env)
                case kSymbolMacroExpand:    res = try eval_macroexpand(list, env)
                case kSymbolTry:            res = try eval_try(list, env)
                default:                    res = TCOVal()
            }
            switch res {
                case let .Return(result):               return result
                case let .Continue(new_ast, new_env):   ast = new_ast; env = new_env; continue
                case .NoResult:                         break
            }
        }

        // Standard list to be applied. Evaluate all the elements first.

        let eval = try eval_ast(ast, env)

        // The result had better be a list and better be non-empty.

        let eval_list = as_list(eval)
        if eval_list.isEmpty {
            return eval
        }

        if DEBUG_EVAL { print("\(indent)>>  \(eval)") }

        // Get the first element of the list and execute it.

        let first = eval_list.first()
        let rest = as_sequence(eval_list.rest())

        if let fn = as_builtinQ(first) {
            let answer = try fn.apply(rest)
            if DEBUG_EVAL { print("\(indent)>>> \(answer)") }
            return answer
        } else if let fn = as_closureQ(first) {
            let new_env = Environment(outer: fn.env)
            let _ = try new_env.set_bindings(fn.args, with_exprs: rest)
            if TCO {
                env = new_env
                ast = fn.body
                continue
            }
            let answer = try EVAL(fn.body, new_env)
            if DEBUG_EVAL { print("\(indent)>>> \(answer)") }
            return answer
        }

        // The first element wasn't a function to be executed. Return an
        // error saying so.

        try throw_error("first list item does not evaluate to a function: \(first)")
    }
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

// Process any command line arguments. Any trailing arguments are incorporated
// into the environment. Any argument immediately after the process name is
// taken as a script to execute. If one exists, it is executed in lieu of
// running the REPL.
//
private func process_command_line(args: [String], _ env: Environment) -> Bool {
    var argv = make_list()
    if args.count > 2 {
        let args1 = args[2..<args.count]
        let args2 = args1.map { make_string($0) }
        let args3 = [MalVal](args2)
        argv = make_list(args3)
    }
    env.set(kSymbolArgv, argv)

    if args.count > 1 {
        RE("(load-file \"\(args[1])\")", env)
        return false
    }

    return true
}

func main() {
    let env = Environment(outer: nil)

    load_history_file()
    load_builtins(env)

    RE("(def! *host-language* \"swift\")", env)
    RE("(def! not (fn* (a) (if a false true)))", env)
    RE("(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \")\")))))", env)
    RE("(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) " +
       "(throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))", env)
    RE("(def! inc (fn* [x] (+ x 1)))", env)
    RE("(def! gensym (let* [counter (atom 0)] (fn* [] (symbol (str \"G__\" (swap! counter inc))))))", env)
    RE("(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) " +
       "(let* (condvar (gensym)) `(let* (~condvar ~(first xs)) (if ~condvar ~condvar (or ~@(rest xs)))))))))", env)

    env.set(kSymbolEval, make_builtin({
         try! unwrap_args($0) {
            (ast: MalVal) -> MalVal in
            try EVAL(ast, env)
         }
    }))

    if process_command_line(Process.arguments, env) {
        RE("(println (str \"Mal [\" *host-language*\"]\"))", env)
        REPL(env)
    }

    save_history_file()
}
