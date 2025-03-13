import 'package:flutter/material.dart';

class AppConstants {
  // Application Name
  static const String appName = 'GitTask';
  
  // Color options for repository selection
  static const List<Color> colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
  ];
  
  // Task status colors
  static const Map<int, Color> taskStatusColors = {
    0: Colors.grey, // todo
    1: Colors.orange, // inProgress
    2: Colors.green, // done
  };
  
  // Task status names
  static const Map<int, String> taskStatusNames = {
    0: 'To Do',
    1: 'In Progress',
    2: 'Completed',
  };
}