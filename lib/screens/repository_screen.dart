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
            // Repository has been deleted
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
                    child: const Text('Back'),
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
                    'No branches',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button at the bottom right to create a new branch',
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
              title: const Text('Create New Branch'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Branch Name',
                        hintText: 'Enter branch name',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter branch description (optional)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Parent Branch',
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
                  child: const Text('Cancel'),
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
                            message: 'Created branch: ${nameController.text.trim()} (from ${parentBranch.name})',
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
                  child: const Text('Create'),
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
          title: const Text('Edit Branch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Branch Name',
                    hintText: 'Enter branch name',
                  ),
                  autofocus: true,
                  enabled: !branch.isMain, // 主分支不能修改名称
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter branch description (optional)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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
                        message: 'Updated branch: ${branch.isMain ? branch.name : nameController.text.trim()}',
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
              child: const Text('Save'),
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
          title: const Text('Delete Branch'),
          content: Text('Are you sure you want to delete branch "${branch.name}"? This will remove all its tasks and cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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
              child: const Text('Delete'),
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
          content: Text('No available target branch for merging'),
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
              title: Text('Merge Branch: ${sourceBranch.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select target branch:'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: targetBranchId,
                      items: targetBranches
                          .map((branch) => DropdownMenuItem(
                                value: branch.id,
                                child: Text(branch.name + (branch.isMain ? ' (Main branch)' : '')),
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
                      'After merging, the target branch will contain all tasks from the source branch with conflicts resolved to the latest updates.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (targetBranchId.isNotEmpty) {
                      Provider.of<RepositoryProvider>(context, listen: false)
                          .mergeBranch(repository.id, targetBranchId, sourceBranch.id);
                      
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully merged branch ${sourceBranch.name} into ${
                            repository.branches.firstWhere((b) => b.id == targetBranchId).name
                          }'),
                        ),
                      );
                    }
                  },
                  child: const Text('Merge'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}