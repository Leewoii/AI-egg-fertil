import 'package:flutter/material.dart';


class FabButtons extends StatelessWidget {
  final VoidCallback onIncreaseTemperature;
  final VoidCallback onDecreaseTemperature;
  final VoidCallback onIncreaseHumidity;
  final VoidCallback onDecreaseHumidity;
  final VoidCallback onIncreaseWaterLevel;
  final VoidCallback onDecreaseWaterLevel;

  FabButtons({
    required this.onIncreaseTemperature,
    required this.onDecreaseTemperature,
    required this.onIncreaseHumidity,
    required this.onDecreaseHumidity,
    required this.onIncreaseWaterLevel,
    required this.onDecreaseWaterLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Increase temperature button
            FloatingActionButton(
              heroTag: "increaseTempButton",
              onPressed: onIncreaseTemperature,
              tooltip: 'Increase Temperature',
              child: Text('+', style: TextStyle(fontSize: 24)),
              backgroundColor: Colors.green,
            ),
            // Increase humidity button
            FloatingActionButton(
              heroTag: "increaseHumidityButton",
              onPressed: onIncreaseHumidity,
              tooltip: 'Increase Humidity',
              child: Text('+', style: TextStyle(fontSize: 24)),
              backgroundColor: Colors.blue,
            ),
            // Increase water level button
            FloatingActionButton(
              heroTag: "increaseWaterButton",
              onPressed: onIncreaseWaterLevel,
              tooltip: 'Increase Water Level',
              child: Text('+', style: TextStyle(fontSize: 24)),
              backgroundColor: Colors.teal,
            ),
          ],
        ),
        SizedBox(height: 16), // Space between rows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Decrease temperature button
            FloatingActionButton(
              heroTag: "decreaseTempButton",
              onPressed: onDecreaseTemperature,
              tooltip: 'Decrease Temperature',
              child: Text('-', style: TextStyle(fontSize: 24)),
              backgroundColor: const Color.fromARGB(255, 244, 54, 54),
            ),
            // Decrease humidity button
            FloatingActionButton(
              heroTag: "decreaseHumidityButton",
              onPressed: onDecreaseHumidity,
              tooltip: 'Decrease Humidity',
              child: Text('-', style: TextStyle(fontSize: 24)),
              backgroundColor: Colors.orange,
            ),
            // Decrease water level button
            FloatingActionButton(
              heroTag: "decreaseWaterButton",
              onPressed: onDecreaseWaterLevel,
              tooltip: 'Decrease Water Level',
              child: Text('-', style: TextStyle(fontSize: 24)),
              backgroundColor: Colors.brown,
            ),
          ],
        ),
      ],
    );
  }
}
