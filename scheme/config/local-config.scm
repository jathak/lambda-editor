; other config files are synced to your Google account
; this config will not be synced (useful for device-specific settings)
; all config files (including this one) are evaluated in the same environment
; synced config files are evaluated in parallel, but this local config file
; will always be evaluated after all of the synced config files finish


; change this if your server is hosted at a different url or port
(set-pref! "server-url" "ws://localhost:6320")
