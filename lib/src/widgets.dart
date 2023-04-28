part of 'mixin.dart';

abstract class GetItWidget extends StatelessWidget {
  const GetItWidget({Key? key}) : super(key: key);

  @override
  _StatelessGetItElement createElement() => _StatelessGetItElement(this);
}

class _StatelessGetItElement extends StatelessElement with _GetItElement {
  _StatelessGetItElement(GetItWidget widget) : super(widget) {
    _state = _MixinState();
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
