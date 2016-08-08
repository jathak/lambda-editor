.PHONY: scheme

GET_SCM=wget http://scheme.cs61a.org

scheme:
	${GET_SCM}/bootstrap.dart.js -O scheme/scheme.dart.js
	${GET_SCM}/scm/lib/html.scm -O scheme/libraries/html.scm
	${GET_SCM}/scm/lib/strings.scm -O scheme/libraries/strings.scm
