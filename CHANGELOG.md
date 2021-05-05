## [3.1.0] - 05.05.2021

* Added new function to rebuild a widget as soon as a GetIt-Scope changed
### Trigger a rebuild on GetIt Scope changes
As it is possible that objects registered in a higher GetIt-Scope can shadow objects of the same registration type in a lower scope it is important to ensure that the UI can update its references to the newly active object (the one last registered).
The get_it_mixin detects such changes and updates them on the next rebuild but if you want to ensure that this happens immediately you can put a call to 

```dart
  /// Will triger a rebuild of the Widget if any new GetIt-Scope is pushed or popped
  /// This function will return `true` if the change was a push otherwise `false`
  /// If no change has happend the return value will be null
  bool? rebuildOnScopeChanges();
```
## [3.0.0] - 03.05.2021

* Major version bump because get_it V7.0.0 is a breaking change

## [2.0.2] - 25.04.2021

* Switched internal structure from LinkedList to List because of  https://github.com/dart-lang/sdk/issues/45767 which made the package unusable on web

## [2.0.1] - 22.03.2021

* Added option to watch any ValueListenable with `watch(target:)`

## [2.0.0] - 04.03.2021

* Null safety migration

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
