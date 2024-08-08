(local printer (require :printer))
(local reader (require :reader))
(local t (require :types))
(local e (require :env))
(local core (require :core))
(local u (require :utils))

(local repl_env
  (let [env (e.make-env)]
    (each [name func (pairs core)]
      (e.env-set env
                 (t.make-symbol name)
                 func))
    env))

(fn READ
  [code-str]
  (reader.read_str code-str))

(fn EVAL
  [ast env]
  (let [dbgeval (e.env-get env "DEBUG-EVAL")]
    (when (and dbgeval
               (not (t.nil?* dbgeval))
               (not (t.false?* dbgeval)))
      (print (.. "EVAL: " (printer.pr_str ast true)))))
  (if (t.symbol?* ast)
      (let [key (t.get-value ast)]
        (or (e.env-get env key)
            (u.throw* (t.make-string (.. "'" key "' not found")))))
      ;;
      (t.vector?* ast)
      (t.make-vector (u.map (fn [elt-ast]
                              (EVAL elt-ast env))
                            (t.get-value ast)))
      ;;
      (t.hash-map?* ast)
      (t.make-hash-map (u.map (fn [elt-ast]
                                (EVAL elt-ast env))
                              (t.get-value ast)))
      ;;
          (or (not (t.list?* ast)) (t.empty?* ast))
          ast
          ;;
          (let [ast-elts (t.get-value ast)
                head-name (t.get-value (. ast-elts 1))]
            ;; XXX: want to check for symbol, but that screws up logic below
            (if (= "def!" head-name)
                (let [def-name (. ast-elts 2)
                      def-val (EVAL (. ast-elts 3) env)]
                  (e.env-set env
                             def-name def-val)
                  def-val)
                ;;
                (= "let*" head-name)
                (let [new-env (e.make-env env)
                      bindings (t.get-value (. ast-elts 2))
                      stop (/ (length bindings) 2)]
                  (for [idx 1 stop]
                       (let [b-name (. bindings (- (* 2 idx) 1))
                             b-val (EVAL (. bindings (* 2 idx)) new-env)]
                         (e.env-set new-env
                                    b-name b-val)))
                  (EVAL (. ast-elts 3) new-env))
                ;;
                (= "do" head-name)
                (u.last (u.map (fn [x] (EVAL x env)) (u.slice ast-elts 2 -1)))
                ;;
                (= "if" head-name)
                (let [cond-res (EVAL (. ast-elts 2) env)]
                  (if (or (t.nil?* cond-res)
                          (t.false?* cond-res))
                      (let [else-ast (. ast-elts 4)]
                        (if (not else-ast)
                            t.mal-nil
                            (EVAL else-ast env)))
                      (EVAL (. ast-elts 3) env)))
                ;;
                (= "fn*" head-name)
                (let [args (t.get-value (. ast-elts 2))
                      body (. ast-elts 3)]
                  (t.make-fn (fn [params]
                               (EVAL body
                                     (e.make-env env args params)))))
                ;;
                (let [eval-list (u.map (fn [x] (EVAL x env)) ast-elts)
                      f (. eval-list 1)
                      args (u.slice eval-list 2 -1)]
                  ((t.get-value f) args))))))

(fn PRINT
  [ast]
  (printer.pr_str ast true))

(fn rep
  [code-str]
  (PRINT (EVAL (READ code-str) repl_env)))

(rep "(def! not (fn* (a) (if a false true)))")

(fn handle-error
  [err]
  (if (t.nil?* err)
      (print)
      (= "string" (type err))
      (print err)
      (print (.. "Error: " (PRINT err)))))

(var done false)

(while (not done)
  (io.write "user> ")
  (io.flush)
  (let [input (io.read)]
    (if (not input)
        (set done true)
        (xpcall (fn []
                  (print (rep input)))
                handle-error))))
                ;; (fn [exc]
                ;;   (if (t.nil?* exc)
                ;;       (print)
                ;;       (= "string" (type exc))
                ;;       (print exc)
                ;;       (print (PRINT exc))))))))
