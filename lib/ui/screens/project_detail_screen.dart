import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/sprint_service.dart';
import 'task_detail_screen.dart';
import 'member_list_view.dart';
import 'hr_dashboard_view.dart';
import 'package:intl/intl.dart';
import '../widgets/skeleton.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  final ProjectService _projectService = ProjectService();
  final TaskService _taskService = TaskService();
  final SprintService _sprintService = SprintService();

  TabController? _tabController;
  Project? _project;
  List<TaskItem> _tasks = [];
  List<Sprint> _sprints = [];
  bool _isLoading = true;
  bool _filterMyTasks = false;
  String _sortOrder = 'Status: Default'; // Default, TODO->DONE, DONE->TODO
  String _userRole = 'Anggota';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final results = await Future.wait([
      _projectService.getProjectDetail(widget.projectId),
      _taskService.getTasks(widget.projectId),
      _sprintService.getSprints(widget.projectId),
    ]);

    if (mounted) {
      final project = results[0] as Project?;
      final tasks = results[1] as List<TaskItem>;
      final sprints = results[2] as List<Sprint>;

      // Tentukan role user di proyek ini
      String role = 'Anggota';
      if (project != null && auth.currentUser != null) {
        for (final m in project.members) {
          if (m.userId == auth.currentUser!.id) {
            role = m.roleName;
            break;
          }
        }
      }

      // Update role di auth provider (untuk digunakan di child screens)
      auth.setProjectRole(role);

      setState(() {
        _project = project;
        _tasks = tasks;
        _sprints = sprints;
        _userRole = role;
        _isLoading = false;
      });

      // Setup tab controller berdasarkan role HANYA jika belum ada atau berganti role
      int tabCount = _userRole == 'Human Resource' ? 1 : 2;
      if (_tabController == null || _tabController!.length != tabCount) {
        _tabController?.dispose();
        _tabController = TabController(length: tabCount, vsync: this);
      }
      
      setState(() {}); // trigger rebuild
    }
  }

  void _showTaskForm([TaskItem? task]) {
    if (_project == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TaskFormModal(
        task: task,
        projectId: widget.projectId,
        members: _project!.members,
        onSaved: () {
          Navigator.pop(ctx);
          _loadData();
        },
      ),
    );
  }

  void _showSprintDetail(BuildContext context) {
    // Cari sprint aktif (yang start_date <= now <= end_date)
    final now = DateTime.now();
    Sprint? activeSprint;
    for (final s in _sprints) {
      if (!s.startDate.isAfter(now) && !s.endDate.isBefore(now)) {
        activeSprint = s;
        break;
      }
    }

    // Jika tidak ada sprint aktif, ambil yang terbaru
    activeSprint ??= _sprints.isNotEmpty ? _sprints.first : null;

    if (activeSprint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada sprint di proyek ini')),
      );
      return;
    }

    final weekNum = ((now.day - 1) ~/ 7) + 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    activeSprint!.name ?? 'Weekly Sprint Minggu Ke-$weekNum',
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
              '${DateFormat('dd MMM').format(activeSprint.startDate)} - ${DateFormat('dd MMM yyyy').format(activeSprint.endDate)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Goals Minggu Ini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (activeSprint.goals.isEmpty)
              const Text('Belum ada goals', style: TextStyle(color: AppColors.textSecondary))
            else
              ...activeSprint.goals.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entry.value.text, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
            const Text(
              'Weekly Plan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (activeSprint.weeklyPlans.isEmpty)
              const Text('Belum ada weekly plan', style: TextStyle(color: AppColors.textSecondary))
            else
              ...activeSprint.weeklyPlans.expand((wp) => wp.planningPoin).map((point) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.checkCircle, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(point, style: const TextStyle(fontSize: 14))),
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
    if (_isLoading || _tabController == null) {
      return GlobalLayout(
        title: 'Detail Proyek',
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) => const Skeleton(height: 120),
        ),
      );
    }

    if (_project == null) {
      return GlobalLayout(
        title: 'Detail Proyek',
        child: const Center(child: Text('Proyek tidak ditemukan')),
      );
    }

    final weekNum = ((DateTime.now().day - 1) ~/ 7) + 1;

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
                            _project!.name,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _project!.status,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _project!.code.isNotEmpty ? _project!.code : '—',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                    ),
                    if (_project!.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _project!.description,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Weekly Sprint (tappable)
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
                                'Weekly Sprint: Minggu Ke-$weekNum ${DateFormat('MMMM yyyy').format(DateTime.now())}',
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
            tabs: _userRole == 'Human Resource'
                ? const [Tab(text: 'HR View')]
                : const [Tab(text: 'Daftar Tugas'), Tab(text: 'Anggota')],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _userRole == 'Human Resource'
                  ? [HRDashboardView(projectId: widget.projectId)]
                  : [
                      _buildTaskList(),
                      MemberListView(
                        projectId: widget.projectId, 
                        members: _project!.members, 
                        userRole: _userRole,
                        onRefresh: _loadData,
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    final isLeaderOrAsisten = _userRole == 'Pemimpin Projek' || _userRole == 'Asisten' || _userRole == 'Pemimpin Proyek';
    final searchController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setLocalState) {
        List<TaskItem> filtered = List.from(_tasks);
        if (searchController.text.isNotEmpty) {
          filtered = filtered.where((t) =>
            t.name.toLowerCase().contains(searchController.text.toLowerCase())
          ).toList();
        }

        if (_filterMyTasks) {
          final currentUser = context.read<AuthProvider>().currentUser;
          if (currentUser != null) {
            filtered = filtered.where((t) => t.pics.any((pic) => pic.userId == currentUser.id)).toList();
          }
        }

        if (_sortOrder == 'TODO -> DONE') {
          const statusOrder = {'TODO': 1, 'IN_PROGRESS': 2, 'REVIEW': 3, 'DONE': 4};
          filtered.sort((a, b) => (statusOrder[a.status] ?? 99).compareTo(statusOrder[b.status] ?? 99));
        } else if (_sortOrder == 'DONE -> TODO') {
          const statusOrder = {'DONE': 1, 'REVIEW': 2, 'IN_PROGRESS': 3, 'TODO': 4};
          filtered.sort((a, b) => (statusOrder[a.status] ?? 99).compareTo(statusOrder[b.status] ?? 99));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari tugas...',
                        prefixIcon: const Icon(LucideIcons.search),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (_) => setLocalState(() {}),
                    ),
                  ),
                  if (isLeaderOrAsisten) ...[
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _showTaskForm,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                      child: const Icon(LucideIcons.plus),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Tugas Saya'),
                    selected: _filterMyTasks,
                    onSelected: (val) {
                      setState(() {
                        _filterMyTasks = val;
                      });
                      setLocalState(() {});
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _sortOrder,
                        icon: const Icon(LucideIcons.sortDesc, size: 16),
                        items: ['Status: Default', 'TODO -> DONE', 'DONE -> TODO']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _sortOrder = val;
                            });
                            setLocalState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
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
                              child: const Icon(LucideIcons.coffee, size: 64, color: AppColors.primary),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              searchController.text.isNotEmpty ? 'Tugas tidak ditemukan' : 'Hooray! Semua tugas selesai, waktunya ngopi ☕',
                              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final task = filtered[i];
                            return Dismissible(
                              key: ValueKey(task.id),
                              direction: task.status == 'DONE' ? DismissDirection.none : DismissDirection.startToEnd,
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 24.0),
                                decoration: BoxDecoration(
                                  color: AppColors.statusDone,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(LucideIcons.checkCircle, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Selesaikan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                final auth = context.read<AuthProvider>();
                                // Simple check if user is PIC, Asisten or Leader
                                final isLeaderOrAsisten = auth.userRole == 'Pemimpin Projek' || auth.userRole == 'Asisten' || auth.userRole == 'Pemimpin Proyek';
                                final isPic = task.pics.any((pic) => pic.userId == auth.currentUser?.id);
                                if (!isLeaderOrAsisten && !isPic) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda tidak memiliki izin menyelesaikan tugas ini.')));
                                  return false;
                                }

                                final resp = await _taskService.updateStatus(task.id, 'DONE');
                                if (resp.success) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tugas ditandai selesai!')));
                                  return true;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyelesaikan tugas.')));
                                return false;
                              },
                              onDismissed: (direction) {
                                setState(() {
                                  _tasks.removeWhere((t) => t.id == task.id);
                                });
                                _loadData();
                              },
                              child: _TaskCard(
                                task: task,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TaskDetailScreen(taskId: task.id, projectId: widget.projectId),
                                    ),
                                  );
                                  // Delay refresh until after the pop animation completes
                                  // to avoid triggering notifyListeners on a dying widget
                                  if (mounted) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) _loadData();
                                    });
                                  }
                                },
                              ),
                            );
                          },
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

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DONE': return AppColors.statusDone;
      case 'IN_PROGRESS': return AppColors.statusInProgress;
      case 'REVIEW': return AppColors.primary;
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
                  child: Text(task.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.displayStatus,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(task.label ?? '—', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (task.deadline != null)
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(formatter.format(task.deadline!), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
  final int projectId;
  final List<ProjectMember> members;
  final VoidCallback onSaved;

  const _TaskFormModal({
    this.task,
    required this.projectId,
    required this.members,
    required this.onSaved,
  });

  @override
  State<_TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends State<_TaskFormModal> {
  final TaskService _taskService = TaskService();
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _deadlineController;
  late TextEditingController _descController;
  String _selectedLabel = 'Desain';
  String _selectedPriority = 'Sedang';
  List<AppUser> _selectedPics = [];
  DateTime? _selectedDeadline;
  bool _isSaving = false;
  String? _errorText; // Fix #1: inline error instead of SnackBar

  static const _validLabels = ['Analisa', 'Backend', 'Desain', 'Evaluasi', 'Frontend', 'Riset', 'Uji Coba', 'Lainnya'];
  static const _validPriorities = ['Rendah', 'Sedang', 'Tinggi'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name);
    _weightController = TextEditingController(text: widget.task?.weight.toString() ?? '');
    _deadlineController = TextEditingController(
      text: widget.task?.deadline != null ? DateFormat('dd/MM/yyyy').format(widget.task!.deadline!) : '',
    );
    _descController = TextEditingController(text: widget.task?.description);
    _selectedLabel = _validLabels.contains(widget.task?.label) ? widget.task!.label! : 'Desain';
    _selectedPriority = _validPriorities.contains(widget.task?.priority) ? widget.task!.priority! : 'Sedang';
    _selectedDeadline = widget.task?.deadline;

    if (widget.task != null && widget.task!.picUsers.isNotEmpty) {
      _selectedPics = List.from(widget.task!.picUsers);
    } else if (widget.task?.pic != null) {
      _selectedPics = [widget.task!.pic!];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _deadlineController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _showPicSelector() {
    final activeMembers = widget.members.where((m) => m.statusMember && m.user != null).toList();

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
                padding: EdgeInsets.only(
                  left: 24, right: 24, top: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
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
                        itemCount: activeMembers.length,
                        itemBuilder: (context, index) {
                          final member = activeMembers[index];
                          final user = member.user!;
                          final isChecked = _selectedPics.any((u) => u.id == user.id);
                          return CheckboxListTile(
                            value: isChecked,
                            activeColor: AppColors.primary,
                            title: Text(user.name, style: const TextStyle(fontSize: 14)),
                            subtitle: Text(member.roleName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Selesai')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveTask() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorText = 'Nama tugas wajib diisi');
      return;
    }
    if (_selectedPics.isEmpty) {
      setState(() => _errorText = 'Minimal pilih 1 PIC');
      return;
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    final isEdit = widget.task != null;
    final resp = isEdit
        ? await _taskService.updateTask(
            widget.task!.id,
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            deadline: _selectedDeadline,
            weight: int.tryParse(_weightController.text) ?? 1,
            label: _selectedLabel,
            priority: _selectedPriority,
            picIds: _selectedPics.map((u) => u.id).toList(),
          )
        : await _taskService.createTask(
            projectId: widget.projectId,
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            deadline: _selectedDeadline,
            weight: int.tryParse(_weightController.text) ?? 1,
            label: _selectedLabel,
            priority: _selectedPriority,
            picIds: _selectedPics.map((u) => u.id).toList(),
          );

    if (mounted) {
      setState(() => _isSaving = false);
      if (resp.success) {
        widget.onSaved();
      } else {
        setState(() => _errorText = resp.message.isNotEmpty ? resp.message : 'Gagal menyimpan tugas');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;

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
                Text(isEdit ? 'Ubah Tugas' : 'Buat Tugas Baru', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
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
              decoration: const InputDecoration(label: Text.rich(TextSpan(text: 'Nama Tugas ', children: [TextSpan(text: '*', style: TextStyle(color: AppColors.statusOverdue))]))),
              onChanged: (_) { if (_errorText != null) setState(() => _errorText = null); },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Bobot'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLabel,
                    decoration: const InputDecoration(labelText: 'Label'),
                    items: _validLabels
                        .map((label) => DropdownMenuItem(value: label, child: Text(label, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) { if (val != null) setState(() => _selectedLabel = val); },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPriority,
                    decoration: const InputDecoration(labelText: 'Prioritas'),
                    items: _validPriorities
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) { if (val != null) setState(() => _selectedPriority = val); },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDeadline,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _deadlineController,
                        decoration: const InputDecoration(
                          labelText: 'Deadline',
                          suffixIcon: Icon(LucideIcons.calendar),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _showPicSelector,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  label: Text.rich(TextSpan(text: 'PIC (Penanggung Jawab) ', children: [TextSpan(text: '*', style: TextStyle(color: AppColors.statusOverdue))])),
                  suffixIcon: Icon(LucideIcons.chevronDown),
                ),
                child: _selectedPics.isEmpty
                    ? const Text('Pilih anggota...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))
                    : Wrap(
                        spacing: 6, runSpacing: 4,
                        children: _selectedPics.map((u) => Chip(
                          label: Text(u.name, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _selectedPics.removeWhere((p) => p.id == u.id)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi', alignLabelWithHint: true),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveTask,
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Simpan' : 'Buat Tugas'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
