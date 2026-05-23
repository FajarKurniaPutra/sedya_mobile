import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/project_service.dart';
import 'project_detail_screen.dart';

import '../widgets/skeleton.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final ProjectService _projectService = ProjectService();
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await _projectService.getProjects();
    if (mounted) {
      setState(() {
        _projects = projects;
        _applySearch();
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredProjects = List.from(_projects);
    } else {
      _filteredProjects = _projects.where((p) =>
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.code.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
  }

  void _showProjectForm([Project? project]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProjectFormModal(
        project: project,
        onSaved: () {
          Navigator.pop(ctx);
          _loadProjects(); // Refresh list setelah simpan
        },
      ),
    );
  }

  // --- FUNGSI BARU: POP-UP GABUNG PROYEK ---
  void _showJoinProjectDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    bool isJoining = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Gabung Proyek', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masukkan kode referral proyek yang ingin kamu ikuti:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: PRJ-12345',
                    prefixIcon: const Icon(LucideIcons.key),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isJoining ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isJoining ? null : () async {
                  if (codeController.text.trim().isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kode tidak boleh kosong!'), backgroundColor: Colors.red),
                     );
                     return;
                  }

                  setStateDialog(() => isJoining = true);

                  final resp = await _projectService.joinProject(codeController.text.trim());
                  bool isSuccess = resp.success;
                  String message = resp.message.isNotEmpty ? resp.message : (isSuccess ? "Berhasil gabung ke proyek!" : "Gagal bergabung ke proyek");
                  setStateDialog(() => isJoining = false);

                  if (mounted) {
                    Navigator.pop(ctx); 
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: isSuccess ? Colors.green : Colors.red,
                      ),
                    );

                    if (isSuccess) {
                      _loadProjects(); 
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isJoining
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Gabung', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _toggleProjectStatus(Project project) async {
    final resp = await _projectService.toggleStatus(project.id);
    if (resp.success) {
      _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status proyek "${project.name}" diperbarui')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return GlobalLayout(
      title: 'Dashboard',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang, ${auth.currentUser?.name ?? "Pengguna"}!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Berikut adalah daftar proyek Anda.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari proyek...',
                prefixIcon: const Icon(LucideIcons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applySearch();
                });
              },
            ),
            const SizedBox(height: 16),
            // Create Project Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showProjectForm(),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('BUAT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showJoinProjectDialog(context),
                    icon: const Icon(LucideIcons.logIn, size: 18, color: AppColors.primary),
                    label: const Text('GABUNG', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Project List
            Expanded(
              child: _isLoading
                  ? ListView.separated(
                      itemCount: 5,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => const Skeleton(height: 100),
                    )
                  : _filteredProjects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.rocket, size: 64, color: AppColors.primary),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _searchQuery.isNotEmpty ? 'Proyek tidak ditemukan' : 'Belum ada proyek, yuk buat baru! 🚀',
                                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProjects,
                          child: ListView.separated(
                            itemCount: _filteredProjects.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                            itemBuilder: (ctx, i) {
                              final project = _filteredProjects[i];
                              return _ProjectCard(
                                project: project,
                                currentUserId: auth.currentUser?.id ?? 0,
                                onEdit: () => _showProjectForm(project),
                                onToggleStatus: () => _toggleProjectStatus(project),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProjectDetailScreen(projectId: project.id),
                                    ),
                                  );
                                  _loadProjects();
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final int currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.currentUserId,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Check per-project role from members list
    bool isLeader = false;
    for (final m in project.members) {
      if (m.userId == currentUserId) {
        isLeader = m.roleName == 'Pemimpin Projek' || m.roleName == 'Pemimpin Proyek';
        break;
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: project.statusActive
                          ? AppColors.statusDone.withValues(alpha: 0.1)
                          : AppColors.statusOverdue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      project.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: project.statusActive
                            ? AppColors.statusDone
                            : AppColors.statusOverdue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                project.code.isNotEmpty ? project.code : '—',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(LucideIcons.user, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Pembuat: ${project.creator?.name ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (isLeader) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(LucideIcons.edit2, size: 16),
                        label: const Text('Ubah'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(project.statusActive ? 'Nonaktifkan Proyek' : 'Aktifkan Proyek'),
                              content: Text('Yakin ingin ${project.statusActive ? "menonaktifkan" : "mengaktifkan"} proyek ${project.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    onToggleStatus();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: project.statusActive ? AppColors.statusOverdue : AppColors.statusDone,
                                  ),
                                  child: Text(project.statusActive ? 'Nonaktifkan' : 'Aktifkan'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(
                          project.statusActive ? LucideIcons.ban : LucideIcons.checkCircle2,
                          size: 16,
                          color: project.statusActive ? AppColors.statusOverdue : AppColors.statusDone,
                        ),
                        label: Text(
                          project.statusActive ? 'Nonaktifkan' : 'Aktifkan',
                          style: TextStyle(
                            color: project.statusActive ? AppColors.statusOverdue : AppColors.statusDone,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(
                            color: project.statusActive ? AppColors.statusOverdue : AppColors.statusDone,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectFormModal extends StatefulWidget {
  final Project? project;
  final VoidCallback onSaved;

  const _ProjectFormModal({this.project, required this.onSaved});

  @override
  State<_ProjectFormModal> createState() => _ProjectFormModalState();
}

class _ProjectFormModalState extends State<_ProjectFormModal> {
  final ProjectService _projectService = ProjectService();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descController;
  String _selectedPhase = 'Perencanaan';
  bool _isSaving = false;
  String? _errorText; // Fix #1: inline error instead of SnackBar behind modal

  static const _validPhases = ['Perencanaan', 'Pengerjaan', 'Review', 'Selesai', 'Tertunda'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name);
    _codeController = TextEditingController(text: widget.project?.code);
    _descController = TextEditingController(text: widget.project?.description);
    _selectedPhase = _validPhases.contains(widget.project?.phase) ? widget.project!.phase : 'Perencanaan';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorText = 'Nama proyek wajib diisi');
      return;
    }
    if (_codeController.text.trim().isEmpty) {
      setState(() => _errorText = 'Kode proyek wajib diisi');
      return;
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    final isEdit = widget.project != null;
    final resp = isEdit
        ? await _projectService.updateProject(
            widget.project!.id,
            name: _nameController.text.trim(),
            code: _codeController.text.trim(),
            description: _descController.text.trim(),
            phase: _selectedPhase,
          )
        : await _projectService.createProject(
            name: _nameController.text.trim(),
            code: _codeController.text.trim(),
            description: _descController.text.trim(),
            phase: _selectedPhase,
          );

    if (mounted) {
      setState(() => _isSaving = false);
      if (resp.success) {
        widget.onSaved();
      } else {
        setState(() => _errorText = resp.message.isNotEmpty ? resp.message : 'Gagal menyimpan proyek');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.project != null;
    final auth = context.read<AuthProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Ubah Proyek' : 'Buat Proyek Baru',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            // Fix #1: Inline error message (visible inside modal)
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.statusOverdue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.statusOverdue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.statusOverdue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorText!, style: const TextStyle(color: AppColors.statusOverdue, fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                label: Text.rich(TextSpan(text: 'NAMA PROYEK ', children: [TextSpan(text: '*', style: TextStyle(color: AppColors.statusOverdue))])),
                hintText: 'Masukkan judul proyek...',
              ),
              onChanged: (_) { if (_errorText != null) setState(() => _errorText = null); },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      label: Text.rich(TextSpan(text: 'KODE PROYEK ', children: [TextSpan(text: '*', style: TextStyle(color: AppColors.statusOverdue))])),
                      hintText: 'e.g. SDY-2024',
                    ),
                    onChanged: (_) { if (_errorText != null) setState(() => _errorText = null); },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    enabled: false,
                    controller: TextEditingController(text: auth.currentUser?.name ?? ''),
                    decoration: const InputDecoration(
                      labelText: 'PENCIPTA PROYEK',
                      fillColor: AppColors.border,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedPhase,
              decoration: const InputDecoration(labelText: 'TAHAPAN PROYEK'),
              items: _validPhases
                  .map((phase) => DropdownMenuItem(value: phase, child: Text(phase)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPhase = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'DESKRIPSI',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProject,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
