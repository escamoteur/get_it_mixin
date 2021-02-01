import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

part 'elements.dart';
part 'mixin_state.dart';

class _MutableWrapper<T> {
  T value;
}

mixin GetItMixin on StatelessWidget {
  /// this is an ugly hack so that you don't get a warning in the StatelessWidget
  final _MutableWrapper<_MixinState/*!*/> _state = _MutableWrapper<_MixinState/*!*/>();
  @override
  StatelessElement createElement() => _StatelessMixInElement(this);

  /// all the following functions can be called inside the build function but also
  /// in e.g. in `initState` of a `StatefulWidget`.
  /// The mixin takes care that everything is correctly disposed.

  /// retrieves or creates an instance of a registered type [T] depending on the registration
  /// function used for this type or based on a name.
  /// for factories you can pass up to 2 parameters [param1,param2] they have to match the types
  /// given at registration with [registerFactoryParam()]
  T/*!*/ get<T>({String instanceName, dynamic param1, dynamic param2}) =>
      GetIt.I<T>(instanceName: instanceName, param1: param1, param2: param2);

  /// like [get] but for async registrations
  Future<T> getAsync<T>(
          {String instanceName, dynamic param1, dynamic param2}) =>
      GetIt.I.getAsync<T>(
          instanceName: instanceName, param1: param1, param2: param2);

  /// like [get] but with an additional [select] function to return a member of [T]
  R getX<T, R>(R Function(T/*!*/) accessor, {String instanceName}) {
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
      _state.value.watchX<T, R>(select, instanceName: instanceName);

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
      _state.value.registerFutureHandler<T, R>(
          select, (context, x, cancel) => (context as Element).markNeedsBuild(),
          initialValueProvider: () => initialValue,
          instanceName: instanceName,
          preserveState: preserveState,
          allowMultipleSubscribers: false);

  /// registers a [handler] for a `ValueListenable` exactly once on the first build
  /// and unregisters is when the widget is destroyed.
  /// [select] allows you to register the handler to a member of the of the Object
  /// stored in GetIt. If the object itself if the `ValueListenable` pass `(x)=>x` here
  /// If you set [executeImmediately] to `true` the handler will be called immediately
  /// with the current value of the `ValueListenable`.
  /// All handler get passed in a [cancel] function that allows to kill the registration
  /// from inside the handler.
  void registerHandler<T, R>(
    ValueListenable<R> Function(T) select,
    void Function(BuildContext context, R newValue, void Function() cancel)
        handler, {
    bool executeImmediately = false,
    String instanceName,
  }) =>
      _state.value.registerHandler<T, R>(select, handler,
          instanceName: instanceName, executeImmediately: executeImmediately);

  @Deprecated('renamed to registerHandler')
  void registerValueListenableHandler<T, R>(
    ValueListenable<R> Function(T) select,
    void Function(BuildContext context, R newValue, void Function() cancel)
        handler, {
    bool executeImmediately = false,
    String instanceName,
  }) =>
      _state.value.registerHandler<T, R>(select, handler,
          instanceName: instanceName, executeImmediately: executeImmediately);

  /// registers a [handler] for a `Stream` exactly once on the first build
  /// and unregisters is when the widget is destroyed.
  /// [select] allows you to register the handler to a member of the of the Object
  /// stored in GetIt. If the object itself if the `Stream` pass `(x)=>x` here
  /// If you pass [initialValue] your passed handler will be executes immediately
  /// with that value
  /// All handler get passed in a [cancel] function that allows to kill the registration
  /// from inside the handler.
  void registerStreamHandler<T, R>(
    Stream<R> Function(T) select,
    void Function(BuildContext context, AsyncSnapshot<R> newValue,
            void Function() cancel)
        handler, {
    R initialValue,
    String instanceName,
  }) =>
      _state.value.registerStreamHandler<T, R>(select, handler,
          initialValue: initialValue, instanceName: instanceName);

  /// registers a [handler] for a `Future` exactly once on the first build
  /// and unregisters is when the widget is destroyed.
  /// This handler will only called once when the `Future` completes.
  /// [select] allows you to register the handler to a member of the of the Object
  /// stored in GetIt. If the object itself if the `Future` pass `(x)=>x` here
  /// If you pass [initialValue] your passed handler will be executes immediately
  /// with that value.
  /// All handler get passed in a [cancel] function that allows to kill the registration
  /// from inside the handler.
  /// /// if the Future has completed [handler] will be called every time until
  /// the handler calls `cancel` or the widget is destroyed
  void registerFutureHandler<T, R>(
    Future<R> Function(T) select,
    void Function(BuildContext context, AsyncSnapshot<R> newValue,
            void Function() cancel)
        handler, {
    R initialValue,
    String instanceName,
  }) {
    assert(handler != null, "Handler can't be null for registerFutureHandler");
    _state.value.registerFutureHandler<T, R>(select, handler,
        initialValueProvider: () => initialValue,
        instanceName: instanceName,
        allowMultipleSubscribers: true);
  }

  /// returns `true` if all registered async or dependent objects are ready
  /// and call [onReady] [onError] handlers when the all-ready state is reached
  /// you can force a timeout Exceptions if [allReady] hasn't
  /// return `true` within [timeout]
  /// It will trigger a rebuild if this state changes
  bool allReady(
          {void Function(BuildContext context) onReady,
          void Function(BuildContext context, Object error) onError,
          Duration timeout}) =>
      _state.value
          .allReady(onReady: onReady, onError: onError, timeout: timeout);

  /// returns `true` if the registered async or dependent object defined by [T] and
  /// [instanceName] is ready
  /// and call [onReady] [onError] handlers when the ready state is reached
  /// you can force a timeout Exceptions if [isReady] hasn't
  /// return `true` within [timeout]
  /// It will trigger a rebuild if this state changes
  bool isReady<T>(
          {void Function(BuildContext context) onReady,
          void Function(BuildContext context, Object error) onError,
          Duration timeout,
          String instanceName}) =>
      _state.value.isReady<T>(
          instanceName: instanceName,
          onReady: onReady,
          onError: onError,
          timeout: timeout);

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

mixin GetItStatefulWidgetMixin on StatefulWidget {
  /// this is an ugly hack so that you don't get a warning in the StatelessWidget
  final _MutableWrapper<_MixinState> _state = _MutableWrapper<_MixinState>();
  @override
  StatefulElement createElement() => _StatefulMixInElement(this);
}

mixin GetItStateMixin<T extends GetItStatefulWidgetMixin> on State<T> {
  /// this is an ugly hack so that you don't get a warning in the statefulwidget
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
      widget._state.value.watch<T>(instanceName: instanceName).value;

  /// like watch but it only triggers a rebuild when the value of
  /// the `ValueListenable`, that the function [select] returns changes
  /// useful if the `ValueListenable` is a member of your business object [T]
  R watchX<T, R>(
    ValueListenable<R> Function(T) select, {
    String instanceName,
  }) =>
      widget._state.value.watchX<T, R>(select, instanceName: instanceName);

  /// like watch but for simple `Listenable` objects.
  /// It only triggers a rebuild when the value that
  /// [only] returns changes. With that you can react to changes of single members
  /// of [T]
  R watchOnly<T extends Listenable, R>(
    R Function(T) only, {
    String instanceName,
  }) =>
      widget._state.value.watchOnly<T, R>(only, instanceName: instanceName);

  /// a combination of [watchX] and [watchOnly] for simple
  /// `Listenable` members [Q] of your object [T]
  R watchXOnly<T, Q extends Listenable, R>(
    Q Function(T) select,
    R Function(Q listenable) only, {
    String instanceName,
  }) =>
      widget._state.value
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
      widget._state.value.watchStream<T, R>(select, initialValue,
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
      widget._state.value.registerFutureHandler<T, R>(
          select, (context, x, cancel) => (context as Element).markNeedsBuild(),
          initialValueProvider: () => initialValue,
          instanceName: instanceName,
          preserveState: preserveState,
          allowMultipleSubscribers: false);

  /// registers a [handler] for a `ValueListenable` exactly once on the first build
  /// and unregisters is when the widget is destroyed.
  /// [select] allows you to register the handler to a member of the of the Object
  /// stored in GetIt. If the object itself if the `ValueListenable` pass `(x)=>x` here
  /// If you set [executeImmediately] to `true` the handler will be called immediately
  /// with the current value of the `ValueListenable`.
  /// All handler get passed in a [cancel] function that allows to kill the registration
  /// from inside the handler.
  void registerHandler<T, R>(
    ValueListenable<R> Function(T) select,
    void Function(BuildContext context, R newValue, void Function() cancel)
        handler, {
    bool executeImmediately = false,
    String instanceName,
  }) =>
      widget._state.value.registerHandler<T, R>(select, handler,
          instanceName: instanceName, executeImmediately: executeImmediately);

  @Deprecated('renamed to registerHandler')
  void registerValueListenableHandler<T, R>(
    ValueListenable<R> Function(T) select,
    void Function(BuildContext context, R newValue, void Function() cancel)
        handler, {
    bool executeImmediately = false,
    String instanceName,
  }) =>
      widget._state.value.registerHandler<T, R>(select, handler,
          instanceName: instanceName, executeImmediately: executeImmediately);

  /// registers a [handler] for a `Stream` exactly once on the first build
  /// and unregisters is when the widget is destroyed.
  /// [select] allows you to register the handler to a member of the of the Object
  /// stored in GetIt. If the object itself if the `ValueListenable` pass `(x)=>x` here
  /// If you pass [initialValue] your passed handler will be executes immediately
  /// with that value
  /// As Streams can emit an error, you can register an optional [errorHandler]
  /// All handler get passed in a [cancel] function that allows to kill the registration
  /// from inside the handler.
  void registerStreamHandler<T, R>(
    Stream<R> Function(T) select,
    void Function(BuildContext context, AsyncSnapshot<R> newValue,
            void Function() cancel)
        handler, {
    R initialValue,
    String instanceName,
  }) =>
      widget._state.value.registerStreamHandler<T, R>(select, handler,
          initialValue: initialValue, instanceName: instanceName);

  /// registers a [handler] for a `Future` exactly once on the first build
  /// and unregisters is when the widget is destroyed.
  /// This handler will only called once when the `Future` completes.
  /// [select] allows you to register the handler to a member of the of the Object
  /// stored in GetIt. If the object itself if the `Future` pass `(x)=>x` here
  /// If you pass [initialValue] your passed handler will be executes immediately
  /// with that value.
  /// All handler get passed in a [cancel] function that allows to kill the registration
  /// from inside the handler.
  /// if the Future has completed [handler] will be called every time until
  /// the handler calls `cancel` or the widget is destroyed
  void registerFutureHandler<T, R>(
    Future<R> Function(T) select,
    void Function(BuildContext context, AsyncSnapshot<R> newValue,
            void Function() cancel)
        handler, {
    R initialValue,
    String instanceName,
  }) =>
      widget._state.value.registerFutureHandler<T, R>(select, handler,
          initialValueProvider: () => initialValue,
          instanceName: instanceName,
          allowMultipleSubscribers: true);

  /// returns `true` if all registered async or dependent objects are ready
  /// and call [onReady] [onError] handlers when the all-ready state is reached
  /// you can force a timeout Exceptions if [allReady] hasn't
  /// return `true` within [timeout]
  /// It will trigger a rebuild if this state changes
  bool allReady(
          {void Function(BuildContext context) onReady,
          void Function(BuildContext context, Object error) onError,
          Duration timeout}) =>
      widget._state.value
          .allReady(onReady: onReady, onError: onError, timeout: timeout);

  /// returns `true` if the registered async or dependent object defined by [T] and
  /// [instanceName] is ready
  /// and call [onReady] [onError] handlers when the ready state is reached
  /// you can force a timeout Exceptions if [isReady] hasn't
  /// return `true` within [timeout]
  /// It will trigger a rebuild if this state changes
  bool isReady<T>(
          {void Function(BuildContext context) onReady,
          void Function(BuildContext context, Object error) onError,
          Duration timeout,
          String instanceName}) =>
      widget._state.value.isReady<T>(
          instanceName: instanceName,
          onReady: onReady,
          onError: onError,
          timeout: timeout);

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
      widget._state.value.pushScope(init: init, dispose: dispose);
}
