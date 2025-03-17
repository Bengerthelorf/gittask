import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/branch.dart';
import '../models/commit.dart';

class GitGraph extends StatelessWidget {
  final Branch branch;
  final Function(Commit)? onCommitTap;
  final double itemHeight = 160.0;

  const GitGraph({
    Key? key,
    required this.branch,
    this.onCommitTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 按时间降序排序提交记录
    final commits = List<Commit>.from(branch.commits)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (commits.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No commit records', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    // 分析分支归属
    final branchAnalyzer = BranchAnalyzer(commits);
    final totalHeight = commits.length * itemHeight;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          // 静态绘制所有节点和连接线
          Positioned.fill(
            child: CustomPaint(
              painter: GitGraphPainter(
                commits: commits,
                branchAnalyzer: branchAnalyzer,
                itemHeight: itemHeight,
              ),
            ),
          ),
          
          // 图标绘制层
          Positioned.fill(
            child: Stack(
              children: List.generate(commits.length, (index) {
                final commit = commits[index];
                final branchName = branchAnalyzer.getCommitBranch(commit.id);
                final color = branchAnalyzer.getBranchColor(branchName);
                // 确定图标类型
                final IconData iconData = _getCommitIcon(commit);
                
                return Positioned(
                  left: 30 - 12, // 中心点调整为图标中心
                  top: itemHeight * index + 26 - 12, // 调整为图标中心点
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // 提交信息列表
          Positioned.fill(
            child: Column(
              children: List.generate(commits.length, (index) {
                final commit = commits[index];
                final branchName = branchAnalyzer.getCommitBranch(commit.id);
                final color = branchAnalyzer.getBranchColor(branchName);
                
                return InkWell(
                  onTap: onCommitTap != null ? () => onCommitTap!(commit) : null,
                  child: SizedBox(
                    height: itemHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左侧留空，由CustomPaint绘制节点
                        const SizedBox(width: 60),
                        // 右侧提交信息
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                            child: _buildCommitInfo(context, commit, branchAnalyzer, color),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  // 根据提交类型确定图标
  IconData _getCommitIcon(Commit commit) {
    if (commit.message.contains('Created branch:')) {
      return Icons.call_split_rounded; // Create branch icon
    } else if (commit.message.contains('Merge branch:')) {
      return Icons.call_merge_rounded; // Merge branch icon
    } else if (commit.message.contains('Create task:')) {
      return Icons.add_circle_outline_rounded; // Create task icon
    } else if (commit.message.contains('Update task:')) {
      return Icons.edit_rounded; // Update task icon
    } else if (commit.message.contains('Delete task:')) {
      return Icons.delete_outline_rounded; // Delete task icon
    } else {
      return Icons.commit_rounded; // Default commit icon
    }
  }
  
  // 构建提交信息 - 修复溢出问题
  Widget _buildCommitInfo(BuildContext context, Commit commit, BranchAnalyzer analyzer, Color color) {
    final isMerge = analyzer.isMergeCommit(commit);
    // final isCreateBranch = analyzer.isCreateBranchCommit(commit);
    String displayBranch = analyzer.getCommitBranch(commit.id);
    
    // 如果是合并提交，显示合并信息
    if (isMerge) {
      final sourceBranch = analyzer.getMergeSourceBranch(commit);
      if (sourceBranch != null) {
        displayBranch = '$sourceBranch -> $displayBranch';
      }
    }
    
    // 使用Expanded和SingleChildScrollView确保不会溢出
    return SizedBox(
      height: itemHeight - 16, // 减去上下内边距
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题部分 - 固定显示
          Text(
            commit.message,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('yyyy-MM-dd HH:mm').format(commit.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          
          // 详细信息部分 - 可滚动
          Expanded(
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, right: 16, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Commit ID: ',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              commit.id.length > 8 ? commit.id.substring(0, 8) : commit.id,
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontFamily: 'monospace',
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (commit.taskId != 'Merge' && commit.taskId != 'branch') ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Task ID: ',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                commit.taskId.length > 8 
                                    ? commit.taskId.substring(0, 8) 
                                    : commit.taskId,
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontFamily: 'monospace',
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // 显示分支标签
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCommitIcon(commit),
                              size: 16,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                displayBranch,
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 自定义绘制GitGraph连接线
class GitGraphPainter extends CustomPainter {
  final List<Commit> commits;
  final BranchAnalyzer branchAnalyzer;
  final double itemHeight;
  
  GitGraphPainter({
    required this.commits,
    required this.branchAnalyzer,
    required this.itemHeight,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    const double nodeSize = 24.0; // 节点大小
    const double nodeRadius = nodeSize / 2;
    const double lineWidth = 2.0; // 线宽
    const double nodeCenterX = 30.0; // 节点中心X坐标
    
    for (int i = 0; i < commits.length; i++) {
      final commit = commits[i];
      final branchName = branchAnalyzer.getCommitBranch(commit.id);
      final color = branchAnalyzer.getBranchColor(branchName);
      
      // 节点的Y坐标
      final double nodeCenterY = itemHeight * i + 26;
      
      // 如果不是最后一个提交，绘制连接线
      if (i < commits.length - 1) {
        // final nextCommit = commits[i + 1];
        // final nextBranchName = branchAnalyzer.getCommitBranch(nextCommit.id);
        // final nextColor = branchAnalyzer.getBranchColor(nextBranchName);
        
        final Paint linePaint = Paint()
          ..color = color
          ..strokeWidth = lineWidth
          ..style = PaintingStyle.stroke;
        
        // 连接线从当前节点底部到下一个节点顶部
        final double lineStartY = nodeCenterY + nodeRadius;
        final double lineEndY = itemHeight * (i + 1) + 26 - nodeRadius;
        
        final path = Path()
          ..moveTo(nodeCenterX, lineStartY)
          ..lineTo(nodeCenterX, lineEndY);
        
        canvas.drawPath(path, linePaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 分支分析器 - 负责跟踪分支创建、合并和颜色分配
class BranchAnalyzer {
  final List<Commit> commits;
  final Map<String, String> commitBranches = {}; // 提交ID -> 分支名
  final Map<String, Color> branchColors = {}; // 分支名 -> 颜色
  final Map<String, String> mergeSourceBranches = {}; // 合并提交ID -> 源分支名
  
  BranchAnalyzer(List<Commit> originalCommits) : 
    // 创建一个副本并按时间正序排列
    commits = List<Commit>.from(originalCommits)..sort((a, b) => a.timestamp.compareTo(b.timestamp)) {
    _analyzeBranchStructure();
    _assignBranchColors();
  }
  
  // 分析分支结构
  void _analyzeBranchStructure() {
    String currentBranch = 'main';
    final activeBranches = <String>{'main'};
    
    // 遍历所有提交按时间正序
    for (final commit in commits) {
      // 检测创建分支
      if (isCreateBranchCommit(commit)) {
        final newBranch = extractBranchName(commit);
        if (newBranch != null && newBranch.isNotEmpty) {
          currentBranch = newBranch;
          activeBranches.add(newBranch);
        }
      }
      // 检测合并分支
      else if (isMergeCommit(commit)) {
        final mergeInfo = extractMergeInfo(commit);
        if (mergeInfo != null) {
          final sourceBranch = mergeInfo['source'];
          final targetBranch = mergeInfo['target'];
          
          if (sourceBranch != null && targetBranch != null) {
            mergeSourceBranches[commit.id] = sourceBranch;
            currentBranch = targetBranch;
            // 合并后源分支可能不再活跃
            activeBranches.remove(sourceBranch);
          }
        }
      }
      
      // 记录当前提交所属的分支
      commitBranches[commit.id] = currentBranch;
    }
  }
  
  // 为每个分支分配唯一颜色
  void _assignBranchColors() {
    // 收集所有唯一的分支名
    final uniqueBranches = commitBranches.values.toSet();
    
    // 从Material Design 3调色板中选择颜色
    final colors = [
      const Color(0xFF2196F3), // Blue - main分支
      const Color(0xFF4CAF50), // Green
      const Color(0xFFF44336), // Red
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF9800), // Orange
      const Color(0xFF009688), // Teal
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF795548), // Brown
    ];
    
    // 首先为main分支分配蓝色
    branchColors['main'] = colors[0];
    
    // 为其他分支分配颜色
    int colorIndex = 1;
    for (final branch in uniqueBranches) {
      if (branch != 'main' && !branchColors.containsKey(branch)) {
        branchColors[branch] = colors[colorIndex % colors.length];
        colorIndex++;
      }
    }
  }
  
  // 获取提交所属的分支
  String getCommitBranch(String commitId) {
    return commitBranches[commitId] ?? 'main';
  }
  
  // 获取分支的颜色
  Color getBranchColor(String branchName) {
    return branchColors[branchName] ?? const Color(0xFF2196F3); // 默认蓝色
  }
  
  // 获取合并提交的源分支
  String? getMergeSourceBranch(Commit commit) {
    return mergeSourceBranches[commit.id];
  }
  
  // 判断是否是创建分支的提交
  bool isCreateBranchCommit(Commit commit) {
    return commit.message.contains('Created branch:');
  }
  
  // 判断是否是合并提交
  bool isMergeCommit(Commit commit) {
    return commit.message.contains('Merge branch:');
  }
  
  // 从提交信息中提取分支名
  String? extractBranchName(Commit commit) {
    final match = RegExp(r'Created branch: (.*?)(?: \(|$)').firstMatch(commit.message);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }
  
  // 从合并提交信息中提取源分支和目标分支
  Map<String, String>? extractMergeInfo(Commit commit) {
    final match = RegExp(r'Merge branch: (.*?) -> (.*)').firstMatch(commit.message);
    if (match != null && match.groupCount >= 2) {
      return {
        'source': match.group(1)?.trim() ?? '',
        'target': match.group(2)?.trim() ?? ''
      };
    }
    return null;
  }
}