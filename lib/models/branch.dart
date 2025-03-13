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
  
  // Task list
  List<Task> tasks;
  
  // Commit history
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
  
  // Convert branch to storable Map
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
  
  // Create branch from Map
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
  
  // Add task
  void addTask(Task task) {
    tasks.add(task);
    commits.add(
      Commit(
        taskId: task.id,
        message: 'Create task: ${task.title}', // changed from '创建任务: ${task.title}'
        oldState: {},
        newState: task.toMap(),
      ),
    );
  }
  
  // Update task
  void updateTask(Task updatedTask) {
    final int index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      final oldTask = tasks[index];
      tasks[index] = updatedTask;
      
      commits.add(
        Commit.fromTaskChange(
          oldTask: oldTask,
          newTask: updatedTask,
          message: 'Update task: ${updatedTask.title}', // changed from '更新任务: ${updatedTask.title}'
        ),
      );
    }
  }
  
  // Delete task
  void deleteTask(String taskId) {
    final int index = tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final oldTask = tasks[index];
      tasks.removeAt(index);
      
      commits.add(
        Commit(
          taskId: taskId,
          message: 'Delete task: ${oldTask.title}', // changed from '删除任务: ${oldTask.title}'
          oldState: oldTask.toMap(),
          newState: {},
        ),
      );
    }
  }
  
  // Merge tasks from another branch
  void mergeBranch(Branch sourceBranch) {
    // In a real application, you can implement a more complex merge logic here,
    // such as resolving task conflicts.
    for (final task in sourceBranch.tasks) {
      if (!tasks.any((t) => t.id == task.id)) {
        tasks.add(task);
      } else {
        // If the task already exists, you can choose to keep the newer version
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
    
    // Add merge commit record
    commits.add(
      Commit(
        taskId: 'merge',
        message: 'Merge branch: ${sourceBranch.name} -> ${name}', // changed from '合并分支: ${sourceBranch.name} -> ${name}'
        oldState: {'branchId': sourceBranch.id},
        newState: {'branchId': id},
      ),
    );
  }
}