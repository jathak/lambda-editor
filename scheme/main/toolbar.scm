(define _menus nil)

(define (find-menu-item . path)
  (define (helper path menus)
    (if (null? path)
        menus
        (if (eq? (car path) (menu-name (car menus)))
            (helper (cdr path) (car menus))
            (helper path (menu-children menus)))))
  (helper path _menus))


(define (redraw-toolbar)
  (define wrapper (query-selector ".toolbar"))
  (js-set! wrapper "innerText" "")
  (define (construct-toolbar menus root parent)
    (if (null? menus) nil
        (begin
          (construct-menu (car menus) root parent)
          (construct-toolbar (cdr menus) root parent))))
  (define (construct-menu menu root parent)
    (if (null? (menu-name menu))
        (add-child parent (make-element "hr"))
        (begin
          (define item-el (make-element "div" (if root "menu-root" "menu-item")))
          (js-set! item-el "innerText" (menu-name menu))
          (if (not root)
            (begin
              (define subtitle (make-element "span" "menu-subtitle"))
              (js-set! subtitle "innerText" (menu-subtitle menu))
              (add-child item-el subtitle)))
          (if (menu-leaf? menu)
              (on-event item-el "click" (lambda args (redraw-toolbar) ((menu-procedure menu))))
              (begin
                (define child-wrapper (make-element "div" "menu-children"))
                (add-child item-el child-wrapper)
                (construct-toolbar (menu-children menu) #f child-wrapper)))
          (add-child parent item-el))))
  (construct-toolbar _menus #t wrapper))


; menu adt
; children should either be a procedure, command, or list of menus
(define (make-menu name children) (cons name children))
(define (menu-name menu) (car menu))
(define (menu-children menu) (cdr menu))
(define (menu-leaf? menu) (not (list? (menu-children menu))))
(define (menu-procedure menu)
  (let ((action (menu-children menu)))
       (cond ((procedure? action) action)
             ((string-or-symbol? action) (lambda () (exec-command action)))
             (else (error "menu is not a command")))))
(define (menu-subtitle menu)
  (if (string-or-symbol? (menu-children menu))
      (begin
        (define binding (get-command-binding (menu-children menu)))
        (if (string-or-symbol? binding)
            (car (split (get-command-binding (menu-children menu)) "|"))
            ""))
      (if (list? (menu-children menu)) "▶" "")))

(define (clear-menu) (set! _menus nil))

(define (add-menu-item item . path)
  (define (rebuild-menus menus path)
    (cond
      ((null? path) item)
      ((null? menus)
       (list (make-menu (car path) (rebuild-menus nil (cdr path)))))
      ((and (eq? (car path) (menu-name (car menus))) (not (null? (car path))))
       (let ((menu (car menus))
             (name (car path)))
            (cons (make-menu name (rebuild-menus (menu-children menu) (cdr path)))
                  (cdr menus))))
      (else (cons (car menus) (rebuild-menus (cdr menus) path)))))
  (set! _menus (rebuild-menus _menus path))
  (if config-complete (redraw-toolbar)))
