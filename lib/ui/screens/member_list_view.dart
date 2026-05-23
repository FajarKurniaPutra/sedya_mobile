import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/project_service.dart';

class MemberListView extends StatefulWidget {
  final int projectId;
  final List<ProjectMember> members;
  final String userRole;
  final VoidCallback? onRefresh;

  const MemberListView({
    super.key,
    required this.projectId,
    required this.members,
    required this.userRole,
    this.onRefresh,
  });

  @override
  State<MemberListView> createState() => _MemberListViewState();
}

class _MemberListViewState extends State<MemberListView> {
  final ProjectService _projectService = ProjectService();

  void _showInviteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InviteModal(projectId: widget.projectId),
    );
  }

  // --- FUNGSI BARU: POP-UP MANIPULASI MEMBER ---
  void _showEditMemberDialog(BuildContext context, int projectId, ProjectMember member) {
    String selectedRole = member.roleName; 
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Edit Anggota:\n${member.user?.name ?? "Unknown"}', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ubah Jabatan/Role:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: ['Pemimpin Proyek', 'Pemimpin Projek', 'Asisten', 'Anggota'].contains(selectedRole) ? selectedRole : 'Anggota',
                  items: ['Asisten', 'Anggota'] 
                      .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 20),
                const Text('Tindakan Status:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: member.statusMember ? Colors.red : Colors.green,
                      side: BorderSide(color: member.statusMember ? Colors.red : Colors.green),
                    ),
                    icon: Icon(member.statusMember ? LucideIcons.userX : LucideIcons.userCheck, size: 16),
                    label: Text(member.statusMember ? 'Nonaktifkan Anggota' : 'Aktifkan Anggota'),
                    onPressed: isSaving ? null : () async {
                      setStateDialog(() => isSaving = true);
                      
                      final resp = await _projectService.toggleMemberStatus(projectId, member.userId);
                      
                      setStateDialog(() => isSaving = false);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(resp.message.isNotEmpty ? resp.message : 'Status anggota berhasil diperbarui'),
                            backgroundColor: resp.success ? Colors.green : Colors.red,
                          ),
                        );
                        // CATATAN: Untuk update layar otomatis setelah berhasil, kamu harus merefresh ulang datanya
                        // Karena file ini dipisah, kamu bisa panggil reload dari parent screen-nya nanti
                        widget.onRefresh?.call();
                      }
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: isSaving ? null : () async {
                  setStateDialog(() => isSaving = true);
                  
                  final resp = await _projectService.updateMemberRole(projectId, member.userId, selectedRole);
                  
                  setStateDialog(() => isSaving = false);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(resp.message.isNotEmpty ? resp.message : 'Role berhasil diperbarui'),
                        backgroundColor: resp.success ? Colors.green : Colors.red,
                      ),
                    );
                    widget.onRefresh?.call();
                  }
                },
                child: isSaving
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMembers = widget.members.where((m) => m.user != null).toList();
    final isLeader = widget.userRole == 'Pemimpin Proyek' || widget.userRole == 'Pemimpin Projek';
    final canInvite = isLeader || widget.userRole == 'Asisten';

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
                      // Mencegah leader mengubah status dirinya sendiri
                      final isSelf = user.name == 'Dina cantik' || user.name == 'Dina'; // Sesuaikan logika login nanti
                      
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
                                backgroundColor: member.statusMember ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                                foregroundColor: member.statusMember ? AppColors.primary : Colors.grey,
                                child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 16,
                                        decoration: member.statusMember ? TextDecoration.none : TextDecoration.lineThrough,
                                        color: member.statusMember ? AppColors.textPrimary : Colors.grey,
                                      ),
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
                              
                              // --- TAMBAHAN TOMBOL EDIT UNTUK LEADER ---
                              if (isLeader && !isSelf && (member.roleName != 'Pemimpin Proyek' && member.roleName != 'Pemimpin Projek')) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(LucideIcons.edit2, size: 20, color: AppColors.primary),
                                  onPressed: () => _showEditMemberDialog(context, widget.projectId, member),
                                )
                              ]
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