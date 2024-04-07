(defpackage :mal
  (:use :common-lisp
        :types
        :env
        :reader
        :printer
        :core)
  (:import-from :cl-readline
                :readline
                :register-function)
  (:import-from :genhash
                :hashref
                :hashmap)
  (:import-from :utils
                :listify
                :getenv
                :common-prefix)
  (:export :main))

(in-package :mal)

(define-condition invalid-function (mal-runtime-exception)
  ((form :initarg :form :reader form)
   (context :initarg :context :reader context))
  (:report (lambda (condition stream)
             (format stream
                     "Invalid function '~a' provided while ~a"
                     (printer:pr-str (form condition))
                     (if (string= (context condition) "apply")
                         "applying"
                         "defining macro")))))


(defvar *repl-env* (env:create-mal-env))

(dolist (binding core:ns)
  (env:set-env *repl-env* (car binding) (cdr binding)))

(defvar mal-def! (make-mal-symbol "def!"))
(defvar mal-let* (make-mal-symbol "let*"))
(defvar mal-do (make-mal-symbol "do"))
(defvar mal-if (make-mal-symbol "if"))
(defvar mal-fn* (make-mal-symbol "fn*"))
(defvar mal-quote (make-mal-symbol "quote"))
(defvar mal-quasiquote (make-mal-symbol "quasiquote"))
(defvar mal-quasiquoteexpand (make-mal-symbol "quasiquoteexpand"))
(defvar mal-unquote (make-mal-symbol "unquote"))
(defvar mal-splice-unquote (make-mal-symbol "splice-unquote"))
(defvar mal-vec (make-mal-symbol "vec"))
(defvar mal-cons (make-mal-symbol "cons"))
(defvar mal-concat (make-mal-symbol "concat"))
(defvar mal-defmacro! (make-mal-symbol "defmacro!"))
(defvar mal-macroexpand (make-mal-symbol "macroexpand"))

(defun eval-sequence (sequence env)
  (map 'list
       (lambda (ast) (mal-eval ast env))
       (mal-data-value sequence)))

(defun eval-hash-map (hash-map env)
  (let ((hash-map-value (mal-data-value hash-map))
        (new-hash-table (make-mal-value-hash-table)))
    (genhash:hashmap (lambda (key value)
                       (setf (genhash:hashref key new-hash-table)
                             (mal-eval value env)))
                     hash-map-value)
    (make-mal-hash-map new-hash-table)))

(defun eval-ast (ast env)
  (switch-mal-type ast
    (types:symbol (env:get-env env ast))
    (types:list (eval-sequence ast env))
    (types:vector (make-mal-vector (apply 'vector (eval-sequence ast env))))
    (types:hash-map (eval-hash-map ast env))
    (types:any ast)))

(defun qq-reducer (elt acc)
  (make-mal-list
    (if (and (mal-list-p elt)
             (mal-data-value= (first (mal-data-value elt)) mal-splice-unquote))
      (list mal-concat (second (mal-data-value elt)) acc)
      (list mal-cons (quasiquote elt) acc))))
(defun qq-iter (elts)
  (reduce #'qq-reducer elts :from-end t :initial-value (make-mal-list ())))
(defun quasiquote (ast)
  (switch-mal-type ast
    (types:list     (if (mal-data-value= (first (mal-data-value ast)) mal-unquote)
                      (second (mal-data-value ast))
                      (qq-iter (mal-data-value ast))))
    (types:vector   (make-mal-list (list mal-vec (qq-iter (listify (mal-data-value ast))))))
    (types:hash-map (make-mal-list (list mal-quote ast)))
    (types:symbol   (make-mal-list (list mal-quote ast)))
    (types:any      ast)))

(defun is-macro-call (ast env)
  (when (mal-list-p ast)
    (let* ((func-symbol (first (mal-data-value ast)))
           (func (when (mal-symbol-p func-symbol)
                   (env:find-env env func-symbol))))
      (and func
           (mal-fn-p func)
           (cdr (assoc :is-macro (mal-data-attrs func)))))))

(defun mal-macroexpand (ast env)
  (loop
     while (is-macro-call ast env)
     do (let* ((forms (mal-data-value ast))
               (func (env:get-env env (first forms))))
          (setf ast (apply (mal-data-value func)
                           (cdr forms)))))
  ast)

(defun mal-read (string)
  (reader:read-str string))

(defun mal-eval (ast env)
  (loop
     do (setf ast (mal-macroexpand ast env))
     do (cond
          ((null ast) (return mal-nil))
          ((not (mal-list-p ast)) (return (eval-ast ast env)))
          ((zerop (length (mal-data-value ast))) (return ast))
          (t (let ((forms (mal-data-value ast)))
               (cond
                 ((mal-data-value= mal-quote (first forms))
                  (return (second forms)))

                 ((mal-data-value= mal-quasiquoteexpand (first forms))
                  (return (quasiquote (second forms))))

                 ((mal-data-value= mal-quasiquote (first forms))
                  (setf ast (quasiquote (second forms))))

                 ((mal-data-value= mal-macroexpand (first forms))
                  (return (mal-macroexpand (second forms) env)))

                 ((mal-data-value= mal-def! (first forms))
                  (return (env:set-env env (second forms) (mal-eval (third forms) env))))

                 ((mal-data-value= mal-defmacro! (first forms))
                  (let ((value (mal-eval (third forms) env)))
                    (return (if (mal-fn-p value)
                                (env:set-env env
                                             (second forms)
                                             (progn
                                               (setf (cdr (assoc :is-macro (mal-data-attrs value))) t)
                                               value))
                                (error 'invalid-function
                                       :form value
                                       :context "macro")))))

                 ((mal-data-value= mal-let* (first forms))
                  (let ((new-env (env:create-mal-env :parent env))
                        (bindings (utils:listify (mal-data-value (second forms)))))

                    (mapcar (lambda (binding)
                              (env:set-env new-env
                                           (car binding)
                                           (mal-eval (or (cdr binding)
                                                         mal-nil)
                                                     new-env)))
                            (loop
                               for (symbol value) on bindings
                               by #'cddr
                               collect (cons symbol value)))
                    (setf ast (third forms)
                          env new-env)))

                 ((mal-data-value= mal-do (first forms))
                  (mapc (lambda (form) (mal-eval form env))
                        (butlast (cdr forms)))
                  (setf ast (car (last forms))))

                 ((mal-data-value= mal-if (first forms))
                  (let ((predicate (mal-eval (second forms) env)))
                    (setf ast (if (or (mal-data-value= predicate mal-nil)
                                      (mal-data-value= predicate mal-false))
                                  (fourth forms)
                                  (third forms)))))

                 ((mal-data-value= mal-fn* (first forms))
                  (return (let ((arglist (second forms))
                                (body (third forms)))
                            (make-mal-fn (lambda (&rest args)
                                           (mal-eval body (env:create-mal-env :parent env
                                                                              :binds (listify (mal-data-value arglist))
                                                                              :exprs args)))
                                         :attrs (list (cons :params arglist)
                                                      (cons :ast body)
                                                      (cons :env env)
                                                      (cons :is-macro nil))))))

                 (t (let* ((evaluated-list (eval-ast ast env))
                           (function (car evaluated-list)))
                      ;; If first element is a mal function unwrap it
                      (cond ((mal-fn-p function)
                             (let* ((attrs (mal-data-attrs function)))
                               (setf ast (cdr (assoc :ast attrs))
                                     env (env:create-mal-env :parent (cdr (assoc :env attrs))
                                                             :binds (map 'list
                                                                         #'identity
                                                                         (mal-data-value (cdr (assoc :params attrs))))
                                                             :exprs (cdr evaluated-list)))))
                            ((mal-builtin-fn-p function)
                             (return (apply (mal-data-value function)
                                            (cdr evaluated-list))))
                            (t (error 'invalid-function
                                      :form function
                                      :context "apply")))))))))))

(defun mal-print (expression)
  (printer:pr-str expression))

(defun rep (string)
  (handler-case
      (mal-print (mal-eval (mal-read string) *repl-env*))
    (mal-error (condition)
      (format nil "~a" condition))
    (error (condition)
      (format nil "Internal error: ~a" condition))))

(env:set-env *repl-env*
             (make-mal-symbol "eval")
             (make-mal-builtin-fn (lambda (ast)
                                    (mal-eval ast *repl-env*))))

(rep "(def! not (fn* (a) (if a false true)))")
(rep "(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\\nnil)\")))))")
(rep "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))")

(defvar *use-readline-p* nil)

(defun complete-toplevel-symbols (input &rest ignored)
  (declare (ignorable ignored))

  (let (candidates)
    (loop for key being the hash-keys of (env:mal-env-bindings *repl-env*)
       when (let ((pos (search input key))) (and pos (zerop pos)))
       do (push key candidates))

    (if (= 1 (length candidates))
        (cons (car candidates) candidates)
        (cons (apply #'utils:common-prefix candidates) candidates))))

(defun raw-input (prompt)
  (format *standard-output* prompt)
  (force-output *standard-output*)
  (read-line *standard-input* nil))

(defun mal-readline (prompt)
  (if *use-readline-p*
      (rl:readline :prompt prompt :add-history t :novelty-check #'string/=)
      (raw-input prompt)))

(defun mal-writeline (string)
  (when string
    (write-line string)
    (force-output *standard-output*)))

(defun repl ()
  (loop do (let ((line (mal-readline "user> ")))
             (if line
                 (mal-writeline (rep line))
                 (return)))))

(defun run-file (file)
  (rep (format nil "(load-file \"~a\")" file)))

(defun main (&optional (argv nil argv-provided-p))

  (setf *use-readline-p* (not (or (string= (utils:getenv "PERL_RL") "false")
                                  (string= (utils:getenv "TERM") "dumb"))))

  ;; In GNU CLISP's batch mode the standard-input seems to be set to some sort
  ;; of input string-stream, this interacts wierdly with the PERL_RL enviroment
  ;; variable which the test runner sets causing `read-line' on *standard-input*
  ;; to fail with an empty stream error. The following reinitializes the
  ;; standard streams
  ;;
  ;; See http://www.gnu.org/software/clisp/impnotes/streams-interactive.html
  #+clisp (setf *standard-input* (ext:make-stream :input)
                *standard-output* (ext:make-stream :output :buffered t)
                *error-output* (ext:make-stream :error :buffered t))

  ;; CCL fails with a error while registering completion function
  ;; See also https://github.com/mrkkrp/cl-readline/issues/5
  #-ccl (rl:register-function :complete #'complete-toplevel-symbols)

  (let ((args (if argv-provided-p
                  argv
                  (cdr (utils:raw-command-line-arguments)))))
    (env:set-env *repl-env*
                 (make-mal-symbol "*ARGV*")
                 (make-mal-list (mapcar #'make-mal-string (cdr args))))
    (if (null args)
        (repl)
        (run-file (car args)))))

;;; Workaround for CMUCL's printing of "Reloaded library ... " messages when an
;;; image containing foreign libraries is restored. The extra messages cause the
;;; MAL testcases to fail

#+cmucl (progn
          (defvar *old-standard-output* *standard-output*
            "Keep track of current value standard output, this is restored after image restore completes")

          (defun muffle-output ()
            (setf *standard-output* (make-broadcast-stream)))

          (defun restore-output ()
            (setf *standard-output* *old-standard-output*))

          (pushnew #'muffle-output ext:*after-save-initializations*)
          (setf ext:*after-save-initializations*
                (append ext:*after-save-initializations* (list #'restore-output))))
