import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/task_service.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  final int projectId;

  const TaskDetailScreen({super.key, required this.taskId, required this.projectId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  TaskItem? _task;
  bool _isLoading = true;
  String _currentStatus = 'TODO';
  final TextEditingController _chatController = TextEditingController();
  bool _isSendingNote = false;
  bool _isPopping = false; // Guard: prevent rebuild during pop
  final ImagePicker _picker = ImagePicker();
  File? _gambarPilihan; // Untuk menyimpan gambar yang dipilih (Android/iOS)
  XFile? _gambarWeb; // Untuk menangani gambar khusus di Web (Chrome)

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  /// Safe setState that checks mounted AND not-popping
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isPopping) setState(fn);
  }

  Future<void> _loadTask() async {
    if (!mounted || _isPopping) return;
    _safeSetState(() => _isLoading = true);
    final task = await _taskService.getTaskDetail(widget.taskId);
    if (mounted && !_isPopping) {
      _safeSetState(() {
        _task = task;
        _currentStatus = task?.status ?? 'TODO';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DONE': return AppColors.statusDone;
      case 'IN_PROGRESS': return AppColors.statusInProgress;
      case 'REVIEW': return AppColors.primary;
      default: return AppColors.textSecondary;
    }
  }

  String _getDisplayStatus(String backendStatus) {
    switch (backendStatus) {
      case 'IN_PROGRESS': return 'In Progress';
      case 'REVIEW': return 'Review';
      case 'DONE': return 'Done';
      default: return 'Not Started';
    }
  }

  Future<void> _updateStatus(String newDisplayStatus) async {
    final backendStatus = TaskItem.toBackendStatus(newDisplayStatus);
    final resp = await _taskService.updateStatus(widget.taskId, backendStatus);
    if (mounted && !_isPopping) {
      if (resp.success) {
        _safeSetState(() => _currentStatus = backendStatus);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : 'Gagal mengubah status')),
        );
      }
    }
  }

  Future<void> _ambilGambar(ImageSource sumber) async {
  try {
    final XFile? gambar = await _picker.pickImage(source: sumber);
    
    if (gambar != null && mounted && !_isPopping) {
      _safeSetState(() {
        if (kIsWeb) {
          _gambarWeb = gambar;
        } else {
          _gambarPilihan = File(gambar.path);
        }
      });
      // TODO: Disini tempat fungsi memanggil API untuk upload gambar ke server
      print("Berhasil memilih gambar: ${gambar.name}");
      
      // Opsional: Tampilkan feedback ke pengguna
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Gambar ${gambar.name} dipilih. (Fitur upload belum disambung)')),
      );
    }
  } catch (e) {
    print("Error mengambil gambar: $e");
  }
}

void _tampilkanPilihanMedia(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.of(context).pop(); 
                _ambilGambar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Ambil Foto (Kamera)'),
              onTap: () {
                Navigator.of(context).pop();
                _ambilGambar(ImageSource.camera);
              },
            ),
          ],
        ),
      );
    },
  );
}

  Future<void> _sendNote() async {
    // Cegah pengiriman jika teks kosong DAN tidak ada gambar
    if (_chatController.text.trim().isEmpty && _gambarPilihan == null && _gambarWeb == null) return;
    
    _safeSetState(() => _isSendingNote = true);

    // TODO: Pastikan _taskService.addNote milikmu sudah diperbarui untuk menerima parameter file gambar
    final resp = await _taskService.addNote(
      widget.taskId, 
      _chatController.text.trim(),
    );

    if (mounted && !_isPopping) {
      if (resp.success) {
        _chatController.clear();
        _safeSetState(() {
          _gambarPilihan = null;
          _gambarWeb = null;
        });
        await _loadTask();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : 'Gagal mengirim catatan')),
        );
      }
    }

    _safeSetState(() => _isSendingNote = false);
  }

  Future<void> _deleteTask() async {
    final resp = await _taskService.deleteTask(widget.taskId);
    if (mounted && !_isPopping) {
      if (resp.success) {
        _safePop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : 'Gagal menghapus tugas')),
        );
      }
    }
  }

  /// Safe pop: set guard flag BEFORE calling Navigator.pop to prevent any
  /// rebuild from crashing the widget during the pop animation.
  void _safePop() {
    if (_isPopping) return;
    _isPopping = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Early return: if we're in the process of popping, show a minimal safe widget
    if (_isPopping) {
      return GlobalLayout(
        title: 'Detail Tugas',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoading) {
      return GlobalLayout(
        title: 'Detail Tugas',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final task = _task;
    if (task == null) {
      return GlobalLayout(
        title: 'Detail Tugas',
        child: const Center(child: Text('Tugas tidak ditemukan')),
      );
    }

    // Capture provider values ONCE at top, no subscription
    final auth = context.watch<AuthProvider>();
    final role = auth.userRole;
    final currentUserId = auth.currentUser?.id;
    final isLeaderOrAsisten = role == 'Pemimpin Projek' || role == 'Asisten' || role == 'Pemimpin Proyek';
    final isPIC = task.picUsers.any((u) => u.id == currentUserId);
    final canChangeStatus = isLeaderOrAsisten || isPIC;
    final statusColor = _getStatusColor(_currentStatus);
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    final displayStatus = _getDisplayStatus(_currentStatus);

    return GlobalLayout(
      title: 'Detail Tugas',
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTask,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          task.label ?? '—',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        if (canChangeStatus)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: displayStatus,
                                icon: Icon(LucideIcons.chevronDown, size: 14, color: statusColor),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                                items: ['Not Started', 'In Progress', 'Review', 'Done']
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) _updateStatus(val);
                                },
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              displayStatus,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                      ],
                    ),
                    if (isLeaderOrAsisten) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => _TaskEditModal(
                                task: task,
                                onSaved: () {
                                  Navigator.pop(ctx);
                                  _loadTask();
                                },
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.edit2, size: 16),
                          label: const Text('Ubah Tugas'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Tugas'),
                                content: Text('Yakin ingin menghapus tugas "${task.name}"? Tindakan ini tidak dapat dibatalkan.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _deleteTask();
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusOverdue),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.statusOverdue),
                          label: const Text('Hapus Tugas', style: TextStyle(color: AppColors.statusOverdue)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            side: const BorderSide(color: AppColors.statusOverdue),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (task.deadline != null)
                      Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text('Deadline: ${formatter.format(task.deadline!)}', style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    const SizedBox(height: 16),
                    // PIC info
                    if (task.picUsers.isNotEmpty)
                      ...task.picUsers.map((pic) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              foregroundColor: AppColors.primary,
                              child: Text(pic.name.isNotEmpty ? pic.name[0] : '?', style: const TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pic.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Text('PIC Tugas', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            )
                          ],
                        ),
                      ))
                    else if (task.pic != null)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            foregroundColor: AppColors.primary,
                            child: Text(task.pic!.name.isNotEmpty ? task.pic!.name[0] : '?', style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.pic!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Text('PIC Tugas', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          )
                        ],
                      ),
                    // Description always shown
                    const SizedBox(height: 24),
                    const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      (task.description != null && task.description!.isNotEmpty) ? task.description! : 'Tidak ada deskripsi',
                      style: TextStyle(
                        height: 1.5,
                        color: (task.description != null && task.description!.isNotEmpty) ? null : AppColors.textSecondary,
                        fontStyle: (task.description != null && task.description!.isNotEmpty) ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 16),
                    const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),

                    // Notes/Chat list
                    if (task.notes.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Belum ada catatan', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: task.notes.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                        itemBuilder: (ctx, i) {
                          final note = task.notes[i];
                          final isMe = note.userId == currentUserId;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.border,
                                  child: Text(
                                    note.sender?.name.isNotEmpty == true ? note.sender!.name[0] : '?',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppColors.primary : AppColors.surface,
                                    borderRadius: BorderRadius.circular(16).copyWith(
                                      topLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                                      topRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                                    ),
                                    border: isMe ? null : Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Text(
                                          note.sender?.name ?? 'Unknown',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        note.message,
                                        style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isMe) const SizedBox(width: 24),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Sticky Footer Chat Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- PREVIEW GAMBAR JIKA ADA ---
                  if (_gambarPilihan != null || _gambarWeb != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: kIsWeb && _gambarWeb != null
                                    ? NetworkImage(_gambarWeb!.path) as ImageProvider
                                    : FileImage(_gambarPilihan!),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -10,
                            top: -10,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () {
                                _safeSetState(() {
                                  _gambarPilihan = null;
                                  _gambarWeb = null;
                                });
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  // -------------------------------

                  Row(
                    children: [
                      // TOMBOL KAMERA
                      IconButton(
                        icon: const Icon(LucideIcons.camera, color: AppColors.primary),
                        onPressed: () => _tampilkanPilihanMedia(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: InputDecoration(
                            hintText: 'Ketikan pesan...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          onSubmitted: (_) => _sendNote(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: _isSendingNote
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : IconButton(
                                icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                                onPressed: _sendNote,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal form untuk MENGUBAH tugas
class _TaskEditModal extends StatefulWidget {
  final TaskItem task;
  final VoidCallback onSaved;

  const _TaskEditModal({required this.task, required this.onSaved});

  @override
  State<_TaskEditModal> createState() => _TaskEditModalState();
}

class _TaskEditModalState extends State<_TaskEditModal> {
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
  String? _errorText;

  static const _validLabels = ['Analisa', 'Backend', 'Desain', 'Evaluasi', 'Frontend', 'Riset', 'Uji Coba', 'Lainnya'];
  static const _validPriorities = ['Rendah', 'Sedang', 'Tinggi'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _weightController = TextEditingController(text: widget.task.weight.toString());
    _descController = TextEditingController(text: widget.task.description);
    _deadlineController = TextEditingController(
      text: widget.task.deadline != null ? DateFormat('dd/MM/yyyy').format(widget.task.deadline!) : '',
    );
    _selectedLabel = _validLabels.contains(widget.task.label) ? widget.task.label! : 'Desain';
    _selectedPriority = _validPriorities.contains(widget.task.priority) ? widget.task.priority! : 'Sedang';
    _selectedDeadline = widget.task.deadline;
    _selectedPics = widget.task.picUsers.isNotEmpty
        ? List.from(widget.task.picUsers)
        : (widget.task.pic != null ? [widget.task.pic!] : []);
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

  Future<void> _saveTask() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorText = 'Nama tugas wajib diisi');
      return;
    }

    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    final resp = await _taskService.updateTask(
      widget.task.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      deadline: _selectedDeadline,
      weight: int.tryParse(_weightController.text) ?? 1,
      label: _selectedLabel,
      priority: _selectedPriority,
      picIds: _selectedPics.isNotEmpty ? _selectedPics.map((u) => u.id).toList() : null,
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
                const Text('Ubah Tugas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
              ],
            ),
            // Inline error message
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
                label: Text.rich(TextSpan(text: 'Nama Tugas ', children: [TextSpan(text: '*', style: TextStyle(color: AppColors.statusOverdue))])),
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
                    initialValue: _selectedLabel,
                    decoration: const InputDecoration(labelText: 'Label'),
                    items: _validLabels
                        .map((label) => DropdownMenuItem(value: label, child: Text(label)))
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
                          labelText: 'Deadline Tugas',
                          suffixIcon: Icon(LucideIcons.calendar),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
