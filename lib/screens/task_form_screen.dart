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
  final Task? task; // 如果为null，则是创建新任务

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
      // 编辑模式，初始化表单数据
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
        title: Text(_isEditing ? '编辑任务' : '创建任务'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: '删除任务',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 标题
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '任务标题',
                hintText: '输入任务标题',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入任务标题';
                }
                return null;
              },
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 16),
            
            // 描述
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '任务描述',
                hintText: '输入任务描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            
            // 状态选择
            Text(
              '任务状态',
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
            
            // 保存按钮
            FilledButton(
              onPressed: _saveTask,
              child: Text(_isEditing ? '保存更改' : '创建任务'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isEditing) {
        // 更新任务
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
          const SnackBar(content: Text('任务已更新')),
        );
      } else {
        // 创建新任务
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
          const SnackBar(content: Text('任务已创建')),
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
          title: const Text('删除任务'),
          content: Text('确定要删除任务"${widget.task?.title}"吗？这将删除该任务的所有历史记录，且无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // 关闭对话框
                
                if (widget.task != null) {
                  Provider.of<RepositoryProvider>(context, listen: false).deleteTask(
                    widget.repository.id,
                    widget.branch.id,
                    widget.task!.id,
                  );
                  
                  Navigator.pop(context); // 返回上一页
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('任务已删除')),
                  );
                }
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