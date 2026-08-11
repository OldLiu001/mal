#!/usr/bin/env python3
# 从 core.sh 按官方 step 增量生成 11 个独立完整的 step 文件。
# 每个文件 = 真实代码（允许重复），功能按 step 裁剪，STEPNUM 固定。
import re, sys

SRC = 'core.sh'
OUTDIR = '.'  # 官方架构要求：step 文件直接放实现根目录（覆盖旧 wrapper 壳）

with open(SRC) as f:
    lines = f.readlines()

# ---------- 函数块切割 ----------
# 函数起始行
func_starts = []
for i, line in enumerate(lines):
    if re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*\(\) \{', line):
        func_starts.append(i)
func_starts.append(len(lines))

def func_span(name):
    """返回 (开始行, 结束行+1)"""
    for idx, i in enumerate(func_starts[:-1]):
        m = re.match(r'^([a-zA-Z_][a-zA-Z0-9_]*)\(\) \{', lines[i])
        if m and m.group(1) == name:
            return (i, func_starts[idx+1])
    return None

# ---------- 函数归属表 ----------
# fn_xxx 首次需要的 step（与当前 init_repl_env 注册门控一致）
FN_STEP = {
    'fn_add': 2, 'fn_sub': 2, 'fn_mul': 2, 'fn_div': 2,
    'fn_list': 4, 'fn_list_p': 4, 'fn_vector_p': 4, 'fn_empty_p': 4,
    'fn_count': 4, 'fn_equal': 4, 'fn_lt': 4, 'fn_le': 4, 'fn_gt': 4, 'fn_ge': 4,
    'fn_pr_str': 4, 'fn_str': 4, 'fn_prn': 4, 'fn_println': 4,
    'fn_nil_p': 4, 'fn_true_p': 4, 'fn_false_p': 4,
    'fn_hash_map': 4, 'fn_assoc': 4, 'fn_get': 4, 'fn_contains_p': 4,
    'fn_keys': 4, 'fn_vals': 4, 'fn_dissoc': 4, 'fn_map_p': 4,
    '_join_args': 4, 'key_equal': 4,
    'fn_read_string': 6, 'fn_slurp': 6, 'fn_eval': 6, 'fn_atom': 6,
    'fn_atom_p': 6, 'fn_deref': 6, 'fn_reset': 6, 'fn_swap': 6,
    'fn_cons': 7, 'fn_concat': 7, 'fn_vec': 7, 'fn_vector': 7,
    'fn_nth': 8, 'fn_first': 8, 'fn_rest': 8, 'fn_macro_p': 8, 'fn_macroexpand': 8,
    'fn_throw': 9, 'fn_symbol_p': 9, 'fn_symbol': 9, 'fn_keyword_p': 9,
    'fn_keyword': 9, 'fn_sequential_p': 9, 'fn_apply': 9, 'fn_map': 9,
    'fn_readline': 10, 'fn_meta': 10, 'fn_with_meta': 10, 'fn_string_p': 10,
    'fn_number_p': 10, 'fn_fn_p': 10, 'fn_conj': 10, 'fn_seq': 10, 'fn_time_ms': 10,
    # 基础机制（step1 起）
    '_set_stored': 1, '_update_stored': 1, '_get_stored': 1, 'new_id': 1,
    'gc_reg': 1, 'gc_mark': 1, 'gc_sweep': 1, 'gc_maybe': 1,
    'mal_type': 1, 'mal_val': 1, 'mal_num': 1, 'mal_sym': 1, 'mal_kw': 1,
    'mal_str': 1, 'mal_list': 1, 'mal_vec': 1, 'mal_map': 1, 'mal_atom': 1,
    'mal_closure_native': 1, 'mal_closure_mal': 1, 'closure_get': 1,
    'env_new': 1, 'env_set': 1, 'env_get': 1,
    'mal_error': 1, 'unescape_str': 1, 'escape_str': 1,
    'emit_token': 1, 'get_tok': 1, 'TOKENIZE': 1,
    'READ': 1, 'READ_FORM': 1, 'READ_WRAP': 1, 'READ_SEQ': 1, 'READ_MAP': 1,
    'classify_atom': 1, 'pr_str': 1, 'PRINT': 1,
    'EVAL': 2, 'APPLY': 2, '_ev1': 2,
    'bind_params': 3, '_quasiquote': 7,
    'init_repl_env': 1, 'rep_silent': 4, 'mal_repl': 1,
}

STEP_NAMES = {
    0: 'step0_repl', 1: 'step1_read_print', 2: 'step2_eval', 3: 'step3_env',
    4: 'step4_if_fn_do', 5: 'step5_tco', 6: 'step6_file', 7: 'step7_quote',
    8: 'step8_macros', 9: 'step9_try', 10: 'stepA_mal',
}

STEP_DESC = {
    0: 'REPL 回显（READ/EVAL/PRINT 恒等）',
    1: 'reader + printer + 值模型/存储/环境基础',
    2: 'eval（符号查找 + 算术调用）',
    3: '环境（def! / let*）',
    4: 'if / fn* / do + 核心库',
    5: 'TCO（EVAL 循环化；DEBUG-EVAL 追踪）',
    6: '文件（load-file / read-string / eval / atom）',
    7: 'quote / quasiquote / cons / concat / vec',
    8: '宏（defmacro! / macroexpand / nth / first / rest / cond）',
    9: 'try* / catch* / throw + hash-map 全量 + apply / map',
    10: 'meta / with-meta / readline / *host-language* / time-ms / seq / conj',
}

def build_step(s):
    """生成 step s 的文件内容"""
    out = []
    out.append(f'''#!/bin/dash
# ============================================================
# mal in dash —— {STEP_NAMES[s]}（官方 step{s}）
#
# {STEP_DESC[s]}
#
# 本文件是独立完整的实现（从单文件实现按官方增量拆分，允许代码
# 重复）。功能裁剪规则与官方 process/step{s}.txt 对应；存储/GC/
# 内联为基础设施，各 step 一致。
# ============================================================
set -f
STEPNUM={s}
''')

    # ---- 全局初始化段：set -f 之后的全局变量定义，到第一个函数前 ----
    first_func = func_starts[0]
    for line in lines[1:first_func]:
        # 跳过原 STEPNUM 默认行与核心注释头（保留其它全局定义）
        if line.startswith('STEPNUM='):
            continue
        if line.startswith('# ================= 值模型'):
            out.append('# ================= 基础设施 =================')
            continue
        out.append(line)

    # ---- 函数按归属裁剪 ----
    # EVAL 特殊处理（内部裁剪）
    ev_start, ev_end = func_span('EVAL')
    for idx, i in enumerate(func_starts[:-1]):
        m = re.match(r'^([a-zA-Z_][a-zA-Z0-9_]*)\(\) \{', lines[i])
        name = m.group(1)
        span_end = func_starts[idx+1]
        if name == 'EVAL':
            out.extend(crop_eval(s))
        elif name in FN_STEP and FN_STEP[name] <= s:
            out.extend(lines[i:span_end])

    # ---- 收尾：REPL 启动（原 wrapper 里的调用） ----
    out.append('\n# ---- 启动：REPL 回显循环 ----\n')
    if s == 0:
        out.append('while true; do\n')
        out.append('  printf \'user> \'\n')
        out.append('  IFS= read -r line || break\n')
        out.append('  printf \'%s\\n\' "$line"\n')
        out.append('done\n')
    else:
        out.append('init_repl_env\nmal_repl "$@"\n')
    return ''.join(out)

def crop_eval(s):
    """EVAL 函数按 step 裁剪分支（保持与门控语义等价）"""
    ev_start, ev_end = func_span('EVAL')
    body = lines[ev_start:ev_end]

    if s <= 1:
        return ['EVAL() {  # $1=ast ref $2=env -> r（恒等）\n',
                '  r="$1"\n', '}\n']

    out = []
    skip_depth = 0  # 跳过块的行数累计（简单方式：直接行级裁剪）
    i = 0
    n = len(body)
    while i < n:
        line = body[i]
        # 1) 恒等门控行（step2 起 EVAL 真干活）
        if 'STEPNUM" -le 1' in line:
            i += 1; continue
        # 2) DEBUG-EVAL 段（step3 引入，官方 step3 测试含 DEBUG-EVAL 用例）
        if s < 3 and line.strip().startswith('# DEBUG-EVAL：'):
            # 跳到配平的外层 fi（块内含嵌套 if/fi）
            j, depth = i + 1, 0
            while j < n:
                t = body[j].strip()
                if t.startswith('if '):
                    # 一行式 if ...; fi 净深度为 0
                    if not t.endswith('fi'):
                        depth += 1
                elif t == 'fi':
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            i = j + 1
            continue
        # 3) __vec / __map 求值分支（step2 引入，官方 step2 测试含向量字面量）
        if s < 2 and (line.strip() == '__vec)' or line.strip() == '__map)'):
            # 跳到 return ;;（分支结束，从 i+1 开始）
            j = i + 1
            while j < n and body[j].strip() != 'return ;;':
                j += 1
            i = j + 1
            continue
        # 4) 门控行（分支裁剪后不再需要）
        if re.search(r'STEPNUM" -lt \d', line):
            i += 1; continue
        # 5) 特殊形式 case 分支
        m = re.match(r"^    '([a-z!*]+)'\)", line)
        if m:
            branch = m.group(1)
            need = {'def!': 3, 'defmacro!': 8, 'let*': 3, 'fn*': 4,
                    'do': 4, 'if': 4, 'try*': 9, 'quote': 7, 'quasiquote': 7}
            if branch in need and s < need[branch]:
                # 跳到下一个 case 分支或 esac（从 i+1 开始，否则卡在自身）
                j = i + 1
                while j < n:
                    if re.match(r"^    '[a-z!*]+'\)", body[j]) or body[j].strip() == 'esac':
                        break
                    j += 1
                i = j
                continue
        # 7) 宏展开块（step8 引入）
        if s < 8 and line.strip().startswith('# ---- 宏展开（step8）'):
            j, depth = i + 1, 0
            while j < n:
                t = body[j].strip()
                if t.startswith('if '):
                    # 一行式 if ...; fi 净深度为 0
                    if not t.endswith('fi'):
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

if __name__ == '__main__':
    import os
    os.makedirs(OUTDIR, exist_ok=True)
    for s in range(0, 11):
        content = build_step(s)
        path = f'{OUTDIR}/{STEP_NAMES[s]}.sh'
        with open(path, 'w') as f:
            f.write(content)
        print(f'生成 {path} ({len(content.splitlines())} 行)')
