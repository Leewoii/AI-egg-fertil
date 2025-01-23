// gradients.dart
import 'package:flutter/material.dart';

LinearGradient getTemperatureGradient(double temperature) {
  if (temperature >= 0 && temperature <= 5) {
    return const LinearGradient(
      colors: [
        Color(0xFFD3D3D3), // Light grey
        Color(0xFFA9A9A9), // Dark grey
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  } else {
    double percentage =
        (temperature - 5) / 95; // Adjust percentage for range 5-100
    Color startColor = Color.lerp(
      const Color(0xFFF7E609), // #F7E609
      const Color(0xFF931D0A), // #931D0A
      percentage,
    )!;

    Color endColor = Color.lerp(
      const Color(0xFFF7E609), // #F7E609
      const Color(0xFF931D0A), // #931D0A
      percentage,
    )!;

    return LinearGradient(
      colors: [startColor, endColor],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }
}

LinearGradient getHumidityGradient(double humidity) {
  if (humidity <= 35) {
    return const LinearGradient(
      colors: [
        Color(0xFFDE505E), // #DE505E
        Color(0xFFBA697C), // #BA697C
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  } else if (humidity >= 71) {
    return const LinearGradient(
      colors: [
        Color(0xFF4F6DDD), // #4F6DDD
        Color(0xFF548AE2), // #548AE2
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  } else {
    return const LinearGradient(
      colors: [
        Color(0xFF9F8BA6), // #9F8BA6
        Color(0xFF7FABCE), // #7FABCE
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }
}

LinearGradient getWaterLevelGradient(double waterLevel) {
  double percentage = waterLevel / 100; // Convert water level to percentage
  Color startColor = Color.lerp(
    const Color(0xFF256FFF), // Maximum color
    const Color(0xFF25AFFF), // Minimum color
    percentage,
  )!;
  Color endColor = Color.lerp(
    const Color(0xFF256FFF), // Maximum color
    const Color(0xFF25AFFF), // Minimum color
    percentage,
  )!;

  return LinearGradient(
    colors: [startColor, endColor],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
