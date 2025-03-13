import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/branch.dart';
import '../models/task.dart';
// import '../utils/constants.dart';

class BranchCard extends StatelessWidget {
  final Branch branch;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMerge;

  const BranchCard({
    Key? key,
    required this.branch,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onMerge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate task statistics
    final int totalTasks = branch.tasks.length;
    final int completedTasks = branch.tasks
        .where((task) => task.status == TaskStatus.done)
        .length;
    final double progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    color: branch.isMain
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      branch.name + (branch.isMain ? ' (Main Branch)' : ''),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (onMerge != null && !branch.isMain)
                    IconButton(
                      icon: const Icon(Icons.merge_type, size: 20),
                      onPressed: onMerge,
                      tooltip: 'Merge Branch',
                    ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit Branch',
                    ),
                  if (onDelete != null && !branch.isMain)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete Branch',
                    ),
                ],
              ),
              if (branch.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  branch.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Progress: $completedTasks/$totalTasks',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Created on: ${DateFormat('MM-dd').format(branch.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}