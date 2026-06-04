import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/project_service.dart';
import '../../providers/auth_provider.dart';

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
    bool selectedStatus = member.statusMember;
    String deactivationReason = '';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            title: Text('Edit Anggota:\n${member.user?.name ?? "Unknown"}', textAlign: TextAlign.center),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ubah Jabatan/Role:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: ['Pemimpin Proyek', 'Pemimpin Projek', 'Asisten', 'Human Resource', 'Anggota'].contains(selectedRole) ? selectedRole : 'Anggota',
                    items: ['Asisten', 'Human Resource', 'Anggota'] 
                        .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Tindakan Status:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Status Aktif'),
                    subtitle: Text(selectedStatus ? 'Anggota memiliki akses ke proyek' : 'Akses anggota dibekukan'),
                    value: selectedStatus,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setStateDialog(() => selectedStatus = val);
                    },
                  ),
                  if (!selectedStatus && member.statusMember) ...[
                    const SizedBox(height: 12),
                    const Text('Alasan Penonaktifan:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      maxLength: 255,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Tidak aktif selama 2 minggu...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => deactivationReason = val,
                    ),
                  ],
                ],
              ),
            ),
            ),
            actions: [
              OutlinedButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: isSaving ? null : () async {
                  setStateDialog(() => isSaving = true);
                  
                  final roleResp = await _projectService.updateMemberRole(projectId, member.userId, selectedRole);
                  bool statusSuccess = true;
                  if (selectedStatus != member.statusMember) {
                    if (!selectedStatus && deactivationReason.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan penonaktifan wajib diisi!'), backgroundColor: Colors.red));
                      setStateDialog(() => isSaving = false);
                      return;
                    }
                    final statusResp = await _projectService.toggleMemberStatus(projectId, member.userId, deactivationReason: !selectedStatus ? deactivationReason : null);
                    statusSuccess = statusResp.success;
                  }
                  
                  setStateDialog(() => isSaving = false);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(roleResp.success && statusSuccess ? 'Data anggota berhasil diperbarui' : (roleResp.message.isNotEmpty ? roleResp.message : 'Gagal memperbarui data')),
                        backgroundColor: roleResp.success && statusSuccess ? Colors.green : Colors.red,
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
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.currentUser?.id;

    final activeMembers = widget.members.where((m) => m.user != null).toList();
    
    final rolePriority = {'Pemimpin Projek': 1, 'Pemimpin Proyek': 1, 'Asisten': 2, 'Human Resource': 3, 'Anggota': 4};
    activeMembers.sort((a, b) {
      int rankA = rolePriority[a.roleName] ?? 5;
      int rankB = rolePriority[b.roleName] ?? 5;
      if (rankA != rankB) return rankA.compareTo(rankB);
      return (a.user?.name ?? '').compareTo(b.user?.name ?? '');
    });

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
                ? Center(child: Text('Belum ada anggota', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    itemCount: activeMembers.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final member = activeMembers[i];
                      final user = member.user!;
                      // Mencegah leader mengubah status dirinya sendiri dan memberi penanda
                      final isSelf = user.id == currentUserId;
                      
                      // Apakah member ini bisa diedit oleh leader?
                      final canEdit = isLeader && !isSelf && (member.roleName != 'Pemimpin Proyek' && member.roleName != 'Pemimpin Projek');

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.border),
                        ),
                        color: AppColors.surface,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: canEdit ? () => _showEditMemberDialog(context, widget.projectId, member) : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: member.statusMember ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                                  foregroundColor: member.statusMember ? AppColors.primary : Colors.grey,
                                  backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty) 
                                      ? NetworkImage(user.photoUrl!) 
                                      : null,
                                  child: (user.photoUrl == null || user.photoUrl!.isEmpty) 
                                      ? Text(user.name.isNotEmpty ? user.name[0] : '?') 
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(text: user.name),
                                            if (isSelf)
                                              TextSpan(
                                                text: ' (Anda)',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontStyle: FontStyle.italic,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                          ],
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 16,
                                          decoration: member.statusMember ? TextDecoration.none : TextDecoration.lineThrough,
                                          color: member.statusMember ? AppColors.textPrimary : Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        user.email,
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                                
                                // Tombol kick hanya muncul untuk member nonaktif
                                if (canEdit && !member.statusMember) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(LucideIcons.userMinus, size: 20, color: AppColors.statusOverdue),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Keluarkan Anggota'),
                                          content: const Text('Yakin ingin mengeluarkan anggota ini secara permanen dari proyek?'),
                                          actions: [
                                            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusOverdue),
                                              onPressed: () async {
                                                Navigator.pop(ctx);
                                                final resp = await _projectService.removeMember(widget.projectId, member.userId);
                                                if (resp.success) {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                    content: Text(resp.message.isNotEmpty ? resp.message : 'Anggota berhasil dikeluarkan'),
                                                    backgroundColor: Colors.green,
                                                  ));
                                                  widget.onRefresh?.call();
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                    content: Text(resp.message.isNotEmpty ? resp.message : 'Gagal mengeluarkan anggota'),
                                                    backgroundColor: Colors.red,
                                                  ));
                                                }
                                              },
                                              child: const Text('Keluarkan', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
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
          SizedBox(height: 16),
          Text('Bagikan kode undangan ini ke anggota tim Anda:', style: TextStyle(color: AppColors.textSecondary)),
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
                        style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold,
                          letterSpacing: 2, color: AppColors.primary,
                        ),
                      ),

                    ],
                  ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_referralCode != null) {
                Clipboard.setData(ClipboardData(text: _referralCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kode undangan disalin!')),
                );
              }
            },
            icon: const Icon(LucideIcons.copy),
            label: const Text('Salin Kode'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              if (_referralCode == null) return;
              final text = 'Bergabunglah dengan proyek di SEDYA!\n\nMasukkan kode referral berikut: $_referralCode';
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