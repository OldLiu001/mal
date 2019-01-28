# mal - Make a Lisp

[![Build Status](https://travis-ci.org/kanaka/mal.svg?branch=master)](https://travis-ci.org/kanaka/mal)

## Description

Mal is a Clojure inspired Lisp interpreter.

Mal is implemented in 74 languages:

* Ada - *created by [Chris Moore](https://github.com/zmower)*
* GNU awk - *created by [Miutsuru Kariya](https://github.com/kariya-mitsuru)*
* Bash 4
* BASIC (C64 and QBasic)
* C
* C++ - *created by [Stephen Thirlwall](https://github.com/sdt)*
* C#
* ChucK - *created by [Vasilij Schneidermann](https://github.com/wasamasa)*
* Common Lisp - *created by [Iqbal Ansari](https://github.com/iqbalansari)*
* Clojure (Clojure and ClojureScript)
* CoffeeScript
* Crystal - *created by [Linda_pp](https://github.com/rhysd)*
* D - *created by [Dov Murik](https://github.com/dubek)*
* Dart - *created by [Harry Terkelsen](https://github.com/hterkelsen)*
* Elixir - *created by [Martin Ek](https://github.com/ekmartin)*
* Elm - *created by [Jos van Bakel](https://github.com/c0deaddict)*
* Emacs Lisp - *created by [Vasilij Schneidermann](https://github.com/wasamasa)*
* Erlang - *created by [Nathan Fiedler](https://github.com/nlfiedler)*
* ES6 (ECMAScript 6 / ECMAScript 2015)
* F# - *created by [Peter Stephens](https://github.com/pstephens)*
* Factor - *created by [Jordan Lewis](https://github.com/jordanlewis)*
* Fantom - *created by [Dov Murik](https://github.com/dubek)*
* Forth - *created by [Chris Houser](https://github.com/chouser)*
* Go
* Groovy
* GNU Guile - *created by [Mu Lei](https://github.com/NalaGinrut).*
* GNU Smalltalk - *created by [Vasilij Schneidermann](https://github.com/wasamasa)*
* Haskell
* Haxe (Neko, Python, C++ and JavaScript)
* Hy
* Io - *created by [Dov Murik](https://github.com/dubek)*
* Java
* JavaScript ([Online Demo](http://kanaka.github.io/mal))
* Julia
* Kotlin - *created by [Javier Fernandez-Ivern](https://github.com/ivern)*
* LiveScript - *created by [Jos van Bakel](https://github.com/c0deaddict)*
* Logo - *created by [Dov Murik](https://github.com/dubek)*
* Lua
* GNU Make
* mal itself
* Matlab (GNU Octave and MATLAB)
* [miniMAL](https://github.com/kanaka/miniMAL)
* NASM - *created by [Ben Dudson](https://github.com/bendudson)*
* Nim - *created by [Dennis Felsing](https://github.com/def-)*
* Object Pascal
* Objective C
* OCaml - *created by [Chris Houser](https://github.com/chouser)*
* Perl
* Perl 6 - *created by [Hinrik Örn Sigurðsson](https://github.com/hinrik)*
* PHP
* Picolisp - *created by [Vasilij Schneidermann](https://github.com/wasamasa)*
* PL/pgSQL (Postgres)
* PL/SQL (Oracle)
* Postscript
* PowerShell
* Python (2.X and 3.X)
* RPython
* R
* Racket
* Rexx - *created by [Dov Murik](https://github.com/dubek)*
* Ruby
* Rust
* Scala
* Scheme (R7RS) *created by [Vasilij Schneidermann](https://github.com/wasamasa)*
* Skew - *created by [Dov Murik](https://github.com/dubek)*
* Swift - *created by [Keith Rollin](https://github.com/keith-rollin)*
* Swift 3
* Tcl - *created by [Dov Murik](https://github.com/dubek)*
* TypeScript - *created by [Masahiro Wakame](https://github.com/vvakame)*
* VHDL - *created by [Dov Murik](https://github.com/dubek)*
* Vimscript - *created by [Dov Murik](https://github.com/dubek)*
* Visual Basic.NET
* WebAssembly (wasm)
* Yorick - *created by [Dov Murik](https://github.com/dubek)*


Mal is a learning tool. See the [make-a-lisp process
guide](process/guide.md). Each implementation of mal is separated into
11 incremental, self-contained (and testable) steps that demonstrate
core concepts of Lisp. The last step is capable of self-hosting
(running the mal implementation of mal).

The mal (make a lisp) steps are:

* [step0_repl](process/guide.md#step0)
* [step1_read_print](process/guide.md#step1)
* [step2_eval](process/guide.md#step2)
* [step3_env](process/guide.md#step3)
* [step4_if_fn_do](process/guide.md#step4)
* [step5_tco](process/guide.md#step5)
* [step6_file](process/guide.md#step6)
* [step7_quote](process/guide.md#step7)
* [step8_macros](process/guide.md#step8)
* [step9_try](process/guide.md#step9)
* [stepA_mal](process/guide.md#stepA)


Mal was presented publicly for the first time in a lightning talk at
Clojure West 2014 (unfortunately there is no video). See
examples/clojurewest2014.mal for the presentation that was given at the
conference (yes, the presentation is a mal program). At Midwest.io
2015, Joel Martin gave a presentation on Mal titled "Achievement
Unlocked: A Better Path to Language Learning".
[Video](https://www.youtube.com/watch?v=lgyOAiRtZGw),
[Slides](http://kanaka.github.io/midwest.io.mal/). More recently
Joel gave a presentation on "Make Your Own Lisp Interpreter in
10 Incremental Steps" at LambdaConf 2016:
[Part 1](https://www.youtube.com/watch?v=jVhupfthTEk),
[Part 2](https://www.youtube.com/watch?v=X5OQBMGpaTU),
[Part 3](https://www.youtube.com/watch?v=6mARZzGgX4U),
[Part 4](https://www.youtube.com/watch?v=dCO1SYR5kDU),
[Slides](http://kanaka.github.io/lambdaconf/).

If you are interesting in creating a mal implementation (or just
interested in using mal for something), please drop by the #mal
channel on freenode. In addition to the [make-a-lisp process
guide](process/guide.md) there is also a [mal/make-a-lisp
FAQ](docs/FAQ.md) where I attempt to answer some common questions.

## Building/running implementations

The simplest way to run any given implementation is to use docker.
Every implementation has a docker image pre-built with language
dependencies installed. You can launch the REPL using a convenient
target in the top level Makefile (where IMPL is the implementation
directory name and stepX is the step to run):

```
make DOCKERIZE=1 "repl^IMPL^stepX"
    # OR stepA is the default step:
make DOCKERIZE=1 "repl^IMPL"
```


### Ada

The Ada implementation was developed with GNAT 4.9 on debian. It also
compiles unchanged on windows if you have windows versions of git,
GNAT and (optionally) make.  There are no external dependencies
(readline not implemented).

```
cd ada
make
./stepX_YYY
```

### GNU awk

The GNU awk implementation of mal has been tested with GNU awk 4.1.1.

```
cd gawk
gawk -O -f stepX_YYY.awk
```

### Bash 4

```
cd bash
bash stepX_YYY.sh
```

### BASIC (C64 and QBasic)

The BASIC implementation uses a preprocessor that can generate BASIC
code that is compatible with both C64 BASIC (CBM v2) and QBasic. The
C64 mode has been tested with
[cbmbasic](https://github.com/kanaka/cbmbasic) (the patched version is
currently required to fix issues with line input) and the QBasic mode
has been tested with [qb64](http://www.qb64.net/).

Generate C64 code and run it using cbmbasic:

```
cd basic
make stepX_YYY.bas
STEP=stepX_YYY ./run
```

Generate QBasic code and load it into qb64:

```
cd basic
make MODE=qbasic stepX_YYY.bas
./qb64 stepX_YYY.bas
```

Thanks to [Steven Syrek](https://github.com/sjsyrek) for the original
inspiration for this implementation.


### C

The C implementation of mal requires the following libraries (lib and
header packages): glib, libffi6, libgc, and either the libedit or GNU readline
library.

```
cd c
make
./stepX_YYY
```

### C++

The C++ implementation of mal requires g++-4.9 or clang++-3.5 and
a readline compatible library to build. See the `cpp/README.md` for
more details:

```
cd cpp
make
    # OR
make CXX=clang++-3.5
./stepX_YYY
```


### C# ###

The C# implementation of mal has been tested on Linux using the Mono
C# compiler (mcs) and the Mono runtime (version 2.10.8.1). Both are
required to build and run the C# implementation.

```
cd cs
make
mono ./stepX_YYY.exe
```

### ChucK

The ChucK implementation has been tested with ChucK 1.3.5.2.

```
cd chuck
./run
```

### Common Lisp

The implementation has been tested with SBCL, CCL, CMUCL, GNU CLISP, ECL and
Allegro CL on Ubuntu 16.04 and Ubuntu 12.04, see
the [README](common-lisp/README.org) for more details. Provided you have the
dependencies mentioned installed, do the following to run the implementation

```
cd common-lisp
make
./run
```

### Clojure

For the most part the Clojure implementation requires Clojure 1.5,
however, to pass all tests, Clojure 1.8.0-RC4 is required.

```
cd clojure
lein with-profile +stepX trampoline run
```

### CoffeeScript

```
sudo npm install -g coffee-script
cd coffee
coffee ./stepX_YYY
```

### Crystal

The Crystal implementation of mal has been tested with Crystal 0.26.1.

```
cd crystal
crystal run ./stepX_YYY.cr
    # OR
make   # needed to run tests
./stepX_YYY
```

### D

The D implementation of mal was tested with GDC 4.8.  It requires the GNU
readline library.

```
cd d
make
./stepX_YYY
```

### Dart

The Dart implementation has been tested with Dart 1.20.

```
cd dart
dart ./stepX_YYY
```

### Emacs Lisp

The Emacs Lisp implementation of mal has been tested with Emacs 24.3
and 24.5.  While there is very basic readline editing (`<backspace>`
and `C-d` work, `C-c` cancels the process), it is recommended to use
`rlwrap`.

```
cd elisp
emacs -Q --batch --load stepX_YYY.el
# with full readline support
rlwrap emacs -Q --batch --load stepX_YYY.el
```

### Elixir

The Elixir implementation of mal has been tested with Elixir 1.0.5.

```
cd elixir
mix stepX_YYY
# Or with readline/line editing functionality:
iex -S mix stepX_YYY
```

### Elm

The Elm implementation of mal has been tested with Elm 0.18.0

```
cd elm
make stepX_YYY.js
STEP=stepX_YYY ./run
```

### Erlang

The Erlang implementation of mal requires [Erlang/OTP R17](http://www.erlang.org/download.html)
and [rebar](https://github.com/rebar/rebar) to build.

```
cd erlang
make
    # OR
MAL_STEP=stepX_YYY rebar compile escriptize # build individual step
./stepX_YYY
```

### ES6 (ECMAScript 6 / ECMAScript 2015)

The ES6 implementation uses the [babel](https://babeljs.io) compiler
to generate ES5 compatible JavaScript. The generated code has been
tested with Node 0.12.4.

```
cd es6
make
node build/stepX_YYY.js
```


### F# ###

The F# implementation of mal has been tested on Linux using the Mono
F# compiler (fsharpc) and the Mono runtime (version 3.12.1). The mono C#
compiler (mcs) is also necessary to compile the readline dependency. All are
required to build and run the F# implementation.

```
cd fsharp
make
mono ./stepX_YYY.exe
```

### Factor

The Factor implementation of mal has been tested with Factor 0.97
([factorcode.org](http://factorcode.org)).

```
cd factor
FACTOR_ROOTS=. factor -run=stepX_YYY
```

### Fantom

The Fantom implementation of mal has been tested with Fantom 1.0.70.

```
cd fantom
make lib/fan/stepX_YYY.pod
STEP=stepX_YYY ./run
```

### Forth

```
cd forth
gforth stepX_YYY.fs
```

### Go

The Go implementation of mal requires that go is installed on on the
path. The implementation has been tested with Go 1.3.1.

```
cd go
make
./stepX_YYY
```


### Groovy

The Groovy implementation of mal requires Groovy to run and has been
tested with Groovy 1.8.6.

```
cd groovy
make
groovy ./stepX_YYY.groovy
```

### GNU Guile 2.1+

```
cd guile
guile -L ./ stepX_YYY.scm
```

### GNU Smalltalk

The Smalltalk implementation of mal has been tested with GNU Smalltalk 3.2.91.

```
cd gnu-smalltalk
./run
```

### Haskell

The Haskell implementation requires the ghc compiler version 7.10.1 or
later and also the Haskell parsec and readline (or editline) packages.

```
cd haskell
make
./stepX_YYY
```

### Haxe (Neko, Python, C++ and JavaScript)

The Haxe implementation of mal requires Haxe version 3.2 to compile.
Four different Haxe targets are supported: Neko, Python, C++, and
JavaScript.

```
cd haxe
# Neko
make all-neko
neko ./stepX_YYY.n
# Python
make all-python
python3 ./stepX_YYY.py
# C++
make all-cpp
./cpp/stepX_YYY
# JavaScript
make all-js
node ./stepX_YYY.js
```

### Hy

The Hy implementation of mal has been tested with Hy 0.13.0.

```
cd hy
./stepX_YYY.hy
```

### Io

The Io implementation of mal has been tested with Io version 20110905.

```
cd io
io ./stepX_YYY.io
```

### Java 1.7

The Java implementation of mal requires maven2 to build.

```
cd java
mvn compile
mvn -quiet exec:java -Dexec.mainClass=mal.stepX_YYY
    # OR
mvn -quiet exec:java -Dexec.mainClass=mal.stepX_YYY -Dexec.args="CMDLINE_ARGS"
```

### JavaScript/Node

```
cd js
npm update
node stepX_YYY.js
```

### Julia

The Julia implementation of mal requires Julia 0.4.

```
cd julia
julia stepX_YYY.jl
```

### Kotlin

The Kotlin implementation of mal has been tested with Kotlin 1.0.

```
cd kotlin
make
java -jar stepX_YYY.jar
```

### LiveScript

The LiveScript implementation of mal has been tested with LiveScript 1.5.

```
cd livescript
make
node_modules/.bin/lsc stepX_YYY.ls
```

### Logo

The Logo implementation of mal has been tested with UCBLogo 6.0.

```
cd logo
logo stepX_YYY.lg
```

### Lua

The Lua implementation of mal has been tested with Lua 5.2. The
implementation requires that luarocks and the lua-rex-pcre library
are installed.

```
cd lua
make  # to build and link linenoise.so
./stepX_YYY.lua
```

### Mal

Running the mal implementation of mal involves running stepA of one of
the other implementations and passing the mal step to run as a command
line argument.

```
cd IMPL
IMPL_STEPA_CMD ../mal/stepX_YYY.mal

```

### GNU Make 3.81

```
cd make
make -f stepX_YYY.mk
```

### NASM

The NASM implementation of mal is written for x86-64 Linux, and has been tested
with Linux 3.16.0-4-amd64 and NASM version 2.11.05.

```
cd nasm
make
./stepX_YYY
```

### Nim 0.17.0

The Nim implementation of mal has been tested with Nim 0.17.0.

```
cd nim
make
  # OR
nimble build
./stepX_YYY
```

### Object Pascal

The Object Pascal implementation of mal has been built and tested on
Linux using the Free Pascal compiler version 2.6.2 and 2.6.4.

```
cd objpascal
make
./stepX_YYY
```

### Objective C

The Objective C implementation of mal has been built and tested on
Linux using clang/LLVM 3.6. It has also been built and tested on OS
X using XCode 7.

```
cd objc
make
./stepX_YYY
```

### OCaml 4.01.0

```
cd ocaml
make
./stepX_YYY
```

### MatLab (GNU Octave and MATLAB)

The MatLab implementation has been tested with GNU Octave 4.2.1.
It has also been tested with MATLAB version R2014a on Linux. Note that
MATLAB is a commercial product.

```
cd matlab
./stepX_YYY
octave -q --no-gui --no-history --eval "stepX_YYY();quit;"
matlab -nodisplay -nosplash -nodesktop -nojvm -r "stepX_YYY();quit;"
    # OR with command line arguments
octave -q --no-gui --no-history --eval "stepX_YYY('arg1','arg2');quit;"
matlab -nodisplay -nosplash -nodesktop -nojvm -r "stepX_YYY('arg1','arg2');quit;"
```

### miniMAL

[miniMAL](https://github.com/kanaka/miniMAL) is small Lisp interpreter
implemented in less than 1024 bytes of JavaScript. To run the miniMAL
implementation of mal you need to download/install the miniMAL
interpreter (which requires Node.js).
```
cd miniMAL
# Download miniMAL and dependencies
npm install
export PATH=`pwd`/node_modules/minimal-lisp/:$PATH
# Now run mal implementation in miniMAL
miniMAL ./stepX_YYY
```

### Perl 5.8

For readline line editing support, install Term::ReadLine::Perl or
Term::ReadLine::Gnu from CPAN.

```
cd perl
perl stepX_YYY.pl
```

### Perl 6

The Perl 6 implementation was tested on Rakudo Perl 6 2016.04.

```
cd perl6
perl6 stepX_YYY.pl
```

### PHP 5.3

The PHP implementation of mal requires the php command line interface
to run.

```
cd php
php stepX_YYY.php
```

### Picolisp

The Picolisp implementation requires libreadline and Picolisp 3.1.11
or later.

```
cd picolisp
./run
```

### PL/pgSQL (Postgres SQL Procedural Language)

The PL/pgSQL implementation of mal requires a running Postgres server
(the "kanaka/mal-test-plpgsql" docker image automatically starts
a Postgres server). The implementation connects to the Postgres server
and create a database named "mal" to store tables and stored
procedures. The wrapper script uses the psql command to connect to the
server and defaults to the user "postgres" but this can be overridden
with the PSQL_USER environment variable. A password can be specified
using the PGPASSWORD environment variable. The implementation has been
tested with Postgres 9.4.

```
cd plpgsql
./wrap.sh stepX_YYY.sql
    # OR
PSQL_USER=myuser PGPASSWORD=mypass ./wrap.sh stepX_YYY.sql
```

### PL/SQL (Oracle SQL Procedural Language)

The PL/pgSQL implementation of mal requires a running Oracle DB
server (the "kanaka/mal-test-plsql" docker image automatically
starts an Oracle Express server). The implementation connects to the
Oracle server to create types, tables and stored procedures. The
default SQL*Plus logon value (username/password@connect_identifier) is
"system/oracle" but this can be overridden with the ORACLE_LOGON
environment variable. The implementation has been tested with Oracle
Express Edition 11g Release 2. Note that any SQL*Plus connection
warnings (user password expiration, etc) will interfere with the
ability of the wrapper script to communicate with the DB.

```
cd plsql
./wrap.sh stepX_YYY.sql
    # OR
ORACLE_LOGON=myuser/mypass@ORCL ./wrap.sh stepX_YYY.sql
```

### Postscript Level 2/3

The Postscript implementation of mal requires ghostscript to run. It
has been tested with ghostscript 9.10.

```
cd ps
gs -q -dNODISPLAY -I./ stepX_YYY.ps
```

### PowerShell

The PowerShell implementation of mal requires the PowerShell script
language. It has been tested with PowerShell 6.0.0 Alpha 9 on Linux.

```
cd powershell
powershell ./stepX_YYY.ps1
```

### Python (2.X and 3.X)

```
cd python
python stepX_YYY.py
```

### RPython

You must have [rpython](https://rpython.readthedocs.org/) on your path
(included with [pypy](https://bitbucket.org/pypy/pypy/)).

```
cd rpython
make        # this takes a very long time
./stepX_YYY
```

### R

The R implementation of mal requires R (r-base-core) to run.

```
cd r
make libs  # to download and build rdyncall
Rscript stepX_YYY.r
```

### Racket (5.3)

The Racket implementation of mal requires the Racket
compiler/interpreter to run.

```
cd racket
./stepX_YYY.rkt
```

### Rexx

The Rexx implementation of mal has been tested with Regina Rexx 3.6.

```
cd rexx
make
rexx -a ./stepX_YYY.rexxpp
```

### Ruby (1.9+)

```
cd ruby
ruby stepX_YYY.rb
```

### Rust (1.0.0 nightly)

The rust implementation of mal requires the rust compiler and build
tool (cargo) to build.

```
cd rust
cargo run --release --bin stepX_YYY
```

### Scala ###

Install scala and sbt (http://www.scala-sbt.org/0.13/tutorial/Installing-sbt-on-Linux.html):

```
cd scala
sbt 'run-main stepX_YYY'
    # OR
sbt compile
scala -classpath target/scala*/classes stepX_YYY
```

### Scheme (R7RS) ###

The Scheme implementation of mal has been tested with Chibi-Scheme
0.7.3, Kawa 2.4, Gauche 0.9.5, CHICKEN 4.11.0, Sagittarius 0.8.3,
Cyclone 0.6.3 (Git version) and Foment 0.4 (Git version).  You should
be able to get it running on other conforming R7RS implementations
after figuring out how libraries are loaded and adjusting the
`Makefile` and `run` script accordingly.

```
cd scheme
make symlinks
# chibi
scheme_MODE=chibi ./run
# kawa
make kawa
scheme_MODE=kawa ./run
# gauche
scheme_MODE=gauche ./run
# chicken
make chicken
scheme_MODE=chicken ./run
# sagittarius
scheme_MODE=sagittarius ./run
# cyclone
make cyclone
scheme_MODE=cyclone ./run
# foment
scheme_MODE=foment ./run
```

### Skew ###

The Skew implementation of mal has been tested with Skew 0.7.42.

```
cd skew
make
node stepX_YYY.js
```


### Swift

The Swift implementation of mal requires the Swift 2.0 compiler (XCode
7.0) to build. Older versions will not work due to changes in the
language and standard library.

```
cd swift
make
./stepX_YYY
```

### Swift 3

The Swift 3 implementation of mal requires the Swift 3.0 compiler. It
has been tested with Swift 3 Preview 3.

```
cd swift3
make
./stepX_YYY
```

### Tcl 8.6

The Tcl implementation of mal requires Tcl 8.6 to run.  For readline line
editing support, install tclreadline.

```
cd tcl
tclsh ./stepX_YYY.tcl
```

### TypeScript

The TypeScript implementation of mal requires the TypeScript 2.2 compiler.
It has been tested with Node.js v6.

```
cd ts
make
node ./stepX_YYY.js
```

### VHDL

The VHDL implementation of mal has been tested with GHDL 0.29.

```
cd vhdl
make
./run_vhdl.sh ./stepX_YYY
```

### Vimscript

The Vimscript implementation of mal requires Vim 8.0 to run.

```
cd vimscript
./run_vimscript.sh ./stepX_YYY.vim
```

### Visual Basic.NET ###

The VB.NET implementation of mal has been tested on Linux using the Mono
VB compiler (vbnc) and the Mono runtime (version 2.10.8.1). Both are
required to build and run the VB.NET implementation.

```
cd vb
make
mono ./stepX_YYY.exe
```

### WebAssembly (wasm) ###

The WebAssembly implementation is written in
[Wam](https://github.com/kanaka/wam) (WebAssembly Macro language) and
runs under the [wac/wace](https://github.com/kanaka/wac) WebAssembly
runtime.

```
cd wasm
make
wace ./stepX_YYY.wasm
```

### Yorick

The Yorick implementation of mal was tested on Yorick 2.2.04.

```
cd yorick
yorick -batch ./stepX_YYY.i
```



## Running tests

### Functional tests

The are over 600 generic functional tests (for all implementations)
in the `tests/` directory. Each step has a corresponding test file
containing tests specific to that step. The `runtest.py` test harness
launches a Mal step implementation and then feeds the tests one at
a time to the implementation and compares the output/return value to
the expected output/return value.

To simplify the process of running tests, a top level Makefile is
provided with convenient test targets.

* To run all the tests across all implementations (be prepared to wait):

```
make test
```

* To run all tests against a single implementation:

```
make "test^IMPL"

# e.g.
make "test^clojure"
make "test^js"
```

* To run tests for a single step against all implementations:

```
make "test^stepX"

# e.g.
make "test^step2"
make "test^step7"
```

* To run tests for a specific step against a single implementation:

```
make "test^IMPL^stepX"

# e.g
make "test^ruby^step3"
make "test^ps^step4"
```

### Self-hosted functional tests

* To run the functional tests in self-hosted mode, you specify `mal`
  as the test implementation and use the `MAL_IMPL` make variable
  to change the underlying host language (default is JavaScript):
```
make MAL_IMPL=IMPL "test^mal^step2"

# e.g.
make "test^mal^step2"   # js is default
make MAL_IMPL=ruby "test^mal^step2"
make MAL_IMPL=python "test^mal^step2"
```

### Starting the REPL

* To start the REPL of an implementation in a specific step:

```
make "repl^IMPL^stepX"

# e.g
make "repl^ruby^step3"
make "repl^ps^step4"
```

* If you omit the step, then `stepA` is used:

```
make "repl^IMPL"

# e.g
make "repl^ruby"
make "repl^ps"
```

* To start the REPL of the self-hosted implementation, specify `mal` as the
  REPL implementation and use the `MAL_IMPL` make variable to change the
  underlying host language (default is JavaScript):
```
make MAL_IMPL=IMPL "repl^mal^stepX"

# e.g.
make "repl^mal^step2"   # js is default
make MAL_IMPL=ruby "repl^mal^step2"
make MAL_IMPL=python "repl^mal"
```

### Performance tests

Warning: These performance tests are neither statistically valid nor
comprehensive; runtime performance is a not a primary goal of mal. If
you draw any serious conclusions from these performance tests, then
please contact me about some amazing oceanfront property in Kansas
that I'm willing to sell you for cheap.

* To run performance tests against a single implementation:
```
make "perf^IMPL"

# e.g.
make "perf^js"
```

* To run performance tests against all implementations:
```
make "perf"
```

### Generating language statistics

* To report line and byte statistics for a single implementation:
```
make "stats^IMPL"

# e.g.
make "stats^js"
```

* To report line and bytes statistics for general Lisp code (env, core
  and stepA):
```
make "stats-lisp^IMPL"

# e.g.
make "stats-lisp^js"
```

## Dockerized testing

Every implementation directory contains a Dockerfile to create
a docker image containing all the dependencies for that
implementation. In addition, the top-level Makefile contains support
for running the tests target (and perf, stats, repl, etc) within
a docker container for that implementation by passing *"DOCKERIZE=1"*
on the make command line. For example:

```
make DOCKERIZE=1 "test^js^step3"
```

Existing implementations already have docker images built and pushed
to the docker registry. However, if
you wish to build or rebuild a docker image locally, the toplevel
Makefile provides a rule for building docker images:

```
make "docker-build^IMPL"
```


**Notes**:
* Docker images are named *"kanaka/mal-test-IMPL"*
* JVM-based language implementations (Groovy, Java, Clojure, Scala):
  you will probably need to run this command once manually
  first `make DOCKERIZE=1 "repl^IMPL"` before you can run tests because
  runtime dependencies need to be downloaded to avoid the tests timing
  out. These dependencies are downloaded to dot-files in the /mal
  directory so they will persist between runs.


## External Implementations

The following implementations are maintained as separate projects:

### HolyC

* [by Alexander Bagnalla](https://github.com/bagnalla/holyc_mal)

### Rust

* [by Tim Morgan](https://github.com/seven1m/mal-rust)
* [by vi](https://github.com/vi/mal-rust-vi) - using [Pest](https://pest.rs/) grammar, not using typical Mal infrastructure (cargo-ized steps and built-in converted tests).


## Projects using mal

 * [malc](https://github.com/dubek/malc) - Mal (Make A Lisp) compiler. Compiles a Mal program to LLVM assembly language, then binary.
 * [frock](https://github.com/chr15m/frock) - Clojure-flavoured PHP. Uses mal/php to run programs.

## License

Mal (make-a-lisp) is licensed under the MPL 2.0 (Mozilla Public
License 2.0). See LICENSE.txt for more details.
