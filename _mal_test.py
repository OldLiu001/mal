import sys
# usage: python _mal_test.py <test_basename> <bat_name> [timeout]
tfile, bat = sys.argv[1], sys.argv[2]
tmo = sys.argv[3] if len(sys.argv) > 3 else '90'
if not tfile.endswith('.mal'):
    tfile += '.mal'
sys.argv = ['runtest.py', '../tests/' + tfile, '--no-pty', '--test-timeout', tmo,
            '--rundir', 'impls/batch', '--', 'python', '_runtest_driver.py', bat]
src = open('runtest.py', encoding='utf-8').read()
old = 'args = parser.parse_args(sys.argv[1:])'
new = ('try:\n    args = parser.parse_args(sys.argv[1:])\n'
       'except SystemExit:\n'
       '    i = sys.argv.index("--") if "--" in sys.argv else len(sys.argv)\n'
       '    args = parser.parse_args(sys.argv[1:i])\n'
       '    args.mal_cmd = sys.argv[i+1:]')
assert old in src, 'runtest.py parse line not found'
src = src.replace(old, new)
exec(compile(src, 'runtest.py', 'exec'))