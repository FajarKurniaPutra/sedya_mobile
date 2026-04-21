import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../core/dummy_data.dart';
import '../../models/models.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final List<Project> _projects = DummyData.projects;

  void _showProjectForm([Project? project]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProjectFormModal(project: project),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      title: 'Proyek Anda',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari proyek...',
                prefixIcon: const Icon(LucideIcons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 16),
            // Create Project Button (Only for Leader)
            if (DummyData.currentUser.role == 'Pemimpin Proyek') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showProjectForm(),
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('BUAT PROYEK'),
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Project List
            Expanded(
              child: ListView.separated(
                itemCount: _projects.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                itemBuilder: (ctx, i) {
                  final project = _projects[i];
                  return _ProjectCard(
                    project: project,
                    onEdit: () => _showProjectForm(project),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(project: project),
                        ),
                      );
                    },
                  );
                },
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
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.onEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: project.status == 'Active'
                          ? AppColors.statusDone.withValues(alpha: 0.1)
                          : AppColors.statusOverdue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      project.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: project.status == 'Active'
                            ? AppColors.statusDone
                            : AppColors.statusOverdue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                project.code,
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
                      'Pembuat: ${project.creator.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (DummyData.currentUser.role == 'Pemimpin Proyek') ...[
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
                              title: const Text('Nonaktifkan Proyek'),
                              content: Text('Yakin ingin menonaktifkan proyek ${project.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusOverdue),
                                  child: const Text('Nonaktifkan'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.ban, size: 16, color: AppColors.statusOverdue),
                        label: const Text('Nonaktifkan', style: TextStyle(color: AppColors.statusOverdue)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppColors.statusOverdue),
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

class _ProjectFormModal extends StatelessWidget {
  final Project? project;

  const _ProjectFormModal({this.project});

  @override
  Widget build(BuildContext context) {
    final bool isEdit = project != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEdit ? 'Ubah Proyek' : 'Buat Proyek Baru',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: project?.name),
            decoration: const InputDecoration(
              labelText: 'NAMA PROYEK',
              hintText: 'Enter project title...',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: project?.code),
                  decoration: const InputDecoration(
                    labelText: 'KODE PROYEK',
                    hintText: 'e.g. SDY-2024',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  enabled: false,
                  controller: TextEditingController(text: DummyData.currentUser.name),
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
            initialValue: project?.phase ?? 'Planning',
            decoration: const InputDecoration(labelText: 'TAHAPAN PROYEK'),
            items: ['Planning', 'Execution', 'Review', 'Completed']
                .map((phase) => DropdownMenuItem(
                      value: phase,
                      child: Text(phase),
                    ))
                .toList(),
            onChanged: (val) {},
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
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
