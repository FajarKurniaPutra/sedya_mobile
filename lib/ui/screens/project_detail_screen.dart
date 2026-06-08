import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import '../../services/sprint_service.dart';
import 'task_detail_screen.dart';
import 'member_list_view.dart';
import 'hr_dashboard_view.dart';
import 'package:intl/intl.dart';
import '../widgets/skeleton.dart';
import 'package:file_picker/file_picker.dart';

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
  String _sortOrder = 'Antrean -> Selesai';
  String _userRole = 'Anggota';
  bool _isProjectDescExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

      // Setup tab controller berdasarkan role
      int tabCount = 2; // Semua role punya 2 tab
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Goals Minggu Ini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activeSprint.goals.isEmpty)
                      Text('Belum ada goals', style: TextStyle(color: AppColors.textSecondary))
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
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(entry.value.text, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        );
                      }),
                    if (activeSprint.weeklyPlans.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Weekly Plan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ...activeSprint.weeklyPlans.expand((wp) => wp.planningPoin).map((point) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(LucideIcons.checkCircle, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(point, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
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

    final now = DateTime.now();
    Sprint? activeSprint;
    for (final s in _sprints) {
      if (!s.startDate.isAfter(now) && !s.endDate.isBefore(now)) {
        activeSprint = s;
        break;
      }
    }

    final weekNum = ((now.day - 1) ~/ 7) + 1;
    final indonesianMonths = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final monthName = indonesianMonths[now.month - 1];

    return GlobalLayout(
      title: 'Detail Proyek',
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
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
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (_project!.code.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.hash, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 4),
                                  Text(_project!.code, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                                ],
                              ),
                            if (_project!.type != null && _project!.type!.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.briefcase, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 4),
                                  Text(_project!.type!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                                ],
                              ),
                            if (_project!.phase.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.gitCommit, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 4),
                                  Text(_project!.phase, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                                ],
                              ),
                          ],
                        ),
                        if (_project!.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isProjectDescExpanded = !_isProjectDescExpanded;
                              });
                            },
                            child: Text(
                              _project!.description,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              maxLines: _isProjectDescExpanded ? null : 3,
                              overflow: _isProjectDescExpanded ? null : TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Weekly Sprint (tappable / non-tappable)
                        if (activeSprint != null)
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
                                      'Weekly Sprint: Minggu Ke-$weekNum $monthName ${now.year}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Icon(LucideIcons.chevronRight, color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.calendarX2, color: Colors.white.withValues(alpha: 0.5), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tidak ada sprint di minggu ini',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: _userRole == 'Human Resource'
                      ? const [Tab(text: 'Daftar Tugas'), Tab(text: 'HR Overview')]
                      : const [Tab(text: 'Daftar Tugas'), Tab(text: 'Anggota')],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _userRole == 'Human Resource'
              ? [
                  _buildTaskList(),
                  HRDashboardView(projectId: widget.projectId),
                ]
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
    );
  }

  Widget _buildTaskList() {
    final isLeaderOrAsisten = _userRole == 'Pemimpin Projek' || _userRole == 'Asisten' || _userRole == 'Pemimpin Proyek';

    return StatefulBuilder(
      builder: (context, setLocalState) {
        List<TaskItem> filtered = List.from(_tasks);
        if (_searchController.text.isNotEmpty) {
          filtered = filtered.where((t) =>
            t.name.toLowerCase().contains(_searchController.text.toLowerCase())
          ).toList();
        }

        if (_filterMyTasks) {
          final currentUser = context.read<AuthProvider>().currentUser;
          if (currentUser != null) {
            filtered = filtered.where((t) => t.picUsers.any((pic) => pic.id == currentUser.id)).toList();
          }
        }

        if (_sortOrder == 'Antrean -> Selesai') {
          const statusOrder = {'TODO': 1, 'IN_PROGRESS': 2, 'REVIEW': 3, 'DONE': 4};
          filtered.sort((a, b) {
            int statA = statusOrder[a.status] ?? 99;
            int statB = statusOrder[b.status] ?? 99;
            if (statA != statB) return statA.compareTo(statB);
            return a.id.compareTo(b.id); // Waktu ditambahkan (ascending)
          });
        } else if (_sortOrder == 'Selesai -> Antrean') {
          const statusOrder = {'DONE': 1, 'REVIEW': 2, 'IN_PROGRESS': 3, 'TODO': 4};
          filtered.sort((a, b) {
            int statA = statusOrder[a.status] ?? 99;
            int statB = statusOrder[b.status] ?? 99;
            if (statA != statB) return statA.compareTo(statB);
            return b.id.compareTo(a.id);
          });
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
                      controller: _searchController,
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
                        icon: const Icon(LucideIcons.listFilter, size: 16),
                        items: ['Antrean -> Selesai', 'Selesai -> Antrean']
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
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.coffee, size: 64, color: AppColors.primary),
                              ),
                              SizedBox(height: 24),
                              Text(
                                _searchController.text.isNotEmpty ? 'Tugas tidak ditemukan' : 'Waktunya ngopi atau rencanakan tugas baru untuk tim Anda.',
                                style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final task = filtered[i];
                            return _TaskCard(
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
                Text(task.label ?? '—', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (task.deadline != null)
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text(formatter.format(task.deadline!), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
  String? _selectedLabel;
  String _selectedPriority = 'Rendah';
  List<AppUser> _selectedPics = [];
  DateTime? _selectedDeadline;
  bool _isSaving = false;
  String? _errorText; // Fix #1: inline error instead of SnackBar
  String? _successText;
  List<PlatformFile> _attachmentFiles = [];

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
    _selectedLabel = _validLabels.contains(widget.task?.label) ? widget.task!.label! : null;
    _selectedPriority = _validPriorities.contains(widget.task?.priority) ? widget.task!.priority! : 'Rendah';
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedDeadline ?? today;
    final firstDate = initialDate.isBefore(today) ? initialDate : today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
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
                            title: Text(user.name, style: TextStyle(fontSize: 14)),
                            subtitle: Text(member.roleName, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            secondary: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(user.name[0], style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
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

  Future<void> _pickFiles() async {
    int existingFiles = (widget.task?.documents.length ?? 0) + (widget.task?.images.length ?? 0);
    int remaining = 5 - (existingFiles + _attachmentFiles.length);
    if (remaining <= 0) {
      setState(() {
        _errorText = 'Maksimal 5 file untuk 1 tugas.';
      });
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'zip', 'rar', 'txt', 'csv'],
      );

      if (result != null) {
        List<PlatformFile> validFiles = [];
        bool hasOversizeError = false;
        for (var file in result.files) {
          if (file.size > 2 * 1024 * 1024) {
            hasOversizeError = true;
            if (mounted) {
              setState(() {
                _errorText = '${file.name} melebihi 2MB';
                _successText = null;
              });
            }
            continue;
          }
          validFiles.add(file);
        }

        if (validFiles.length > remaining) {
          if (mounted) {
            setState(() {
              _errorText = 'Sisa slot lampiran: $remaining. Tidak bisa menambah ${validFiles.length} file.';
              _successText = null;
            });
          }
          return;
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            _attachmentFiles.addAll(validFiles);
            _successText = '${validFiles.length} file berhasil ditambahkan';
            if (!hasOversizeError) _errorText = null;
          });

          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _successText = null);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Gagal memilih file';
          _successText = null;
        });
      }
    }
  }

  Future<void> _deleteExistingAttachment(String type, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Lampiran?'),
        content: const Text('Tindakan ini akan menghapus file dari server dan tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      final resp = await _taskService.deleteAttachment(widget.task!.id, type, id);
      if (mounted) {
        setState(() {
          _isSaving = false;
          if (resp.success) {
            _successText = 'Lampiran berhasil dihapus';
            if (type == 'images') {
              widget.task!.images.removeWhere((i) => i.id == id);
            } else {
              widget.task!.documents.removeWhere((d) => d.id == id);
            }
          } else {
            _errorText = resp.message.isNotEmpty ? resp.message : 'Gagal menghapus lampiran';
          }
        });
      }
    }
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
    if (_selectedDeadline == null) {
      setState(() => _errorText = 'Deadline tugas wajib diisi');
      return;
    }


    final isEdit = widget.task != null;
    
    if (isEdit) {
      final task = widget.task!;
      final currentName = task.name;
      final currentDesc = task.description ?? '';
      final currentDeadline = task.deadline;
      final currentWeight = task.weight;
      final currentLabel = task.label ?? 'Lainnya';
      final currentPriority = task.priority;
      final currentPicIds = task.picUsers.map((u) => u.id).toSet();
      final newPicIds = _selectedPics.map((u) => u.id).toSet();

      final isNameChanged = _nameController.text.trim() != currentName;
      final isDescChanged = _descController.text.trim() != currentDesc;
      
      bool isDeadlineChanged = false;
      if (_selectedDeadline == null && currentDeadline != null) isDeadlineChanged = true;
      if (_selectedDeadline != null && currentDeadline == null) isDeadlineChanged = true;
      if (_selectedDeadline != null && currentDeadline != null) {
        if (_selectedDeadline!.year != currentDeadline.year ||
            _selectedDeadline!.month != currentDeadline.month ||
            _selectedDeadline!.day != currentDeadline.day) {
          isDeadlineChanged = true;
        }
      }

      final newWeight = int.tryParse(_weightController.text) ?? 1;
      final isWeightChanged = newWeight != currentWeight;
      
      final isLabelChanged = (_selectedLabel ?? 'Lainnya') != currentLabel;
      final isPriorityChanged = _selectedPriority != currentPriority;
      
      bool isPicsChanged = currentPicIds.length != newPicIds.length || !currentPicIds.containsAll(newPicIds);
      bool isAttachmentChanged = _attachmentFiles.isNotEmpty;

      if (!isNameChanged && !isDescChanged && !isDeadlineChanged && !isWeightChanged && !isLabelChanged && !isPriorityChanged && !isPicsChanged && !isAttachmentChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada perubahan data yang disimpan.')),
        );
        Navigator.pop(context);
        return;
      }
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    final resp = isEdit
        ? await _taskService.updateTask(
            widget.task!.id,
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            deadline: _selectedDeadline,
            weight: int.tryParse(_weightController.text) ?? 1,
            label: _selectedLabel ?? 'Lainnya',
            priority: _selectedPriority,
            picIds: _selectedPics.map((u) => u.id).toList(),
          )
        : await _taskService.createTask(
            projectId: widget.projectId,
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            deadline: _selectedDeadline,
            weight: int.tryParse(_weightController.text) ?? 1,
            label: _selectedLabel ?? 'Lainnya',
            priority: _selectedPriority,
            picIds: _selectedPics.map((u) => u.id).toList(),
          );

    if (mounted) {
      if (resp.success) {
        int newTaskId = isEdit ? widget.task!.id : (resp.data != null && resp.data['id'] != null ? resp.data['id'] : 0);
        String msg = resp.message.isNotEmpty ? resp.message : (isEdit ? 'Tugas berhasil diperbarui' : 'Tugas berhasil dibuat');
        bool attachSuccess = true;

        if (_attachmentFiles.isNotEmpty && newTaskId > 0) {
          final attachResp = await _taskService.uploadAttachments(newTaskId, _attachmentFiles);
          if (!attachResp.success) {
             msg = 'Tugas tersimpan, tapi gagal unggah lampiran: ${attachResp.message}';
             attachSuccess = false;
          } else {
             msg = '$msg dan lampiran berhasil diunggah';
          }
        }
        
        setState(() => _isSaving = false);
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: attachSuccess ? Colors.green : Colors.orange,
          ),
        );
        widget.onSaved();
      } else {
        setState(() {
          _isSaving = false;
          _errorText = resp.message.isNotEmpty ? resp.message : 'Gagal menyimpan tugas';
        });
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
                    Icon(LucideIcons.alertCircle, size: 16, color: AppColors.statusOverdue),
                    SizedBox(width: 8),
                    Expanded(child: Text(_errorText!, style: TextStyle(color: AppColors.statusOverdue, fontSize: 13))),
                  ],
                ),
              ),
            ],
            if (_successText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.checkCircle, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(child: Text(_successText!, style: TextStyle(color: Colors.green, fontSize: 13))),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(text: 'Nama Tugas', children: [TextSpan(text: '\u00A0*', style: TextStyle(color: AppColors.statusOverdue))]),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
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
                    value: _selectedLabel,
                    hint: const Text('Pilih Label', style: TextStyle(fontSize: 13)),
                    decoration: const InputDecoration(labelText: 'Label'),
                    items: _validLabels
                        .map((label) => DropdownMenuItem(value: label, child: Text(label, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) { if (val != null) setState(() { _selectedLabel = val; _errorText = null; }); },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    hint: const Text('Pilih Prioritas', style: TextStyle(fontSize: 13)),
                    decoration: const InputDecoration(labelText: 'Prioritas'),
                    items: _validPriorities
                        .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13))))
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
                        decoration: InputDecoration(
                          label: Text.rich(
                            TextSpan(text: 'Deadline', children: [TextSpan(text: '\u00A0*', style: TextStyle(color: AppColors.statusOverdue))]),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                          ),
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
                decoration: InputDecoration(
                  label: Text.rich(
                    TextSpan(text: 'PIC (Penanggung Jawab)', children: [TextSpan(text: '\u00A0*', style: TextStyle(color: AppColors.statusOverdue))]),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                  suffixIcon: Icon(LucideIcons.chevronDown),
                ),
                child: _selectedPics.isEmpty
                    ? Text('Pilih anggota...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))
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
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lampiran File (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _attachmentFiles.length >= 5 ? null : _pickFiles,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _attachmentFiles.length >= 5 ? Colors.grey : AppColors.primary.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _attachmentFiles.length >= 5 ? Colors.grey.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.05),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.uploadCloud,
                          size: 32,
                          color: _attachmentFiles.length >= 5 ? Colors.grey : AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _attachmentFiles.length >= 5 ? 'Batas maksimal 5 file' : 'Tekan untuk mengunggah file',
                          style: TextStyle(
                            color: _attachmentFiles.length >= 5 ? Colors.grey : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Maks. 2MB per file (Dokumen/Gambar)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                if (widget.task != null || _attachmentFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      if (widget.task != null) ...[
                        ...widget.task!.images.map((img) => Chip(
                          label: Text(img.originalName ?? 'Gambar', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                          avatar: const Icon(LucideIcons.image, size: 12),
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          deleteIcon: const Icon(LucideIcons.x, size: 14),
                          onDeleted: () => _deleteExistingAttachment('images', img.id),
                        )),
                        ...widget.task!.documents.map((doc) => Chip(
                          label: Text(doc.originalName ?? 'Dokumen', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                          avatar: const Icon(LucideIcons.fileText, size: 12),
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          deleteIcon: const Icon(LucideIcons.x, size: 14),
                          onDeleted: () => _deleteExistingAttachment('documents', doc.id),
                        )),
                      ],
                      ..._attachmentFiles.asMap().entries.map((entry) {
                        int idx = entry.key;
                        PlatformFile file = entry.value;
                        return Chip(
                          label: Text(file.name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                          deleteIcon: const Icon(LucideIcons.x, size: 14),
                          onDeleted: () => setState(() => _attachmentFiles.removeAt(idx)),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        );
                      }),
                    ],
                  ),
                ],
              ],
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
                      : Text(isEdit ? 'Simpan' : 'Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;

  _StickyTabBarDelegate(this.child);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  double get maxExtent => child.preferredSize.height;

  @override
  double get minExtent => child.preferredSize.height;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
