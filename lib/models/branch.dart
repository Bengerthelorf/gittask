import 'package:uuid/uuid.dart';
import 'task.dart';
import 'commit.dart';

class Branch {
  final String id;
  final String repositoryId;
  String name;
  String description;
  DateTime createdAt;
  bool isMain;
  String? parentBranchId;
  
  // 任务列表
  List<Task> tasks;
  
  // 提交记录
  List<Commit> commits;
  
  Branch({
    String? id,
    required this.repositoryId,
    required this.name,
    this.description = '',
    DateTime? createdAt,
    this.isMain = false,
    this.parentBranchId,
    List<Task>? tasks,
    List<Commit>? commits,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    tasks = tasks ?? [],
    commits = commits ?? [];
  
  // 将分支转换为可存储的Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'repositoryId': repositoryId,
      'name': name,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isMain': isMain,
      'parentBranchId': parentBranchId,
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'commits': commits.map((commit) => commit.toMap()).toList(),
    };
  }
  
  // 从Map创建分支
  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'],
      repositoryId: map['repositoryId'],
      name: map['name'],
      description: map['description'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isMain: map['isMain'] ?? false,
      parentBranchId: map['parentBranchId'],
      tasks: (map['tasks'] as List?)
          ?.map((taskMap) => Task.fromMap(Map<String, dynamic>.from(taskMap)))
          .toList() ?? [],
      commits: (map['commits'] as List?)
          ?.map((commitMap) => Commit.fromMap(Map<String, dynamic>.from(commitMap)))
          .toList() ?? [],
    );
  }
  
  // 添加任务
  void addTask(Task task) {
    tasks.add(task);
    commits.add(
      Commit(
        taskId: task.id,
        message: '创建任务: ${task.title}',
        oldState: {},
        newState: task.toMap(),
      ),
    );
  }
  
  // 更新任务
  void updateTask(Task updatedTask) {
    final int index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      final oldTask = tasks[index];
      tasks[index] = updatedTask;
      
      commits.add(
        Commit.fromTaskChange(
          oldTask: oldTask,
          newTask: updatedTask,
          message: '更新任务: ${updatedTask.title}',
        ),
      );
    }
  }
  
  // 删除任务
  void deleteTask(String taskId) {
    final int index = tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final oldTask = tasks[index];
      tasks.removeAt(index);
      
      commits.add(
        Commit(
          taskId: taskId,
          message: '删除任务: ${oldTask.title}',
          oldState: oldTask.toMap(),
          newState: {},
        ),
      );
    }
  }
  
  // 从另一个分支合并任务
  void mergeBranch(Branch sourceBranch) {
    // 在实际应用中，这里可以实现更复杂的合并逻辑，
    // 例如解决任务冲突等
    for (final task in sourceBranch.tasks) {
      if (!tasks.any((t) => t.id == task.id)) {
        tasks.add(task);
      } else {
        // 如果任务已存在，可以选择保留较新的版本
        final existingIndex = tasks.indexWhere((t) => t.id == task.id);
        if (existingIndex != -1) {
          final existingTask = tasks[existingIndex];
          if ((task.updatedAt ?? task.createdAt).isAfter(
              existingTask.updatedAt ?? existingTask.createdAt)) {
            tasks[existingIndex] = task;
          }
        }
      }
    }
    
    // 添加合并提交记录
    commits.add(
      Commit(
        taskId: 'merge',
        message: '合并分支: ${sourceBranch.name} -> ${name}',
        oldState: {'branchId': sourceBranch.id},
        newState: {'branchId': id},
      ),
    );
  }
}