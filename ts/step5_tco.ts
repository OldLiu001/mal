import { readline } from "./node_readline";

import { MalType, MalBoolean, MalNull, MalList, MalVector, MalHashMap, MalSymbol, MalFunction, isSeq } from "./types";
import { Env } from "./env";
import * as core from "./core";
import { readStr } from "./reader";
import { prStr } from "./printer";

// READ
function read(str: string): MalType {
    return readStr(str);
}

function evalAST(ast: MalType, env: Env): MalType {
    switch (ast.type) {
        case "symbol":
            const f = env.get(ast);
            if (!f) {
                throw new Error(`unknown symbol: ${ast.v}`);
            }
            return f;
        case "list":
            return new MalList(ast.list.map(ast => evalMal(ast, env)));
        case "vector":
            return new MalVector(ast.list.map(ast => evalMal(ast, env)));
        case "hash-map":
            const list: MalType[] = [];
            for (const [key, value] of ast.entries()) {
                list.push(key);
                list.push(evalMal(value, env));
            }
            return new MalHashMap(list);
        default:
            return ast;
    }
}

// EVAL
function evalMal(ast: MalType, env: Env): MalType {
    loop: while (true) {
        if (ast.type !== "list") {
            return evalAST(ast, env);
        }
        if (ast.list.length === 0) {
            return ast;
        }
        const first = ast.list[0];
        switch (first.type) {
            case "symbol":
                switch (first.v) {
                    case "def!": {
                        const [, key, value] = ast.list;
                        if (!MalSymbol.is(key)) {
                            throw new Error(`unexpected token type: ${key.type}, expected: symbol`);
                        }
                        if (!value) {
                            throw new Error(`unexpected syntax`);
                        }
                        return env.set(key, evalMal(value, env))
                    }
                    case "let*": {
                        env = new Env(env);
                        const pairs = ast.list[1];
                        if (!isSeq(pairs)) {
                            throw new Error(`unexpected token type: ${pairs.type}, expected: list or vector`);
                        }
                        for (let i = 0; i < pairs.list.length; i += 2) {
                            const key = pairs.list[i];
                            const value = pairs.list[i + 1];
                            if (!MalSymbol.is(key)) {
                                throw new Error(`unexpected token type: ${key.type}, expected: symbol`);
                            }
                            if (!key || !value) {
                                throw new Error(`unexpected syntax`);
                            }

                            env.set(key, evalMal(value, env));
                        }
                        ast = ast.list[2];
                        continue loop;
                    }
                    case "do": {
                        const list = ast.list.slice(1, -1);
                        evalAST(new MalList(list), env);
                        ast = ast.list[ast.list.length - 1];
                        continue loop;
                    }
                    case "if": {
                        const [, cond, thenExpr, elseExrp] = ast.list;
                        const ret = evalMal(cond, env);
                        let b = true;
                        if (MalBoolean.is(ret) && !ret.v) {
                            b = false;
                        } else if (MalNull.is(ret)) {
                            b = false;
                        }
                        if (b) {
                            ast = thenExpr;
                        } else if (elseExrp) {
                            ast = elseExrp;
                        } else {
                            ast = MalNull.instance;
                        }
                        continue loop;
                    }
                    case "fn*": {
                        const [, params, bodyAst] = ast.list;
                        if (!isSeq(params)) {
                            throw new Error(`unexpected return type: ${params.type}, expected: list or vector`);
                        }
                        const symbols = params.list.map(param => {
                            if (!MalSymbol.is(param)) {
                                throw new Error(`unexpected return type: ${param.type}, expected: symbol`);
                            }
                            return param;
                        });
                        return MalFunction.fromLisp(evalMal, env, symbols, bodyAst);
                    }
                }
        }
        const result = evalAST(ast, env);
        if (!isSeq(result)) {
            throw new Error(`unexpected return type: ${result.type}, expected: list or vector`);
        }
        const [f, ...args] = result.list;
        if (!MalFunction.is(f)) {
            throw new Error(`unexpected token: ${f.type}, expected: function`);
        }
        if (f.ast) {
            ast = f.ast;
            env = f.newEnv(args);
            continue loop;
        }

        return f.func(...args);
    }
}

// PRINT
function print(exp: MalType): string {
    return prStr(exp);
}

const replEnv = new Env();
function rep(str: string): string {
    return print(evalMal(read(str), replEnv));
}

// core.EXT: defined using Racket
core.ns.forEach((value, key) => {
    replEnv.set(key, value);
});

// core.mal: defined using the language itself
rep("(def! not (fn* (a) (if a false true)))");

while (true) {
    const line = readline("user> ");
    if (line == null) {
        break;
    }
    if (line === "") {
        continue;
    }
    try {
        console.log(rep(line));
    } catch (e) {
        const err: Error = e;
        console.error(err.message);
    }
}
