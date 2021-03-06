(set-ace-theme! "monokai")

(define (color-theme light dark medium-light medium-dark highlight)
  (add-css-prop ".toolbar, .sidebar, .tabs, .statusbar" 'background dark)
  (add-css-prop ".toolbar, .sidebar, .tab-active, .statusbar" 'color light)
  (add-css-prop ".menu-root:hover, .menu-item, .menu-children" 'background light)
  (add-css-prop ".menu-root:hover, .menu-item" 'color dark)
  (add-css-prop ".menu-item:hover" 'background medium-light)
  (add-css-prop ".menu-subtitle" 'color medium-dark)
  (add-css-prop ".tabs" 'color medium-light)
  (add-css-prop ".tab-active" 'background medium-dark)
  (add-css-prop ".tab-indicator" 'background highlight)
  (add-css-prop ".tab-indicator:hover" 'background "#8af")
  (add-css-prop ".tab-close:hover" 'background light)
  (add-css-prop ".tab-close:hover" 'color dark)
  (add-css-prop ".tab-active" 'border-bottom-color highlight))

(color-theme "#eee" "#222" "#bbb" "#444" "#57f")
