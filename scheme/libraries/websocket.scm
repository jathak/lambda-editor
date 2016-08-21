(define (handle-wrapper-websocket type data)
  (cond ((eq? type "websocket-message")
         (on-socket-message (js-ref data 'msg)))
        ((eq? type "websocket-close") (on-socket-close))
        ((eq? type "websocket-error") (on-socket-error))))


(define _active-socket-calls (js-object))
(define _socket-msg-id 0)

(define (on-socket-message msg)
  (define type (js-ref msg "type"))
  (define msg-id (js-ref msg "msg-id"))
  (define data (js-ref _active-socket-calls msg-id))
  (cond ((eq? type "response")
         (define resolve (car data))
         (if (procedure? resolve) (resolve (js-ref msg "result"))))
        ((eq? type "stdout")
         (define on-stdout (car (cdr data)))
         (if (procedure? on-stdout) (on-stdout (js-ref msg "line"))))
        ((eq? type "stderr")
         (define on-stderr (car (cdr (cdr data))))
         (if (procedure? on-stderr) (on-stderr (js-ref msg "line"))))
        ((eq? type "process-exit")
         (define on-exit (car (cdr (cdr (cdr data)))))
         (if (procedure? on-exit) (on-exit (js-ref msg "exit-code"))))))


(define (on-socket-close)
  (display "websocket closed\n"))
(define (on-socket-error)
  (display "websocket errored\n"))

(define (socket-send msg . extras)
  (set! _socket-msg-id (+ _socket-msg-id 1))
  (if (eq? (wrapper-command "websocket-send" msg) "success")
      undefined
      (error "could not send message"))
  (js-ref msg "msg-id"))

(define (socket-send-for-response msg . extras)
  (js-object "Promise"
    (lambda (resolve reject)
      (js-set! msg "msg-id" (string-append _socket-msg-id))
      (set! _socket-msg-id (+ _socket-msg-id 1))
      (js-set! _active-socket-calls (js-ref msg "msg-id") (cons resolve extras))
      (if (not (eq? (wrapper-command "websocket-send" msg) "success"))
          (reject "could not send message")))))


(define (init-socket url)
  (define result (wrapper-command "websocket-init" url))
  (if (eq? result "success")
      (display "websocket open at " url "\n")
      (display "error connecting to " url "\n")))

(define (make-command-msg command opt)
  (define msg (js-object))
  (js-set! msg "command" command)
  (if (= 1 (length opt))
      (js-set! msg "directory" (car opt)))
  msg)

(define (shell-run command-str . opt)
  (define msg (make-command-msg command-str opt))
  (js-set! msg "type" "run")
  (define result (socket-send-for-response msg))
  (cons (js-ref result "stdout") (js-ref result "stderr")))

(define (clean-shell-run . args)
  (js-call-on-string (car (apply shell-run args)) "trim"))

(define (split-shell-lines run-result)
  (split (js-call-on-string (car run-result) "trim") "\n"))

(define (socket-write-file path contents)
  (define msg
    (js-object
      (cons "type" "write-file")
      (cons "path" path)
      (cons "contents" contents)))
  (socket-send-for-response msg))

(define (shell-start command-str on-stdout on-stderr on-exit . opt)
  (define msg (make-command-msg command-str opt))
  (js-set! msg "type" "start")
  (socket-send-for-response msg on-stdout on-stderr on-exit))

(define (shell-input pid . input)
  (define msg
    (js-object
      (cons "type" "input")
      (cons "pid" pid)
      (cons "input" (apply string-append input))))
  (socket-send-for-response msg))
