(define _preferences nil)

(define (get-pref name)
  (define key (string-append name))
  (define (helper prefs)
    (if (null? prefs)
      nil
      (if (eq? (car (car prefs)) key)
          (cdr (car prefs))
          (helper (cdr prefs)))))
  (helper _preferences))

(define (set-pref! name value)
  (define key (string-append name))
  (set! _preferences (cons (cons key value) _preferences)))

(define (get-lang-pref language name)
  (define result (get-pref (string-append language ":" name)))
  (if (null? result)
      (get-pref name)
      result))


(define (set-lang-pref! language name value)
  (set-pref! (string-append language ":" name) value))

(define editor-options
  '("selectionStyle" "highlightActiveLine" "highlightSelectedWord" "cursorStyle"
    "behaviorsEnabled" "hScrollBarAlwaysVisible" "vScrollbarAlwaysVisible"
    "highlightGutterLine" "animatedScroll" "showInvisibles" "showPrintMargin"
    "printMarginColumn" "printMargin" "fadeFoldWidgets" "showFoldWidgets"
    "showLineNumbers" "showGutter" "displayIndentGuides" "fontSize" "fontFamily"
    "scrollPastEnd"))

(define session-options
  '("firstLineNumber" "indentedSoftWrap" "newLineMode" "overwrite" "tabSize"
    "useSoftTabs" "useWorker" "wrap" "wrapMethod"))

(define (refresh-editor-prefs)
  (js-call editor "setOptions" (apply js-object _preferences)))
  ;(define prefs (js-object))
  ;(define (helper options)
  ;  (js-set! prefs (car options) (get-pref (car options)))
  ;  (if (not (null? (cdr options)))
  ;      (helper (cdr options))))
  ;(helper editor-options)
  ;(js-call editor "setOptions" prefs))

(define (refresh-session-prefs session)
  (define prefs (js-object))
  (define lang (car (cdr (cdr (split (js-call session "getOption" "mode") "/")))))
  (define (helper options)
    (js-set! prefs (car options) (get-lang-pref lang (car options)))
    (if (not (null? (cdr options)))
        (helper (cdr options))))
  (helper session-options)
  (js-call session "setOptions" prefs))

(define (load-default-prefs)
  (set! _preferences nil)
  ; add default preferences here
  ; editor/renderer options
  (set-pref! "selectionStyle" "line")
  (set-pref! "highlightActiveLine" #t)
  (set-pref! "highlightSelectedWord" #t)
  (set-pref! "cursorStyle" "ace")
  (set-pref! "behaviorsEnabled" #t)
  (set-pref! "hScrollBarAlwaysVisible" #f)
  (set-pref! "vScrollbarAlwaysVisible" #f)
  (set-pref! "highlightGutterLine" #t)
  (set-pref! "animatedScroll" #f)
  (set-pref! "showInvisibles" #f)
  (set-pref! "showPrintMargin" #t)
  (set-pref! "printMarginColumn" 80)
  (set-pref! "printMargin" 80)
  (set-pref! "fadeFoldWidgets" #f)
  (set-pref! "showFoldWidgets" #t)
  (set-pref! "showLineNumbers" #t)
  (set-pref! "showGutter" #t)
  (set-pref! "displayIndentGuides" #t)
  (set-pref! "fontSize" 12)
  (set-pref! "scrollPastEnd" #t)

  ; session options
  (set-pref! "firstLineNumber" 1)
  (set-pref! "indentedSoftWrap" #t)
  (set-pref! "newLineMode" "unix")
  (set-pref! "overwrite" #f)
  (set-pref! "tabSize" 4)
  (set-lang-pref! "scheme" "tabSize" 2)
  (set-lang-pref! "dart" "tabSize" 2)
  (set-pref! "useSoftTabs" #t)
  (set-pref! "useWorker" #t)
  (set-pref! "wrap" "off")
  (set-pref! "wrapMethod" "auto"))

(load-default-prefs)
