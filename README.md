# get_it_mixin

This package offers a set of mixin types that makes the binding of data that is stored within `
GetIt` really easy.

>When I write of binding, I mean a mechanism that will automatically rebuild a widget that if data it depends on changes 

Several users asked for support of data binding for GetIt like `provider` offers. At the same time I have to admit I got really intrigued by `flutter_hooks` from [Remi Rousselet](https://github.com/rrousselGit/), so I started to think about how to create something similar for `GetIt`. ** I'm very thankful for Remi's work. I took more than one inspiration from his code**

As I want to keep `GetIt` free of Flutter dependencies I choose to write a separate package with mixins to achive this goal.

To be clear you can achieve the same using different Flutter Builders but it will make your Flutter code less readable and you will have more to type.

## Getting started
>For this readme I expect that you know how to work with [GetIt](https://pub.dev/packages/get_it)

Lets create some model class that we want to access with the mixins:

```Dart
class Model extends ChangeNotifier {
  String _country;
  set country(String val) {
    _country = val;
    notifyListeners();
  }
  String get country => _country;

  String _emailAdress;
  set country(String val) {
    _emailAdress = val;
    notifyListeners();
  }
  String get country => _emailAdress;

  final ValueNotifier<String> name;
  final Model nestedModel;

  Stream<String> userNameUpdates; 
  Future get initializationReady;
}
```

No we will explore how to access the different properties by using the `get_it_mixin`

### Reading Data

When you add the `GetItMixin` to your `StatelessWidget` you get a lot of new functions that you can use inside the Widget the easiest one is `get()` and `getX()` which will access data from `GetIt` as if you would to `GetIt.I<Type>()`

```Dart

class TestStateLessWidget extends StatelessWidget with GetItMixin {

  @override
  Widget build(BuildContext context) {
    final name = get<Model>().name;
    return Column(
          children: [
            Text(name),
            Text(getX<Model>((x)=> x.country, instanceName:'secondModell')),
          ],
        ),
    );
  }
}
```

As you can see `get()` is used exactly like using `GetIt` directly with all its parameters. `getX()` does the same but offers a selector function that has to return the final value from the referenced object. Most of the time you probably will only use `get()`, but the selector function can be used to do any data processing that might me needed before you can use the value.

** get() and getX() can be called multiple times inside a Widget and also outside the `build()` function.**

### Watching Data
The following functions will return a value and rebuild the widget every-time this data inside GetIt changes. ** Important: This function can only be called inside the `build()` function and you can only watch any objects only once.



class TestStateLessWidget extends StatelessWidget with GetItMixin {

  @override
  Widget build(BuildContext context) {
    final onlyRead = get<Model>().constantValue;
    final notifierVal = watch<ValueNotifier<String>, String>();
    final country = watchOnly((Model x) => x.country);
    final name = watchX((Model x) => x.name);
    final nestedCountry =
        watchXOnly((Model x) => x.nestedModel, (Model n) => n.country);
    final streamResult = watchStream((Model x) => x.stream, 'streamResult');
    final futureResult = watchFuture((Model x) => x.future, 'futureResult');
    registerStreamHandler((Model x) => x.stream, (x, cancel) {
      streamHandlerResult = x;
      if (x == 'Cancel') {
        cancel();
      }
    });
    registerValueListenableHandler((Model x) => x.name, (x, cancel) {
      listenableHandlerResult = x;
      if (x == 'Cancel') {
        cancel();
      }
    });
    return Column(
          children: [
            Text(onlyRead, key: Key('onlyRead')),
            Text(notifierVal, key: Key('notifierVal')),
            Text(country, key: Key('country')),
            Text(name, key: Key('name')),
            Text(nestedCountry, key: Key('nestedCountry')),
            Text(streamResult.data, key: Key('streamResult')),
            Text(futureResult.data, key: Key('futureResult')),
          ],
        ),
    );
  }
}