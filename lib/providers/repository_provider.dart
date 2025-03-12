import 'package:flutter/foundation.dart';
import '../models/repository.dart';
import '../models/branch.dart';
import '../models/task.dart';
import '../services/storage_service.dart';

class RepositoryProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<Repository> _repositories = [];
  bool _isLoading = true;
  
  RepositoryProvider(this._storageService) {
    _loadRepositories();
  }
  
  // Getters
  List<Repository> get repositories => _repositories;
  bool get isLoading => _isLoading;
  
  // 加载所有仓库
  Future<void> _loadRepositories() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _repositories = await _storageService.getRepositories();
    } catch (e) {
      print('Error loading repositories: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // 刷新仓库列表
  Future<void> refreshRepositories() async {
    await _loadRepositories();
  }
  
  // 添加新仓库
  Future<void> addRepository(Repository repository) async {
    try {
      await _storageService.saveRepository(repository);
      _repositories.add(repository);
      notifyListeners();
    } catch (e) {
      print('Error adding repository: $e');
    }
  }
  
  // 更新仓库
  Future<void> updateRepository(Repository repository) async {
    try {
      await _storageService.saveRepository(repository);
      final index = _repositories.indexWhere((r) => r.id == repository.id);
      if (index != -1) {
        _repositories[index] = repository;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating repository: $e');
    }
  }
  
  // 删除仓库
  Future<void> deleteRepository(String repositoryId) async {
    try {
      await _storageService.deleteRepository(repositoryId);
      _repositories.removeWhere((r) => r.id == repositoryId);
      notifyListeners();
    } catch (e) {
      print('Error deleting repository: $e');
    }
  }
  
  // 根据ID获取仓库
  Repository? getRepositoryById(String repositoryId) {
    try {
      return _repositories.firstWhere((r) => r.id == repositoryId);
    } catch (e) {
      return null;
    }
  }
  
  // 添加分支到仓库
  Future<void> addBranch(String repositoryId, Branch branch) async {
    final repository = getRepositoryById(repositoryId);
    if (repository != null) {
      repository.addBranch(branch);
      await updateRepository(repository);
    }
  }
  
  // 删除分支
  Future<void> deleteBranch(String repositoryId, String branchId) async {
    final repository = getRepositoryById(repositoryId);
    if (repository != null) {
      repository.deleteBranch(branchId);
      await updateRepository(repository);
    }
  }
  
  // 在分支中添加任务
  Future<void> addTask(String repositoryId, String branchId, Task task) async {
    final repository = getRepositoryById(repositoryId);
    if (repository != null) {
      final branchIndex = repository.branches.indexWhere((b) => b.id == branchId);
      if (branchIndex != -1) {
        repository.branches[branchIndex].addTask(task);
        await updateRepository(repository);
      }
    }
  }
  
  // 更新任务
  Future<void> updateTask(String repositoryId, String branchId, Task updatedTask) async {
    final repository = getRepositoryById(repositoryId);
    if (repository != null) {
      final branchIndex = repository.branches.indexWhere((b) => b.id == branchId);
      if (branchIndex != -1) {
        repository.branches[branchIndex].updateTask(updatedTask);
        await updateRepository(repository);
      }
    }
  }
  
  // 删除任务
  Future<void> deleteTask(String repositoryId, String branchId, String taskId) async {
    final repository = getRepositoryById(repositoryId);
    if (repository != null) {
      final branchIndex = repository.branches.indexWhere((b) => b.id == branchId);
      if (branchIndex != -1) {
        repository.branches[branchIndex].deleteTask(taskId);
        await updateRepository(repository);
      }
    }
  }
  
  // 合并分支
  Future<void> mergeBranch(
    String repositoryId, 
    String targetBranchId, 
    String sourceBranchId
  ) async {
    final repository = getRepositoryById(repositoryId);
    if (repository != null) {
      final targetBranchIndex = repository.branches.indexWhere(
        (b) => b.id == targetBranchId
      );
      final sourceBranchIndex = repository.branches.indexWhere(
        (b) => b.id == sourceBranchId
      );
      
      if (targetBranchIndex != -1 && sourceBranchIndex != -1) {
        repository.branches[targetBranchIndex].mergeBranch(
          repository.branches[sourceBranchIndex]
        );
        await updateRepository(repository);
      }
    }
  }
}