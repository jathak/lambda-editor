(define _tab-list nil)

(define tab-bar (query-selector ".tabs"))
(define active-tab nil)

(define (make-tab file)
  (define tab (find-tab file))
  (if (null? tab)
      (begin
        (define element (make-element "div" "tab"))
        (define tab (list file element #f))
        (set! _tab-list (cons tab _tab-list))
        (define name (last (split (file-path file) "/")))
        (js-set! element "innerText" name)
        (on-event element "click"
          (lambda (event)
            (if (not (tab-active? tab))
                (activate-tab tab))))
        (define close (make-element "div" "tab-close"))
        (js-set! close "innerText" "×")
        (on-event close "click"
          (lambda (event)
            (close-tab tab)))
        (add-child element close)
        (define indicator (make-element "div" "tab-indicator"))
        (js-set! indicator "innerText" " ")
        (on-event indicator "click"
          (lambda (event)
            (if (prompt-close tab) (close-tab tab))))
        (add-child element indicator)
        (define original-text (get-session-text (file-session file)))
        (on-file-change file
          (lambda (delta session)
            (if (eq? original-text (get-session-text session))
                (begin
                  (set-css-prop! indicator 'display 'none)
                  (set-css-prop! close 'display 'block))
                (begin
                  (set-css-prop! indicator 'display 'block)
                  (set-css-prop! close 'display 'none)))))
        (set-file-saved-listener! file
          (lambda ()
            (set! original-text (get-session-text (file-session file)))
            (set-css-prop! indicator 'display 'none)
            (set-css-prop! close 'display 'block)))
        (add-child tab-bar element)))
  tab)

(define (prompt-close tab)
  (print "should prompt here")
  #t)

(define (tab-file tab) (car tab))
(define (tab-element tab) (car (cdr tab)))
(define (tab-active? tab) (car (cdr (cdr tab))))
(define (tab-index tab)
  (define (helper lst count)
    (if (null? lst)
        0
        (if (eq? (car lst) tab)
            count
            (helper (cdr lst) (+ count 1)))))
  (helper _tab-list 0))
(define (activate-tab tab)
  (deactivate-all-tabs)
  (set-car! (cdr (cdr tab)) #t)
  (set! active-tab tab)
  (js-set! (tab-element tab) "className" "tab tab-active")
  (set-ace-session! (file-session (tab-file tab)))
  (define file-metas
    (map (lambda (tab) (file-metadata (tab-file tab))) _tab-list))
  (wrapper-command "set-local-property" "fileMetas" file-metas)
  (wrapper-command "set-local-property" "currentTab" (tab-index tab))
  undefined)
(define (deactivate-tab tab)
  (set-car! (cdr (cdr tab)) #f)
  (js-set! (tab-element tab) "className" "tab")
  undefined)

(define (close-tab tab)
  (define (new-tab-list lst)
    (if (null? lst)
        nil
        (if (eq? (car lst) tab)
            (new-tab-list (cdr lst))
            (cons (car lst) (new-tab-list (cdr lst))))))
  (set! _tab-list (new-tab-list _tab-list))
  (js-call tab-bar "removeChild" (tab-element tab))
  (if (null? _tab-list)
      (new-tab)
      (activate-tab (car _tab-list))))



(define (deactivate-all-tabs)
  (define (helper lst)
    (if (not (null? lst))
        (begin
          (deactivate-tab (car lst))
          (helper (cdr lst)))))
  (helper _tab-list))

(define (find-tab file)
  (define (helper lst)
    (if (null? lst)
        nil
        (if (eq? (tab-file (car lst)) file)
            (car lst)
            (helper (cdr lst)))))
  (helper _tab-list))

(define (open-file file)
  (activate-tab (make-tab file)))

(define (new-tab)
  nil)
