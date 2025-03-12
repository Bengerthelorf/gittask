import 'package:flutter/material.dart';

class AppConstants {
  // 应用名称
  static const String appName = 'GitTask';
  
  // 颜色选项，用于仓库颜色选择
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
  
  // 任务状态颜色
  static const Map<int, Color> taskStatusColors = {
    0: Colors.grey, // todo
    1: Colors.orange, // inProgress
    2: Colors.green, // done
  };
  
  // 任务状态名称
  static const Map<int, String> taskStatusNames = {
    0: '待办',
    1: '进行中',
    2: '已完成',
  };
}