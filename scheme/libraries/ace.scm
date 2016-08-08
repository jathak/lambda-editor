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

(define (register-binding command binding . rest)
  (js-call (js-ref editor 'commands) "bindKey" binding command)
  (js-set! _command-keys command binding)
  (if (not (null? rest))
      (apply register-binding (cons command rest))))

(define _command-keys (js-object))

(define (get-command-binding command)
  (define commands (js-ref (js-ref editor 'commands) 'commands))
  (if (js-has-property? _command-keys command)
      (js-ref _command-keys command)
      (if (js-has-property? commands command)
        (let ((cmd-obj (js-ref commands command)))
             (if (js-has-property? cmd-obj "bindKey")
                 (js-ref (js-ref cmd-obj "bindKey") (js "editor.commands.platform"))
                 ""))
        "")))

(define (clear-binding . args)
  (apply register-binding (cons undefined args)))

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
