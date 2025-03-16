import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repository.dart';
import '../providers/repository_provider.dart';
import '../utils/constants.dart';
import '../widgets/repository_card.dart';
import 'repository_screen.dart';
import 'settings_screen.dart';

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
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 160,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Git-Inspired Task Management',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.folder_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Repositories'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.settings_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                showAboutDialog(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: '1.0.1',
                  applicationLegalese: '©2025 GitTask',
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'GitTask is a task management app that implements Git concepts for better task tracking and management.',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
                    'No repositories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the floating button to create a new repository',
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
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _showAddRepositoryDialog(context),
        elevation: 3,
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

  // Rest of the existing methods remain unchanged...
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
              title: const Text('Create New Repository'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Repository Name',
                        hintText: 'Enter repository name',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter repository description (optional)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Color'),
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
                  child: const Text('Cancel'),
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
                  child: const Text('Create'),
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
              title: const Text('Edit Repository'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Repository Name',
                        hintText: 'Enter repository name',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter repository description (optional)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Color'),
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
                  child: const Text('Cancel'),
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
                  child: const Text('Save'),
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
          title: const Text('Delete Repository'),
          content: Text('Are you sure you want to delete the repository "${repository.name}"? This will delete all related branches and tasks and cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}