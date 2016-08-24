(define ace (js "ace"))

(define editor nil)

(define (ace-require module)
  (js-call ace 'require module))

(define (load-ace element-id)
  (set! editor (js-call ace 'edit element-id)))

(define (set-editor-option key value)
  (js-call editor "setOption" key value))

(define (selection)
  (js-ref editor "selection"))

(define (set-ace-theme! name)
  (js-call editor "setTheme" (string-append "ace/theme/" name)))

(define (get-ace-session)
  (js-call editor "getSession"))

(define (get-session-text session)
  (js-call session "getValue"))

(define (set-ace-session! session)
  (js-call editor "setSession" session))

(define (set-ace-mode! session mode)
  (js-call session "setMode" (string-append "ace/mode/" mode)))

(define (get-font-size) (js-call editor "getFontSize"))
(define (set-font-size! size) (js-call editor "setFontSize" size))
(define (add-to-font-size! amount)
  (set-font-size! (+ amount (get-font-size))))

(define (make-command name exec . args)
  (define read-only (if (null? args) #t (car args)))
  (js-object
    (cons 'name name)
    (cons 'exec (lambda args (exec (car args))))
    (cons "readOnly" read-only)))

(define (register-command . args)
  (js-call (js-ref editor 'commands)
           "addCommand"
           (apply make-command args)))

(define (exec-command command)
  (js-call editor "execCommand" command))

(define (init-ace-module name)
  (define module
    (js-object "Promise"
      (lambda (resolve reject)
        (js-call (js-ref ace 'config)
                 "loadModule"
                 name
                 resolve))))
  (js-call module 'init editor)
  module)
