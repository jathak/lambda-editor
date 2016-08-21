## Lambda Editor

> Note: This project is still a work-in-progress

Lambda Editor is an [Ace][]-based text editor written in [61A Scheme][], running
as a Chrome Packaged App.

  [Ace]: https://ace.c9.io
  [61A Scheme]: http://su16.cs61a.org/proj/scheme/scheme-spec.html

At the moment, it can read and save multiple local files in tabs which persist
between uses of the app. You can also input Scheme code to hack at pieces of the
editor. Configuration is done through various Scheme files, which can be opened
from the settings menu.

While the editor can open and edit individual files using the Chrome filesystem
APIs, most features are based around running a server that allows the editor to
run commands through a Bash shell. The server requires Dart to be installed
on something Unix-like where you can host it (I use an Ubuntu chroot on my
Chromebook). You'll need to edit the `ALLOWED_HOSTS` and `ALLOWED_ORIGINS`
properties in `server.dart` to match your configuration. If you're connecting 
to the server from some address other than `localhost`, you'll also want to
update the `server-url` pref the local configuration file under Settings >
Local Settings. You should then run `server.dart`, optionally with an alternate
port as an argument. The server must remain running for the entire time the
editor is active for features that require it to work (the editor does not
currently attempt to reconnect).

### Building and Installing

You'll want to run `make scheme` to get the latest Scheme interpreter and
libraries from [scheme.cs61a.org](http://scheme.cs61a.org).

You should then be able to load it into Chrome as an unpacked extension.
