(define (add-css-prop selector key value)
  (define style (make-element 'style))
  (define css (string-append selector " { " key " : " value " } "))
  (js-set! style "innerHTML" css)
  (add-child (js "document.head") style))

(define (attempt-proc proc on-error)
  (define js-runner
    (js "(proc)=>proc().then((r)=>[true, r], (e)=>[false, e])"))
  (define result-pair (js-runner proc))
  (define status (car result-pair))
  (define result (car (cdr result-pair)))
  (if status result (on-error result)))

(define-macro (try-catch expr fallback)
  `(attempt-proc (lambda () ,expr) (lambda _____args ,fallback)))

(define (string-or-symbol? val)
  (or (string? val) (symbol? val)))

(define (map proc lst)
  (if (null? lst)
      nil
      (cons (proc (car lst))
            (map proc (cdr lst)))))

(define (filter pred lst)
  (if (null? lst)
      nil
      (if (pred (car lst))
          (cons (car lst) (filter pred (cdr lst)))
          (filter pred (cdr lst)))))

(define (background-proc procedure)
 ((js "(fn)=>{fn()}") procedure))

(define-macro (background . exprs)
 (list 'background-proc (cons 'lambda (cons nil exprs))))

(define (parallel-procs . procedures)
 (define remaining (length procedures))
 (define resolver nil)
 (define (complete)
   (set! remaining (- remaining 1))
   (if (zero? remaining) (resolver)))
 (define (run fns)
   (if (null? fns) nil
       (begin
         (define fn (car fns))
         (background (fn) (complete))
         (run (cdr fns)))))
 (js-object "Promise"
   (lambda (resolve reject)
     (set! resolver resolve)
     (run procedures))))

(define-macro (parallel . exprs)
 (define (fnize expr) (list 'lambda nil expr))
 (cons 'parallel-procs (map fnize exprs)))

(define (last lst)
 (if (null? (cdr lst))
     (car lst)
     (last (cdr lst))))
