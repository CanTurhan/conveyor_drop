import 'package:flutter/material.dart';

enum DropColorType { red, blue, green, yellow }

extension DropColorTypeX on DropColorType {
  Color get color {
    switch (this) {
      case DropColorType.red:
        return Colors.redAccent;
      case DropColorType.blue:
        return Colors.blueAccent;
      case DropColorType.green:
        return Colors.greenAccent;
      case DropColorType.yellow:
        return Colors.amberAccent;
    }
  }

  String get label {
    switch (this) {
      case DropColorType.red:
        return 'Red';
      case DropColorType.blue:
        return 'Blue';
      case DropColorType.green:
        return 'Green';
      case DropColorType.yellow:
        return 'Yellow';
    }
  }
}
