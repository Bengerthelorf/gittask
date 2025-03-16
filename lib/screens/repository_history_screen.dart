import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repository.dart';
import '../models/commit.dart';
// import '../models/task.dart';
import '../providers/repository_provider.dart';
import '../widgets/repository_git_graph.dart';

/// 仓库历史屏幕 - 展示仓库级别的Git图表
class RepositoryHistoryScreen extends StatelessWidget {
  final Repository repository;

  const RepositoryHistoryScreen({
    Key? key,
    required this.repository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RepositoryProvider>(
      builder: (context, repositoryProvider, child) {
        // 获取最新的仓库数据
        final updatedRepository = repositoryProvider.getRepositoryById(repository.id);
        
        if (updatedRepository == null) {
          // 仓库已被删除
          return Scaffold(
            appBar: AppBar(
              title: const Text('Git History'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
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
            ),
          );
        }

        return RepositoryGitGraph(
          repository: updatedRepository,
          onCommitTap: (commit) => _showCommitDetails(context, commit),
        );
      },
    );
  }

  void _showCommitDetails(BuildContext context, Commit commit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
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
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 任务创建
                        if (commit.oldState.isEmpty && commit.newState.isNotEmpty) ...[
                          const Text('New Task'),
                          if (commit.newState['title'] != null)
                            Text('Title: ${commit.newState['title']}'),
                          if (commit.newState['description'] != null)
                            Text('Description: ${commit.newState['description']}'),
                        ]
                        // 任务删除
                        else if (commit.oldState.isNotEmpty && commit.newState.isEmpty) ...[
                          const Text('Deleted Task'),
                          if (commit.oldState['title'] != null)
                            Text('Title: ${commit.oldState['title']}'),
                        ]
                        // 任务更新
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
                          if (commit.oldState['status'] != commit.newState['status'] &&
                              commit.oldState['status'] != null &&
                              commit.newState['status'] != null) ...[
                            const Text('Status:'),
                            Text('- ${_getStatusName(commit.oldState['status'])}', 
                                style: const TextStyle(color: Colors.red)),
                            Text('+ ${_getStatusName(commit.newState['status'])}', 
                                style: const TextStyle(color: Colors.green)),
                          ],
                        ]
                        // 分支相关操作
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
  
  // 格式化日期
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  // 获取任务状态名称
  String _getStatusName(int statusIndex) {
    switch (statusIndex) {
      case 0:
        return 'To Do';
      case 1:
        return 'In Progress';
      case 2:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }
}