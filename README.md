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

To Do List:

- Add folders to sidebar
- Get undo and redo working (Ace should have them built-in)
- Sublime-style go to anything search
- More full-featured status bar
- More options for default themes

### Building and Installing

You'll want to run `make scheme` to get the latest Scheme interpreter and
libraries from [scheme.cs61a.org](http://scheme.cs61a.org).

You should then be able to load it into Chrome as an unpacked extension.
