; with piped shortcuts, second is for Mac, first is for everything else
; register-binding takes in a command name (either built-in to Ace or
; defined with register-command) followed by one or more shortcuts

(register-binding "showKeyboardShortcuts" "Ctrl-Alt-h|Command-Alt-h")

; currently using bindings from the editor I use most often (Caret)
; may want to switch these to be Sublime or Atom style
(register-binding "addCursorAbove" "Ctrl-Up")
(register-binding "addCursorBelow" "Ctrl-Down")
(register-binding "gotostart" "Ctrl-Home")
(register-binding "gotoend" "Ctrl-End")
(register-binding "gotopagedown" "PageDown" "Alt-PageDown")
(register-binding "gotopageup" "PageUp" "Alt-PageUp")
(register-binding "gotolinestart" "Home" "Alt-Home")
(register-binding "gotolineend" "End" "Alt-End")
(register-binding "startAutocomplete" "Ctrl-Space") ; not sure how to get this to work
(register-binding "expandtoline" "Ctrl-L")
(register-binding "sublime:ctrl-d" "Ctrl-D")
(register-binding "sublime:goto" "Ctrl-P")
(register-binding "jumptomatching" "Ctrl-M")
(register-binding "lambda:zoom-in" "Ctrl-=")
(register-binding "lambda:zoom-out" "Ctrl--")
(register-binding "lambda:zoom-default" "Ctrl-0")
(register-binding "joinlines" "Ctrl-J")
(register-binding "movelinesup" "Ctrl-Shift-Up")
(register-binding "movelinesdown" "Ctrl-Shift-Down")

(register-binding "lambda:command-line" "Ctrl-.")
(register-binding "lambda:open-file" "Ctrl-O")
(register-binding "lambda:open-folder" "Ctrl-Shift-O")
(register-binding "lambda:save-file" "Ctrl-S")
(register-binding "lambda:save-file-as" "Ctrl-Shift-S")
(register-binding "lambda:save-all-files" "Ctrl-Alt-S")
(register-binding "lambda:close-file" "Ctrl-W")
(register-binding "lambda:shell-log" "Ctrl-Shift-P")
(register-binding "lambda:shell-log-input" "Ctrl-I")
(register-binding "lambda:next-tab" "Ctrl-Tab")
(register-binding "lambda:prev-tab" "Ctrl-Shift-Tab")
