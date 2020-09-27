import 'package:flutter/material.dart';
import 'package:flutter_weather_demo/the_viewmodel.dart';
import 'package:functional_listener/functional_listener.dart';
import 'package:get_it_mixin/get_it_mixin.dart';

import 'listview.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with GetItStateMixin {
  ListenableSubscription errorSubscription;

  @override
  void didChangeDependencies() {
    errorSubscription ??= get<TheViewModel>()
        .updateWeatherCommand
        .thrownExceptions
        .where((x) => x != null) // filter out the error value reset
        .listen((error, _) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('An error has occured!'),
                content: Text(error.toString()),
              ));
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    errorSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning =
        watchX((TheViewModel x) => x.updateWeatherCommand.isExecuting);
    final updateButtonEnbaled =
        watchX((TheViewModel x) => x.updateWeatherCommand.canExecute);
    final switchValue = watchX((TheViewModel x) => x.setExecutionStateCommand);

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
              onChanged: get<TheViewModel>().textChangedCommand,
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
                  child: RaisedButton(
                    child: Text("Update"),
                    color: Color.fromARGB(255, 33, 150, 243),
                    textColor: Color.fromARGB(255, 255, 255, 255),
                    onPressed: updateButtonEnbaled
                        ? get<TheViewModel>().updateWeatherCommand
                        : null,
                  ),
                ),
                Switch(
                  value: switchValue,
                  onChanged: get<TheViewModel>().setExecutionStateCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
