import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repository.dart';
import '../models/branch.dart';
import '../models/task.dart';
import '../providers/repository_provider.dart';
import '../utils/constants.dart';

class TaskFormScreen extends StatefulWidget {
  final Repository repository;
  final Branch branch;
  final Task? task; // If null, then creating a new task

  const TaskFormScreen({
    Key? key,
    required this.repository,
    required this.branch,
    this.task,
  }) : super(key: key);

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskStatus _status = TaskStatus.todo;
  
  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Edit mode, initialize form data
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _status = widget.task!.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Create Task'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: 'Delete Task',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'Enter Task Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Task Description',
                hintText: 'Enter Task Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            
            // Task Status
            Text(
              'Task Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TaskStatus.values.map((status) {
                return ChoiceChip(
                  label: Text(AppConstants.taskStatusNames[status.index] ?? ''),
                  selected: _status == status,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _status = status;
                      });
                    }
                  },
                  backgroundColor: AppConstants.taskStatusColors[status.index]?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                  selectedColor: AppConstants.taskStatusColors[status.index]?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: _status == status
                        ? AppConstants.taskStatusColors[status.index]
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: _status == status ? FontWeight.bold : null,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            
            // Save Button
            FilledButton(
              onPressed: _saveTask,
              child: Text(_isEditing ? 'Save Changes' : 'Create Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isEditing) {
        // Update task
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          updatedAt: DateTime.now(),
        );
        
        Provider.of<RepositoryProvider>(context, listen: false).updateTask(
          widget.repository.id,
          widget.branch.id,
          updatedTask,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated')),
        );
      } else {
        // Create new task
        final newTask = Task(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
        );
        
        Provider.of<RepositoryProvider>(context, listen: false).addTask(
          widget.repository.id,
          widget.branch.id,
          newTask,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created')),
        );
      }
      
      Navigator.pop(context);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete task "${widget.task?.title}"? This will delete all its history and cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                
                if (widget.task != null) {
                  Provider.of<RepositoryProvider>(context, listen: false).deleteTask(
                    widget.repository.id,
                    widget.branch.id,
                    widget.task!.id,
                  );
                  
                  Navigator.pop(context); // Go back to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task deleted')),
                  );
                }
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