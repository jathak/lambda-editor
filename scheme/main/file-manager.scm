(define (make-file path fn-read fn-save . info)
  (define file
    (list (cons path info)
        fn-read
        fn-save
        (js-object "ace.EditSession" (fn-read) (find-mode path))
        (lambda () nil)))
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
  (js-call (file-session file) "setValue" (fn-read)))
(define (file-session file) (car (cdr (cdr (cdr file)))))
(define (file-apply-delta file delta)
  (js-call (js-call (file-session file) "getDocument")
           "applyDelta"
           delta))
(define (on-file-change file listener)
  (js-call (file-session file) "on" "change" listener))
(define (save-file file)
  ((file-saver file) (file-session file))
  ((file-saved-listener file)))

(define (reconstruct-file metadata)
  (define path (car metadata))
  (define type (car (cdr metadata)))
  (define rest-info (cdr (cdr metadata)))
  (cond
    ((eq? type "chromefs") (make-chromefs-file path (car rest-info)))
    ((eq? type "config") (make-config-file (car rest-info)))))

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
      (if (js-object? result) (error "could not save file") result))
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
            (background (load-config name)))))
    "config"
    name))

(define (user-select-file)
  (apply make-chromefs-file (wrapper-command "user-open-file")))

;(define (user-select-folder)
;  (apply make-chrome-fs-file (wrapper-command "user-open-directory")))

(register-command
  "lambda:open-file"
  (lambda (editor) (open-file (user-select-file))))

(register-command
  "lambda:save-file"
  (lambda (editor) (save-file (tab-file active-tab))))
