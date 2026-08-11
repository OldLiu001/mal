#!/usr/bin/env python3
# 按官方架构模块化重构：
#   模块文件（官方 types.qx/reader.qx/printer.qx/env.qx/core.qx 对应）：
#     types.sh    值模型 + 存储 + GC + 内联
#     reader.sh   tokenizer + reader（含 READ 入口）
#     printer.sh  pr_str / PRINT
#     env.sh      Env（env_new/env_set/env_get）
#     core.sh     核心函数库 fn_* + key_equal + _join_args
#   step 主文件（官方 stepN_xxx.qx 对应）：
#     source 所需模块 + 主逻辑（EVAL/APPLY/_ev1/_quasiquote/bind_params/
#     init_repl_env/rep_silent/rep/mal_repl）+ 启动
# 输入：当前根目录的自包含 step*.sh（split_steps.py 生成）
# 输出：5 个模块文件 + 覆盖 11 个 step 主文件
import re, os

STEP_NAMES = {
    0: 'step0_repl', 1: 'step1_read_print', 2: 'step2_eval', 3: 'step3_env',
    4: 'step4_if_fn_do', 5: 'step5_tco', 6: 'step6_file', 7: 'step7_quote',
    8: 'step8_macros', 9: 'step9_try', 10: 'stepA_mal',
}
STEP_DESC = {
    0: 'REPL 回显（READ/EVAL/PRINT/rep 桩）',
    1: 'reader + printer（引入 types/reader/printer 模块）',
    2: 'eval（符号查找 + 算术调用；引入 env 模块）',
    3: '环境（def! / let*）',
    4: 'if / fn* / do + 核心库（引入 core 模块）',
    5: 'TCO（EVAL 循环化；DEBUG-EVAL 追踪）',
    6: '文件（load-file / read-string / eval / atom）',
    7: 'quote / quasiquote / cons / concat / vec',
    8: '宏（defmacro! / macroexpand / nth / first / rest / cond）',
    9: 'try* / catch* / throw + hash-map 全量 + apply / map',
    10: 'meta / with-meta / readline / *host-language* / time-ms / seq / conj',
}
# 各 step 需要 source 的模块（官方增量）
STEP_MODULES = {
    0: [], 1: ['types', 'reader', 'printer'], 2: ['types', 'reader', 'printer', 'env'],
    3: ['types', 'reader', 'printer', 'env'], 4: ['types', 'reader', 'printer', 'env', 'core'],
    5: ['types', 'reader', 'printer', 'env', 'core'], 6: ['types', 'reader', 'printer', 'env', 'core'],
    7: ['types', 'reader', 'printer', 'env', 'core'], 8: ['types', 'reader', 'printer', 'env', 'core'],
    9: ['types', 'reader', 'printer', 'env', 'core'], 10: ['types', 'reader', 'printer', 'env', 'core'],
}
# 函数 -> 模块
FN_MODULE = {
    # types.sh
    '_set_stored': 'types', '_update_stored': 'types', '_get_stored': 'types',
    'new_id': 'types', 'gc_reg': 'types', 'gc_mark': 'types', 'gc_sweep': 'types',
    'gc_maybe': 'types', 'mal_type': 'types', 'mal_val': 'types',
    'mal_num': 'types', 'mal_sym': 'types', 'mal_kw': 'types', 'mal_str': 'types',
    'mal_list': 'types', 'mal_vec': 'types', 'mal_map': 'types', 'mal_atom': 'types',
    'mal_closure_native': 'types', 'mal_closure_mal': 'types', 'closure_get': 'types',
    'mal_error': 'types',
    # reader.sh
    'emit_token': 'reader', 'get_tok': 'reader', 'TOKENIZE': 'reader',
    'READ': 'reader', 'READ_FORM': 'reader', 'READ_WRAP': 'reader',
    'READ_SEQ': 'reader', 'READ_MAP': 'reader', 'classify_atom': 'reader',
    # printer.sh
    'unescape_str': 'printer', 'escape_str': 'printer', 'pr_str': 'printer', 'PRINT': 'printer',
    # env.sh
    'env_new': 'env', 'env_set': 'env', 'env_get': 'env',
    # core.sh
    'key_equal': 'core', '_join_args': 'core',
}
# fn_* 归 core.sh；fn_add/sub/mul/div 例外：官方 step2 主文件内联算术
# （step2 尚无 core.qx，+ - * / 直接定义在 step 主文件）
def fn_module(name):
    if name.startswith('fn_'):
        if name in ('fn_add', 'fn_sub', 'fn_mul', 'fn_div'):
            return None
        return 'core'
    return FN_MODULE.get(name, None)

# 主文件函数（不属于模块）
MAIN_FUNCS = {'EVAL', 'APPLY', '_ev1', '_quasiquote', 'bind_params',
              'init_repl_env', 'rep_silent', 'rep', 'mal_repl'}

def split_functions(lines):
    """按函数边界切块，返回 [(name, start, end)]（含函数后的尾随空行）"""
    funcs = []
    starts = []
    for i, line in enumerate(lines):
        if re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*\(\) \{', line):
            starts.append(i)
    starts.append(len(lines))
    for idx, i in enumerate(starts[:-1]):
        m = re.match(r'^([a-zA-Z_][a-zA-Z0-9_]*)\(\) \{', lines[i])
        funcs.append((m.group(1), i, starts[idx+1]))
    return funcs

def load(path):
    with open(path) as f:
        return f.readlines()

def build_modules(stepA_lines):
    """从 stepA 完整实现提取 5 个模块文件内容"""
    funcs = split_functions(stepA_lines)
    # 全局初始化段：从 set -f 行到第一个函数，原样保留
    # （含 NL=' 多行单引号字符串等，不能按行过滤）
    first_func_line = funcs[0][1]
    setf_line = None
    for i, line in enumerate(stepA_lines):
        if line.strip() == 'set -f':
            setf_line = i
            break
    assert setf_line is not None
    globals_head = stepA_lines[setf_line:first_func_line]

    mods = {m: [] for m in ['types', 'reader', 'printer', 'env', 'core']}
    mods['types'].append('#!/bin/dash\n')
    mods['types'].append('# ============================================================\n')
    mods['types'].append('# types.sh —— mal 值模型（官方 types.qx）\n')
    mods['types'].append('# 类型标签 ref、构造器、存储、GC、内联小对象、错误机制\n')
    mods['types'].append('# ============================================================\n')
    mods['types'].extend(globals_head)

    headers = {
        'reader': ('reader.sh —— tokenizer + reader（官方 reader.qx）\n# TOKENIZE / READ / READ_FORM / READ_SEQ / READ_MAP'),
        'printer': ('printer.sh —— 打印（官方 printer.qx）\n# escape / pr_str / PRINT'),
        'env': ('env.sh —— 环境（官方 env.qx）\n# env_new / env_set / env_get'),
        'core': ('core.sh —— 核心函数库（官方 core.qx）\n# fn_* 全部 + key_equal + _join_args'),
    }
    for m in ['reader', 'printer', 'env', 'core']:
        mods[m].append('#!/bin/dash\n')
        mods[m].append('# ============================================================\n')
        mods[m].append('# ' + headers[m] + '\n')
        mods[m].append('# ============================================================\n')

    for name, start, end in funcs:
        m = fn_module(name)
        if m:
            mods[m].extend(stepA_lines[start:end])
            # 补一个空行
            if mods[m][-1].strip() != '':
                mods[m].append('\n')
    return mods

def crop_init_env(s, init_lines):
    """静态裁剪 init_repl_env 的门控块：保留 N<=s 的块"""
    out = []
    i = 0
    n = len(init_lines)
    while i < n:
        line = init_lines[i]
        m = re.search(r'if \[ "\$STEPNUM" -ge (\d+) \]; then', line)
        if m and int(m.group(1)) > s:
            # 平衡跳过整个块
            depth = 0
            j = i
            while j < n:
                t = init_lines[j].strip()
                if t.startswith('if '):
                    depth += 1
                elif t == 'fi':
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            i = j + 1
            continue
        out.append(line)
        i += 1
    return out

def build_step_main(s, step_lines):
    """生成 step 主文件：source 模块 + 主逻辑 + 启动"""
    funcs = split_functions(step_lines)
    by_name = {name: (start, end) for name, start, end in funcs}

    out = []
    out.append('#!/bin/dash\n')
    out.append('# ============================================================\n')
    out.append(f'# {STEP_NAMES[s]} —— 官方 step{s}\n')
    out.append(f'# {STEP_DESC[s]}\n')
    out.append('# 官方模块化架构：本文件 = step 主文件（主逻辑 + 启动），\n')
    out.append('# source 共享模块（types/reader/printer/env/core）。\n')
    out.append('# ============================================================\n')
    out.append('set -f\n')
    out.append(f'STEPNUM={s}\n')
    for m in STEP_MODULES[s]:
        out.append(f'. "$(dirname "$0")/{m}.sh"\n')
    out.append('\n')

    # 主逻辑函数：EVAL/APPLY/_ev1/_quasiquote/bind_params/init_repl_env/rep_silent/mal_repl
    # + 所有不属于模块的函数（如 step2 内联的 fn_add/sub/mul/div）
    main_order = ['EVAL', 'APPLY', '_ev1', '_quasiquote', 'bind_params',
                  'init_repl_env', 'rep_silent', 'rep', 'mal_repl']
    extra = [name for name, _, _ in funcs
             if name not in main_order and fn_module(name) is None]
    for name in main_order + extra:
        if name in by_name:
            start, end = by_name[name]
            if name == 'init_repl_env' and s < 10:
                content = crop_init_env(s, step_lines[start:end])
            else:
                content = step_lines[start:end]
            # 剥离块内可能混入的启动段（自包含文件里 mal_repl 块
            # 的 span 会包含末尾的启动调用行）
            for l in content:
                t = l.strip()
                if t in ('init_repl_env', 'mal_repl "$@"') or t.startswith('# ---- 启动'):
                    continue
                out.append(l)
            out.append('\n')

    # 启动
    out.append('# ---- 启动 ----\n')
    if s == 0:
        out.append('while true; do\n')
        out.append('  printf \'user> \'\n')
        out.append('  IFS= read -r line || break\n')
        out.append('  printf \'%s\\n\' "$line"\n')
        out.append('done\n')
    else:
        out.append('init_repl_env\n')
        out.append('mal_repl "$@"\n')
    return out

if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.abspath(__file__)) + '/..')
    # 防重复运行：输入必须是自包含版（含模块函数定义），否则拒绝
    probe = load('stepA_mal.sh')
    if any('. "$(dirname "$0")/types.sh"' in l for l in probe):
        raise SystemExit('错误：stepA_mal.sh 已是模块化主文件（源被覆盖）。'
                         '请先从 git 恢复自包含版本再运行。')
    stepA = load('stepA_mal.sh')
    mods = build_modules(stepA)
    for m in ['types', 'reader', 'printer', 'env', 'core']:
        with open(f'{m}.sh', 'w') as f:
            f.writelines(mods[m])
        print(f'生成 {m}.sh ({len(mods[m])} 行)')
    for s in range(0, 11):
        step_lines = load(f'{STEP_NAMES[s]}.sh')
        content = build_step_main(s, step_lines)
        with open(f'{STEP_NAMES[s]}.sh', 'w') as f:
            f.writelines(content)
        print(f'生成 {STEP_NAMES[s]}.sh ({len(content)} 行)')
