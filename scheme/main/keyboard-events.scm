(define get-key-modifier-hash
  ; adapted from ace source
  (js "(e)=>0 | (e.ctrlKey ? 1 : 0) | (e.altKey ? 2 : 0) | "
      "(e.shiftKey ? 4 : 0) | (e.metaKey ? 8 : 0)"))

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

(js-call
  (js "document.body")
  "addEventListener"
  "keydown"
  (lambda (event)
    (define hash (get-key-modifier-hash event))
    (if (> hash 0)
        (js-call
          (js "editor.keyBinding")
          "onCommandKey"
          event
          hash
          (js-ref event "keyCode"))))
  #t)
