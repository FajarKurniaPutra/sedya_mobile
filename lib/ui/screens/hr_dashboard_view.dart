import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../services/hr_service.dart';

class HRDashboardView extends StatefulWidget {
  final int projectId;

  const HRDashboardView({super.key, required this.projectId});

  @override
  State<HRDashboardView> createState() => _HRDashboardViewState();
}

class _HRDashboardViewState extends State<HRDashboardView> {
  final HRService _hrService = HRService();
  List<HRMemberPerformance> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _hrService.getTeamPerformance(widget.projectId);
    if (mounted) {
      setState(() {
        _members = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Performa Tim',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur unduh laporan akan segera hadir')),
                  );
                },
                icon: const Icon(LucideIcons.download, size: 16),
                label: const Text('Unduh Laporan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _members.isEmpty
                ? const Center(child: Text('Belum ada data performa', style: TextStyle(color: AppColors.textSecondary)))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.separated(
                      itemCount: _members.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final member = _members[i];
                        Color statusColor;
                        switch (member.badge) {
                          case 'Optimal':
                            statusColor = AppColors.statusDone;
                            break;
                          case 'Perlu Review':
                            statusColor = AppColors.statusInProgress;
                            break;
                          default:
                            statusColor = AppColors.statusOverdue;
                        }

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        member.username,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        member.badge,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      member.role,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Skor: ${member.score}',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.checkCircle2, color: AppColors.statusDone, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${member.done} Diselesaikan',
                                          style: const TextStyle(color: AppColors.statusDone, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.clock, color: AppColors.statusOverdue, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${member.delayed} Tertunda',
                                          style: const TextStyle(color: AppColors.statusOverdue, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
