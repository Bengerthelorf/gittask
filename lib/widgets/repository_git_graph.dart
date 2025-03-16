import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/repository.dart';
// import '../models/branch.dart';
import '../models/commit.dart';

/// 仓库级别的Git图表组件
/// 展示所有分支的提交历史，以及它们之间的关系
class RepositoryGitGraph extends StatefulWidget {
  final Repository repository;
  final Function(Commit)? onCommitTap;

  const RepositoryGitGraph({
    Key? key,
    required this.repository,
    this.onCommitTap,
  }) : super(key: key);

  @override
  State<RepositoryGitGraph> createState() => _RepositoryGitGraphState();
}

class _RepositoryGitGraphState extends State<RepositoryGitGraph> {
  /// 所有提交记录，按时间戳排序
  List<Commit> _allCommits = [];
  
  /// 分支信息映射: branch name -> branch info
  Map<String, BranchInfo> _branchInfoMap = {};
  
  /// 提交到分支的映射: commit id -> branch name
  Map<String, String> _commitBranchMap = {};
  
  /// 分支创建和合并的关系
  Map<String, Map<String, dynamic>> _branchRelations = {};
  
  /// 是否正在加载数据
  bool _isLoading = true;
  
  /// 错误消息，如果有的话
  String? _errorMessage;
  
  /// 常量
  static const double _rowHeight = 72.0;     // 每行的高度
  static const double _nodeRadius = 11.0;    // 节点半径
  static const double _leftPadding = 50.0;   // 左侧边距
  static const double _branchGap = 30.0;     // 分支之间的间距
  static const double _textCardPadding = 20.0; // 文本卡片与最右侧分支的间距
  
  /// 在同一合并点显示的源分支和目标分支
  Map<String, Set<String>> _mergePointBranches = {};

  /// 计算文本卡片的左侧位置，基于最右侧分支
  double _getTextLeftPosition() {
    double rightmostPosition = _leftPadding; // 初始化为最左侧分支的位置
    
    // 查找最右侧的分支位置
    for (final info in _branchInfoMap.values) {
      if (info.xPosition > rightmostPosition) {
        rightmostPosition = info.xPosition;
      }
    }
    
    // 返回最右侧分支位置加上额外间距
    return rightmostPosition + _nodeRadius * 2 + _textCardPadding;
  }

  @override
  void initState() {
    super.initState();
    _processRepositoryData();
  }
  
  @override
  void didUpdateWidget(RepositoryGitGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository.id != widget.repository.id) {
      _processRepositoryData();
    }
  }
  
  /// 处理仓库数据，准备绘制Git图
  void _processRepositoryData() {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // 第一步：收集所有提交，并创建一个提交ID到对象的映射
      final Map<String, Commit> commitMap = {};
      
      // 从每个分支收集提交
      for (final branch in widget.repository.branches) {
        for (final commit in branch.commits) {
          commitMap[commit.id] = commit;
        }
      }
      
      // 第二步：按时间戳排序所有提交
      final sortedCommits = commitMap.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 最新的排在前面
      
      // 防止后续可能的空列表引起的错误
      if (sortedCommits.isEmpty) {
        setState(() {
          _allCommits = [];
          _isLoading = false;
        });
        return;
      }
      
      _allCommits = sortedCommits;
      
      // 第三步：分析分支信息和提交关系
      _analyzeBranchStructure();
      
      // 第四步：分析合并点上的所有相关分支
      _analyzeMergePoints();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error processing repository data: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to process repository data: $e';
        _isLoading = false;
      });
    }
  }
  
  /// 分析合并点上显示的所有分支
  void _analyzeMergePoints() {
    _mergePointBranches = {};
    
    for (final entry in _branchRelations.entries) {
      final commitId = entry.key;
      final relation = entry.value;
      
      if (relation['type'] == 'merge') {
        final sourceId = relation['source'] as String;
        final targetId = relation['target'] as String;
        
        if (!_mergePointBranches.containsKey(commitId)) {
          _mergePointBranches[commitId] = {};
        }
        
        // 在合并点上，源分支和目标分支都应该有节点
        _mergePointBranches[commitId]!.add(sourceId);
        _mergePointBranches[commitId]!.add(targetId);
      }
    }
  }
  
  /// 分析分支结构，确定每个分支的位置和提交归属
  void _analyzeBranchStructure() {
    // 重置数据
    _branchInfoMap = {};
    _commitBranchMap = {};
    _branchRelations = {};
    
    // 收集所有分支及其父分支关系
    final List<String> branchNames = [];
    final Map<String, String> branchParents = {}; // 分支名 -> 父分支名
    
    for (final branch in widget.repository.branches) {
      branchNames.add(branch.name);
      
      // 记录分支的父分支关系
      if (branch.parentBranchId != null) {
        // 查找父分支名称
        for (final parentBranch in widget.repository.branches) {
          if (parentBranch.id == branch.parentBranchId) {
            branchParents[branch.name] = parentBranch.name;
            break;
          }
        }
      }
    }
    
    // 如果没有分支，早期返回
    if (branchNames.isEmpty) {
      return;
    }
    
    // 确保main分支在最左侧
    if (branchNames.contains('main')) {
      branchNames.remove('main');
      branchNames.insert(0, 'main');
    }
    
    // 为每个分支分配一个X坐标
    double xPosition = _leftPadding;
    
    for (final branchName in branchNames) {
      _branchInfoMap[branchName] = BranchInfo(
        name: branchName,
        xPosition: xPosition,
        color: _getBranchColor(branchName, branchNames.indexOf(branchName)),
        parentBranch: branchParents[branchName],
      );
      xPosition += _branchGap;
    }
    
    // 分析提交与分支的关系
    for (final branch in widget.repository.branches) {
      for (final commit in branch.commits) {
        // 如果此提交尚未被分配到任何分支
        if (!_commitBranchMap.containsKey(commit.id)) {
          _commitBranchMap[commit.id] = branch.name;
        }
        
        // 检测分支创建和合并
        if (_isBranchCreation(commit)) {
          final newBranchName = _extractBranchName(commit);
          final parentBranchNameFromMessage = _extractParentBranchName(commit);
          
          if (newBranchName != null && branchNames.contains(newBranchName)) {
            // 确定源分支：优先使用消息中提取的父分支，否则使用当前分支
            String sourceBranch = parentBranchNameFromMessage ?? branch.name;
            
            _branchRelations[commit.id] = {
              'type': 'creation',
              'source': sourceBranch,
              'target': newBranchName,
            };
            
            // 如果没有已记录的父分支关系，添加一个
            if (!branchParents.containsKey(newBranchName)) {
              branchParents[newBranchName] = sourceBranch;
              
              // 更新分支信息中的父分支
              final branchInfo = _branchInfoMap[newBranchName];
              if (branchInfo != null) {
                _branchInfoMap[newBranchName] = BranchInfo(
                  name: branchInfo.name,
                  xPosition: branchInfo.xPosition,
                  color: branchInfo.color,
                  parentBranch: sourceBranch,
                );
              }
            }
          }
        } else if (_isBranchMerge(commit)) {
          final mergeInfo = _extractMergeInfo(commit);
          if (mergeInfo != null && 
              branchNames.contains(mergeInfo['source']) && 
              branchNames.contains(mergeInfo['target'])) {
            _branchRelations[commit.id] = {
              'type': 'merge',
              'source': mergeInfo['source'],
              'target': mergeInfo['target'],
            };
          }
        }
      }
    }
  }
  
  /// 获取分支对应的颜色
  Color _getBranchColor(String branchName, int index) {
    // 使用预定义的颜色列表，符合MD3风格
    final colors = [
      const Color(0xFF2196F3), // Blue - main
      const Color(0xFF4CAF50), // Green
      const Color(0xFFF44336), // Red
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF9800), // Orange
      const Color(0xFF009688), // Teal
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF3F51B5), // Indigo
    ];
    
    // main分支始终使用第一个颜色
    if (branchName == 'main') {
      return colors[0];
    }
    
    // 其他分支使用循环分配的颜色
    return colors[1 + (index - 1) % (colors.length - 1)];
  }
  
  /// 检查是否是分支创建提交
  bool _isBranchCreation(Commit commit) {
    return commit.message.contains('Created branch:');
  }
  
  /// 检查是否是分支合并提交
  bool _isBranchMerge(Commit commit) {
    return commit.message.contains('Merge branch:');
  }
  
  /// 从提交消息中提取分支名称
  String? _extractBranchName(Commit commit) {
    final match = RegExp(r'Created branch: (.*?)(?: \(|$)').firstMatch(commit.message);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }
  
  /// 从提交消息中提取父分支名称
  String? _extractParentBranchName(Commit commit) {
    // 提取格式为 "Created branch: newBranch (from parentBranch)" 中的parentBranch
    final match = RegExp(r'Created branch:.*?\(from (.*?)\)').firstMatch(commit.message);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }
  
  /// 从合并提交消息中提取源和目标分支
  Map<String, String>? _extractMergeInfo(Commit commit) {
    final match = RegExp(r'Merge branch: (.*?) -> (.*)').firstMatch(commit.message);
    if (match != null && match.groupCount >= 2) {
      return {
        'source': match.group(1) ?? '',
        'target': match.group(2) ?? '',
      };
    }
    return null;
  }
  
  /// 获取提交所属的分支
  String _getCommitBranch(String commitId) {
    return _commitBranchMap[commitId] ?? 'main';
  }
  
  /// 获取提交节点的X坐标
  double _getCommitXPosition(String commitId) {
    final branchName = _getCommitBranch(commitId);
    return _branchInfoMap[branchName]?.xPosition ?? _leftPadding;
  }
  
  /// 检查是否应该在特定分支上显示合并节点
  bool _shouldShowMergeNodeOnBranch(String commitId, String branchName) {
    return _mergePointBranches.containsKey(commitId) && 
           _mergePointBranches[commitId]!.contains(branchName);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Git History: ${widget.repository.name}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Git History: ${widget.repository.name}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _processRepositoryData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_allCommits.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Git History: ${widget.repository.name}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No commit history found'),
            ],
          ),
        ),
      );
    }
    
    // 找出每个分支的第一个和最后一个提交的索引
    final Map<String, CommitRange> branchCommitRanges = _findBranchCommitRanges();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Git History: ${widget.repository.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CustomPaint(
        painter: GitGraphBackgroundPainter(
          branchInfoMap: _branchInfoMap,
          branchCommitRanges: branchCommitRanges,
          allCommitsCount: _allCommits.length,
          rowHeight: _rowHeight,
          branchRelations: _branchRelations, // 新增传参
        ),
        child: ListView.builder(
          itemCount: _allCommits.length,
          itemBuilder: (context, index) {
            final commit = _allCommits[index];
            final branchName = _getCommitBranch(commit.id);
            final xPosition = _getCommitXPosition(commit.id);
            final branchInfo = _branchInfoMap[branchName];
            
            // 检查是否是合并提交，以及是否有其他分支在此处显示节点
            Set<String> additionalBranchesAtThisCommit = {};
            if (_mergePointBranches.containsKey(commit.id)) {
              additionalBranchesAtThisCommit = Set.from(_mergePointBranches[commit.id]!);
              // 移除当前分支，因为它已经默认显示
              additionalBranchesAtThisCommit.remove(branchName);
            }
            
            if (branchInfo == null) {
              return SizedBox(height: _rowHeight);
            }
            
            return SizedBox(
              height: _rowHeight,
              child: Stack(
                children: [
                  // 1. 先绘制分支关系线 - 放在最底层
                  CustomPaint(
                    painter: CommitConnectionPainter(
                      commit: commit,
                      branchInfoMap: _branchInfoMap,
                      branchRelations: _branchRelations,
                      rowHeight: _rowHeight,
                    ),
                    size: Size(MediaQuery.of(context).size.width, _rowHeight),
                  ),
                  
                  // 2. 提交信息卡片 - 放在中间层
                  Positioned(
                    left: _getTextLeftPosition(),
                    right: 8,
                    top: 8,
                    bottom: 8,
                    child: _buildCommitCard(context, commit),
                  ),
                  
                  // 3. 当前分支的节点 - 放在最上层
                  Positioned(
                    left: xPosition - _nodeRadius,
                    top: (_rowHeight - _nodeRadius * 2) / 2,
                    child: _buildCommitNode(context, commit, branchInfo.color),
                  ),
                  
                  // 4. 额外分支的节点（例如合并提交）- 也在最上层
                  ...additionalBranchesAtThisCommit.map((otherBranchName) {
                    final otherBranchInfo = _branchInfoMap[otherBranchName];
                    if (otherBranchInfo == null) return const SizedBox();
                    
                    return Positioned(
                      left: otherBranchInfo.xPosition - _nodeRadius,
                      top: (_rowHeight - _nodeRadius * 2) / 2,
                      child: _buildCommitNode(context, commit, otherBranchInfo.color),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  /// 构建符合MD3风格的提交信息卡片
  Widget _buildCommitCard(BuildContext context, Commit commit) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          if (widget.onCommitTap != null) {
            widget.onCommitTap!(commit);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 确保Column只占用必要的空间
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                commit.message,
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // 减小间距
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(commit.timestamp),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 构建提交节点
  Widget _buildCommitNode(BuildContext context, Commit commit, Color branchColor) {
    return GestureDetector(
      onTap: () {
        if (widget.onCommitTap != null) {
          widget.onCommitTap!(commit);
        }
      },
      child: Container(
        width: _nodeRadius * 2,
        height: _nodeRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: branchColor,
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 2,
          ),
        ),
        child: Center(
          child: _getCommitIcon(commit),
        ),
      ),
    );
  }
  
  /// 获取提交图标
  Widget _getCommitIcon(Commit commit) {
    IconData iconData;
    double iconSize = _nodeRadius;
    
    if (_isBranchCreation(commit)) {
      iconData = Icons.call_split;
    } else if (_isBranchMerge(commit)) {
      iconData = Icons.call_merge;
    } else if (commit.message.contains('Create task:')) {
      iconData = Icons.add;
    } else if (commit.message.contains('Update task:')) {
      iconData = Icons.edit;
    } else if (commit.message.contains('Delete task:')) {
      iconData = Icons.delete;
    } else {
      iconData = Icons.circle;
      iconSize = _nodeRadius * 0.4; // 小圆点
    }
    
    return Icon(
      iconData,
      size: iconSize,
      color: Colors.white,
    );
  }
  
  /// 找出每个分支的第一个和最后一个提交的索引
  Map<String, CommitRange> _findBranchCommitRanges() {
    Map<String, CommitRange> ranges = {};
    
    // 对于每个分支，找出它在_allCommits中的第一个和最后一个提交的索引
    for (final branchName in _branchInfoMap.keys) {
      int firstIndex = -1;
      int lastIndex = -1;
      
      for (int i = 0; i < _allCommits.length; i++) {
        if (_getCommitBranch(_allCommits[i].id) == branchName) {
          if (firstIndex == -1) {
            firstIndex = i;
          }
          lastIndex = i;
        }
        
        // 检查合并提交，如果这个分支在合并中涉及
        if (_mergePointBranches.containsKey(_allCommits[i].id) && 
            _mergePointBranches[_allCommits[i].id]!.contains(branchName)) {
          if (firstIndex == -1) {
            firstIndex = i;
          }
          lastIndex = i;
        }
      }
      
      // 只有main分支可以没有commit但仍然显示
      if (firstIndex != -1 || branchName == 'main') {
        ranges[branchName] = CommitRange(
          firstIndex: firstIndex, 
          lastIndex: lastIndex
        );
      }
    }
    
    return ranges;
  }
}

/// 分支提交范围类
class CommitRange {
  final int firstIndex; // 分支第一个提交的索引，-1表示没有
  final int lastIndex;  // 分支最后一个提交的索引，-1表示没有
  
  CommitRange({
    required this.firstIndex,
    required this.lastIndex,
  });
}

/// 分支信息类
class BranchInfo {
  final String name;
  final double xPosition;
  final Color color;
  final String? parentBranch; // 父分支名称
  
  BranchInfo({
    required this.name,
    required this.xPosition,
    required this.color,
    this.parentBranch,
  });
}

/// Git图表背景绘制器 - 绘制持续的分支线条
class GitGraphBackgroundPainter extends CustomPainter {
  final Map<String, BranchInfo> branchInfoMap;
  final Map<String, CommitRange> branchCommitRanges;
  final int allCommitsCount;
  final double rowHeight;
  final Map<String, Map<String, dynamic>> branchRelations; // 新增属性
  
  GitGraphBackgroundPainter({
    required this.branchInfoMap,
    required this.branchCommitRanges,
    required this.allCommitsCount,
    required this.rowHeight,
    required this.branchRelations, // 新增构造函数参数
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final double totalHeight = allCommitsCount * rowHeight;
    // 绘制 main 分支的垂直线
    final mainBranchInfo = branchInfoMap['main'];
    // main 分支蓝色线始于 y=0
    if (mainBranchInfo != null) {
      final mainPaint = Paint()
        ..color = mainBranchInfo.color.withOpacity(0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(mainBranchInfo.xPosition, 0),
        Offset(mainBranchInfo.xPosition, totalHeight),
        mainPaint,
      );
    }
    
    // 绘制其他分支的线条
    for (final entry in branchInfoMap.entries) {
      final branchName = entry.key;
      final branchInfo = entry.value;
      if (branchName == 'main') continue;
      
      final range = branchCommitRanges[branchName];
      if (range != null && range.firstIndex != -1) {
        final branchPaint = Paint()
          ..color = branchInfo.color.withOpacity(0.6)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        
        // 计算分支有提交区域的起点与终点
        final startY = range.firstIndex * rowHeight + rowHeight / 2;
        final endY = range.lastIndex * rowHeight + rowHeight / 2;
        canvas.drawLine(
          Offset(branchInfo.xPosition, startY),
          Offset(branchInfo.xPosition, endY),
          branchPaint,
        );
        
        // 判断是否有 merge（存在 merge 后不绘制延长线）
        bool isMerged = branchRelations.values.any((relation) =>
            relation['type'] == 'merge' && relation['source'] == branchName);
        
        // 对未 merge 的分支，绘制灰色延长线，延伸至 main 分支蓝色线的顶端 (y = 0)
        if (!isMerged) {
          final extraPaint = Paint()
            ..color = Colors.grey
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(branchInfo.xPosition, startY),
            Offset(branchInfo.xPosition, 0),
            extraPaint,
          );
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// 提交连接线绘制器 - 绘制分支之间的连接线
class CommitConnectionPainter extends CustomPainter {
  final Commit commit;
  final Map<String, BranchInfo> branchInfoMap;
  final Map<String, Map<String, dynamic>> branchRelations;
  final double rowHeight;
  
  CommitConnectionPainter({
    required this.commit,
    required this.branchInfoMap,
    required this.branchRelations,
    required this.rowHeight,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerY = rowHeight / 2;
    
    // 绘制分支关系线（创建或合并）
    if (branchRelations.containsKey(commit.id)) {
      final relation = branchRelations[commit.id]!;
      final type = relation['type'] as String;
      final sourceName = relation['source'] as String;
      final targetName = relation['target'] as String;
      
      final sourceInfo = branchInfoMap[sourceName];
      final targetInfo = branchInfoMap[targetName];
      
      if (sourceInfo != null && targetInfo != null) {
        final sourceX = sourceInfo.xPosition;
        final targetX = targetInfo.xPosition;
        
        final connectionPaint = Paint()
          ..color = (type == 'creation' ? targetInfo.color : sourceInfo.color).withOpacity(0.8)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        
        // 绘制连接线
        final path = Path();
        path.moveTo(sourceX, centerY);
        path.lineTo(targetX, centerY);
        
        canvas.drawPath(path, connectionPaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}