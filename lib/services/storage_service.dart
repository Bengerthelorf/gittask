import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/repository.dart';

class StorageService {
  static const String _repositoriesBoxName = 'repositories';
  late Box<String> _repositoriesBox;
  
  // 初始化Hive并打开box
  Future<void> init() async {
    await Hive.initFlutter();
    _repositoriesBox = await Hive.openBox<String>(_repositoriesBoxName);
  }
  
  // 获取所有仓库
  Future<List<Repository>> getRepositories() async {
    final List<Repository> repositories = [];
    
    for (final key in _repositoriesBox.keys) {
      final String? repoJson = _repositoriesBox.get(key);
      if (repoJson != null) {
        try {
          final Map<String, dynamic> repoMap = jsonDecode(repoJson);
          repositories.add(Repository.fromMap(repoMap));
        } catch (e) {
          print('Error loading repository: $e');
        }
      }
    }
    
    return repositories;
  }
  
  // 保存仓库
  Future<void> saveRepository(Repository repository) async {
    final String repoJson = jsonEncode(repository.toMap());
    await _repositoriesBox.put(repository.id, repoJson);
  }
  
  // 删除仓库
  Future<void> deleteRepository(String repositoryId) async {
    await _repositoriesBox.delete(repositoryId);
  }
  
  // 根据ID获取仓库
  Future<Repository?> getRepository(String repositoryId) async {
    final String? repoJson = _repositoriesBox.get(repositoryId);
    if (repoJson != null) {
      try {
        final Map<String, dynamic> repoMap = jsonDecode(repoJson);
        return Repository.fromMap(repoMap);
      } catch (e) {
        print('Error loading repository: $e');
        return null;
      }
    }
    return null;
  }
}