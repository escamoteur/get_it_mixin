## [1.5.1] - 17.10.2020

* fixed bug that you couldn't use `watchOnly` and `watchXonly` more than once on the same `Listenable` object.
* split source into several part files.

## [1.5.0] - 16.10.2020

* Refactoring and corrected cancelation of futures

## [1.4.0] - 14.10.2020

* Bug fix for Hot reload and added a warning in the readme

## [1.2.0] - 07.10.2020

* the previous implementation of `allReady()` would have called `GetIt.allReady` on every build which would return every time a new Future so that it did rebuild unpredictable 

## [1.1.0] - 07.10.2020

* deprecated `registerValueListenableHandler` in favour of `registerHandler`

## [1.0.0] - 06.10.2020

* some breaking changes of the handler function definitions
* added support for `allReady` and isReady

## [0.9.0] - 02.10.2020

* now with readme and tests 

## [0.1.0] - 26.09.2020

* Initial release without docs and tests
