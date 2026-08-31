#!/usr/bin/env python3
"""build_jsc.py - Build JSC.NET (JScript.NET) compatible single-file from mal JS sources.

Usage: python build_jsc.py <step_name>
  e.g. python build_jsc.py step0_repl
"""

import re
import sys
import os

IMPL_DIR = os.path.dirname(os.path.abspath(__file__))

COMMON_FILES = [
    'runtime_jsc.js',
    'io.js',
    'types.js',
    'reader.js',
    'printer.js',
    'env.js',
    'core.js',
    'interop.js',
]

STUBS = """// ---- Stubs for undeclared globals (prevent JS1135 compile errors) ----
var WScript = null;
var process = null;
var module = null;
var console = null;
var Buffer = null;
var readline_sync = null;
var global = null;
var window = null;
var ActiveXObject = null;
var exports = null;
function __noop__() { return {}; }"""


def read_file(name):
    path = os.path.join(IMPL_DIR, name)
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()


def find_receiver_start(content, dot_pos):
    """Find the start position of the expression preceding .method() at dot_pos."""
    pos = dot_pos - 1
    paren_depth = 0
    bracket_depth = 0
    brace_depth = 0
    
    while pos >= 0:
        ch = content[pos]
        
        if ch == ')':
            paren_depth += 1
        elif ch == '(':
            if paren_depth == 0:
                break
            paren_depth -= 1
        elif ch == ']':
            bracket_depth += 1
        elif ch == '[':
            if bracket_depth == 0:
                break
            bracket_depth -= 1
        elif ch == '}':
            brace_depth += 1
        elif ch == '{':
            if brace_depth == 0:
                break
            brace_depth -= 1
        elif paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
            if ch.isalnum() or ch == '_' or ch == '$' or ch == '.':
                pass
            elif ch.isspace():
                p2 = pos - 1
                while p2 >= 0 and content[p2].isspace():
                    p2 -= 1
                if p2 >= 0:
                    prev = content[p2]
                    if prev.isalnum() or prev == '_' or prev == '$':
                        word_end = p2 + 1
                        word_start = p2
                        while word_start >= 0 and (content[word_start].isalnum() or content[word_start] == '_'):
                            word_start -= 1
                        word = content[word_start+1:word_end]
                        if word in ('return', 'var', 'typeof', 'new', 'if', 'else', 'while', 'for', 'function', 'case', 'in'):
                            start = word_end
                            while start < dot_pos and content[start].isspace():
                                start += 1
                            return start
                        pos = p2
                        continue
                    elif prev in (')', ']'):
                        pos = p2
                        continue
                    else:
                        break
                else:
                    break
            else:
                break
        pos -= 1
    
    start = pos + 1
    while start < dot_pos and content[start].isspace():
        start += 1
    return start


def replace_method_calls(content):
    """Replace .map(fn), .filter(fn), .reduceRight(fn, init), .reduce(fn, init)
    with _map(receiver, fn), etc."""
    
    methods = {
        '.map(': '_map',
        '.filter(': '_filter',
        '.reduceRight(': '_reduceRight',
        '.reduce(': '_reduce',
    }
    
    for method_pattern, helper_name in methods.items():
        idx = 0
        while True:
            pos = content.find(method_pattern, idx)
            if pos == -1:
                break
            
            dot_pos = pos
            recv_start = find_receiver_start(content, dot_pos)
            receiver = content[recv_start:dot_pos]
            
            if not receiver or receiver in ('this',):
                idx = pos + 1
                continue
            
            # Find matching closing paren
            paren_start = pos + len(method_pattern) - 1
            paren_depth = 1
            j = paren_start + 1
            while j < len(content) and paren_depth > 0:
                if content[j] == '(':
                    paren_depth += 1
                elif content[j] == ')':
                    paren_depth -= 1
                j += 1
            
            if paren_depth != 0:
                idx = pos + 1
                continue
            
            args = content[paren_start + 1:j - 1]
            replacement = helper_name + '(' + receiver + ', ' + args + ')'
            content = content[:recv_start] + replacement + content[j:]
            idx = recv_start + len(replacement)
    
    # Handle array .indexOf() - only for known array variables
    idx = 0
    while True:
        pos = content.find('.indexOf(', idx)
        if pos == -1:
            break
        
        dot_pos = pos
        recv_start = find_receiver_start(content, dot_pos)
        receiver = content[recv_start:dot_pos]
        
        if receiver == 'cache':
            paren_start = pos + len('.indexOf(') - 1
            paren_depth = 1
            j = paren_start + 1
            while j < len(content) and paren_depth > 0:
                if content[j] == '(':
                    paren_depth += 1
                elif content[j] == ')':
                    paren_depth -= 1
                j += 1
            args = content[paren_start + 1:j - 1]
            replacement = '_indexOf(' + receiver + ', ' + args + ')'
            content = content[:recv_start] + replacement + content[j:]
            idx = recv_start + len(replacement)
        else:
            idx = pos + 1
    
    return content


def replace_typeof_checks(content):
    """Replace typeof checks on undeclared globals with RUNTIME comparisons."""
    replacements = [
        (r'typeof module\s*===\s*[\'"]undefined[\'"]', "RUNTIME !== 'node'"),
        (r'typeof module\s*!==\s*[\'"]undefined[\'"]', "RUNTIME === 'node'"),
        (r'typeof WScript\s*!==\s*[\'"]undefined[\'"]', "RUNTIME === 'jscript'"),
        (r'typeof WScript\s*===\s*[\'"]undefined[\'"]', "RUNTIME !== 'jscript'"),
        (r'typeof global\s*!==\s*[\'"]undefined[\'"]', "RUNTIME === 'node'"),
        (r'typeof global\s*===\s*[\'"]undefined[\'"]', "RUNTIME !== 'node'"),
        (r'typeof window\s*!==\s*[\'"]undefined[\'"]', 'false'),
        (r'typeof window\s*===\s*[\'"]undefined[\'"]', 'true'),
        (r'typeof readline_sync\s*!==\s*[\'"]undefined[\'"]', 'false'),
        (r'typeof readline_sync\s*===\s*[\'"]undefined[\'"]', 'true'),
        (r'typeof process\s*!==\s*[\'"]undefined[\'"]', "RUNTIME === 'node'"),
        (r'typeof process\s*===\s*[\'"]undefined[\'"]', "RUNTIME !== 'node'"),
        (r'typeof Array\.isArray\s*!==\s*[\'"]function[\'"]', 'false'),
        (r'typeof Array\.isArray\s*===\s*[\'"]function[\'"]', 'true'),
        (r'typeof Object\.keys\s*!==\s*[\'"]function[\'"]', 'false'),
        (r'typeof Object\.keys\s*===\s*[\'"]function[\'"]', 'true'),
        (r'typeof Array\.prototype\.\w+\s*!==\s*[\'"]function[\'"]', 'false'),
        (r'typeof Array\.prototype\.\w+\s*===\s*[\'"]function[\'"]', 'true'),
        (r'typeof String\.prototype\.\w+\s*!==\s*[\'"]function[\'"]', 'false'),
        (r'typeof String\.prototype\.\w+\s*===\s*[\'"]function[\'"]', 'true'),
        (r'typeof Function\.prototype\.\w+\s*!==\s*[\'"]function[\'"]', 'false'),
        (r'typeof Function\.prototype\.\w+\s*===\s*[\'"]function[\'"]', 'true'),
        (r'typeof JSON\s*!==\s*[\'"]object[\'"]', 'false'),
        (r'typeof JSON\s*===\s*[\'"]object[\'"]', 'true'),
        (r'typeof JSON\.stringify\s*!==\s*[\'"]function[\'"]', 'false'),
        (r'typeof JSON\.stringify\s*===\s*[\'"]function[\'"]', 'true'),
    ]
    
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)
    
    return content


def remove_io_autodetect(content):
    """Remove the io.js auto-detection block."""
    marker = "if (typeof RUNTIME === 'undefined')"
    pos = content.find(marker)
    if pos == -1:
        return content
    
    brace_pos = content.find('{', pos)
    if brace_pos == -1:
        return content
    
    depth = 1
    i = brace_pos + 1
    while i < len(content) and depth > 0:
        if content[i] == '{':
            depth += 1
        elif content[i] == '}':
            depth -= 1
        i += 1
    
    if depth != 0:
        return content
    
    start = pos
    while start > 0 and content[start-1] != '\n':
        start -= 1
    
    content = content[:start] + content[i:]
    return content


def remove_function_prototype_clone(content):
    """Remove Function.prototype.clone assignment and replace .clone() calls."""
    # Remove the assignment block
    pattern = r'Function\.prototype\.clone\s*=\s*function\s*\([^)]*\)\s*\{'
    match = re.search(pattern, content)
    if match:
        brace_pos = match.end() - 1
        depth = 1
        i = brace_pos + 1
        while i < len(content) and depth > 0:
            if content[i] == '{':
                depth += 1
            elif content[i] == '}':
                depth -= 1
            i += 1
        # Remove from the start of the line to the closing brace + semicolon
        line_start = match.start()
        while line_start > 0 and content[line_start-1] != '\n':
            line_start -= 1
        end = i
        if end < len(content) and content[end] == ';':
            end += 1
        content = content[:line_start] + content[end:]
    
    # Replace .clone() calls with _cloneFn()
    content = re.sub(r'(\w+)\.clone\(\)', r'_cloneFn(\1)', content)
    
    # Add _cloneFn function (will be added to the output)
    clone_fn = """
function _cloneFn(fn) {
    var temp = function(..._vargs : Object[]) {
        var arguments = _toArr(_vargs);
        return fn.apply(this, arguments);
    };
    for (var key in fn) {
        temp[key] = fn[key];
    }
    return temp;
}
"""
    content = clone_fn + content
    
    return content


def transform_all_functions(content):
    """Transform ALL functions (named and anonymous) that use `arguments`.
    
    Single-pass approach: finds all function declarations, checks if body
    contains `arguments`, and if so, adds variadic params + var arguments line.
    """
    
    # Pattern for named functions: function NAME(params) {
    # Pattern for anonymous functions: function(params) {
    # Use negative lookbehind to distinguish: 'function ' (with space) = named,
    # 'function(' (no space) = anonymous
    # But also handle: var x = function(params) { (anonymous with space before)
    
    # Combined pattern: match both named and anonymous
    # Named: function\s+(\w+)\s*\(([^)]*)\)\s*\{
    # Anonymous: (?<![\w$])function\s*\(([^)]*)\)\s*\{
    
    results = []
    last_end = 0
    
    # Process named functions first
    named_pattern = re.compile(r'function\s+(\w+)\s*\(([^)]*)\)\s*\{')
    anon_pattern = re.compile(r'(?<![\w$])function\s*\(([^)]*)\)\s*\{')
    
    # Find all function positions (named and anonymous)
    all_matches = []
    for m in named_pattern.finditer(content):
        all_matches.append(('named', m))
    for m in anon_pattern.finditer(content):
        all_matches.append(('anon', m))
    
    # Sort by position
    all_matches.sort(key=lambda x: x[1].start())
    
    # Remove overlapping matches (anon pattern might match inside named pattern)
    filtered = []
    prev_end = 0
    for typ, m in all_matches:
        if m.start() < prev_end:
            continue  # Overlapping with previous match
        all_matches.append((typ, m))
        prev_end = m.end()
    
    # Actually, let me just use a different approach:
    # Find all 'function' keywords, then check what follows
    func_keyword = re.compile(r'\bfunction\b')
    
    for m in func_keyword.finditer(content):
        pos = m.end()
        # Skip whitespace
        while pos < len(content) and content[pos].isspace():
            pos += 1
        
        # Check if next is an identifier (named) or ( (anonymous)
        if pos < len(content) and content[pos] == '(':
            # Anonymous function
            func_type = 'anon'
            params_start = pos + 1
        elif pos < len(content) and (content[pos].isalnum() or content[pos] == '_' or content[pos] == '$'):
            # Named function
            func_type = 'named'
            # Skip the function name
            while pos < len(content) and (content[pos].isalnum() or content[pos] == '_' or content[pos] == '$'):
                pos += 1
            # Skip whitespace
            while pos < len(content) and content[pos].isspace():
                pos += 1
            if pos >= len(content) or content[pos] != '(':
                continue  # Not a function declaration
            params_start = pos + 1
        else:
            continue
        
        # Find closing paren for params
        paren_depth = 1
        i = params_start
        while i < len(content) and paren_depth > 0:
            if content[i] == '(':
                paren_depth += 1
            elif content[i] == ')':
                paren_depth -= 1
            i += 1
        
        if paren_depth != 0:
            continue
        
        params_str = content[params_start:i-1].strip()
        
        # Find opening brace
        brace_pos = i
        while brace_pos < len(content) and content[brace_pos].isspace():
            brace_pos += 1
        if brace_pos >= len(content) or content[brace_pos] != '{':
            continue
        brace_pos = brace_pos  # position of '{'
        
        # Find matching closing brace
        depth = 1
        j = brace_pos + 1
        while j < len(content) and depth > 0:
            if content[j] == '{':
                depth += 1
            elif content[j] == '}':
                depth -= 1
            j += 1
        
        if depth != 0:
            continue
        
        func_body = content[brace_pos + 1:j - 1]
        
        # Check if the function body uses 'arguments'
        # Use word boundary to avoid matching 'arguments' in strings/comments
        if not re.search(r'\barguments\b', func_body):
            continue
        
        # Parse named params (exclude variadic params already added)
        if params_str:
            named_params = []
            for p in params_str.split(','):
                p = p.strip()
                if p and not p.startswith('...'):
                    named_params.append(p)
        else:
            named_params = []
        
        # Build var arguments line
        if named_params:
            params_array = '[' + ', '.join(named_params) + ']'
            var_args_line = 'var arguments = ' + params_array + '.concat(_toArr(_vargs));'
        else:
            var_args_line = 'var arguments = _toArr(_vargs);'
        
        # Build new signature
        new_params = ', '.join(named_params) if named_params else ''
        if new_params:
            new_params += ', ..._vargs : Object[]'
        else:
            new_params = '..._vargs : Object[]'
        
        if func_type == 'named':
            # Extract function name
            name_end = m.end()
            while name_end < len(content) and content[name_end].isspace():
                name_end += 1
            name_start = name_end
            while name_end < len(content) and (content[name_end].isalnum() or content[name_end] == '_'):
                name_end += 1
            func_name = content[name_start:name_end]
            new_decl = 'function ' + func_name + '(' + new_params + ') {'
        else:
            new_decl = 'function(' + new_params + ') {'
        
        # Insert var arguments line after opening brace
        new_func = new_decl + '\n    ' + var_args_line + '\n' + content[brace_pos + 1:j]
        
        results.append((m.start(), j, new_func))
    
    # Apply transformations (in reverse order to preserve positions)
    for start, end, new_func in reversed(results):
        content = content[:start] + new_func + content[end:]
    
    return content


def replace_prototype_calls(content):
    """Replace Array.prototype.X.call(Y, ...) with helper calls."""
    # Array.prototype.map.call(X, fn) -> _map(X, fn)
    content = re.sub(
        r'Array\.prototype\.map\.call\(([^,]+),\s*',
        r'_map(\1, ',
        content
    )
    
    # Array.prototype.slice.call(X, N) -> X.slice(N)
    def replace_slice_call(m):
        receiver = m.group(1)
        rest = m.group(2)
        return receiver + '.slice(' + rest
    
    content = re.sub(
        r'Array\.prototype\.slice\.call\(([^,]+),\s*([^)]*)\)',
        replace_slice_call,
        content
    )
    
    # Array.prototype.slice.call(X) -> X.slice()
    content = re.sub(
        r'Array\.prototype\.slice\.call\(([^)]+)\)',
        r'\1.slice()',
        content
    )
    
    # Array.prototype.reduceRight.call(X, fn, init) -> _reduceRight(X, fn, init)
    content = re.sub(
        r'Array\.prototype\.reduceRight\.call\(([^,]+),\s*',
        r'_reduceRight(\1, ',
        content
    )
    
    return content


def replace_array_object_methods(content):
    """Replace Array.isArray() and Object.keys() with helpers."""
    content = re.sub(r'Array\.isArray\(', '_isArray(', content)
    content = re.sub(r'Object\.keys\(', '_keys(', content)
    return content


def replace_require(content):
    """Replace require() calls with __noop__() to avoid reserved word issues."""
    content = re.sub(r'require\(', '__noop__(', content)
    return content


def build(step_name):
    """Build JSC.NET-compatible single file for the given step."""
    step_file = step_name + '.js'
    step_path = os.path.join(IMPL_DIR, step_file)
    
    if not os.path.exists(step_path):
        print('Error: ' + step_file + ' not found')
        sys.exit(1)
    
    # Read and concatenate files
    parts = []
    for f in COMMON_FILES:
        parts.append(read_file(f))
    parts.append(read_file(step_file))
    content = '\n'.join(parts)
    
    # 1. Remove Function.prototype.clone assignment
    content = remove_function_prototype_clone(content)
    
    # 2. Remove io.js auto-detection block
    content = remove_io_autodetect(content)
    
    # 3. Replace typeof checks
    content = replace_typeof_checks(content)
    
    # 4. Replace require() calls
    content = replace_require(content)
    
    # 5. Replace Array/Object methods
    content = replace_array_object_methods(content)
    
    # 6. Replace Array.prototype.X.call() patterns
    content = replace_prototype_calls(content)
    
    # 7. Replace direct method calls (.map, .filter, etc.)
    content = replace_method_calls(content)
    
    # 8. Transform arguments (all functions - single pass)
    content = transform_all_functions(content)
    
    # 9. Prepend imports and stubs
    header = 'import System;\nimport System.IO;\n\n' + STUBS + '\n\n'
    content = header + content
    
    # Write output
    dist_dir = os.path.join(IMPL_DIR, 'dist')
    os.makedirs(dist_dir, exist_ok=True)
    output_path = os.path.join(dist_dir, 'jsc_' + step_file)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    lines = content.count('\n') + 1
    print('Built ' + output_path + ' (' + str(lines) + ' lines)')
    return output_path


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: python build_jsc.py <step_name>')
        print('  e.g. python build_jsc.py step0_repl')
        sys.exit(1)
    
    build(sys.argv[1])
