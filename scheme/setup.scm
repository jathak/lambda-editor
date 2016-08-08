(display "Scheme loaded. Setting up...\n")

(define _current-call-id 0)
(define _active-calls (js-object))
(define scheme (js 'scheme))
(define window (js 'window))
(js-set! window "activeCalls" _active-calls)
(define wrapper-message (js "wrapperMessage"))

(js-call window "addEventListener" "message"
  (lambda (event)
    (define data (js-ref event 'data))
    (define type (js-ref data 'type))
    (cond
      ((eq? type "command-response")
       (define call (js-ref _active-calls (js-ref data 'id)))
       (call (js-ref data 'response))
       (js-set! _active-calls (js-ref data 'id) nil)))))

(define (wrapper-command command . args)
 (define msg
   (js-object
    (cons 'type 'command)
    (cons 'command command)
    (cons 'args args)
    (cons 'id _current-call-id)))
 (set! _current-call-id (+ _current-call-id 1))
 (js-object "Promise"
  (lambda (resolve reject)
   (js-set! _active-calls (js-ref msg 'id) resolve)
   (wrapper-message msg))))

(define global-environment (current-environment))

(define (library name . args)
 (define url (string-append "scheme/libraries/" name ".scm"))
 (js-call scheme "runCode" (wrapper-command "fetch" url)))

(define (import name)
 (define url (string-append "scheme/main/" name ".scm"))
 (js-call scheme "runCode" (wrapper-command "fetch" url)))

(define (get-config name)
 (wrapper-command "get-config" name))

(define (set-config! name contents)
 (wrapper-command "set-config" name contents))

(define (load-config name . args)
 (define env (if (null? args) global-environment (car args)))
 (js-call scheme "runCode" (get-config name) env))

(define scheme-build-info build-info)
(unbind 'build-info)

(display "Setup complete. Starting main.scm...\n")
(import 'main)
