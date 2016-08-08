(register-command
  "lambda:zoom-out"
  (lambda (editor)
    (add-to-font-size! -1)))

(register-command
  "lambda:zoom-in"
  (lambda (editor)
    (add-to-font-size! 1)))

(register-command
  "lambda:zoom-default"
  (lambda (editor)
    (set-font-size! (get-pref "fontSize"))))

(register-command
  "sublime:goto"
  (lambda (editor)
    (print "sublime-style goto")))

(register-command
  "sublime:ctrl-d"
  (lambda (editor)
    (if (js-call (selection) "isEmpty")
        (js-call (selection) "selectWord")
        (exec-command editor "selectMoreAfter"))))
