(define (make-file path fn-read fn-save . info)
  (define file
    (list (cons path info)
        fn-read
        fn-save
        (js-object "ace.EditSession" "" (find-mode path))
        (lambda () nil)))
  (file-update file)
  (refresh-session-prefs (file-session file))
  file)
(define (file-path file) (car (car file)))
(define (file-metadata file) (car file))
(define (file-reader file) (car (cdr file)))
(define (file-saver file) (car (cdr (cdr file))))
(define (file-saved-listener file) (car (cdr (cdr (cdr (cdr file))))))
(define (set-file-saved-listener! file listener)
  (set-car! (cdr (cdr (cdr (cdr file)))) listener))

(define (file-update file)
  (define text (try-catch ((file-reader file)) ""))
  (define session (file-session file))
  (js-call session "setValue" text))

(define (file-session file) (car (cdr (cdr (cdr file)))))
(define (file-apply-delta file delta)
  (js-call (js-call (file-session file) "getDocument")
           "applyDelta"
           delta))
(define (on-file-change file listener)
  (js-call (file-session file) "on" "change" listener))
(define (save-file file)
  ((file-saver file) (file-session file))
  (define listener (file-saved-listener file))
  (if (procedure? listener) (listener)))

(define (reconstruct-file metadata)
  (define path (car metadata))
  (define type (car (cdr metadata)))
  (define rest-info (cdr (cdr metadata)))
  (cond
    ((eq? type "chromefs") (make-chromefs-file path (car rest-info)))
    ((eq? type "config") (make-config-file (car rest-info)))
    ((eq? type "socket") (make-socket-file path))
    ((eq? type "log") (make-log-file path (car (car rest-info)) (car (cdr (car rest-info)))))))

(define (find-mode path)
  (cond
    ((js-call-on-string path "endsWith" ".scm") "ace/mode/scheme")
    ((js-call-on-string path "endsWith" ".logic") "ace/mode/scheme")
    ((js-call-on-string path "endsWith" ".py") "ace/mode/python")
    ((js-call-on-string path "endsWith" ".sql") "ace/mode/sql")
    ((js-call-on-string path "endsWith" ".md") "ace/mode/markdown")
    ((js-call-on-string path "endsWith" ".mdown") "ace/mode/markdown")
    ((js-call-on-string path "endsWith" ".dart") "ace/mode/dart")
    ((js-call-on-string path "endsWith" ".js") "ace/mode/javascript")
    ((js-call-on-string path "endsWith" ".css") "ace/mode/css")
    ((js-call-on-string path "endsWith" ".html") "ace/mode/html")
    (else "ace/mode/text")))

(define (make-chromefs-file path entry)
  (make-file
    path
    (lambda ()
      (define result (wrapper-command "read-file" entry))
      (if (js-object? result) (error "could not read file") result))
    (lambda (session)
      (define result (wrapper-command "save-file" entry (get-session-text session)))
      (if (js-object? result) (error "could not save file")))
    "chromefs"
    entry))

(define (make-config-file name)
  (make-file
    (string-append "config/" name ".scm")
    (lambda () (wrapper-command "get-config" name))
    (lambda (session)
      (if (js-call-on-string name "startsWith" "default-")
          (begin
            (update-status "Default config files can't be updated")
            (js-call session "setValue" (wrapper-command "get-config" name)))
          (begin
            (wrapper-command "set-config" name (get-session-text session))
            (background (load-config name config-environment)))))
    "config"
    name))

(define (make-socket-file path)
  (make-file
    path
    (lambda ()
      (define result (shell-run (string-append "cat " path)))
      (if (pair? result)
          (car result)
          (error "could not read file")))
    (lambda (session)
      (socket-write-file path (get-session-text session)))
    "socket"))

(define (make-log-file name contents . opt)
  (define pid (if (null? opt) nil (car opt)))
  (define container (list contents pid))
  (define log
    (make-file
      name
      (lambda () (car container))
      (lambda (session) (file-update log))
      "log"
      container))
  log)

(define (set-log-pid! log pid)
  (define container (car (cdr (cdr (file-metadata log)))))
  (set-car! (cdr container) pid))

(define (send-log-process-input log line)
  (define pid (car (cdr (car (cdr (cdr (file-metadata log)))))))
  (if (not (null? pid))
      (begin
        (append-to-log log line "\n")
        (shell-input pid line "\n"))))

(define (append-to-log log . msgs)
  (define container (car (cdr (cdr (file-metadata log)))))
  (set-car! container (string-append (car container) (apply string-append msgs)))
  (save-file log)
  (save-tabs-state))

(define (shell-log command . opt)
  (define directory (if (null? opt) shell-pwd (car opt)))
  (define log
    (make-log-file
      (car (split command " "))
      (string-append shell-user "@" shell-hostname ":"
                     directory "$ " command "\n")))
  (js-object "Promise"
    (lambda (resolve reject)
      (define (on-output line)
        (append-to-log log line "\n"))
      (define (on-exit code)
        (resolve code))
      (define pid (shell-start command on-output on-output on-exit directory))
      (set-log-pid! log pid)
      (open-file log))))

(register-command
  "lambda:shell-log"
  (lambda (editor)
    (define file (tab-file active-tab))
    (define path (file-path file))
    (define type (car (cdr (file-metadata file))))
    (define dir
      (substring
        path
        0
        (- (string-length path) 1
           (string-length (last (split path "/"))))))
    (if (or (eq? dir "") (not (eq? type "socket"))) (define dir shell-pwd))
    (shell-log (prompt "Enter Bash command to run from " dir) dir)))

(register-command
  "lambda:shell-log-input"
  (lambda (editor)
    (define log (tab-file active-tab))
    (if (eq? (car (cdr (file-metadata log))) "log")
        (send-log-process-input log (prompt "Input to current process")))))


(define (user-select-file)
  (make-socket-file (prompt "Enter file path here")))

(define (user-select-chrome-file)
  (apply make-chromefs-file (wrapper-command "user-open-file")))

(register-command
  "lambda:open-chrome-file"
  (lambda (editor) (open-file (user-select-chrome-file))))

(register-command
  "lambda:open-file"
  (lambda (editor) (open-file (user-select-file))))

(register-command
  "lambda:save-file"
  (lambda (editor) (save-file (tab-file active-tab))))
