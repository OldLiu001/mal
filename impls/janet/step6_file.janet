(import ./reader)
(import ./printer)
(import ./types :as t)
(import ./env :as e)
(import ./core)

(def repl_env
  (let [env (e/make-env)]
    (eachp [k v] core/ns
      (e/env-set env k v))
    env))

(defn READ
  [code-str]
  (reader/read_str code-str))

(var EVAL nil)

(defn eval_ast
  [ast env]
  (cond
    (t/symbol?* ast)
    (e/env-get env ast)
    #
    (t/hash-map?* ast)
    (t/make-hash-map (struct ;(map |(EVAL $0 env)
                                   (kvs (t/get-value ast)))))
    #
    (t/list?* ast)
    (t/make-list (map |(EVAL $0 env)
                      (t/get-value ast)))
    #
    (t/vector?* ast)
    (t/make-vector (map |(EVAL $0 env)
                        (t/get-value ast)))
    #
    ast))

(varfn EVAL
  [ast-param env-param]
  (var ast ast-param)
  (var env env-param)
  (label result
    (while true
      (cond
        (not (t/list?* ast))
        (return result (eval_ast ast env))
        ##
        (t/empty?* ast)
        (return result ast)
        ##
        (let [ast-head (first (t/get-value ast))
              head-name (t/get-value ast-head)]
          (case head-name
            "def!"
            (let [def-name (in (t/get-value ast) 1)
                  def-val (EVAL (in (t/get-value ast) 2) env)]
              (e/env-set env
                         def-name def-val)
              (return result def-val))
            ##
            "let*"
            (let [new-env (e/make-env env)
                  bindings (t/get-value (in (t/get-value ast) 1))]
              (each [let-name let-val] (partition 2 bindings)
                    (e/env-set new-env
                               let-name (EVAL let-val new-env)))
              ## tco
              (set ast (in (t/get-value ast) 2))
              (set env new-env))
            ##
            "do"
            (let [most-do-body-forms (slice (t/get-value ast) 1 -2)
                  last-body-form (last (t/get-value ast))
                  res-ast (eval_ast (t/make-list most-do-body-forms) env)]
              ## tco
              (set ast last-body-form))
            ##
            "if"
            (let [cond-res (EVAL (in (t/get-value ast) 1) env)]
              (if (or (t/nil?* cond-res)
                      (t/false?* cond-res))
                (if-let [else-ast (get (t/get-value ast) 3)]
                  ## tco
                  (set ast else-ast)
                  (return result t/mal-nil))
                ## tco
                (set ast (in (t/get-value ast) 2))))
            ##
            "fn*"
            (let [params (t/get-value (in (t/get-value ast) 1))
                  body (in (t/get-value ast) 2)]
              ## tco
              (return result
                      (t/make-function (fn [args]
                                         (EVAL body
                                           (e/make-env env params args)))
                                       nil false
                                       body params env)))
            ##
            (let [eval-list (t/get-value (eval_ast ast env))
                  f (first eval-list)
                  args (drop 1 eval-list)]
              (if-let [body (t/get-ast f)] ## tco
                (do
                  (set ast body)
                  (set env (e/make-env (t/get-env f) (t/get-params f) args)))
                (return result
                        ((t/get-value f) args))))))))))

(defn PRINT
  [ast]
  (printer/pr_str ast true))

(defn rep
  [code-str]
  (PRINT (EVAL (READ code-str) repl_env)))

(rep "(def! not (fn* (a) (if a false true)))")

(e/env-set repl_env
           (t/make-symbol "eval")
           (t/make-function (fn [asts]
                              (EVAL (in asts 0) repl_env))))

(rep ``
  (def! load-file
        (fn* (fpath)
          (eval
            (read-string (str "(do "
                                (slurp fpath) "\n"
                                "nil)")))))
``)

# getline gives problems
(defn getstdin [prompt buf]
  (file/write stdout prompt)
  (file/flush stdout)
  (file/read stdin :line buf))

(defn handle-error
  [err]
  (cond
    (t/nil?* err)
    (print)
    ##
    (string? err)
    (print err)
    ##
    (print (string "Error: " (PRINT err)))))

(defn main
  [& args]
  (let [args-len (length args)
        argv (if (<= 2 args-len)
               (drop 2 args)
               ())]
    (e/env-set repl_env
               (t/make-symbol "*ARGV*")
               (t/make-list (map t/make-string argv)))
    (if (< 1 args-len)
      (try
        (rep
          (string "(load-file \"" (in args 1) "\")")) # XXX: escaping?
        ([err]
         (handle-error err)))
      (do
        (var buf nil)
        (while true
          (set buf @"")
          (getstdin "user> " buf)
          (if (= 0 (length buf))
            (break)
            (try
              (print (rep buf))
              ([err]
               (handle-error err)))))))))
