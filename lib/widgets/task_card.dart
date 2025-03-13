import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/constants.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final Function(TaskStatus)? onStatusChange;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTap,
    this.onStatusChange,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  if (onStatusChange != null)
                    GestureDetector(
                      onTap: () {
                        final nextStatus = _getNextStatus(task.status);
                        onStatusChange!(nextStatus);
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppConstants.taskStatusColors[task.status.index],
                          shape: BoxShape.circle,
                        ),
                        child: task.status == TaskStatus.done
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: task.status == TaskStatus.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.taskStatusColors[task.status.index]
                          ?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppConstants.taskStatusNames[task.status.index]!,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppConstants.taskStatusColors[task.status.index],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit Task',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete Task',
                    ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created on: ${DateFormat('yyyy-MM-dd').format(task.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (task.updatedAt != null)
                    Text(
                      'Last updated: ${DateFormat('yyyy-MM-dd').format(task.updatedAt!)}',
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

  // Get the next status
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
}