import 'package:uuid/uuid.dart';
import 'branch.dart';

class Repository {
  final String id;
  String name;
  String description;
  DateTime createdAt;
  String color; // Repository color
  
  // Branch list
  List<Branch> branches;
  
  Repository({
    String? id,
    required this.name,
    this.description = '',
    DateTime? createdAt,
    this.color = '#2196F3', // Default blue color
    List<Branch>? branches,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    branches = branches ?? [] {
    // Ensure that a new repository has at least one main branch
    if (branches == null || branches.isEmpty) {
      this.branches.add(Branch(
        repositoryId: this.id,
        name: 'main',
        description: 'Main branch',
        isMain: true,
      ));
    }
  }
  
  // Convert repository to a storable Map
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
  
  // Create repository from Map
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
  
  // Get main branch
  Branch getMainBranch() {
    return branches.firstWhere(
      (branch) => branch.isMain,
      orElse: () => branches.first,
    );
  }
  
  // Add branch
  void addBranch(Branch branch) {
    branches.add(branch);
  }
  
  // Delete branch
  void deleteBranch(String branchId) {
    branches.removeWhere((branch) => branch.id == branchId && !branch.isMain);
  }
}