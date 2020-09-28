import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

class _MutableWrapper<T> {
  T value;
}

mixin GetItMixin on StatelessWidget {
  /// this is an ugly hack so that you don't get a warning in the StatelessWidget
  final _MutableWrapper<_MixinState> _state = _MutableWrapper<_MixinState>();
  @override
  StatelessElement createElement() => _StatelessMixInElement(this);

  /// all the following functions can be called inside the build function but also
  /// in e.g. in `initState` of a `StatefulWidget`.
  /// The mixin takes care that everything is correctly disposed.

  /// retrieves or creates an instance of a registered type [T] depending on the registration
  /// function used for this type or based on a name.
  /// for factories you can pass up to 2 parameters [param1,param2] they have to match the types
  /// given at registration with [registerFactoryParam()]
  T get<T>({String instanceName, dynamic param1, dynamic param2}) =>
      GetIt.I<T>(instanceName: instanceName, param1: param1, param2: param2);

  /// like [get] but for async registrations
  Future<T> getAsync<T>(
          {String instanceName, dynamic param1, dynamic param2}) =>
      GetIt.I.getAsync<T>(
          instanceName: instanceName, param1: param1, param2: param2);

  /// like [get] but with an additional [select] function to return a member of [T]
  R getX<T, R>(R Function(T) accessor, {String instanceName}) {
    assert(accessor != null);
    return accessor(GetIt.I<T>(instanceName: instanceName));
  }

  /// To observe `ValueListenables`
  /// like [get] but it also registers a listener to [T] and
  /// triggers a rebuild every time [T].value changes
  R watch<T extends ValueListenable<R>, R>({String instanceName}) =>
      _state.value.watch<T>(instanceName: instanceName).value;

  /// like watch but it only triggers a rebuild when the value of
  /// the `ValueListenable`, that the function [select] returns changes
  /// useful if the `ValueListenable` is a member of your business object [T]
  R watchX<T, R>(
    ValueListenable<R> Function(T) select, {
    String instanceName,
  }) =>
      _state.value
          .watchX<T, ValueListenable<R>>(select, instanceName: instanceName)
          .value;

  /// like watch but for simple `Listenable` objects.
  /// It only triggers a rebuild when the value that
  /// [only] returns changes. With that you can react to changes of single members
  /// of [T]
  R watchOnly<T extends Listenable, R>(
    R Function(T) only, {
    String instanceName,
  }) =>
      _state.value.watchOnly<T, R>(only, instanceName: instanceName);

  /// a combination of [watchX] and [watchOnly] for simple
  /// `Listenable` members [Q] of your object [T]
  R watchXOnly<T, Q extends Listenable, R>(
    Q Function(T) select,
    R Function(Q listenable) only, {
    String instanceName,
  }) =>
      _state.value
          .watchXOnly<T, Q, R>(select, only, instanceName: instanceName);

  /// subscribes to the `Stream` returned by [select] and returns
  /// an `AsyncSnapshot` with the latest received data from the `Stream`
  /// Whenever new data is received it triggers a rebuild.
  /// When you call [watchStream] a second time on the same `Stream` it will
  /// return the last received data but not subscribe another time.
  /// To be able to use [watchStream] inside a `build` function we have to pass
  /// [initialValue] so that it can return something before it has received the first data
  /// if [select] returns a different Stream than on the last call, [watchStream]
  /// will cancel the previous subscription and subscribe to the new stream.
  /// [preserveState] determines then if the new initial value should be the last
  /// value of the previous stream or again [initialValue]
  AsyncSnapshot<R> watchStream<T, R>(
    Stream<R> Function(T) select,
    R initialValue, {
    String instanceName,
    bool preserveState = true,
  }) =>
      _state.value.watchStream<T, R>(select, initialValue,
          instanceName: instanceName, preserveState: preserveState);

  /// awaits the ` Future` returned by [select] and triggers a rebuild as soon
  /// as the `Future` completes. After that it returns
  /// an `AsyncSnapshot` with the received data from the `Future`
  /// When you call [watchFuture] a second time on the same `Future` it will
  /// return the last received data but not observe the Future a another time.
  /// To be able to use [watchStream] inside a `build` function
  /// we have to pass [initialValue] so that it can return something before
  /// the `Future` has completed
  /// if [select] returns a different `Future` than on the last call, [watchFuture]
  /// will ignore the completion of the previous Future and observe the completion
  /// of the new Future.
  /// [preserveState] determines then if the new initial value should be the last
  /// value of the previous stream or again [initialValue]
  AsyncSnapshot<R> watchFuture<T, R>(
    Future<R> Function(T) select,
    R initialValue, {
    String instanceName,
    bool preserveState = true,
  }) =>
      _state.value.watchFuture<T, R>(select, initialValue,
          instanceName: instanceName, preserveState: preserveState);

  /// Pushes a new GetIt-Scope. After pushing it executes [init] where you can register
  /// objects that should only exist as long as this scope exists.
  /// Can be called inside the `build` method method of a `StatelessWidget`.
  /// It ensures that it's only called once in the lifetime of a widget.
  /// When the widget is destroyed the scope too gets destroyed after [dispose]
  /// is executed. If you use this function and you have registered your objects with
  /// an async disposal function, that functions won't be awaited.
  /// I would recommend doing pushing and popping from your business layer but sometimes
  /// this might come in handy
  void pushScope({void Function(GetIt getIt) init, void Function() dispose}) =>
      _state.value.pushScope(init: init, dispose: dispose);
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
    newWidget._state.value = _state;
    super.update(newWidget);
  }
}

mixin GetItStateMixin<T extends StatefulWidget> on State<T> {
  /// this is an ugly hack so that you don't get a warning in the statelesswidget
  final _MutableWrapper<_MixinState> _state = _MutableWrapper<_MixinState>();
  @override
  void initState() {
    _state.value = _MixinState();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _state.value.init(context);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(Widget newWidget) {
    _state.value.clearRegistratons();
    _state.value.resetCurrentWatch();
    super.didUpdateWidget(newWidget);
  }

  @override
  void dispose() {
    _state.value.dispose();
    super.dispose();
  }

  /// all the following functions can be called inside the build function but also
  /// the mixin takes care that everything is correctly disposed.

  /// retrieves or creates an instance of a registered type [t] depending on the registration
  /// function used for this type or based on a name.
  /// for factories you can pass up to 2 parameters [param1,param2] they have to match the types
  /// given at registration with [registerfactoryparam()]
  T get<T>({String instanceName, dynamic param1, dynamic param2}) =>
      GetIt.I<T>(instanceName: instanceName, param1: param1, param2: param2);

  /// like [get] but for async registrations
  Future<T> getasync<T>(
          {String instanceName, dynamic param1, dynamic param2}) =>
      GetIt.I.getAsync<T>(
          instanceName: instanceName, param1: param1, param2: param2);

  /// like [get] but with an additional [select] function to return a member of [T]
  R getx<T, R>(R Function(T) accessor, {String instanceName}) {
    assert(accessor != null);
    return accessor(GetIt.I<T>(instanceName: instanceName));
  }

  /// To observe `ValueListenables`
  /// like [get] but it also registers a listener to [T] and
  /// triggers a rebuild every time [T].value changes
  R watch<T extends ValueListenable<R>, R>({String instanceName}) =>
      _state.value.watch<T>(instanceName: instanceName).value;

  /// like watch but it only triggers a rebuild when the value of
  /// the `ValueListenable`, that the function [select] returns changes
  /// useful if the `ValueListenable` is a member of your business object [T]
  R watchX<T, R>(
    ValueListenable<R> Function(T) select, {
    String instanceName,
  }) =>
      _state.value
          .watchX<T, ValueListenable<R>>(select, instanceName: instanceName)
          .value;

  /// like watch but for simple `Listenable` objects.
  /// It only triggers a rebuild when the value that
  /// [only] returns changes. With that you can react to changes of single members
  /// of [T]
  R watchOnly<T extends Listenable, R>(
    R Function(T) only, {
    String instanceName,
  }) =>
      _state.value.watchOnly<T, R>(only, instanceName: instanceName);

  /// a combination of [watchX] and [watchOnly] for simple
  /// `Listenable` members [Q] of your object [T]
  R watchXOnly<T, Q extends Listenable, R>(
    Q Function(T) select,
    R Function(Q listenable) only, {
    String instanceName,
  }) =>
      _state.value
          .watchXOnly<T, Q, R>(select, only, instanceName: instanceName);

  /// subscribes to the `Stream` returned by [select] and returns
  /// an `AsyncSnapshot` with the latest received data from the `Stream`
  /// Whenever new data is received it triggers a rebuild.
  /// When you call [watchStream] a second time on the same `Stream` it will
  /// return the last received data but not subscribe another time.
  /// To be able to use [watchStream] inside a `build` function we have to pass
  /// [initialValue] so that it can return something before it has received the first data
  /// if [select] returns a different Stream than on the last call, [watchStream]
  /// will cancel the previous subscription and subscribe to the new stream.
  /// [preserveState] determines then if the new initial value should be the last
  /// value of the previous stream or again [initialValue]
  AsyncSnapshot<R> watchStream<T, R>(
    Stream<R> Function(T) select,
    R initialValue, {
    String instanceName,
    bool preserveState = true,
  }) =>
      _state.value.watchStream<T, R>(select, initialValue,
          instanceName: instanceName, preserveState: preserveState);

  /// awaits the ` Future` returned by [select] and triggers a rebuild as soon
  /// as the `Future` completes. After that it returns
  /// an `AsyncSnapshot` with the received data from the `Future`
  /// When you call [watchFuture] a second time on the same `Future` it will
  /// return the last received data but not observe the Future a another time.
  /// To be able to use [watchStream] inside a `build` function
  /// we have to pass [initialValue] so that it can return something before
  /// the `Future` has completed
  /// if [select] returns a different `Future` than on the last call, [watchFuture]
  /// will ignore the completion of the previous Future and observe the completion
  /// of the new Future.
  /// [preserveState] determines then if the new initial value should be the last
  /// value of the previous stream or again [initialValue]
  AsyncSnapshot<R> watchFuture<T, R>(
    Future<R> Function(T) select,
    R initialValue, {
    String instanceName,
    bool preserveState = true,
  }) =>
      _state.value.watchFuture<T, R>(select, initialValue,
          instanceName: instanceName, preserveState: preserveState);

  /// Pushes a new GetIt-Scope. After pushing it executes [init] where you can register
  /// objects that should only exist as long as this scope exists.
  /// Can be called inside the `build` method method of a `StatelessWidget`.
  /// It ensures that it's only called once in the lifetime of a widget.
  /// When the widget is destroyed the scope too gets destroyed after [dispose]
  /// is executed. If you use this function and you have registered your objects with
  /// an async disposal function, that functions won't be awaited.
  /// I would recommend doing pushing and popping from your business layer but sometimes
  /// this might come in handy
  void pushScope({void Function(GetIt getIt) init, void Function() dispose}) =>
      _state.value.pushScope(init: init, dispose: dispose);
}

/// will cancel the previous subscription and subscribe to the new stream.
mixin _GetItElement on ComponentElement {
  _MixinState _state;

  @override
  void mount(Element parent, newSlot) {
    _state.init(this);
    super.mount(parent, newSlot);
  }

  @override
  Widget build() {
    _state.resetCurrentWatch();
    return super.build();
  }

  @override
  void update(Widget newWidget) {
    super.update(newWidget);
    _state.clearRegistratons();
  }

  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  void unmount() {
    _state.dispose();
    super.unmount();
  }
}

class _WatchEntry<TObservedObject, TValue>
    extends LinkedListEntry<_WatchEntry<Object, Object>> {
  TObservedObject observedObject;
  Function notificationHandler;
  StreamSubscription subscription;
  TValue Function(TObservedObject) selector;
  void Function(_WatchEntry entry) _dispose;
  TValue lastValue;
  _WatchEntry(
      {this.notificationHandler,
      this.subscription,
      void Function(_WatchEntry entry) dispose,
      this.lastValue,
      this.selector,
      this.observedObject})
      : _dispose = dispose;
  void dispose() {
    _dispose(this);
  }

  TValue getSelectedValue() {
    assert(selector != null);
    return selector(observedObject);
  }

  bool get hasSelector => selector != null;

  bool watchesTheSame(_WatchEntry entry) {
    if (entry.observedObject != null) {
      if (entry.observedObject == observedObject) {
        if (entry.hasSelector && hasSelector) {
          return entry.getSelectedValue() == getSelectedValue();
        }
        return true;
      }
      return false;
    }
    return false;
  }
}

class _MixinState {
  Element _element;

  LinkedList<_WatchEntry> _watchList = LinkedList<_WatchEntry>();
  _WatchEntry currentWatch;

  void init(Element element) {
    _element = element;
  }

  void resetCurrentWatch() {
    currentWatch = _watchList.isNotEmpty ? _watchList.first : null;
  }

  _WatchEntry _getWatch<T>() {
    if (currentWatch != null) {
      final result = currentWatch;
      currentWatch = currentWatch.next;
      return result;
    }
    return null;
  }

  void _appendWatch(_WatchEntry entry) {
    for (final watch in _watchList) {
      if (watch.watchesTheSame(entry)) {
        throw ArgumentError('This Object is already watched by get_it_mixin');
      }
    }
    _watchList.add(entry);
    currentWatch = null;
  }

  T watch<T extends Listenable>({String instanceName}) {
    final listenable = GetIt.I<T>(instanceName: instanceName);
    final watch = _getWatch<T>();

    if (watch == null) {
      final handler = () => _element.markNeedsBuild();
      _appendWatch(_WatchEntry<Listenable, Listenable>(
        observedObject: listenable,
        lastValue: listenable,
        notificationHandler: handler,
        dispose: (x) => listenable.removeListener(x.notificationHandler),
      ));
      listenable.addListener(handler);
    }
    return listenable;
  }

  R watchX<T, R extends Listenable>(
    R Function(T) select, {
    String instanceName,
  }) {
    assert(select != null, 'select can\'t be null if you use watchX');
    final parentObject = GetIt.I<T>(instanceName: instanceName);
    final listenable = select(parentObject);
    assert(listenable != null, 'select returned null in watchX');

    _WatchEntry watch = _getWatch();

    if (watch != null) {
      if (listenable == watch.observedObject) {
        return listenable;
      } else {
        /// select returned a different value than the last time
        /// so we have to unregister out handler and subscribe anew
        watch.dispose();
      }
    } else {
      watch = _WatchEntry<R, R>(
        observedObject: listenable,
        dispose: (x) => listenable.removeListener(
          x.notificationHandler,
        ),
      );
      _appendWatch(watch);
    }

    final handler = () => _element.markNeedsBuild();
    watch.notificationHandler = handler;
    watch.observedObject = listenable;

    listenable.addListener(handler);
    return listenable;
  }

  R watchOnly<T extends Listenable, R>(
    R Function(T) only, {
    String instanceName,
  }) {
    assert(only != null, 'only can\'t be null if you use watchOnly');
    final parentObject = GetIt.I<T>(instanceName: instanceName);

    _WatchEntry alreadyRegistered = _getWatch();

    if (alreadyRegistered == null) {
      final onlyTarget = only(parentObject);
      final watch = _WatchEntry<T, R>(
          observedObject: parentObject,
          selector: only,
          lastValue: onlyTarget,
          dispose: (x) => parentObject.removeListener(x.notificationHandler));

      final handler = () {
        final newValue = only(parentObject);
        if (watch.lastValue != newValue) {
          _element.markNeedsBuild();
          watch.lastValue = newValue;
        }
      };
      watch.notificationHandler = handler;
      _appendWatch(watch);

      parentObject.addListener(handler);
    }
    return only(parentObject);
  }

  R watchXOnly<T, Q extends Listenable, R>(
    Q Function(T) select,
    R Function(Q) only, {
    String instanceName,
  }) {
    assert(only != null, 'only can\'t be null if you use watchXOnly');
    assert(select != null, 'select can\'t be null if you use watchXOnly');
    final parentObject = GetIt.I<T>(instanceName: instanceName);
    final Q listenable = select(parentObject);
    assert(listenable != null, 'watchXOnly: select must return a Listenable');

    _WatchEntry watch = _getWatch();

    if (watch != null) {
      if (listenable == watch.observedObject) {
        return watch.lastValue;
      } else {
        /// select returned a different value than the last time
        /// so we have to unregister out handler and subscribe anew
        watch.dispose();
      }
    } else {
      watch = _WatchEntry<Q, R>(
          observedObject: listenable,
          lastValue: only(listenable),
          selector: only,
          dispose: (x) => listenable.removeListener(x.notificationHandler));
      _appendWatch(watch);
    }

    final handler = () {
      final newValue = only(listenable);
      if (watch.lastValue != newValue) {
        _element.markNeedsBuild();
        watch.lastValue = newValue;
      }
    };

    watch.observedObject = listenable;
    watch.notificationHandler = handler;

    listenable.addListener(handler);
    return only(listenable);
  }

  AsyncSnapshot<R> watchStream<T, R>(
    Stream<R> Function(T) select,
    R initialValue, {
    String instanceName,
    bool preserveState = true,
  }) {
    assert(select != null, 'select can\'t be null if you use watchStream');
    final parentObject = GetIt.I<T>(instanceName: instanceName);
    final stream = select(parentObject);
    assert(stream != null, 'select returned null in watchX');

    _WatchEntry watch = _getWatch();

    if (watch != null) {
      if (stream == watch.observedObject) {
        ///  still the same stream so we can directly return lastvalue
        return watch.lastValue;
      } else {
        /// select returned a different value than the last time
        /// so we have to unregister out handler and subscribe anew
        watch.dispose();
        initialValue =
            preserveState ? watch.lastValue ?? initialValue : initialValue;
      }
    } else {
      watch = _WatchEntry<Stream<R>, AsyncSnapshot<R>>(
          dispose: (x) => x.subscription.cancel(), observedObject: stream);
      _appendWatch(watch);
    }

    // ignore: cancel_subscriptions
    final subscription = stream.listen(
      (x) {
        watch.lastValue = AsyncSnapshot.withData(ConnectionState.active, x);
        _element.markNeedsBuild();
      },
      onError: (error) {
        watch.lastValue =
            AsyncSnapshot.withError(ConnectionState.active, error);
        _element.markNeedsBuild();
      },
    );
    watch.subscription = subscription;
    watch.observedObject = stream;
    watch.lastValue =
        AsyncSnapshot<R>.withData(ConnectionState.waiting, initialValue);

    return watch.lastValue;
  }

  AsyncSnapshot<R> watchFuture<T, R>(
      Future<R> Function(T) select, R initialValue,
      {String instanceName, bool preserveState}) {
    assert(select != null, 'select can\'t be null if you use watchStream');
    final parentObject = GetIt.I<T>(instanceName: instanceName);
    final future = select(parentObject);
    assert(future != null, 'select returned null in watchX');

    _WatchEntry watch = _getWatch();

    if (watch != null) {
      if (future == watch.observedObject) {
        ///  still the same Future so we can directly return lastvalue
        return watch.lastValue;
      } else {
        /// select returned a different value than the last time
        /// so we have to unregister out handler and subscribe anew
        watch.dispose();
        initialValue =
            preserveState ? watch.lastValue ?? initialValue : initialValue;
      }
    } else {
      watch = _WatchEntry<Future<R>, AsyncSnapshot<R>>(
          dispose: (x) => x.observedObject = null, observedObject: future);

      _appendWatch(watch);
    }

    watch.observedObject = future;
    future.then(
      (x) {
        if (watch.observedObject != null) {
          // only update if Future is still valid
          watch.lastValue = AsyncSnapshot.withData(ConnectionState.active, x);
          _element.markNeedsBuild();
        }
      },
      onError: (error) {
        if (watch.observedObject != null) {
          watch.lastValue =
              AsyncSnapshot.withError(ConnectionState.active, error);
          _element.markNeedsBuild();
        }
      },
    );
    watch.lastValue =
        AsyncSnapshot<R>.withData(ConnectionState.waiting, initialValue);

    return watch.lastValue;
  }

  bool _scopeWasPushed = false;

  void pushScope({void Function(GetIt getIt) init, void Function() dispose}) {
    if (!_scopeWasPushed) {
      GetIt.I.pushNewScope(dispose: dispose);
      init(GetIt.I);
    }
  }

  void clearRegistratons() {
    _watchList.forEach((x) => x.dispose());
    _watchList.clear();
    currentWatch = null;
  }

  void dispose() {
    clearRegistratons();
    if (_scopeWasPushed) {
      GetIt.I.popScope();
    }
    _element = null; // making sure the Garbage collector can do its job
  }
}
