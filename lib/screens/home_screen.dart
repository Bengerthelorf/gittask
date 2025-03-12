import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repository.dart';
import '../providers/repository_provider.dart';
import '../utils/constants.dart';
import '../widgets/repository_card.dart';
import 'repository_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
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
          if (repositoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (repositoryProvider.repositories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '没有任务仓库',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角的按钮创建一个新的仓库',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: repositoryProvider.repositories.length,
            itemBuilder: (context, index) {
              final repository = repositoryProvider.repositories[index];
              return RepositoryCard(
                repository: repository,
                onTap: () => _navigateToRepositoryScreen(context, repository),
                onEdit: () => _showEditRepositoryDialog(context, repository),
                onDelete: () => _showDeleteConfirmation(context, repository),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRepositoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToRepositoryScreen(BuildContext context, Repository repository) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepositoryScreen(repository: repository),
      ),
    );
  }

  void _showAddRepositoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedColor = AppConstants.colorOptions[0].value.toRadixString(16);
    selectedColor = '#${selectedColor.substring(2)}';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('创建新仓库'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '仓库名称',
                        hintText: '输入仓库名称',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: '描述',
                        hintText: '输入仓库描述（可选）',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    const Text('选择颜色'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.colorOptions
                          .map((color) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = '#${color.value.toRadixString(16).substring(2)}';
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == '#${color.value.toRadixString(16).substring(2)}'
                                          ? Colors.black
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
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
                      final newRepository = Repository(
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        color: selectedColor,
                      );
                      
                      Provider.of<RepositoryProvider>(context, listen: false)
                          .addRepository(newRepository);
                      
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

  void _showEditRepositoryDialog(BuildContext context, Repository repository) {
    final nameController = TextEditingController(text: repository.name);
    final descriptionController = TextEditingController(text: repository.description);
    String selectedColor = repository.color;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('编辑仓库'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '仓库名称',
                        hintText: '输入仓库名称',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: '描述',
                        hintText: '输入仓库描述（可选）',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    const Text('选择颜色'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.colorOptions
                          .map((color) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = '#${color.value.toRadixString(16).substring(2)}';
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == '#${color.value.toRadixString(16).substring(2)}'
                                          ? Colors.black
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
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
                      final updatedRepository = Repository(
                        id: repository.id,
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        color: selectedColor,
                        createdAt: repository.createdAt,
                        branches: repository.branches,
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
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Repository repository) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除仓库'),
          content: Text('确定要删除仓库"${repository.name}"吗？这将删除所有相关的分支和任务，且无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Provider.of<RepositoryProvider>(context, listen: false)
                    .deleteRepository(repository.id);
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
}