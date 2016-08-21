(define (paren-diff text)
  (define count 0)
  (define (stringify count)
    (if (= count 0)
        ""
        (string-append ")" (stringify (- count 1)))))
  (define (helper chars)
    (if (not (null? chars))
        (begin
          (define char (car chars))
          (if (eq? char "(")
              (set! count (+ count 1))
              (if (eq? char ")")
                  (set! count (- count 1))))
          (helper (cdr chars)))))
  (helper (js-call (js "scheme") "tokenizeLine" text))
  (stringify count))

(define (eval-line line env)
  (define js-eval-line
    (js "(line, env, onError)=>{"
        "  var tokens = scheme.tokenizeLine(line);"
        "  function jsEvalTokens(){"
        "    var expr = scheme.read(tokens);"
        "    return scheme.eval(expr, env).then("
        "       (result)=>{if (tokens.length === 0){return result;} else {return jsEvalTokens()}},"
        "       (error)=>onError(scheme.jsify(error)))"
        "  };"
        "  return jsEvalTokens();"
        "}"))
  (define (on-error msg)
    (update-status (last (split msg "\n"))))
  (js-eval-line line env on-error))

; all commands will be run in this environment directly
; extending the global environment
(define command-environment nil)

(define (reset-command-environment)
  (set! command-environment
    (eval '(let () (current-environment)) config-environment)))

(reset-command-environment)

(define (open-command-line)
  (define el (make-element "textarea" "command-line"))
  (js-set! el "placeholder" "Enter Scheme code here")
  (define (run-line line)
    (background
      (define result (eval-line line command-environment))
      (if (eq? result undefined)
          (update-status "")
          (update-status (string-append "Result: " result))))
    (wait 50)
    (js-call (query-selector 'body) "removeChild" el)
    (js-call editor "focus"))
  (on-event el "keypress"
    (lambda (event)
      (define code (js-ref event "keyCode"))
      (if (= code 13)
          (begin
            (define shift (js-ref event "shiftKey"))
            (define text (js-ref el "value"))
            (define diff (paren-diff text))
            (if (or shift (eq? diff ""))
                (run-line (string-append text diff)))))))
  (add-child (query-selector 'body) el)
  (js-call el "focus"))

(register-command
  "lambda:command-line"
  (lambda (editor)
    (open-command-line)))
