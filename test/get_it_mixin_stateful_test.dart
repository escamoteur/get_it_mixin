// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_local_variable
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_mixin/get_it_mixin.dart';

class Model extends ChangeNotifier {
  String? constantValue;
  String? _country;
  set country(String? val) {
    _country = val;
    notifyListeners();
  }

  String? get country => _country;
  final ValueNotifier<String> name;
  final Model? nestedModel;
  // ignore: close_sinks
  final StreamController<String> streamController = StreamController<String>.broadcast();

  Model({this.constantValue, String? country, required this.name, this.nestedModel}) : _country = country;

  Stream<String> get stream => streamController.stream;
  final Completer<String> completer = Completer<String>();
  Future<String> get future => completer.future;
}

class TestStateFullWidget extends StatefulWidget with GetItStatefulWidgetMixin {
  final bool watchTwice;
  final bool watchOnlyTwice;
  final bool watchXtwice;
  final bool watchXonlytwice;
  final bool watchStreamTwice;
  final bool watchFutureTwice;
  final bool testIsReady;
  final bool testAllReady;

  TestStateFullWidget(
      {Key? key,
      this.watchTwice = false,
      this.watchOnlyTwice = false,
      this.watchXtwice = false,
      this.watchXonlytwice = false,
      this.watchStreamTwice = false,
      this.watchFutureTwice = false,
      this.testIsReady = false,
      this.testAllReady = false})
      : super(key: key);

  @override
  _TestStateFullWidgetState createState() => _TestStateFullWidgetState();
}

class _TestStateFullWidgetState extends State<TestStateFullWidget> with GetItStateMixin {
  @override
  Widget build(BuildContext context) {
    buildCount++;
    final onlyRead = get<Model>().constantValue!;
    final notifierVal = watch<ValueNotifier<String>, String>();
    final country = watchOnly((Model x) => x.country!);
    final name = watchX((Model x) => x.name);
    final nestedCountry = watchXOnly((Model x) => x.nestedModel!, (Model n) => n.country!);
    final streamResult = watchStream((Model x) => x.stream, 'streamResult');
    final futureResult = watchFuture((Model x) => x.future, 'futureResult');
    registerStreamHandler<Model, String>((x) => x.stream, (contex, s, cancel) {
      streamHandlerResult = s.data;
      if (streamHandlerResult == 'Cancel') {
        cancel();
      }
    });
    registerHandler((Model x) => x.name, (contex, String x, cancel) {
      listenableHandlerResult = x;
      if (x == 'Cancel') {
        cancel();
      }
    });
    bool? allReadyResult;
    if (widget.testAllReady) {
      allReadyResult = allReady(onReady: (context) => allReadyHandlerResult = 'Ready');
    }
    bool? isReadyResult;

    if (widget.testIsReady) {
      isReadyResult = isReady<Model>(instanceName: 'isReadyTest', onReady: (context) => isReadyHandlerResult = 'Ready');
    }
    if (widget.watchTwice) {
      final notifierVal = watch<ValueNotifier<String>, String>();
    }
    if (widget.watchOnlyTwice) {
      final country = watchOnly((Model x) => x.country);
    }
    if (widget.watchXtwice) {
      final name = watchX((Model x) => x.name);
    }
    if (widget.watchXonlytwice) {
      final nestedCountry = watchXOnly((Model x) => x.nestedModel!, (Model? n) => n!.country);
    }
    if (widget.watchStreamTwice) {
      final streamResult = watchStream((Model x) => x.stream, 'streamResult');
    }
    if (widget.watchFutureTwice) {
      final futureResult = watchFuture((Model x) => x.future, 'futureResult');
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text(onlyRead, key: const Key('onlyRead')),
          Text(notifierVal, key: const Key('notifierVal')),
          Text(country, key: const Key('country')),
          Text(name, key: const Key('name')),
          Text(nestedCountry, key: const Key('nestedCountry')),
          Text(streamResult.data!, key: const Key('streamResult')),
          Text(futureResult.data!, key: const Key('futureResult')),
          Text(allReadyResult.toString(), key: const Key('allReadyResult')),
          Text(isReadyResult.toString(), key: const Key('isReadyResult')),
        ],
      ),
    );
  }
}

late Model theModel;
late ValueNotifier<String> valNotifier;
int buildCount = 0;
String? streamHandlerResult;
String? listenableHandlerResult;
String? allReadyHandlerResult;
String? isReadyHandlerResult;

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
        nestedModel: Model(
          country: 'nestedCountry',
          name: ValueNotifier<String>(''),
        ));
    GetIt.I.registerSingleton<Model>(theModel);
    GetIt.I.registerSingleton(valNotifier);
  });

  testWidgets('onetime access without any data changes', (tester) async {
    await tester.pumpWidget(TestStateFullWidget());
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal = tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry = tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult = tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult = tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

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
    await tester.pumpWidget(TestStateFullWidget(
      watchTwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });

  testWidgets('wathXtwice', (tester) async {
    await tester.pumpWidget(TestStateFullWidget(
      watchXtwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });

// Unfortunately we can't check if two selectors point to the same
  // testWidgets('watchOnlyTwice', (tester) async {
  //   await tester.pumpWidget(TestStateFullWidget(
  //     watchOnlyTwice: true,
  //   ));
  //   await tester.pump();

  //   expect(tester.takeException(), isA<ArgumentError>());
  // });

  // testWidgets('watchXOnlyTwice', (tester) async {
  //   await tester.pumpWidget(TestStateFullWidget(
  //     watchXonlytwice: true,
  //   ));
  //   await tester.pump();

  //   expect(tester.takeException(), isA<ArgumentError>());
  // });

  testWidgets('watchStream twice', (tester) async {
    await tester.pumpWidget(TestStateFullWidget(
      watchStreamTwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });
  testWidgets('watchFuture twice', (tester) async {
    await tester.pumpWidget(TestStateFullWidget(
      watchFutureTwice: true,
    ));
    await tester.pump();

    expect(tester.takeException(), isA<ArgumentError>());
  });

  testWidgets('update of non watched field', (tester) async {
    await tester.pumpWidget(TestStateFullWidget());
    theModel.constantValue = '42';
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal = tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry = tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult = tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult = tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

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
    await tester.pumpWidget(TestStateFullWidget());
    valNotifier.value = '42';
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal = tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry = tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult = tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult = tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

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
    await tester.pumpWidget(TestStateFullWidget());
    theModel.name.value = '42';
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal = tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry = tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult = tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult = tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

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
    await tester.pumpWidget(TestStateFullWidget());
    theModel.nestedModel!.country = '42';
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal = tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry = tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult = tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult = tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    expect(onlyRead, 'onlyRead');
    expect(notifierVal, 'notifierVal');
    expect(country, 'country');
    expect(name, 'name');
    expect(nestedCountry, '42');
    expect(streamResult, 'streamResult');
    expect(futureResult, 'futureResult');
    expect(buildCount, 2);
  });
  testWidgets('test watchOnly with notification but no value change', (tester) async {
    await tester.pumpWidget(TestStateFullWidget());
    theModel.notifyListeners();
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal = tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry = tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult = tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult = tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

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
    await tester.pumpWidget(TestStateFullWidget());
    theModel.streamController.sink.add('42');
    await tester.pump();
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal = tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry = tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult = tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult = tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

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
    await tester.pumpWidget(TestStateFullWidget());
    theModel.completer.complete('42');
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal = tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry = tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult = tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult = tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

    final error = tester.takeException();
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
    await tester.pumpWidget(TestStateFullWidget());
    theModel.name.value = '42';
    theModel._country = 'Lummerland';
    await tester.pump();

    final onlyRead = tester.widget<Text>(find.byKey(const Key('onlyRead'))).data;
    final notifierVal = tester.widget<Text>(find.byKey(const Key('notifierVal'))).data;
    final country = tester.widget<Text>(find.byKey(const Key('country'))).data;
    final name = tester.widget<Text>(find.byKey(const Key('name'))).data;
    final nestedCountry = tester.widget<Text>(find.byKey(const Key('nestedCountry'))).data;
    final streamResult = tester.widget<Text>(find.byKey(const Key('streamResult'))).data;
    final futureResult = tester.widget<Text>(find.byKey(const Key('futureResult'))).data;

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
    await tester.pumpWidget(TestStateFullWidget());

    expect(theModel.hasListeners, true);
    expect(theModel.name.hasListeners, true);
    expect(theModel.streamController.hasListener, true);
    expect(valNotifier.hasListeners, true);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(theModel.hasListeners, false);
    expect(theModel.name.hasListeners, false);
    expect(theModel.streamController.hasListener, false);
    expect(valNotifier.hasListeners, false);

    expect(buildCount, 1);
  });
  testWidgets('test handlers', (tester) async {
    await tester.pumpWidget(TestStateFullWidget());

    theModel.name.value = '42';
    theModel.streamController.sink.add('4711');
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));

    expect(streamHandlerResult, '4711');
    expect(listenableHandlerResult, '42');

    theModel.name.value = 'Cancel';
    theModel.streamController.sink.add('Cancel');
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));

    theModel.name.value = '42';
    theModel.streamController.sink.add('4711');
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));

    expect(streamHandlerResult, 'Cancel');
    expect(listenableHandlerResult, 'Cancel');
    expect(buildCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(theModel.hasListeners, false);
    expect(theModel.name.hasListeners, false);
    expect(theModel.streamController.hasListener, false);
    expect(valNotifier.hasListeners, false);
  });
  testWidgets('allReady no async object', (tester) async {
    await tester.pumpWidget(TestStateFullWidget(
      testAllReady: true,
    ));
    await tester.pump(const Duration(milliseconds: 10));

    final allReadyResult = tester.widget<Text>(find.byKey(const Key('allReadyResult'))).data;
    expect(allReadyResult, 'true');
    expect(allReadyHandlerResult, 'Ready');

    expect(buildCount, 2);
  });
  testWidgets('allReady async object that is finished', (tester) async {
    GetIt.I.registerSingletonAsync(
        () => Future.delayed(
            const Duration(milliseconds: 10),
            () => Model(
                  name: ValueNotifier('AsyncObject'),
                )),
        instanceName: 'asyncObject1');
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(TestStateFullWidget(
      testAllReady: true,
    ));
    await tester.pump();

    final allReadyResult = tester.widget<Text>(find.byKey(const Key('allReadyResult'))).data;

    expect(allReadyResult, 'true');
    expect(allReadyHandlerResult, 'Ready');

    expect(buildCount, 2);
  });
  testWidgets('allReady async object that is not finished at the start', (tester) async {
    GetIt.I.registerSingletonAsync(
        () => Future.delayed(
            const Duration(milliseconds: 10),
            () => Model(
                  name: ValueNotifier('AsyncObject'),
                )),
        instanceName: 'asyncObject2');
    await tester.pumpWidget(TestStateFullWidget(
      testAllReady: true,
    ));
    await tester.pump();

    var allReadyResult = tester.widget<Text>(find.byKey(const Key('allReadyResult'))).data;

    expect(allReadyResult, 'false');
    expect(allReadyHandlerResult, null);

    await tester.pump(const Duration(milliseconds: 120));
    allReadyResult = tester.widget<Text>(find.byKey(const Key('allReadyResult'))).data;

    expect(allReadyResult, 'true');
    expect(allReadyHandlerResult, 'Ready');
    expect(buildCount, 2);
  });
  testWidgets('isReady async object that is finished', (tester) async {
    GetIt.I.registerSingletonAsync<Model>(
        () => Future.delayed(
            const Duration(milliseconds: 10),
            () => Model(
                  name: ValueNotifier('AsyncObject'),
                )),
        instanceName: 'isReadyTest');
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(TestStateFullWidget(
      testIsReady: true,
    ));
    await tester.pump();

    final isReadyResult = tester.widget<Text>(find.byKey(const Key('isReadyResult'))).data;

    expect(isReadyResult, 'true');
    expect(isReadyHandlerResult, 'Ready');

    expect(buildCount, 2);
  });
  testWidgets('isReady async object that is not finished at the start', (tester) async {
    GetIt.I.registerSingletonAsync(
        () => Future.delayed(
            const Duration(milliseconds: 10),
            () => Model(
                  name: ValueNotifier('AsyncObject'),
                )),
        instanceName: 'isReadyTest');
    await tester.pumpWidget(TestStateFullWidget(
      testIsReady: true,
    ));
    await tester.pump();
    await tester.pump();

    var isReadyResult = tester.widget<Text>(find.byKey(const Key('isReadyResult'))).data;

    expect(isReadyResult, 'false');
    expect(isReadyHandlerResult, null);

    await tester.pump(const Duration(milliseconds: 120));
    isReadyResult = tester.widget<Text>(find.byKey(const Key('isReadyResult'))).data;

    expect(isReadyResult, 'true');
    expect(isReadyHandlerResult, 'Ready');
    expect(buildCount, 2);
  });
}
