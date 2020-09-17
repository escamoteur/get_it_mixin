import 'package:flutter/material.dart';
import 'package:flutter_weather_demo/the_viewmodel.dart';
import 'package:get_it/get_it.dart';

import 'homepage.dart';

void main() {
  registerViewModel();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: HomePage(),
    );
  }
}

void registerViewModel() {
  GetIt.I.registerSingleton<TheViewModel>(TheViewModel());
}
