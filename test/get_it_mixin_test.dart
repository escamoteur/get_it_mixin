import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_mixin/get_it_mixin.dart';

class Model extends ChangeNotifier {
  final String constantValue;
  final String country;
  final ValueNotifier<String> name;
  final Model nestedModel;
  final StreamController<String> streamController = StreamController<String>();

  Model({this.constantValue, this.country, this.name, this.nestedModel});
  Stream<String> get stream => streamController.stream;
  final Completer<String> completer = Completer<String>();
  Future get future => completer.future;
}

class TestStateLessWidget extends StatelessWidget with GetItMixin {
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
    final futureResult1 = watchFuture((Model x) => x.future, 'futureResult');

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

void main() {
  setUp(() async {
    buildCount = 0;
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
}
