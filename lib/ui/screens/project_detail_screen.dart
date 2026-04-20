import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../core/dummy_data.dart';
import '../../models/models.dart';
import 'task_detail_screen.dart';
import 'member_list_view.dart';
import 'hr_dashboard_view.dart';
import 'package:intl/intl.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<TaskItem> _tasks = DummyData.tasks;

  @override
  void initState() {
    super.initState();
    final role = DummyData.currentUser.role;
    int tabCount = role == 'Human Resource' ? 1 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTaskForm([TaskItem? task]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TaskFormModal(task: task),
    );
  }

  // Menghitung minggu ke berapa dalam bulan berjalan (kalender masehi)
  int _getWeekOfMonth() {
    final now = DateTime.now();
    return ((now.day - 1) ~/ 7) + 1;
  }

  // Menampilkan detail Weekly Sprint dalam BottomSheet
  void _showSprintDetail(BuildContext context) {
    final weekNum = _getWeekOfMonth();
    final monthYear = DateFormat('MMMM yyyy').format(DateTime.now());

    // Dummy sprint goals
    final sprintGoals = [
      'Penyelesaian full sistem Beyonder',
      'Perkuat fitur keamanan Night Hawk',
      'Penyelesaian permintaan client dari Demonness Grub',
      'Review dan QA seluruh modul yang sudah selesai',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Weekly Sprint Minggu Ke-$weekNum',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Text(
              monthYear,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Goals Minggu Ini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...sprintGoals.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(entry.value, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalLayout(
      title: 'Detail Proyek',
      child: Column(
        children: [
          // Project Info Card (Top)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              color: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            widget.project.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.project.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.project.code,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.project.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Weekly Sprint (tappable) - posisi di bawah deskripsi
                    InkWell(
                      onTap: () => _showSprintDetail(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendarDays, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Weekly Sprint: Minggu Ke-${_getWeekOfMonth()} ${DateFormat('MMMM yyyy').format(DateTime.now())}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: DummyData.currentUser.role == 'Human Resource'
                ? const [Tab(text: 'HR View')]
                : const [Tab(text: 'Daftar Tugas'), Tab(text: 'Anggota')],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: DummyData.currentUser.role == 'Human Resource'
                  ? const [HRDashboardView()]
                  : [
                      _buildTaskList(),
                      const MemberListView(),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari tugas...',
                    prefixIcon: const Icon(LucideIcons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              if (DummyData.currentUser.role == 'Pemimpin Proyek' || 
                  DummyData.currentUser.role == 'Asisten') ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _showTaskForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Icon(LucideIcons.plus),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _tasks.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final task = _tasks[i];
                return _TaskCard(
                  task: task,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(task: task),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Done': return AppColors.statusDone;
      case 'In Progress': return AppColors.statusInProgress;
      case 'Review': return AppColors.primary;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(task.status);
    final DateFormat formatter = DateFormat('dd MMM yyyy');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task.code,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      formatter.format(task.deadline),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskFormModal extends StatefulWidget {
  final TaskItem? task;
  const _TaskFormModal({this.task});

  @override
  State<_TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends State<_TaskFormModal> {
  // List PIC yang dipilih (multiple value)
  late List<AppUser> _selectedPics;

  @override
  void initState() {
    super.initState();
    // Jika mode edit, isi PIC dari task yang ada; jika baru, kosong
    _selectedPics = widget.task != null ? [widget.task!.pic] : [];
  }

  // Membuka bottom sheet berisi checkbox untuk multi-select PIC
  void _showPicSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, controller) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pilih PIC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: DummyData.allUsers.length,
                        itemBuilder: (context, index) {
                          final user = DummyData.allUsers[index];
                          final isChecked = _selectedPics.any((u) => u.id == user.id);
                          return CheckboxListTile(
                            value: isChecked,
                            activeColor: AppColors.primary,
                            title: Text(user.name, style: const TextStyle(fontSize: 14)),
                            subtitle: Text(user.role, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            secondary: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(user.name[0], style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                            onChanged: (val) {
                              setSheetState(() {
                                if (val == true) {
                                  _selectedPics.add(user);
                                } else {
                                  _selectedPics.removeWhere((u) => u.id == user.id);
                                }
                              });
                              setState(() {}); // Update parent juga
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Selesai'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    final startDateText = widget.task != null
        ? DateFormat('dd/MM/yyyy').format(widget.task!.startDate)
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Ubah Tugas' : 'Buat Tugas Baru',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Nama Tugas
            TextField(
              controller: TextEditingController(text: widget.task?.name),
              decoration: const InputDecoration(labelText: 'Nama Tugas'),
            ),
            const SizedBox(height: 16),

            // Bobot & Label (Grid 2 kolom)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: widget.task?.weight.toString() ?? '',
                    ),
                    decoration: const InputDecoration(labelText: 'Bobot'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.task?.label ?? 'Design',
                    decoration: const InputDecoration(labelText: 'Label'),
                    items: ['Design', 'Backend', 'Frontend', 'Research']
                        .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                        .toList(),
                    onChanged: (val) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tanggal Mulai (auto-filled, read-only) & Deadline
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: false,
                    controller: TextEditingController(text: startDateText),
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Mulai',
                      suffixIcon: Icon(LucideIcons.calendar),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: widget.task != null
                          ? DateFormat('dd/MM/yyyy').format(widget.task!.deadline)
                          : '',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Deadline Tugas',
                      hintText: 'dd/mm/yyyy',
                      suffixIcon: Icon(LucideIcons.calendar),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // PIC (Dropdown Multi-select yang kompak)
            InkWell(
              onTap: () => _showPicSelector(),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'PIC (Penanggung Jawab)',
                  suffixIcon: Icon(LucideIcons.chevronDown),
                ),
                child: _selectedPics.isEmpty
                    ? const Text('Pilih anggota...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _selectedPics.map((u) => Chip(
                          label: Text(u.name, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setState(() => _selectedPics.removeWhere((p) => p.id == u.id));
                          },
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Deskripsi
            TextField(
              controller: TextEditingController(text: widget.task?.description),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Lampiran
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.background,
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.uploadCloud, size: 32, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text(
                    'Tarik & Lepas file di sini atau klik untuk mengunggah file',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol aksi
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isEdit ? 'Simpan' : 'Buat Tugas'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
