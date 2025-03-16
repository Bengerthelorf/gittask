import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/repository.dart';
import '../models/commit.dart';

/// 仓库级别的 Git 图表组件
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
    double rightmostPosition = _leftPadding;

    for (final info in _branchInfoMap.values) {
      if (info.xPosition > rightmostPosition) {
        rightmostPosition = info.xPosition;
      }
    }

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

  /// 处理仓库数据，准备绘制 Git 图
  void _processRepositoryData() {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 第一步：收集所有提交
      final Map<String, Commit> commitMap = {};
      for (final branch in widget.repository.branches) {
        for (final commit in branch.commits) {
          commitMap[commit.id] = commit;
        }
      }

      // 第二步：按时间戳排序
      final sortedCommits = commitMap.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (sortedCommits.isEmpty) {
        setState(() {
          _allCommits = [];
          _isLoading = false;
        });
        return;
      }

      _allCommits = sortedCommits;

      // 第三步：分析分支结构
      _analyzeBranchStructure();

      // 第四步：分析合并点
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

  /// 分析合并点上的分支
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

        _mergePointBranches[commitId]!.add(sourceId);
        _mergePointBranches[commitId]!.add(targetId);
      }
    }
  }

  /// 分析分支结构
  void _analyzeBranchStructure() {
    _branchInfoMap = {};
    _commitBranchMap = {};
    _branchRelations = {};

    final List<String> branchNames = [];
    final Map<String, String> branchParents = {};

    for (final branch in widget.repository.branches) {
      branchNames.add(branch.name);
      if (branch.parentBranchId != null) {
        for (final parentBranch in widget.repository.branches) {
          if (parentBranch.id == branch.parentBranchId) {
            branchParents[branch.name] = parentBranch.name;
            break;
          }
        }
      }
    }

    if (branchNames.isEmpty) return;

    if (branchNames.contains('main')) {
      branchNames.remove('main');
      branchNames.insert(0, 'main');
    }

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

    for (final branch in widget.repository.branches) {
      for (final commit in branch.commits) {
        if (!_commitBranchMap.containsKey(commit.id)) {
          _commitBranchMap[commit.id] = branch.name;
        }

        if (_isBranchCreation(commit)) {
          final newBranchName = _extractBranchName(commit);
          final parentBranchName = _extractParentBranchName(commit);

          if (newBranchName != null && branchNames.contains(newBranchName)) {
            String sourceBranch = parentBranchName ?? branch.name;
            _branchRelations[commit.id] = {
              'type': 'creation',
              'source': sourceBranch,
              'target': newBranchName,
            };

            if (!branchParents.containsKey(newBranchName)) {
              branchParents[newBranchName] = sourceBranch;
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

  /// 获取分支颜色
  Color _getBranchColor(String branchName, int index) {
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

    if (branchName == 'main') return colors[0];
    return colors[1 + (index - 1) % (colors.length - 1)];
  }

  /// 检查是否是分支创建提交
  bool _isBranchCreation(Commit commit) {
    return commit.message.contains('Created branch:');
  }

  /// 检查是否是分支合并提交
  bool _isBranchMerge(Commit commit) {
    // 严格判断，仅当消息以 "Merge branch:" 开头时认为是合并提交
    return commit.message.startsWith('Merge branch:');
  }

  /// 提取分支名称
  String? _extractBranchName(Commit commit) {
    final match = RegExp(r'Created branch: (.*?)(?: \(|$)').firstMatch(commit.message);
    return match?.group(1);
  }

  /// 提取父分支名称
  String? _extractParentBranchName(Commit commit) {
    final match = RegExp(r'Created branch:.*?\(from (.*?)\)').firstMatch(commit.message);
    return match?.group(1);
  }

  /// 提取合并信息
  Map<String, String>? _extractMergeInfo(Commit commit) {
    final match = RegExp(r'^Merge branch: (.*?) -> (.*)').firstMatch(commit.message);
    if (match != null && match.groupCount >= 2) {
      return {
        'source': match.group(1) ?? '',
        'target': match.group(2) ?? '',
      };
    }
    return null;
  }

  /// 获取提交所属分支
  String _getCommitBranch(String commitId) {
    return _commitBranchMap[commitId] ?? 'main';
  }

  /// 获取提交节点的 X 坐标
  double _getCommitXPosition(String commitId) {
    final branchName = _getCommitBranch(commitId);
    return _branchInfoMap[branchName]?.xPosition ?? _leftPadding;
  }

  /// 找出分支的提交范围
  Map<String, CommitRange> _findBranchCommitRanges() {
    Map<String, CommitRange> ranges = {};

    for (final branchName in _branchInfoMap.keys) {
      int firstIndex = -1;
      int lastIndex = -1;

      for (int i = 0; i < _allCommits.length; i++) {
        final commit = _allCommits[i];
        if (_getCommitBranch(commit.id) == branchName) {
          if (firstIndex == -1) firstIndex = i; // 记录分支的第一个提交
          lastIndex = i; // 更新最后一个提交
        }

        // 处理合并点，确保合并提交也包含在范围内
        if (_mergePointBranches.containsKey(commit.id) &&
            _mergePointBranches[commit.id]!.contains(branchName)) {
          if (firstIndex == -1) firstIndex = i;
          lastIndex = i;
        }
      }

      // 对于 main 分支，确保覆盖所有提交
      if (branchName == 'main') {
        firstIndex = 0;
        lastIndex = _allCommits.length - 1;
      }

      if (firstIndex != -1 || branchName == 'main') {
        ranges[branchName] = CommitRange(
          firstIndex: firstIndex,
          lastIndex: lastIndex,
        );
      }
    }

    return ranges;
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
        body: const Center(child: CircularProgressIndicator()),
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

    final branchCommitRanges = _findBranchCommitRanges();

    return Scaffold(
      appBar: AppBar(
        title: Text('Git History: ${widget.repository.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        itemCount: _allCommits.length,
        itemBuilder: (context, index) {
          final commit = _allCommits[index];
          final branchName = _getCommitBranch(commit.id);
          final xPosition = _getCommitXPosition(commit.id);
          final branchInfo = _branchInfoMap[branchName];

          Set<String> additionalBranchesAtThisCommit = {};
          if (_mergePointBranches.containsKey(commit.id)) {
            additionalBranchesAtThisCommit = Set.from(_mergePointBranches[commit.id]!);
            additionalBranchesAtThisCommit.remove(branchName);
          }

          if (branchInfo == null) return const SizedBox(height: _rowHeight);

          return SizedBox(
            height: _rowHeight,
            child: Stack(
              children: [
                // 背景线条
                CustomPaint(
                  painter: GitGraphBackgroundPainter(
                    branchInfoMap: _branchInfoMap,
                    branchCommitRanges: branchCommitRanges,
                    currentIndex: index,
                    rowHeight: _rowHeight,
                    branchRelations: _branchRelations,
                  ),
                  size: Size(MediaQuery.of(context).size.width, _rowHeight),
                ),

                // 连接线
                CustomPaint(
                  painter: CommitConnectionPainter(
                    commit: commit,
                    branchInfoMap: _branchInfoMap,
                    branchRelations: _branchRelations,
                    rowHeight: _rowHeight,
                  ),
                  size: Size(MediaQuery.of(context).size.width, _rowHeight),
                ),

                // 提交信息卡片
                Positioned(
                  left: _getTextLeftPosition(),
                  right: 8,
                  top: 8,
                  bottom: 8,
                  child: _buildCommitCard(context, commit),
                ),

                // 当前分支节点
                Positioned(
                  left: xPosition - _nodeRadius,
                  top: (_rowHeight - _nodeRadius * 2) / 2,
                  child: _buildCommitNode(context, commit, branchInfo.color),
                ),

                // 合并提交的额外节点
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
    );
  }

  /// 构建提交信息卡片
  Widget _buildCommitCard(BuildContext context, Commit commit) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => widget.onCommitTap?.call(commit),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                commit.message,
                style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
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
      onTap: () => widget.onCommitTap?.call(commit),
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
        child: Center(child: _getCommitIcon(commit)),
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
      iconSize = _nodeRadius * 0.4;
    }

    return Icon(iconData, size: iconSize, color: Colors.white);
  }
}

/// 分支提交范围类
class CommitRange {
  final int firstIndex;
  final int lastIndex;

  CommitRange({required this.firstIndex, required this.lastIndex});
}

/// 分支信息类
class BranchInfo {
  final String name;
  final double xPosition;
  final Color color;
  final String? parentBranch;

  BranchInfo({
    required this.name,
    required this.xPosition,
    required this.color,
    this.parentBranch,
  });
}

/// Git 图表背景绘制器
class GitGraphBackgroundPainter extends CustomPainter {
  final Map<String, BranchInfo> branchInfoMap;
  final Map<String, CommitRange> branchCommitRanges;
  final int currentIndex;
  final double rowHeight;
  final Map<String, Map<String, dynamic>> branchRelations;

  GitGraphBackgroundPainter({
    required this.branchInfoMap,
    required this.branchCommitRanges,
    required this.currentIndex,
    required this.rowHeight,
    required this.branchRelations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double nodeY = rowHeight / 2; // 节点位置在行的中间

    // 绘制 main 分支的线条段
    final mainBranchInfo = branchInfoMap['main'];
    if (mainBranchInfo != null) {
      final mainPaint = Paint()
        ..color = mainBranchInfo.color.withOpacity(0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(mainBranchInfo.xPosition, 0),
        Offset(mainBranchInfo.xPosition, rowHeight),
        mainPaint,
      );
    }

    // 绘制非 main 分支的线条段
    for (final entry in branchInfoMap.entries) {
      final branchName = entry.key;
      final branchInfo = entry.value;
      if (branchName == 'main') continue;

      final range = branchCommitRanges[branchName];
      if (range != null) {
        bool isMerged = branchRelations.values.any((relation) =>
            relation['type'] == 'merge' && relation['source'] == branchName);

        // 在分支的提交范围上方，绘制灰色线段（如果未合并）
        if (currentIndex < range.firstIndex && !isMerged) {
          final grayPaint = Paint()
            ..color = Colors.grey
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(branchInfo.xPosition, 0),
            Offset(branchInfo.xPosition, rowHeight),
            grayPaint,
          );
        }
        // 对于顶部节点（firstIndex），只绘制从节点到行底部的彩色线段
        else if (currentIndex == range.firstIndex && range.firstIndex != range.lastIndex) {
          final branchPaint = Paint()
            ..color = branchInfo.color.withOpacity(0.6)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(branchInfo.xPosition, nodeY),
            Offset(branchInfo.xPosition, rowHeight),
            branchPaint,
          );
        }
        // 对于中间行，绘制贯穿整个行的彩色线段
        else if (currentIndex > range.firstIndex && currentIndex < range.lastIndex) {
          final branchPaint = Paint()
            ..color = branchInfo.color.withOpacity(0.6)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(branchInfo.xPosition, 0),
            Offset(branchInfo.xPosition, rowHeight),
            branchPaint,
          );
        }
        // 对于底部节点（lastIndex），只绘制从行顶部到节点的彩色线段
        else if (currentIndex == range.lastIndex && range.firstIndex != range.lastIndex) {
          final branchPaint = Paint()
            ..color = branchInfo.color.withOpacity(0.6)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(branchInfo.xPosition, 0),
            Offset(branchInfo.xPosition, nodeY),
            branchPaint,
          );
        }
        // 对于单个节点分支（firstIndex == lastIndex），绘制从行顶部到节点的灰色线段
        else if (currentIndex == range.firstIndex && range.firstIndex == range.lastIndex) {
          final grayPaint = Paint()
            ..color = Colors.grey
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(branchInfo.xPosition, 0),
            Offset(branchInfo.xPosition, nodeY),
            grayPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 提交连接线绘制器
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

        final path = Path()
          ..moveTo(sourceX, centerY)
          ..lineTo(targetX, centerY);

        canvas.drawPath(path, connectionPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}