;; -*- lexical-binding: t; -*-

(setq debug-on-error t)
(require 'mal/types)
(require 'mal/func)
(require 'mal/env)
(require 'mal/reader)
(require 'mal/printer)
(require 'mal/core)

(defvar repl-env (mal-env))

(dolist (binding core-ns)
  (let ((symbol (car binding))
        (fn (cdr binding)))
    (mal-env-set repl-env symbol fn)))

(defun READ (input)
  (read-str input))

(defun EVAL (ast env)
  (catch 'return
    (while t

     (let ((dbgeval (mal-env-get env 'DEBUG-EVAL)))
       (if (and dbgeval
                (not (member (mal-type dbgeval) '(false nil))))
         (println "EVAL: %s\n" (PRINT ast))))

     (cl-case (mal-type ast)

     (list
          (let* ((a (mal-value ast))
                 (a1 (cadr a))
                 (a2 (nth 2 a))
                 (a3 (nth 3 a)))
            (unless a (throw 'return ast))
            (cl-case (mal-value (car a))
             (def!
              (let ((identifier (mal-value a1))
                    (value (EVAL a2 env)))
                (throw 'return (mal-env-set env identifier value))))
             (let*
              (let ((env* (mal-env env))
                    (bindings (mal-listify a1))
                    (form a2))
                (while bindings
                  (let ((key (mal-value (pop bindings)))
                        (value (EVAL (pop bindings) env*)))
                    (mal-env-set env* key value)))
                (setq env env*
                      ast form))) ; TCO
             (do
              (let* ((a0... (cdr a))
                     (butlast (butlast a0...))
                     (last (car (last a0...))))
                (mapcar (lambda (item) (EVAL item env)) butlast)
                (setq ast last))) ; TCO
             (if
              (let* ((condition (EVAL a1 env))
                     (condition-type (mal-type condition))
                     (then a2)
                     (else a3))
                (if (and (not (eq condition-type 'false))
                         (not (eq condition-type 'nil)))
                    (setq ast then) ; TCO
                  (if else
                      (setq ast else) ; TCO
                    (throw 'return mal-nil)))))
             (fn*
              (let* ((binds (mapcar 'mal-value (mal-value a1)))
                     (body a2)
                     (fn (mal-fn
                          (lambda (&rest args)
                            (let ((env* (mal-env env binds args)))
                              (EVAL body env*))))))
                (throw 'return (mal-func body binds env fn))))
             (t
              ;; not a special form
              (let ((fn (EVAL (car a) env))
                    (args (mapcar (lambda (x) (EVAL x env)) (cdr a))))
                (if (mal-func-p fn)
                    (let ((env* (mal-env (mal-func-env fn)
                                         (mal-func-params fn)
                                         args)))
                      (setq env env*
                            ast (mal-func-ast fn))) ; TCO
                  ;; built-in function
                  (let ((fn* (mal-value fn)))
                    (throw 'return (apply fn* args)))))))))
     (symbol
      (let ((key (mal-value ast)))
        (throw 'return (or (mal-env-get env key)
                           (error "'%s' not found" key)))))
     (vector
      (throw 'return
             (mal-vector (vconcat (mapcar (lambda (item) (EVAL item env))
                                          (mal-value ast))))))
     (map
      (let ((map (copy-hash-table (mal-value ast))))
        (maphash (lambda (key val)
                   (puthash key (EVAL val env) map))
                 map)
        (throw 'return (mal-map map))))
     (t
      ;; return as is
      (throw 'return ast))))))

(defun PRINT (input)
  (pr-str input t))

(defun rep (input)
  (PRINT (EVAL (READ input) repl-env)))

(rep "(def! not (fn* (a) (if a false true)))")

(defun readln (prompt)
  ;; C-d throws an error
  (ignore-errors (read-from-minibuffer prompt)))

(defun println (format-string &rest args)
  (if (not args)
      (princ format-string)
    (princ (apply 'format format-string args)))
  (terpri))

(defun main ()
  (let (eof)
    (while (not eof)
      (let ((input (readln "user> ")))
        (if input
            (condition-case err
                (println (rep input))
              (end-of-token-stream
               ;; empty input, carry on
               )
              (unterminated-sequence
               (princ (format "Expected '%c', got EOF\n"
                              (cl-case (cadr err)
                                (string ?\")
                                (list   ?\))
                                (vector ?\])
                                (map    ?})))))
              (error ; catch-all
               (println (error-message-string err))))
          (setq eof t)
          ;; print final newline
          (terpri))))))

(main)
