(define config-complete #f)
(library 'utils)

(parallel
  (library 'ace)
  (library 'html)
  (library 'strings))

(load-ace "editor")
(js-set! window 'editor editor)

;(background (init-ace-module "ace/ext/keybinding_menu"))

(define statusbar (query-selector ".statusbar"))
(define (update-status status)
  (js-set! statusbar "innerText" (string-append status)))

(js-set! (js "scheme")
         "onOutput"
         (lambda (output error?) (if error? (update-status (string-append "Error: " output)))))

(import 'preference-manager)
(import 'toolbar)
(import 'file-manager)
(import 'tabs)
(import 'command-line)

; loads all config files in separate isolated envs
(parallel-procs
  (lambda () (load-config 'commands (current-environment)))
  (lambda () (load-config 'bindings (current-environment)))
  (lambda () (load-config 'menus (current-environment)))
  (lambda () (load-config 'theme (current-environment)))
  (lambda () (load-config 'preferences (current-environment))))
(define config-complete #t)

(define (reload-tabs)
  (define file-metas (wrapper-command "get-local-property" "fileMetas" nil))
  (define current-tab (wrapper-command "get-local-property" "currentTab" 0))
  (define files (map reconstruct-file file-metas))
  (define to-activate nil)
  (define (helper lst count)
    (if (not (null? lst))
      (begin
        (helper (cdr lst) (+ count 1))
        (define tab (make-tab (car lst)))
        (if (= count current-tab) (set! to-activate tab)))))
  (helper files 0)
  (if (not (null? to-activate)) (activate-tab to-activate)))

(define (edit-config name)
  (activate-tab (make-tab (make-config-file name))))

(parallel-procs
  redraw-toolbar
  refresh-editor-prefs)

(reload-tabs)


(js-set! (query-selector ".loading") "className" "loading hidden")
(js-set! window "onfocus" (lambda args (js-call editor 'focus)))
