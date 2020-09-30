import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_mixin/get_it_mixin.dart';

class Model extends ChangeNotifier {
  String constantValue;
  String _country;
  set country(String val) {
    _country = val;
    notifyListeners();
  }

  String get country => _country;
  final ValueNotifier<String> name;
  final Model nestedModel;
  final StreamController<String> streamController =
      StreamController<String>.broadcast();

  Model({this.constantValue, String country, this.name, this.nestedModel})
      : _country = country;

  Stream<String> get stream => streamController.stream;
  final Completer<String> completer = Completer<String>();
  Future get future => completer.future;
}

class TestStateLessWidget extends StatelessWidget with GetItMixin {
  final bool watchTwice;
  final bool watchOnlyTwice;
  final bool watchXtwice;
  final bool watchXonlytwice;
  final bool watchStreamTwice;
  final bool watchFutureTwice;

  TestStateLessWidget(
      {Key key,
      this.watchTwice = false,
      this.watchOnlyTwice = false,
      this.watchXtwice = false,
      this.watchXonlytwice = false,
      this.watchStreamTwice = false,
      this.watchFutureTwice = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    buildCount++;
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
    if (watchTwice) {
      final notifierVal = watch<ValueNotifier<String>, String>();
    }
    if (watchOnlyTwice) {
      final country = watchOnly((Model x) => x.country);
    }
    if (watchXtwice) {
      final name = watchX((Model x) => x.name);
    }
    if (watchXonlytwice) {
      final nestedCountry =
          watchXOnly((Model x) => x.nestedModel, (Model n) => n.country);
    }
    if (watchStreamTwice) {
      final streamResult = watchStream((Model x) => x.stream, 'streamResult');
    }
    if (watchFutureTwice) {
      final futureResult = watchFuture((Model x) => x.future, 'futureResult');
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        child: Column(
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
      ),
    );
  }
}

Model theModel;
ValueNotifier<String> valNotifier;
int buildCount;
String streamHandlerResult;
String listenableHandlerResult;

void main() {
  setUp(() async {
    buildCount = 0;
    streamHandlerResult = null;
    listenableHandlerResult = null;
    await GetIt.I.reset();
    valNotifier = ValueNotifier<String>('notifierVal');
    theModel = Model(
        constantValue: 'onlyRead',
        country: 'country',
        name: ValueNotifier('name'),
        nestedModel: Model(country: 'nestedCountry'));
    GetIt.I.registerSingleton<Model>(theModel);
    GetIt.I.registerSingleton(valNotifier);
  });

  testWidgets('onetime access without any data changes', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 1);
  });

  testWidgets('wathTwice', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchTwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });

  testWidgets('wathXtwice', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchXtwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });

  testWidgets('watchOnlyTwice', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchOnlyTwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });

  testWidgets('watchXOnlyTwice', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchXonlytwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });

  testWidgets('watchStream twice', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchStreamTwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });
  testWidgets('watchFuture twice', (tester) async {
    await tester.pumpWidget(TestStateLessWidget(
      watchFutureTwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });

  testWidgets('update of non watched field', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.constantValue = '42';
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 1);
  });

  testWidgets('test watch', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    valNotifier.value = '42';
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, '42');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('test watchX', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.name.value = '42';
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, '42');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });

  testWidgets('test watchXonly', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.nestedModel.country = '42';
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, '42');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('test watchOnly with notification but no value change',
      (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.notifyListeners();
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 1);
  });
  testWidgets('watchStream', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.streamController.sink.add('42');
    await tester.pump();
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, '42');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('watchFuture', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.completer.complete('42');
    await tester.runAsync(() => Future.delayed(Duration(milliseconds: 100)));
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(Key('futureResult'))).data;

    final error = tester.takeException();
    print(error);
    print('before expect');
    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, '42');
    expect(buildCount, 2);
  });
  testWidgets('change multiple data', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());
    theModel.name.value = '42';
    theModel._country = 'Lummerland';
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(Key('onlyRead'))).data;
    final notifierVal =
        tester.widget<Text>(find.byKey(Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(Key('name'))).data;
    final nestedCountry =
        tester.widget<Text>(find.byKey(Key('nestedCountry'))).data;
    final streamResult =
        tester.widget<Text>(find.byKey(Key('streamResult'))).data;
    final futureResult =
        tester.widget<Text>(find.byKey(Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'Lummerland');
    expect(name, '42');
    expect(nestedCountry, 'nestedCountry');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('check that everything is released', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());

    expect(theModel.hasListeners, true);
    expect(theModel.name.hasListeners, true);
    expect(theModel.streamController.hasListener, true);
    expect(valNotifier.hasListeners, true);

    await tester.pumpWidget(SizedBox.shrink());

    expect(theModel.hasListeners, false);
    expect(theModel.name.hasListeners, false);
    expect(theModel.streamController.hasListener, false);
    expect(valNotifier.hasListeners, false);

    expect(buildCount, 1);
  });
  testWidgets('test handlers', (tester) async {
    await tester.pumpWidget(TestStateLessWidget());

    theModel.name.value = '42';
    theModel.streamController.sink.add('4711');
    await tester.runAsync(() => Future.delayed(Duration(milliseconds: 100)));

    expect(streamHandlerResult, '4711');
    expect(listenableHandlerResult, '42');

    theModel.name.value = 'Cancel';
    theModel.streamController.sink.add('Cancel');
    await tester.runAsync(() => Future.delayed(Duration(milliseconds: 100)));

    theModel.name.value = '42';
    theModel.streamController.sink.add('4711');
    await tester.runAsync(() => Future.delayed(Duration(milliseconds: 100)));

    expect(streamHandlerResult, 'Cancel');
    expect(listenableHandlerResult, 'Cancel');
    expect(buildCount, 1);

    await tester.pumpWidget(SizedBox.shrink());

    expect(theModel.hasListeners, false);
    expect(theModel.name.hasListeners, false);
    expect(theModel.streamController.hasListener, false);
    expect(valNotifier.hasListeners, false);
  });
}
