import functools
import readline
import sys
from typing import List, Dict

import core
import reader
from env import Env
from mal_types import MalExpression, MalSymbol, MalException
from mal_types import (
    MalList,
    MalNil,
    MalBoolean,
    MalFunctionCompiled,
    MalFunctionRaw,
    MalAtom,
    MalVector,
    MalHash_map,
)
from mal_types import MalUnknownSymbolException, MalInvalidArgumentException, MalString


def READ(x: str) -> MalExpression:
    return reader.read(x)


def qq_loop(acc: MalList, elt: MalExpression) -> MalList:
    if isinstance(elt, MalList):
        lst = elt.native()
        if len(lst) == 2:
            fst = lst[0]
            if isinstance(fst, MalSymbol) and fst.native() == u"splice-unquote":
                return MalList([MalSymbol(u"concat"), lst[1], acc])
    return MalList([MalSymbol(u"cons"), quasiquote(elt), acc])

def qq_foldr(xs: List[MalExpression]) -> MalList:
    return functools.reduce(qq_loop, reversed(xs), MalList([]))

def quasiquote(ast: MalExpression) -> MalExpression:
    if isinstance(ast, MalList):
        lst = ast.native()
        if len(lst) == 2:
            fst = lst[0]
            if isinstance(fst, MalSymbol) and fst.native() == u'unquote':
                return lst[1]
        return qq_foldr(lst)
    elif isinstance(ast, MalVector):
        return MalList([MalSymbol("vec"), qq_foldr(ast.native())])
    elif isinstance(ast, MalSymbol) or isinstance(ast, MalHash_map):
        return MalList([MalSymbol("quote"), ast])
    else:
        return ast


def EVAL(ast: MalExpression, env: Env) -> MalExpression:
    while True:
        dbgeval = env.get("DEBUG-EVAL")
        if (dbgeval is not None
            and not isinstance(dbgeval, MalNil)
            and (not isinstance(dbgeval, MalBoolean) or dbgeval.native())):
            print("EVAL: " + str(ast))
        ast_native = ast.native()
        if isinstance(ast, MalSymbol):
            key = str(ast)
            val = env.get(key)
            if val is None: raise MalUnknownSymbolException(key)
            return val
        if isinstance(ast, MalVector):
            return MalVector([EVAL(x, env) for x in ast_native])
        if isinstance(ast, MalHash_map):
            new_dict = {}  # type: Dict[str, MalExpression]
            for key in ast_native:
                new_dict[key] = EVAL(ast_native[key], env)
            return MalHash_map(new_dict)
        if not isinstance(ast, MalList):
            return ast
        elif len(ast_native) == 0:
            return ast

        first_str = str(ast_native[0])
        if first_str == "def!":
            name: str = str(ast_native[1])
            value: MalExpression = EVAL(ast_native[2], env)
            return env.set(name, value)
        if first_str == "defmacro!":
            name = str(ast_native[1])
            value = EVAL(ast_native[2], env)
            assert isinstance(value, MalFunctionCompiled) or isinstance(
                value, MalFunctionRaw
            )
            value.make_macro()
            return env.set(name, value)
        elif first_str == "let*":
            assert len(ast_native) == 3
            let_env = Env(env)
            bindings: MalExpression = ast_native[1]
            assert isinstance(bindings, MalList) or isinstance(bindings, MalVector)
            bindings_list: List[MalExpression] = bindings.native()
            assert len(bindings_list) % 2 == 0
            for i in range(0, len(bindings_list), 2):
                assert isinstance(bindings_list[i], MalSymbol)
                assert isinstance(bindings_list[i + 1], MalExpression)
                let_env.set(str(bindings_list[i]), EVAL(bindings_list[i + 1], let_env))
            env = let_env
            ast = ast_native[2]
            continue
        elif first_str == "do":
            for x in range(1, len(ast_native) - 1):
                EVAL(ast_native[x], env)
            ast = ast_native[len(ast_native) - 1]
            continue
        elif first_str == "if":
            condition = EVAL(ast_native[1], env)

            if isinstance(condition, MalNil) or (
                isinstance(condition, MalBoolean) and condition.native() is False
            ):
                if len(ast_native) >= 4:
                    ast = ast_native[3]
                    continue
                else:
                    return MalNil()
            else:
                ast = ast_native[2]
                continue
        elif first_str == "fn*":
            raw_ast = ast_native[2]
            raw_params = ast_native[1]

            def fn(args: List[MalExpression]) -> MalExpression:
                f_ast = raw_ast
                f_env = Env(outer=env, binds=raw_params.native(), exprs=args)
                return EVAL(f_ast, f_env)

            return MalFunctionRaw(fn=fn, ast=raw_ast, params=raw_params, env=env)
        elif first_str == "quote":
            return (
                MalList(ast_native[1].native())
                if isinstance(ast_native[1], MalVector)
                else ast_native[1]
            )
        elif first_str == "quasiquote":
            ast = quasiquote(ast_native[1])
            continue
        elif first_str == "try*":
            try:
                return EVAL(ast_native[1], env)
            except MalException as e:
                if len(ast_native) < 3:
                    raise e
                catch_block = ast_native[2]
                assert (
                    isinstance(catch_block, MalList)
                    and isinstance(catch_block.native()[0], MalSymbol)
                    and str(catch_block.native()[0]) == "catch*"
                    and len(catch_block.native()) == 3
                )
                exception_symbol = catch_block.native()[1]
                assert isinstance(exception_symbol, MalSymbol)
                env = Env(env)
                env.set(str(exception_symbol), e.native())
                ast = catch_block.native()[2]
                continue
        else:
            f = EVAL(ast_native[0], env)
            if isinstance(f, (MalFunctionCompiled, MalFunctionRaw)) and f.is_macro():
                ast = f.call(ast_native[1:])
                continue
            args = [EVAL(ast_native[i], env) for i in range(1, len(ast_native))]
            if isinstance(f, MalFunctionRaw):
                ast = f.ast()

                env = Env(
                    outer=f.env(),
                    binds=f.params().native(),
                    exprs=args,
                )
                continue
            elif isinstance(f, MalFunctionCompiled):
                return f.call(args)
            else:
                raise MalInvalidArgumentException(f, "not a function")


def PRINT(x: MalExpression) -> str:
    return str(x)


def rep(x: str, env: Env) -> str:
    return PRINT(EVAL(READ(x), env))


def init_repl_env() -> Env:
    def eval_func(args: List[MalExpression], env: Env) -> MalExpression:
        a0 = args[0]
        assert isinstance(a0, MalExpression)
        return EVAL(a0, env)

    def swap(args: List[MalExpression], env: Env) -> MalExpression:
        atom = args[0]
        assert isinstance(atom, MalAtom)
        func = args[1]
        atom.reset(EVAL(MalList([func, atom.native()] + args[2:]), env))
        return atom.native()

    repl_env = Env(None)
    for key in core.ns:
        repl_env.set(key, core.ns[key])

    repl_env.set("eval", MalFunctionCompiled(lambda args: eval_func(args, repl_env)))

    rep(
        '(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) "\nnil)")))))',
        repl_env,
    )

    mal_argv = MalList([MalString(x) for x in sys.argv[2:]])
    repl_env.set("*ARGV*", mal_argv)

    rep(
        "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))",
        repl_env,
    )

    return repl_env


def rep_handling_exceptions(line: str, repl_env: Env) -> str:
    try:
        return rep(line, repl_env)
    except MalUnknownSymbolException as e:
        return "'" + e.func + "' not found"
    except MalException as e:
        return "ERROR: " + str(e)


if __name__ == "__main__":
    # repl loop
    eof: bool = False
    repl_env = init_repl_env()

    if len(sys.argv) >= 2:
        file_str = sys.argv[1]
        rep_handling_exceptions('(load-file "' + file_str + '")', repl_env)
        exit(0)

    while not eof:
        try:
            line = input("user> ")
            readline.add_history(line)
            print(rep_handling_exceptions(line, repl_env))
        except EOFError:
            eof = True
