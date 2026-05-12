import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/project_service.dart';

class MemberListView extends StatelessWidget {
  final int projectId;
  final List<ProjectMember> members;
  final String userRole;

  const MemberListView({
    super.key,
    required this.projectId,
    required this.members,
    required this.userRole,
  });

  void _showInviteModal(BuildContext context) {
    // Cari kode referral dari project (tersedia via members dari parent)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InviteModal(projectId: projectId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMembers = members.where((m) => m.user != null).toList();
    final isLeader = userRole == 'Pemimpin Proyek' || userRole == 'Pemimpin Projek';
    final canInvite = isLeader || userRole == 'Asisten';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (canInvite) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showInviteModal(context),
                icon: const Icon(LucideIcons.userPlus),
                label: const Text('Undang Anggota'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: activeMembers.isEmpty
                ? const Center(child: Text('Belum ada anggota', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    itemCount: activeMembers.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final member = activeMembers[i];
                      final user = member.user!;
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        color: AppColors.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                foregroundColor: AppColors.primary,
                                child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.email,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      member.roleName,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: member.statusMember
                                          ? AppColors.statusDone.withValues(alpha: 0.1)
                                          : AppColors.statusOverdue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      member.statusMember ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: member.statusMember ? AppColors.statusDone : AppColors.statusOverdue,
                                      ),
                                    ),
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
        ],
      ),
    );
  }
}

class _InviteModal extends StatefulWidget {
  final int projectId;

  const _InviteModal({required this.projectId});

  @override
  State<_InviteModal> createState() => _InviteModalState();
}

class _InviteModalState extends State<_InviteModal> {
  final ProjectService _projectService = ProjectService();
  String? _referralCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final project = await _projectService.getProjectDetail(widget.projectId);
    if (mounted) {
      setState(() {
        _referralCode = project?.referralCode;
        _isLoading = false;
      });
    }
  }

  String _getJoinLink() {
    return 'https://sedya.app/join/$_referralCode';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Undang Anggota', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Bagikan tautan undangan ini ke anggota tim Anda:', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Text(
                        _referralCode ?? '—',
                        style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold,
                          letterSpacing: 2, color: AppColors.primary,
                        ),
                      ),
                      if (_referralCode != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _getJoinLink(),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_referralCode != null) {
                Clipboard.setData(ClipboardData(text: _getJoinLink()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tautan undangan disalin!')),
                );
              }
            },
            icon: const Icon(LucideIcons.copy),
            label: const Text('Salin Tautan'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              if (_referralCode == null) return;
              final text = 'Bergabunglah dengan proyek di SEDYA!\n\nGunakan tautan berikut untuk bergabung:\n${_getJoinLink()}\n\nAtau masukkan kode referral: $_referralCode';
              await SharePlus.instance.share(ShareParams(text: text));
            },
            icon: const Icon(LucideIcons.share2),
            label: const Text('Bagikan'),
          ),
        ],
      ),
    );
  }
}
