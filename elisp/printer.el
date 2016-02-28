(defun pr-str (form &optional print-readably)
  (let ((type (mal-type form))
        (value (mal-value form)))
    (cond
     ((eq type 'nil)
      "nil")
     ((eq type 'true)
      "true")
     ((eq type 'false)
      "false")
     ((eq type 'number)
      (number-to-string (mal-value form)))
     ((eq type 'string)
      (if print-readably
          ;; HACK prin1-to-string does only quotes and backslashes
          (replace-regexp-in-string "\n" "\\\\n" (prin1-to-string value))
        value))
     ((or (eq type 'symbol) (eq type 'keyword))
      (symbol-name value))
     ((eq type 'list)
      (pr-list value print-readably))
     ((eq type 'vector)
      (pr-vector value print-readably))
     ((eq type 'map)
      (pr-map value print-readably)))))

(defun pr-list (form print-readably)
  (let ((items (mapconcat
                (lambda (item) (pr-str item print-readably))
                form " ")))
    (concat "(" items ")")))

(defun pr-vector (form print-readably)
  (let ((items (mapconcat
                (lambda (item) (pr-str item print-readably))
                (append form nil) " ")))
    (concat "[" items "]")))

(defun pr-map (form print-readably)
  (let (pairs)
    (maphash
     (lambda (key value)
       (push (cons (pr-str key print-readably)
                   (pr-str value print-readably))
             pairs))
     form)
    (let ((items (mapconcat
                  (lambda (item) (concat (car item) " " (cdr item)))
                  (nreverse pairs) ", ")))
      (concat "{" items "}"))))
