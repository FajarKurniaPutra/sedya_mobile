import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../global_layout.dart';
import '../../core/constants.dart';
import '../../core/dummy_data.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskItem task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task.status;
  }
  final List<ChatMessage> _chats = DummyData.chats;
  final TextEditingController _chatController = TextEditingController();

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
    final statusColor = _getStatusColor(_currentStatus);
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    final role = DummyData.currentUser.role;
    final isLeaderOrAsisten = role == 'Pemimpin Proyek' || role == 'Asisten';
    final canChangeStatus = isLeaderOrAsisten || DummyData.currentUser.id == widget.task.pic.id;

    return GlobalLayout(
      title: 'Detail Tugas',
      child: Column(
        children: [
          // Task Info
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.name,
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
                        widget.task.code,
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
                              value: _currentStatus,
                              icon: Icon(LucideIcons.chevronDown, size: 14, color: statusColor),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                              items: ['Not Started', 'In Progress', 'Review', 'Done']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _currentStatus = val);
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
                            _currentStatus,
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
                    // Tombol Ubah - full width dengan ikon
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => _TaskEditModal(task: widget.task),
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
                    // Tombol Hapus - full width dengan ikon, warna merah
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Hapus Tugas'),
                              content: Text('Yakin ingin menghapus tugas "${widget.task.name}"? Tindakan ini tidak dapat dibatalkan.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
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
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Deadline: ${formatter.format(widget.task.deadline)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primary,
                        child: Text(widget.task.pic.name[0], style: const TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.task.pic.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Text('PIC Tugas', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    widget.task.description,
                    style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  
                  // Chat Messages List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _chats.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) {
                      final chat = _chats[i];
                      final isMe = chat.sender.id == DummyData.currentUser.id;
                      
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.border,
                              child: Text(chat.sender.name[0], style: const TextStyle(fontSize: 10)),
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
                                      chat.sender.name,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    chat.message,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) const SizedBox(width: 24), // spacing logic for layout
                        ],
                      );
                    },
                  ),
                ],
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
              child: Row(
                children: [
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                      onPressed: () {
                        // Mock sending message
                        if (_chatController.text.isNotEmpty) {
                          setState(() {
                            _chats.add(ChatMessage(
                              id: 'new',
                              taskId: widget.task.id,
                              sender: DummyData.currentUser,
                              message: _chatController.text,
                              timestamp: DateTime.now(),
                            ));
                            _chatController.clear();
                          });
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modal form untuk MENGUBAH tugas (isinya sudah terisi dari data task yang dipilih)
class _TaskEditModal extends StatefulWidget {
  final TaskItem task;

  const _TaskEditModal({required this.task});

  @override
  State<_TaskEditModal> createState() => _TaskEditModalState();
}

class _TaskEditModalState extends State<_TaskEditModal> {
  late List<AppUser> _selectedPics;

  @override
  void initState() {
    super.initState();
    _selectedPics = [widget.task.pic];
  }

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
                              setState(() {});
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
            // Header modal
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
                )
              ],
            ),
            const SizedBox(height: 16),

            // Nama Tugas
            TextField(
              controller: TextEditingController(text: widget.task.name),
              decoration: const InputDecoration(labelText: 'Nama Tugas'),
            ),
            const SizedBox(height: 16),

            // Bobot & Label
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: widget.task.weight.toString()),
                    decoration: const InputDecoration(labelText: 'Bobot'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.task.label,
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

            // Tanggal Mulai (read-only) & Deadline
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: false,
                    controller: TextEditingController(
                      text: DateFormat('dd/MM/yyyy').format(widget.task.startDate),
                    ),
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
                      text: DateFormat('dd/MM/yyyy').format(widget.task.deadline),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Deadline Tugas',
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
              controller: TextEditingController(text: widget.task.description),
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
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
