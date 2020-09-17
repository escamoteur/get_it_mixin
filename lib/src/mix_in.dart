import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

mixin GetItMixin on StatelessWidget {
  @override
  StatelessElement createElement() => _StatelessMixInElement(this);
}

class _StatelessMixInElement extends StatelessElement with _GetItElement {
  _StatelessMixInElement(Widget widget) : super(widget);
}

mixin _GetItElement on ComponentElement {
  @override
  void update(Widget newWidget) {
    super.update(newWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  void unmount() {
    super.unmount();
    // if (_hooks != null && _hooks.isNotEmpty) {
    //   for (var hook = _hooks.last; hook != null; hook = hook.previous) {
    //     try {
    //       hook.value.dispose();
    //     } catch (exception, stack) {
    //       FlutterError.reportError(
    //         FlutterErrorDetails(
    //           exception: exception,
    //           stack: stack,
    //           library: 'hooks library',
    //           context: DiagnosticsNode.message(
    //             'while disposing ${hook.runtimeType}',
    //           ),
    //         ),
    //       );
    //     }
    //   }
    // }
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // for (final hookState in debugHooks) {
    //   if (hookState.debugHasShortDescription) {
    //     if (hookState.debugSkipValue) {
    //       properties.add(
    //         StringProperty(hookState.debugLabel, '', ifEmpty: ''),
    //       );
    //     } else {
    //       properties.add(
    //         DiagnosticsProperty<dynamic>(
    //           hookState.debugLabel,
    //           hookState.debugValue,
    //         ),
    //       );
    //     }
    //   } else {
    //     properties.add(
    //       DiagnosticsProperty(hookState.debugLabel, hookState),
    //     );
    //   }
    // }
  }
}
