import 'package:flutter/material.dart';

class AppSeedColors {
  static const Map<String, int> presets = {
    'Blue': 0xff1976d2,
    'Teal': 0xff00897b,
    'Green': 0xff388e3c,
    'Purple': 0xff7b1fa2,
    'Orange': 0xfff57c00,
    'Pink': 0xffc2185b,
    'Red': 0xffd32f2f,
    'Indigo': 0xff303f9f,
  };

  static Color fromInt(int value) => Color(value);
}
