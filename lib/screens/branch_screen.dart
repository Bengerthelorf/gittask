import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repository.dart';
import '../models/branch.dart';
import '../models/task.dart';
import '../models/commit.dart';
import '../providers/repository_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/git_graph.dart';
import 'task_form_screen.dart';

class BranchScreen extends StatefulWidget {
  final Repository repository;
  final Branch branch;

  const BranchScreen({
    Key? key,
    required this.repository,
    required this.branch,
  }) : super(key: key);

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  bool _showGraph = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.repository.name),
            Text(
              widget.branch.name + (widget.branch.isMain ? ' (Main Branch)' : ''),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          // Toggle view button
          IconButton(
            icon: Icon(_showGraph ? Icons.list : Icons.account_tree),
            onPressed: () {
              setState(() {
                _showGraph = !_showGraph;
              });
            },
            tooltip: _showGraph ? 'Task List' : 'Git Graph',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<RepositoryProvider>(context, listen: false)
                  .refreshRepositories();
            },
          ),
        ],
      ),
      body: Consumer<RepositoryProvider>(
        builder: (context, repositoryProvider, child) {
          // 获取最新的仓库数据
          final updatedRepository = repositoryProvider.getRepositoryById(widget.repository.id);
          if (updatedRepository == null) {
            // 仓库已被删除
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Repository not found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // 获取更新后的分支
          final updatedBranch = updatedRepository.branches.firstWhere(
            (b) => b.id == widget.branch.id,
            orElse: () => widget.branch,
          );

          if (_showGraph) {
            // 显示Git图表
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commit History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (updatedBranch.commits.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.history, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'No commit history',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  else
                    GitGraph(
                      branch: updatedBranch,
                      onCommitTap: _showCommitDetails,
                    ),
                ],
              ),
            );
          } else {
            // 显示任务列表
            if (updatedBranch.tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Tasks',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click the button at the bottom right to create a new task',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: updatedBranch.tasks.length,
              itemBuilder: (context, index) {
                final task = updatedBranch.tasks[index];
                return TaskCard(
                  task: task,
                  onTap: () => _showTaskDetails(updatedRepository, updatedBranch, task),
                  onStatusChange: (newStatus) => _updateTaskStatus(
                    updatedRepository,
                    updatedBranch,
                    task,
                    newStatus,
                  ),
                  onEdit: () => _navigateToTaskForm(
                    context,
                    updatedRepository,
                    updatedBranch,
                    task,
                  ),
                  onDelete: () => _showDeleteConfirmation(
                    context,
                    updatedRepository,
                    updatedBranch,
                    task,
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: !_showGraph
          ? FloatingActionButton(
              onPressed: () => _navigateToTaskForm(
                context,
                widget.repository,
                widget.branch,
                null,
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showTaskDetails(Repository repository, Branch branch, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusName(task.status),
                    style: TextStyle(
                      color: _getStatusColor(task.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  task.description.isEmpty ? 'No description' : task.description,
                  style: TextStyle(
                    color: task.description.isEmpty
                        ? Colors.grey
                        : Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Task History',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // 显示与该任务相关的提交记录
                if (_getTaskCommits(branch, task.id).isEmpty)
                  const Text('No commit history', style: TextStyle(color: Colors.grey))
                else
                  for (final commit in _getTaskCommits(branch, task.id))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              commit.message,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Time: ${_formatDate(commit.timestamp)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Edit button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToTaskForm(context, repository, branch, task);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    // Change status button
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateTaskStatus(
                          repository,
                          branch,
                          task,
                          _getNextStatus(task.status),
                        );
                      },
                      icon: const Icon(Icons.sync),
                      label: Text('Change to ${_getNextStatusName(task.status)}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommitDetails(Commit commit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        commit.message,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Commit ID: ${commit.id.length > 8 ? commit.id.substring(0, 8) : commit.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Time: ${_formatDate(commit.timestamp)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                  if (commit.taskId != 'merge' && commit.taskId != 'branch') ...[
                    const SizedBox(height: 4),
                    Text(
                      'Task ID: ${commit.taskId.length > 8 ? commit.taskId.substring(0, 8) : commit.taskId}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                const SizedBox(height: 16),
                if (commit.oldState.isNotEmpty || commit.newState.isNotEmpty) ...[
                  const Text(
                    'Change Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 如果是任务创建
                        if (commit.oldState.isEmpty && commit.newState.isNotEmpty) ...[
                          const Text('New Task'),
                          if (commit.newState['title'] != null)
                            Text('Title: ${commit.newState['title']}'),
                          if (commit.newState['description'] != null)
                            Text('Description: ${commit.newState['description']}'),
                        ]
                        // 如果是任务删除
                        else if (commit.oldState.isNotEmpty && commit.newState.isEmpty) ...[
                          const Text('Deleted Task'),
                          if (commit.oldState['title'] != null)
                            Text('Title: ${commit.oldState['title']}'),
                        ]
                        // 如果是任务更新
                        else if (commit.oldState.isNotEmpty && commit.newState.isNotEmpty) ...[
                          const Text('Updated Task'),
                          // 比较标题变化
                          if (commit.oldState['title'] != commit.newState['title']) ...[
                            const Text('Title:'),
                            Text('- ${commit.oldState['title']}', style: const TextStyle(color: Colors.red)),
                            Text('+ ${commit.newState['title']}', style: const TextStyle(color: Colors.green)),
                          ],
                          // 比较描述变化
                          if (commit.oldState['description'] != commit.newState['description']) ...[
                            const Text('Description:'),
                            Text('- ${commit.oldState['description']}', style: const TextStyle(color: Colors.red)),
                            Text('+ ${commit.newState['description']}', style: const TextStyle(color: Colors.green)),
                          ],
                          // 比较状态变化
                          if (commit.oldState['status'] != commit.newState['status']) ...[
                            const Text('Status:'),
                            Text('- ${_getStatusName(TaskStatus.values[commit.oldState['status']])}', 
                                style: const TextStyle(color: Colors.red)),
                            Text('+ ${_getStatusName(TaskStatus.values[commit.newState['status']])}', 
                                style: const TextStyle(color: Colors.green)),
                          ],
                        ]
                        // 如果是分支相关操作
                        else if (commit.taskId == 'branch' || commit.taskId == 'merge') ...[
                          Text(commit.message),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToTaskForm(
    BuildContext context,
    Repository repository,
    Branch branch,
    Task? task,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(
          repository: repository,
          branch: branch,
          task: task,
        ),
      ),
    );
  }

  void _updateTaskStatus(
    Repository repository,
    Branch branch,
    Task task,
    TaskStatus newStatus,
  ) {
    // 创建更新后的任务
    final updatedTask = task.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    
    // 更新任务
    Provider.of<RepositoryProvider>(context, listen: false).updateTask(
      repository.id,
      branch.id,
      updatedTask,
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Repository repository,
    Branch branch,
    Task task,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete task "${task.title}"? This will delete all its history and cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Provider.of<RepositoryProvider>(context, listen: false)
                    .deleteTask(repository.id, branch.id, task.id);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // 辅助方法 - 获取任务的提交记录
  List<Commit> _getTaskCommits(Branch branch, String taskId) {
    return branch.commits
        .where((commit) => commit.taskId == taskId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 按时间降序排序
  }

  // 辅助方法 - 格式化日期
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 辅助方法 - 获取状态颜色
  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  // 辅助方法 - 获取状态名称
  String _getStatusName(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Completed';
    }
  }

  // 辅助方法 - 获取下一个状态
  TaskStatus _getNextStatus(TaskStatus currentStatus) {
    switch (currentStatus) {
      case TaskStatus.todo:
        return TaskStatus.inProgress;
      case TaskStatus.inProgress:
        return TaskStatus.done;
      case TaskStatus.done:
        return TaskStatus.todo;
    }
  }

  // 辅助方法 - 获取下一个状态名称
  String _getNextStatusName(TaskStatus currentStatus) {
    return _getStatusName(_getNextStatus(currentStatus));
  }
}