part of 'mixin.dart';

mixin _GetItElement on ComponentElement {
  /*late*/ _MixinState _state;

  @override
  void mount(Element parent, newSlot) {
    _state.init(this);
    super.mount(parent, newSlot);
  }

  @override
  Widget build() {
    //print('build');
    _state.resetCurrentWatch();
    return super.build();
  }

  @override
  void update(Widget newWidget) {
//    print('update');
    _state.clearRegistratons();
    super.update(newWidget);
  }

  @override
  void unmount() {
    _state.dispose();
    super.unmount();
  }
}

class _StatelessMixInElement<W extends GetItMixin> extends StatelessElement
    with _GetItElement {
  _StatelessMixInElement(
    W widget,
  ) : super(widget) {
    _state = _MixinState();
    widget._state.value = _state;
  }
  @override
  W get widget => super.widget;

  @override
  void update(W newWidget) {
    //print('update stateless element');
    newWidget._state.value = _state;
    super.update(newWidget);
  }
}

class _StatefulMixInElement<W extends GetItStatefulWidgetMixin>
    extends StatefulElement with _GetItElement {
  _StatefulMixInElement(
    W widget,
  ) : super(widget) {
    _state = _MixinState();
    widget._state.value = _state;
  }
  @override
  W get widget => super.widget;

  @override
  void update(W newWidget) {
    //print('update statefull element');
    newWidget._state.value = _state;
    super.update(newWidget);
  }
}
