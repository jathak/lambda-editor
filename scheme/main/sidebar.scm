(define (make-folder-entry path)
  (list "folder"
        path
        (make-entry-element path #t)))

(define (make-file-entry path)
  (list "file"
        path
        (make-entry-element path #f)))

(define (entry-type entry) (car entry))
(define (entry-path entry) (car (cdr entry)))
(define (entry-element entry) (car (cdr (cdr entry))))
(define (folder-children folder) (find-children (entry-path folder)))
(define (folder? entry) (eq? (entry-type entry) "folder"))

(define (find-children path)
  (define folder-paths (split-shell-lines (shell-run "ls -d $PWD/*/" path)))
  (define folders (map make-folder-entry folder-paths))
  (define file-paths (split-shell-lines (shell-run "for f in *; do [[ -d \"$f\" ]] || echo \"$f\"; done" path)))
  (define file-paths (map (lambda (x) (string-append path "/" x)) file-paths))
  (define file-entries (map make-file-entry file-paths))
  (append folders file-entries))

(define (make-entry-element path is-folder)
  (define name (last (split path "/")))
  (define element (make-element "div" "sidebar-entry"
                    (if is-folder "sidebar-folder" "sidebar-file")))
  (define label (make-element "span" "entry-label"))
  (js-set! label "innerText" name)
  (add-child element label)
  (if is-folder
    (begin
      (define children-wrapper (make-element "div" "folder-children"))
      (add-child element children-wrapper)
      (define visible #f)
      (on-event element "click"
        (lambda (event)
          (set! visible (not visible))
          (js-set! children-wrapper "innerHTML" "")
          (if visible
            (begin
              (define children (find-children path))
              (map (lambda (c)
                    (add-entry-to-element c children-wrapper))
                   children))))))
    (begin
      (on-event element "click"
        (lambda (event)
          (open-file (make-socket-file path))))))
  element)




(define (add-entry-to-sidebar entry)
  (add-entry-to-element entry (query-selector ".sidebar")))

(define (add-entry-to-element entry parent)
  (define element (entry-element entry))
  (define old-parent (js-ref element "parentElement"))
  (if (js-object? old-parent)
      (js-call old-parent "removeChild" element))
  (add-child parent element))

(register-command
  "lambda:open-folder"
  (lambda (editor) (add-entry-to-sidebar (user-select-folder))))
