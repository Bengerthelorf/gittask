import 'package:uuid/uuid.dart';
import 'task.dart';

class Commit {
  final String id;
  final String taskId;
  final String message;
  final Map<String, dynamic> oldState;
  final Map<String, dynamic> newState;
  final DateTime timestamp;

  Commit({
    String? id,
    required this.taskId,
    required this.message,
    required this.oldState,
    required this.newState,
    DateTime? timestamp,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();
  
  // 从任务变更创建提交记录
  factory Commit.fromTaskChange({
    required Task oldTask, 
    required Task newTask, 
    required String message
  }) {
    return Commit(
      taskId: newTask.id,
      message: message,
      oldState: oldTask.toMap(),
      newState: newTask.toMap(),
      timestamp: DateTime.now(),
    );
  }
  
  // 将提交记录转换为可存储的Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'message': message,
      'oldState': oldState,
      'newState': newState,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
  
  // 从Map创建提交记录
  factory Commit.fromMap(Map<String, dynamic> map) {
    return Commit(
      id: map['id'],
      taskId: map['taskId'],
      message: map['message'],
      oldState: Map<String, dynamic>.from(map['oldState']),
      newState: Map<String, dynamic>.from(map['newState']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}