(define (get-url url)
  (js-object "Promise"
    (lambda (resolve reject)
      (define client (js-object "XMLHttpRequest"))
      (js-call client 'open "GET" url)
      (js-set! client 'onload
        (lambda args
          (if (and (>= (js-ref client 'status) 200)
                   (<  (js-ref client 'status) 300))
            (resolve (js-ref client 'response))
            (reject (js-ref client "statusText")))))
      (js-set! client 'onerror
        (lambda args (reject (js-ref client "statusText"))))
      (js-call client 'send))))

(define (post-request url . params)
  (define (params-to-uri params first)
    (if (null? params) ""
        (begin
          (define start (if first "?" "&"))
          (define encode (js "encodeURIComponent"))
          (define key (encode (car (car params))))
          (define value (encode (cdr (car params))))
          (string-append start key '= value
            (params-to-uri (cdr params) #f)))))
  (js-object "Promise"
    (lambda (resolve reject)
      (define client (js-object "XMLHttpRequest"))
      (js-call client 'open "POST" (string-append url (params-to-uri params #t)))
      (js-set! client 'onload
        (lambda args
          (if (and (>= (js-ref client 'status) 200)
                   (<  (js-ref client 'status) 300))
            (resolve (js-ref client 'response))
            (reject (js-ref client "statusText")))))
      (js-set! client 'onerror
        (lambda args (reject (js-ref client "statusText"))))
      (js-call client 'send))))

(define (query-selector . args)
  (cond ((null? args) (error "not enough arguments to query-selector"))
        ((= (length args) 2) (js-call (car args) "querySelector" (car (cdr args))))
        ((= (length args) 1) (js-call (js "document") "querySelector" (car args)))
        (else (error "too many arguments to query-selector"))))

(define (query-selector-all . args)
  (js-call (js "[].slice") 'call
    (cond ((null? args) (error "not enough arguments to query-selector-all"))
          ((= (length args) 2) (js-call (car args) "querySelectorAll" (car (cdr args))))
          ((= (length args) 1) (js-call (js "document") "querySelectorAll" (car args)))
          (else (error "too many arguments to query-selector-all")))))

(define (make-element type . classes)
  (define elem (js-call (js "document") "createElement" type))
  (js-set! elem "classList" classes)
  elem)

(define (_on-all-elem elem proc)
  (cond ((null? elem) undefined)
        ((pair? elem)
          (_on-all-elem (car elem) proc)
          (_on-all-elem (cdr elem) proc))
        ((or (string? elem) (symbol? elem))
          (_on-all-elem (query-selector-all elem) proc))
        (else (proc elem))))

(define (set-css-prop! elem key value)
  (_on-all-elem elem (lambda (item) (js-set! (js-ref item 'style) key value))))

(define (on-event elem event callback)
  (define (add-event-listener elem)
    (js-call elem "addEventListener" event callback))
  (_on-all-elem elem add-event-listener))

(define (add-child parent child)
  (js-call parent "appendChild" child))
