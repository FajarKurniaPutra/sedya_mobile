import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/task_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/skeleton.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  final int projectId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.projectId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  TaskItem? _task;
  List<ActivityLog> _logs = [];
  bool _isLoading = true;
  String _currentStatus = 'TODO';
  final TextEditingController _chatController = TextEditingController();
  bool _isSendingNote = false;
  bool _isPopping = false; // Guard: prevent rebuild during pop
  XFile? _noteAttachment;
  bool _isDescExpanded = false;

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
    final logs = await _taskService.getTaskLogs(widget.taskId);
    if (mounted && !_isPopping) {
      _safeSetState(() {
        _task = task;
        _logs = logs;
        _currentStatus = task?.status ?? 'TODO';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DONE':
        return AppColors.statusDone;
      case 'IN_PROGRESS':
        return AppColors.statusInProgress;
      case 'REVIEW':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getDisplayStatus(String backendStatus) {
    switch (backendStatus) {
      case 'IN_PROGRESS':
        return 'Proses';
      case 'REVIEW':
        return 'Review';
      case 'DONE':
        return 'Selesai';
      default:
        return 'Antrean';
    }
  }

  Future<void> _updateStatus(String newDisplayStatus) async {
    final backendStatus = TaskItem.toBackendStatus(newDisplayStatus);
    
    if (backendStatus == _currentStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada perubahan data status.')),
      );
      return;
    }
    
    final auth = context.read<AuthProvider>();
    final role = auth.userRole;
    final isLeader = role == 'Pemimpin Projek' || role == 'Pemimpin Proyek';
    final isMultiPic = (_task?.picUsers.length ?? 0) > 1;

    if (isMultiPic && (backendStatus == 'REVIEW' || backendStatus == 'DONE')) {
      if (isLeader) {
        final noteController = TextEditingController();
        final submitConfirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Konfirmasi Override Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sebagai pemimpin, Anda menggunakan otoritas override pada tugas Multi-PIC. Berikan alasan override.'),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Berikan alasan override...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  if (noteController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Alasan override wajib diisi.')));
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Konfirmasi'),
              ),
            ],
          ),
        );

        if (submitConfirm == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );
          await _taskService.addNote(
            widget.taskId,
            '[OVERRIDE PEMIMPIN] ${noteController.text.trim()}',
          );
          Navigator.pop(context); // pop loading
        } else {
          return;
        }
      } else {
        final currentUserId = auth.currentUser?.id;
        final notes = _task?.notes ?? [];
        final prefixCheck = backendStatus == 'REVIEW' ? '[KONFIRMASI PENINJAUAN]' : '[KONFIRMASI PENYELESAIAN]';
        final hasConfirmed = notes.any((n) => n.userId == currentUserId && n.message.startsWith(prefixCheck));

        if (!hasConfirmed) {
          final noteController = TextEditingController();
          final submitConfirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(backendStatus == 'REVIEW' ? 'Konfirmasi Peninjauan Tugas' : 'Konfirmasi Penyelesaian Tugas'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tugas dengan lebih dari 1 PIC memerlukan catatan konfirmasi dari setiap penanggung jawab sebelum statusnya dapat diubah.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Berikan laporan pekerjaan Anda...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    if (noteController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Catatan konfirmasi wajib diisi.')));
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Konfirmasi'),
                ),
              ],
            ),
          );

          if (submitConfirm == true) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(child: CircularProgressIndicator()),
            );
            await _taskService.addNote(
              widget.taskId,
              '$prefixCheck ${noteController.text.trim()}',
            );
            Navigator.pop(context); // pop loading
          } else {
            return;
          }
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final resp = await _taskService.updateStatus(widget.taskId, backendStatus);
    
    if (mounted && !_isPopping) {
      Navigator.pop(context);
      
      if (resp.success) {
        await _loadTask();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resp.message.isNotEmpty ? resp.message : 'Gagal mengubah status',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'zip', 'rar', 'txt', 'csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 2 * 1024 * 1024) {
          if (mounted && !_isPopping) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${file.name} melebihi 2MB')));
          return;
        }

        if (mounted && !_isPopping) {
          _safeSetState(() {
            _noteAttachment = XFile(file.path!, name: file.name);
          });
        }
      }
    } catch (e) {
      if (mounted && !_isPopping) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memilih file')));
    }
  }



  Future<void> _sendNote() async {
    // Cegah pengiriman jika teks kosong
    if (_chatController.text.trim().isEmpty) {
      if (_noteAttachment != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan teks wajib diisi meskipun mengirim lampiran'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    _safeSetState(() => _isSendingNote = true);

    final resp = await _taskService.addNote(
      widget.taskId,
      _chatController.text.trim(),
      attachmentFile: _noteAttachment,
    );

    if (mounted && !_isPopping) {
      if (resp.success) {
        _chatController.clear();
        _safeSetState(() {
          _noteAttachment = null;
        });
        await _loadTask();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resp.message.isNotEmpty ? resp.message : 'Gagal mengirim catatan',
            ),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp.message.isNotEmpty ? resp.message : 'Tugas berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resp.message.isNotEmpty ? resp.message : 'Gagal menghapus tugas',
            ),
          ),
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

  Future<void> _downloadAttachment(String type, int attachmentId, String? originalName) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mengunduh ${originalName ?? 'file'}...')));
    try {
      final bytes = await _taskService.downloadAttachment(widget.taskId, type, attachmentId);
      if (!kIsWeb) {
        try {
          final fileName = originalName ?? 'attachment_$attachmentId';
          File? savedFile;

          if (Platform.isAndroid) {
            // Coba simpan langsung ke folder Download publik (Android)
            final downloadDir = Directory('/storage/emulated/0/Download');
            if (await downloadDir.exists()) {
              final ts = DateTime.now().millisecondsSinceEpoch;
              // Tambahkan awalan timestamp agar tidak bentrok dengan file yang sudah ada dari aplikasi lain
              savedFile = File('${downloadDir.path}/${ts}_$fileName');
              await savedFile.writeAsBytes(bytes);
            }
          }

          if (savedFile != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Berhasil disimpan ke folder Download:\n${savedFile.path}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } else {
            // Fallback: iOS atau jika gagal, simpan di private folder lalu gunakan opsi share
            final dir = await getApplicationDocumentsDirectory();
            final fallbackFile = File('${dir.path}/$fileName');
            await fallbackFile.writeAsBytes(bytes);
            final xfile = XFile(fallbackFile.path);
            await Share.shareXFiles([xfile], text: 'Lampiran Tugas');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal menyimpan file ke penyimpanan internal.')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Berhasil diunduh! Silakan cek file pada platform Anda.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
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
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) => const Skeleton(height: 60),
        ),
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
    final isLeaderOrAsisten =
        role == 'Pemimpin Projek' ||
        role == 'Asisten' ||
        role == 'Pemimpin Proyek';
    final isPIC = task.picUsers.any((u) => u.id == currentUserId);
    final canChangeStatus = isLeaderOrAsisten || isPIC;
    final statusColor = _getStatusColor(_currentStatus);
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    final displayStatus = _getDisplayStatus(_currentStatus);

    return DefaultTabController(
      length: 2,
      child: GlobalLayout(
        title: 'Detail Tugas',
        child: Column(
          children: [
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Detail'),
                Tab(text: 'Riwayat'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // --- TAB 1: Detail Tugas & Chat ---
                  Column(
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
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          task.label ?? '—',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (canChangeStatus)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: displayStatus,
                                icon: Icon(
                                  LucideIcons.chevronDown,
                                  size: 14,
                                  color: statusColor,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                                items:
                                    ['Antrean', 'Proses', 'Review', 'Selesai']
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (val) {
                                  if (val != null) _updateStatus(val);
                                },
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              displayStatus,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
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
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
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
                                content: Text(
                                  'Yakin ingin menghapus tugas "${task.name}"? Tindakan ini tidak dapat dibatalkan.',
                                ),
                                actions: [
                                  OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _deleteTask();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.statusOverdue,
                                    ),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(
                            LucideIcons.trash2,
                            size: 16,
                            color: AppColors.statusOverdue,
                          ),
                          label: Text(
                            'Hapus Tugas',
                            style: TextStyle(color: AppColors.statusOverdue),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide(
                              color: AppColors.statusOverdue,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (task.deadline != null)
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Deadline: ${formatter.format(task.deadline!)}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    // PIC info
                    if (task.picUsers.isNotEmpty)
                      ...task.picUsers.map(
                        (pic) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: AppColors.primary,
                                child: Text(
                                  pic.name.isNotEmpty ? pic.name[0] : '?',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pic.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'PIC Tugas',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (task.pic != null)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: AppColors.primary,
                            child: Text(
                              task.pic!.name.isNotEmpty
                                  ? task.pic!.name[0]
                                  : '?',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.pic!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'PIC Tugas',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    // Description always shown
                    const SizedBox(height: 24),
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (task.description == null || task.description!.isEmpty)
                      Text(
                        'Tidak ada deskripsi',
                        style: TextStyle(
                          height: 1.5,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.description!,
                            maxLines: _isDescExpanded ? null : 3,
                            overflow: _isDescExpanded ? null : TextOverflow.ellipsis,
                            style: const TextStyle(height: 1.5),
                          ),
                          if (task.description!.length > 100 || '\n'.allMatches(task.description!).length > 2)
                            GestureDetector(
                              onTap: () {
                                _safeSetState(() {
                                  _isDescExpanded = !_isDescExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _isDescExpanded ? 'Tampilkan lebih sedikit' : 'Tampilkan semua deskripsi',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    
                    if (task.images.isNotEmpty || task.documents.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Lampiran Tugas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          ...task.images.map((img) => ActionChip(
                            label: Text(img.originalName ?? 'Gambar', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                            avatar: Icon(LucideIcons.image, size: 14, color: AppColors.primary),
                            onPressed: () => _downloadAttachment('images', img.id, img.originalName),
                          )),
                          ...task.documents.map((doc) => ActionChip(
                            label: Text(doc.originalName ?? 'Dokumen', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                            avatar: Icon(LucideIcons.fileText, size: 14, color: AppColors.primary),
                            onPressed: () => _downloadAttachment('documents', doc.id, doc.originalName),
                          )),
                        ],
                      ),
                    ],
                    SizedBox(height: 32),
                    Divider(color: AppColors.border),
                    const SizedBox(height: 16),
                    const Text(
                      'Diskusi Tugas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes/Chat list
                    if (task.notes.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Belum ada catatan',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: task.notes.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 16),
                        itemBuilder: (ctx, i) {
                          final note = task.notes[i];
                          final isMe = note.userId == currentUserId;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.border,
                                  child: Text(
                                    note.sender?.name.isNotEmpty == true
                                        ? note.sender!.name[0]
                                        : '?',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: IntrinsicWidth(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(16)
                                        .copyWith(
                                          topLeft: isMe
                                              ? const Radius.circular(16)
                                              : const Radius.circular(0),
                                          topRight: isMe
                                              ? const Radius.circular(0)
                                              : const Radius.circular(16),
                                        ),
                                    border: isMe
                                        ? null
                                        : Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Text(
                                          note.sender?.name ?? 'Unknown',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        note.message,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (note.documents.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ...note.documents.map((doc) => GestureDetector(
                                          onTap: () => _downloadAttachment('note-documents', doc.id, doc.originalName),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            margin: const EdgeInsets.only(top: 4),
                                            decoration: BoxDecoration(
                                              color: isMe ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(LucideIcons.paperclip, size: 12, color: isMe ? Colors.white : AppColors.primary),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    doc.originalName ?? 'Lampiran',
                                                    style: TextStyle(fontSize: 11, color: isMe ? Colors.white : AppColors.primary),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ))
                                      ],
                                      if (note.createdAt != null) ...[
                                        const SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            DateFormat('HH:mm').format(note.createdAt!),
                                            style: TextStyle(
                                              color: isMe ? Colors.white70 : AppColors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- PREVIEW FILE JIKA ADA ---
                  if (_noteAttachment != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(_noteAttachment!.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        deleteIcon: const Icon(LucideIcons.x, size: 14),
                        onDeleted: () => _safeSetState(() => _noteAttachment = null),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                    ),

                  // -------------------------------
                  Row(
                    children: [
                      // TOMBOL FILE
                      IconButton(
                        icon: Icon(
                          LucideIcons.paperclip,
                          color: AppColors.primary,
                        ),
                        onPressed: _pickAttachment,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: InputDecoration(
                            hintText: 'Ketikan pesan...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _sendNote(),
                        ),
                      ),
                      SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: _isSendingNote
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  LucideIcons.send,
                                  color: Colors.white,
                                  size: 18,
                                ),
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
        ), // End of Tab 1 Column
        // --- TAB 2: Riwayat Aktivitas ---
                  RefreshIndicator(
                    onRefresh: _loadTask,
                    child: _logs.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Text('Belum ada riwayat aktivitas', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _logs.length,
                            itemBuilder: (ctx, i) {
                              final log = _logs[i];
                              final isLast = i == _logs.length - 1;
                              final time = log.createdAt != null
                                  ? DateFormat('dd MMM, HH.mm').format(log.createdAt!)
                                  : '';
                              
                              // Determine icon & color based on action type
                              IconData iconData;
                              Color iconBgColor;
                              
                              switch (log.action) {
                                case 'status_changed':
                                  iconData = LucideIcons.refreshCcw;
                                  iconBgColor = const Color(0xFF1976D2); // Blue
                                  break;
                                case 'note_added':
                                  iconData = LucideIcons.messageSquare;
                                  iconBgColor = const Color(0xFFF59E0B); // Amber/Orange
                                  break;
                                case 'updated':
                                  iconData = LucideIcons.info;
                                  iconBgColor = const Color(0xFF607D8B); // Blue Grey
                                  break;
                                case 'created':
                                  iconData = LucideIcons.plusCircle;
                                  iconBgColor = const Color(0xFF4CAF50); // Green
                                  break;
                                default:
                                  iconData = LucideIcons.activity;
                                  iconBgColor = Colors.grey;
                              }

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Timeline column: icon + line
                                    SizedBox(
                                      width: 36,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: iconBgColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(iconData, size: 18, color: Colors.white),
                                          ),
                                          if (!isLast)
                                            Expanded(
                                              child: Container(
                                                width: 2,
                                                margin: const EdgeInsets.symmetric(vertical: 4),
                                                color: AppColors.border,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Content column
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 2),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                log.description,
                                                style: const TextStyle(fontSize: 14, height: 1.4),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                time,
                                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  String? _successText;
  List<PlatformFile> _attachmentFiles = [];

  static const _validLabels = [
    'Analisa',
    'Backend',
    'Desain',
    'Evaluasi',
    'Frontend',
    'Riset',
    'Uji Coba',
    'Lainnya',
  ];
  static const _validPriorities = ['Rendah', 'Sedang', 'Tinggi'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _weightController = TextEditingController(
      text: widget.task.weight.toString(),
    );
    _descController = TextEditingController(text: widget.task.description);
    _deadlineController = TextEditingController(
      text: widget.task.deadline != null
          ? DateFormat('dd/MM/yyyy').format(widget.task.deadline!)
          : '',
    );
    _selectedLabel = _validLabels.contains(widget.task.label)
        ? widget.task.label!
        : 'Desain';
    _selectedPriority = _validPriorities.contains(widget.task.priority)
        ? widget.task.priority!
        : 'Sedang';
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _selectedDeadline ?? today.add(const Duration(days: 7));
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

  Future<void> _pickFiles() async {
    int existingFiles = (widget.task.documents.length) + (widget.task.images.length);
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
      final resp = await _taskService.deleteAttachment(widget.task.id, type, id);
      if (mounted) {
        setState(() {
          _isSaving = false;
          if (resp.success) {
            _successText = 'Lampiran berhasil dihapus';
            if (type == 'images') {
              widget.task.images.removeWhere((i) => i.id == id);
            } else {
              widget.task.documents.removeWhere((d) => d.id == id);
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

    final currentName = widget.task.name;
    final currentDesc = widget.task.description ?? '';
    final currentDeadline = widget.task.deadline;
    final currentWeight = widget.task.weight;
    final currentLabel = widget.task.label;
    final currentPriority = widget.task.priority;
    final currentPicIds = widget.task.picUsers.map((u) => u.id).toSet();
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
    final isLabelChanged = _selectedLabel != currentLabel;
    final isPriorityChanged = _selectedPriority != currentPriority;
    
    bool isPicsChanged = currentPicIds.length != newPicIds.length || !currentPicIds.containsAll(newPicIds);
    bool isAttachmentChanged = _attachmentFiles.isNotEmpty;

    if (!isNameChanged && !isDescChanged && !isDeadlineChanged && !isWeightChanged && !isLabelChanged && !isPriorityChanged && !isPicsChanged && !isAttachmentChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada perubahan data.')),
      );
      Navigator.pop(context);
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
      picIds: _selectedPics.isNotEmpty
          ? _selectedPics.map((u) => u.id).toList()
          : null,
    );

    if (mounted) {
      if (resp.success) {
        String msg = resp.message.isNotEmpty ? resp.message : 'Tugas berhasil diperbarui';
        bool attachSuccess = true;

        if (_attachmentFiles.isNotEmpty) {
          final attachResp = await _taskService.uploadAttachments(widget.task.id, _attachmentFiles);
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
        Navigator.pop(context);
        widget.onSaved();
      } else {
        setState(
          () {
            _isSaving = false;
            _errorText = resp.message.isNotEmpty
                ? resp.message
                : 'Gagal menyimpan tugas';
          }
        );
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
        left: 24,
        right: 24,
        top: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ubah Tugas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            // Inline error message
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusOverdue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.statusOverdue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      size: 16,
                      color: AppColors.statusOverdue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorText!,
                        style: TextStyle(
                          color: AppColors.statusOverdue,
                          fontSize: 13,
                        ),
                      ),
                    ),
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
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                label: Text.rich(
                  TextSpan(
                    text: 'Nama Tugas ',
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: AppColors.statusOverdue),
                      ),
                    ],
                  ),
                ),
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
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
                        .map(
                          (label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLabel = val);
                    },
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
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPriority = val);
                    },
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
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                alignLabelWithHint: true,
              ),
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
                if (widget.task.images.isNotEmpty || widget.task.documents.isNotEmpty || _attachmentFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      ...widget.task.images.map((img) => Chip(
                        label: Text(img.originalName ?? 'Gambar', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                        avatar: const Icon(LucideIcons.image, size: 12),
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        deleteIcon: const Icon(LucideIcons.x, size: 14),
                        onDeleted: () => _deleteExistingAttachment('images', img.id),
                      )),
                      ...widget.task.documents.map((doc) => Chip(
                        label: Text(doc.originalName ?? 'Dokumen', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                        avatar: const Icon(LucideIcons.fileText, size: 12),
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        deleteIcon: const Icon(LucideIcons.x, size: 14),
                        onDeleted: () => _deleteExistingAttachment('documents', doc.id),
                      )),
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
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveTask,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
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
