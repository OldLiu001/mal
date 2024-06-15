require "readline"

require_relative "core"
require_relative "env"
require_relative "errors"
require_relative "printer"
require_relative "reader"

module Mal
  extend self

  def boot_repl!
    @repl_env = Env.new

    Core.ns.each do |k, v|
      @repl_env.set(k, v)
    end

    @repl_env.set(
      Types::Symbol.for("eval"),

      Types::Builtin.new("eval") do |mal|
        Mal.EVAL(mal, @repl_env)
      end
    )

    Mal.rep("(def! not (fn* (a) (if a false true)))")
    Mal.rep("(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\nnil)\")))))")
    Mal.rep("(def! *ARGV* (list))") if !run_application?
  end

  def run_application?
    ARGV.any?
  end

  def run!
    Mal.rep("(def! *ARGV* (list #{ARGV[1..].map(&:inspect).join(" ")}))")
    Mal.rep("(load-file #{ARGV.first.inspect})")
  end

  def READ(input)
    read_str(input)
  end

  def EVAL(ast, environment)
    loop do
      if Types::List === ast && ast.size > 0
        case ast.first
        when Types::Symbol.for("def!")
          _, sym, val = ast
          return environment.set(sym, EVAL(val, environment))
        when Types::Symbol.for("let*")
          e = Env.new(environment)
          _, bindings, val = ast

          unless Types::List === bindings || Types::Vector === bindings
            raise InvalidLetBindingsError
          end

          until bindings.empty?
            k, v = bindings.shift(2)

            raise InvalidLetBindingsError if k.nil?
            v = Types::Nil.instance if v.nil?

            e.set(k, EVAL(v, e))
          end

          if !val.nil?
            # Continue loop
            ast = val
            environment = e
          else
            return Types::Nil.instance
          end
        when Types::Symbol.for("do")
          _, *values = ast

          if !values.nil? && values.any?
            values[0...-1].each do |v|
              EVAL(v, environment)
            end

            # Continue loop
            ast = values.last
          else
            return Types::Nil.instance
          end
        when Types::Symbol.for("if")
          _, condition, when_true, when_false = ast

          case EVAL(condition, environment)
          when Types::False.instance, Types::Nil.instance
            if !when_false.nil?
              # Continue loop
              ast = when_false
            else
              return Types::Nil.instance
            end
          else
            if !when_true.nil?
              # Continue loop
              ast = when_true
            else
              raise InvalidIfExpressionError
            end
          end
        when Types::Symbol.for("fn*")
          _, binds, to_eval = ast

          return Types::Function.new(to_eval, binds, environment) do |*exprs|
            EVAL(to_eval, Env.new(environment, binds, exprs))
          end
        else
          evaluated = eval_ast(ast, environment)
          maybe_callable = evaluated.first

          if maybe_callable.respond_to?(:call) && maybe_callable.is_mal_fn?
            # Continue loop
            ast = maybe_callable.ast
            environment = Env.new(
              maybe_callable.env,
              maybe_callable.params,
              evaluated[1..],
            )
          elsif maybe_callable.respond_to?(:call) && !maybe_callable.is_mal_fn?
            return maybe_callable.call(Types::Args.new(evaluated[1..]))
          else
            raise NotCallableError, "Error! #{PRINT(maybe_callable)} is not callable."
          end
        end
      elsif Types::List === ast && ast.size == 0
        return ast
      else
        return eval_ast(ast, environment)
      end
    end
  end

  def PRINT(input)
    pr_str(input, true)
  end

  def rep(input)
    PRINT(EVAL(READ(input), @repl_env))
  rescue InvalidHashmapKeyError => e
    "Error! Hashmap keys can only be strings or keywords."
  rescue NotCallableError => e
    e.message
  rescue SymbolNotFoundError => e
    e.message
  rescue UnbalancedEscapingError => e
    "Error! Detected unbalanced escaping. Check for matching '\\'."
  rescue UnbalancedHashmapError => e
    "Error! Detected unbalanced list. Check for matching '}'."
  rescue UnbalancedListError => e
    "Error! Detected unbalanced list. Check for matching ')'."
  rescue UnbalancedStringError => e
    "Error! Detected unbalanced string. Check for matching '\"'."
  rescue UnbalancedVectorError => e
    "Error! Detected unbalanced list. Check for matching ']'."
  rescue SkipCommentError
    nil
  end

  def eval_ast(mal, environment)
    case mal
    when Types::Symbol
      environment.get(mal)
    when Types::List
      list = Types::List.new
      mal.each { |i| list << EVAL(i, environment) }
      list
    when Types::Vector
      vec = Types::Vector.new
      mal.each { |i| vec << EVAL(i, environment) }
      vec
    when Types::Hashmap
      hashmap = Types::Hashmap.new
      mal.each { |k, v| hashmap[k] = EVAL(v, environment) }
      hashmap
    else
      mal
    end
  end
end

Mal.boot_repl!

if Mal.run_application?
  Mal.run!
else
  while input = Readline.readline("user> ")
    val = Mal.rep(input)
    puts val unless val.nil?
  end

  puts
end
