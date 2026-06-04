import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../services/hr_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb

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
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: _members.isEmpty
                ? Center(child: Text('Belum ada data performa', style: TextStyle(color: AppColors.textSecondary)))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      children: [
                        _buildEvaluationSummary(),
                        const SizedBox(height: 16),
                        ..._members.map((member) {
                          Color statusColor;
                          if (!member.isActive) {
                            statusColor = Colors.grey;
                          } else if (member.badge.contains('Optimal') || member.badge.contains('Teladan')) {
                            statusColor = AppColors.statusDone;
                          } else if (member.badge.contains('Review')) {
                            statusColor = AppColors.statusInProgress;
                          } else {
                            statusColor = AppColors.statusOverdue;
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppColors.border),
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
                                            !member.isActive ? 'Nonaktif' : member.badge,
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
                                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                        const Spacer(),
                                        if (member.isActive)
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
                                    if (!member.isActive && member.deactivationReason != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Alasan: ${member.deactivationReason}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ] else if (member.isActive) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(LucideIcons.checkCircle2, color: AppColors.statusDone, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                '${member.done} Diselesaikan',
                                                style: TextStyle(color: AppColors.statusDone, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(LucideIcons.clock, color: AppColors.statusOverdue, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                '${member.delayed} Tertunda',
                                                style: TextStyle(color: AppColors.statusOverdue, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationSummary() {
    int optimal = _members.where((m) => m.isActive && (m.badge.contains('Optimal') || m.badge.contains('Teladan'))).length;
    int critical = _members.where((m) => m.isActive && m.badge.contains('Kritis')).length;
    int review = _members.where((m) => m.isActive && m.badge.contains('Review')).length;
    final inactiveMembers = _members.where((m) => !m.isActive).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clipboardList, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Catatan Evaluasi',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• $optimal anggota berkinerja optimal\n• $review anggota perlu direview\n• $critical anggota berada di fase kritis',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
          ),
          if (inactiveMembers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '• ${inactiveMembers.length} anggota dinonaktifkan:',
              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
            ),
            ...inactiveMembers.map((m) => Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                '- ${m.username}: ${m.deactivationReason ?? 'Tanpa alasan spesifik'}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            )),
          ],
        ],
      ),
    );
  }

}
