import 'package:flutter/material.dart';
import 'package:flutter_weather_demo/weather_manager.dart';
import 'package:get_it_mixin/get_it_mixin.dart';

import 'listview.dart';

class HomePage extends StatefulWidget with GetItStatefulWidgetMixin {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with GetItStateMixin {
  @override
  Widget build(BuildContext context) {
    registerHandler(
        (WeatherManager x) => x.updateWeatherCommand.thrownExceptions,
        (context, error, cancel) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('An error has occurred!'),
                content: Text(error.toString()),
              ));
    });

    final isRunning =
        watchX((WeatherManager x) => x.updateWeatherCommand.isExecuting);
    final updateButtonEnbaled =
        watchX((WeatherManager x) => x.updateWeatherCommand.canExecute);
    final switchValue =
        watchX((WeatherManager x) => x.setExecutionStateCommand);

    return Scaffold(
      appBar: AppBar(title: Text("WeatherDemo")),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextField(
              autocorrect: false,
              decoration: InputDecoration(
                hintText: "Filter cities",
                hintStyle: TextStyle(color: Color.fromARGB(150, 0, 0, 0)),
              ),
              style: TextStyle(
                fontSize: 20.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              onChanged: get<WeatherManager>().textChangedCommand,
            ),
          ),
          Expanded(
            // Handle events to show / hide spinner
            child: Stack(
              children: [
                WeatherListView(),
                // if true we show a busy Spinner otherwise the ListView
                if (isRunning == true)
                  Center(
                    child: Container(
                      width: 50.0,
                      height: 50.0,
                      child: CircularProgressIndicator(),
                    ),
                  )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            // We use a ValueListenableBuilder to toggle the enabled state of the button
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    child: Text("Update"),
                    style: ElevatedButton.styleFrom(
                        primary: Color.fromARGB(255, 33, 150, 243),
                        onPrimary: Color.fromARGB(255, 255, 255, 255)),
                    onPressed: updateButtonEnbaled
                        ? get<WeatherManager>().updateWeatherCommand.call
                        : null,
                  ),
                ),
                Switch(
                  value: switchValue,
                  onChanged: get<WeatherManager>().setExecutionStateCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
