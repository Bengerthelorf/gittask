import 'package:uuid/uuid.dart';
import 'branch.dart';

class Repository {
  final String id;
  String name;
  String description;
  DateTime createdAt;
  String color; // 仓库颜色
  
  // 分支列表
  List<Branch> branches;
  
  Repository({
    String? id,
    required this.name,
    this.description = '',
    DateTime? createdAt,
    this.color = '#2196F3', // 默认蓝色
    List<Branch>? branches,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    branches = branches ?? [] {
    // 确保新仓库至少有一个主分支
    if (branches == null || branches.isEmpty) {
      this.branches.add(Branch(
        repositoryId: this.id,
        name: 'main',
        description: '主分支',
        isMain: true,
      ));
    }
  }
  
  // 将仓库转换为可存储的Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'color': color,
      'branches': branches.map((branch) => branch.toMap()).toList(),
    };
  }
  
  // 从Map创建仓库
  factory Repository.fromMap(Map<String, dynamic> map) {
    return Repository(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      color: map['color'] ?? '#2196F3',
      branches: (map['branches'] as List?)
          ?.map((branchMap) => Branch.fromMap(Map<String, dynamic>.from(branchMap)))
          .toList() ?? [],
    );
  }
  
  // 获取主分支
  Branch getMainBranch() {
    return branches.firstWhere(
      (branch) => branch.isMain,
      orElse: () => branches.first,
    );
  }
  
  // 添加分支
  void addBranch(Branch branch) {
    branches.add(branch);
  }
  
  // 删除分支
  void deleteBranch(String branchId) {
    branches.removeWhere((branch) => branch.id == branchId && !branch.isMain);
  }
}