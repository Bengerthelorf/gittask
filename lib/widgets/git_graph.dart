import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/branch.dart';
import '../models/commit.dart';

class GitGraph extends StatelessWidget {
  final Branch branch;
  final Function(Commit)? onCommitTap;

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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: commits.length,
      itemBuilder: (context, index) {
        final commit = commits[index];
        final isLastItem = index == commits.length - 1;
        
        return InkWell(
          onTap: onCommitTap != null ? () => onCommitTap!(commit) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图形部分
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.commit,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 14,
                      ),
                    ),
                    if (!isLastItem)
                      Container(
                        width: 2,
                        height: 50,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
              // 提交信息部分
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commit.message,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(commit.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '提交ID: ',
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  commit.id.length > 8 ? commit.id.substring(0, 8) : commit.id,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            if (commit.taskId != 'merge') ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '任务ID: ',
                                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    commit.taskId == 'merge' || commit.taskId == 'branch' 
                                        ? commit.taskId 
                                        : (commit.taskId.length > 8 
                                            ? commit.taskId.substring(0, 8) 
                                            : commit.taskId),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}