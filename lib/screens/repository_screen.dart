import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repository.dart';
import '../models/branch.dart';
import '../models/commit.dart';
import '../providers/repository_provider.dart';
import '../widgets/branch_card.dart';
import 'branch_screen.dart';

class RepositoryScreen extends StatelessWidget {
  final Repository repository;

  const RepositoryScreen({Key? key, required this.repository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(repository.name),
        actions: [
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
          final updatedRepository = repositoryProvider.getRepositoryById(repository.id);
          if (updatedRepository == null) {
            // 仓库已被删除
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '仓库不存在',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回'),
                  ),
                ],
              ),
            );
          }

          if (updatedRepository.branches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '没有分支',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角的按钮创建一个新的分支',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: updatedRepository.branches.length,
            itemBuilder: (context, index) {
              final branch = updatedRepository.branches[index];
              return BranchCard(
                branch: branch,
                onTap: () => _navigateToBranchScreen(context, updatedRepository, branch),
                onEdit: () => _showEditBranchDialog(context, updatedRepository, branch),
                onDelete: branch.isMain
                    ? null
                    : () => _showDeleteConfirmation(context, updatedRepository, branch),
                onMerge: branch.isMain
                    ? null
                    : () => _showMergeDialog(context, updatedRepository, branch),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBranchDialog(context, repository),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToBranchScreen(
      BuildContext context, Repository repository, Branch branch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BranchScreen(
          repository: repository,
          branch: branch,
        ),
      ),
    );
  }

  void _showAddBranchDialog(BuildContext context, Repository repository) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? parentBranchId = repository.getMainBranch().id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('创建新分支'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '分支名称',
                        hintText: '输入分支名称',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: '描述',
                        hintText: '输入分支描述（可选）',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: '从哪个分支创建',
                      ),
                      value: parentBranchId,
                      items: repository.branches
                          .map((branch) => DropdownMenuItem(
                                value: branch.id,
                                child: Text(branch.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          parentBranchId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      // 获取父分支
                      final parentBranch = repository.branches.firstWhere(
                        (b) => b.id == parentBranchId,
                        orElse: () => repository.getMainBranch(),
                      );
                      
                      // 创建新分支，复制父分支的任务
                      final newBranch = Branch(
                        repositoryId: repository.id,
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        parentBranchId: parentBranch.id,
                        // 复制父分支的任务和提交记录
                        tasks: List.from(parentBranch.tasks),
                        commits: [
                          ...List.from(parentBranch.commits),
                          // 添加分支创建的提交记录
                          Commit(
                            taskId: 'branch',
                            message: '创建分支: ${nameController.text.trim()} (从 ${parentBranch.name})',
                            oldState: {'parentBranchId': parentBranch.id},
                            newState: {},
                          ),
                        ],
                      );
                      
                      Provider.of<RepositoryProvider>(context, listen: false)
                          .addBranch(repository.id, newBranch);
                      
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('创建'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditBranchDialog(
      BuildContext context, Repository repository, Branch branch) {
    final nameController = TextEditingController(text: branch.name);
    final descriptionController = TextEditingController(text: branch.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑分支'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '分支名称',
                    hintText: '输入分支名称',
                  ),
                  autofocus: true,
                  enabled: !branch.isMain, // 主分支不能修改名称
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '描述',
                    hintText: '输入分支描述（可选）',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty || branch.isMain) {
                  // 创建更新后的分支
                  final updatedBranch = Branch(
                    id: branch.id,
                    repositoryId: repository.id,
                    name: branch.isMain ? branch.name : nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    createdAt: branch.createdAt,
                    isMain: branch.isMain,
                    parentBranchId: branch.parentBranchId,
                    tasks: branch.tasks,
                    commits: [
                      ...branch.commits,
                      // 添加分支更新的提交记录
                      Commit(
                        taskId: 'branch',
                        message: '更新分支: ${branch.isMain ? branch.name : nameController.text.trim()}',
                        oldState: {
                          'name': branch.name,
                          'description': branch.description,
                        },
                        newState: {
                          'name': branch.isMain ? branch.name : nameController.text.trim(),
                          'description': descriptionController.text.trim(),
                        },
                      ),
                    ],
                  );
                  
                  // 更新仓库中的分支
                  final updatedRepository = Repository(
                    id: repository.id,
                    name: repository.name,
                    description: repository.description,
                    createdAt: repository.createdAt,
                    color: repository.color,
                    branches: repository.branches.map((b) {
                      return b.id == branch.id ? updatedBranch : b;
                    }).toList(),
                  );
                  
                  Provider.of<RepositoryProvider>(context, listen: false)
                      .updateRepository(updatedRepository);
                  
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, Repository repository, Branch branch) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除分支'),
          content: Text('确定要删除分支"${branch.name}"吗？这将删除该分支的所有任务，且无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Provider.of<RepositoryProvider>(context, listen: false)
                    .deleteBranch(repository.id, branch.id);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _showMergeDialog(
      BuildContext context, Repository repository, Branch sourceBranch) {
    // 获取可以合并到的目标分支（不包括当前分支）
    final targetBranches = repository.branches
        .where((b) => b.id != sourceBranch.id)
        .toList();
    
    String targetBranchId = targetBranches.isNotEmpty 
        ? targetBranches.first.id 
        : '';
    
    if (targetBranches.isEmpty) {
      // 没有可合并的目标分支
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有可合并的目标分支'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('合并分支: ${sourceBranch.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('选择要合并到的目标分支:'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: targetBranchId,
                      items: targetBranches
                          .map((branch) => DropdownMenuItem(
                                value: branch.id,
                                child: Text(branch.name + (branch.isMain ? ' (主分支)' : '')),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          targetBranchId = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '合并后，目标分支将包含源分支的所有任务，冲突的任务将以最新更新的版本为准。',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    if (targetBranchId.isNotEmpty) {
                      Provider.of<RepositoryProvider>(context, listen: false)
                          .mergeBranch(repository.id, targetBranchId, sourceBranch.id);
                      
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('成功合并分支 ${sourceBranch.name} 到 ${
                            repository.branches.firstWhere((b) => b.id == targetBranchId).name
                          }'),
                        ),
                      );
                    }
                  },
                  child: const Text('合并'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}