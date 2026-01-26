import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/todo_model.dart';
import '../core/constants/colors.dart';
import '../services/localization_service.dart';
import '../services/auth_service.dart';
import '../services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class TaskDetailSheet extends StatefulWidget {
  final TodoModel todo;
  final Function(TodoModel updatedTodo) onTaskUpdate;

  const TaskDetailSheet({
    super.key,
    required this.todo,
    required this.onTaskUpdate,
  });

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TodoPriority _priority;
  late TaskCategory _category;
  DateTime? _dueDate;
  bool _isLoading = false;
  late bool _isReadOnly;
  late List<String> _imageUrls;
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController =
        TextEditingController(text: widget.todo.description);
    _priority = widget.todo.priority;
    _category = widget.todo.category;
    _dueDate = widget.todo.dueDate;
    _isReadOnly = widget.todo.status == TodoStatus.completed;
    _imageUrls = List.from(widget.todo.imageUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    if (_isReadOnly) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.lightPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      // Show time picker after date selection
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.lightPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      } else {
        // If time not selected, keep existing time or use end of day
        setState(() {
          final existingTime = _dueDate ?? DateTime.now();
          _dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            existingTime.hour,
            existingTime.minute,
          );
        });
      }
    }
  }

  Future<void> _updateTask() async {
    final loc = context.read<LocalizationService>();
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('please_enter_title')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedTodo = widget.todo.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
        priority: _priority,
        category: _category,
        imageUrls: _imageUrls,
      );

      await widget.onTaskUpdate(updatedTodo);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.translate('error_prefix')}$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Image with pinch to zoom
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: Colors.white54, size: 48),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.read<LocalizationService>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isReadOnly
                          ? loc.translate('task_details')
                          : loc.translate('edit_task'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightText,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 32),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compact Status & Date Row
                      Row(
                        children: [
                          Expanded(child: _buildStatusBadge(loc)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCompactedDateArea(loc)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Title Input
                      TextField(
                        controller: _titleController,
                        enabled: !_isReadOnly,
                        decoration: InputDecoration(
                          hintText: loc.translate('what_needs_to_be_done'),
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 18),
                          border: InputBorder.none,
                          filled: true,
                          fillColor:
                              _isReadOnly ? Colors.grey[50] : Colors.grey[100],
                          contentPadding: const EdgeInsets.all(20),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.lightPrimary, width: 2),
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),

                      // Description Input
                      TextField(
                        controller: _descriptionController,
                        enabled: !_isReadOnly,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: loc.translate('add_details_optional'),
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          filled: true,
                          fillColor:
                              _isReadOnly ? Colors.grey[50] : Colors.grey[100],
                          contentPadding: const EdgeInsets.all(20),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.lightPrimary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Image Attachments Display
                      if (widget.todo.imageUrls.isNotEmpty) ...[
                        Text(
                          loc.translate('attachments'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                _imageUrls.length + (_isReadOnly ? 0 : 1),
                            itemBuilder: (context, index) {
                              if (index == _imageUrls.length) {
                                // Add button
                                return GestureDetector(
                                  onTap: () async {
                                    final authService =
                                        context.read<AuthService>();
                                    final userId = authService.currentUser!.uid;

                                    // Show option dialog
                                    final source =
                                        await showModalBottomSheet<String>(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20)),
                                        ),
                                        padding: const EdgeInsets.all(24),
                                        child: Wrap(
                                          children: [
                                            Text(
                                              loc.translate('add_attachment'),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.lightText,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 20,
                                              width: double.infinity,
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                  Icons.photo_library),
                                              title: const Text('Thư viện ảnh'),
                                              onTap: () => Navigator.pop(
                                                  context, 'gallery_images'),
                                            ),
                                            // ListTile(
                                            //   leading: const Icon(
                                            //       Icons.photo_camera),
                                            //   title: const Text('Chụp ảnh'),
                                            //   onTap: () => Navigator.pop(
                                            //       context, 'camera_photo'),
                                            // ),
                                          ],
                                        ),
                                      ),
                                    );

                                    if (source == null) return;

                                    List<XFile> pickedFiles = [];
                                    if (source == 'gallery_images') {
                                      pickedFiles = await _imageUploadService
                                          .pickMultipleImages();
                                    } else if (source == 'camera_photo') {
                                      final p = await _imageUploadService
                                          .pickFromCamera(isVideo: false);
                                      if (p != null) pickedFiles.add(p);
                                    }

                                    if (pickedFiles.isNotEmpty) {
                                      setState(() => _isLoading = true);
                                      try {
                                        final urls = await _imageUploadService
                                            .uploadFiles(pickedFiles, userId);
                                        setState(() {
                                          _imageUrls.addAll(urls);
                                        });
                                      } finally {
                                        setState(() => _isLoading = false);
                                      }
                                    }
                                  },
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                          style: BorderStyle.solid),
                                    ),
                                    child: const Center(
                                        child: Icon(Icons.add_a_photo_rounded,
                                            color: Colors.grey)),
                                  ),
                                );
                              }

                              final imageUrl = _imageUrls[index];
                              final isVideo = imageUrl
                                      .toLowerCase()
                                      .contains('/video/upload/') ||
                                  imageUrl.toLowerCase().endsWith('.mp4') ||
                                  imageUrl.toLowerCase().endsWith('.mov');

                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      if (isVideo) {
                                        // Launch URL for video
                                        debugPrint(
                                            'Launching video: $imageUrl');
                                        if (await url_launcher.canLaunchUrl(
                                            Uri.parse(imageUrl))) {
                                          await url_launcher.launchUrl(
                                            Uri.parse(imageUrl),
                                            mode: url_launcher
                                                .LaunchMode.externalApplication,
                                          );
                                        } else {
                                          debugPrint(
                                              'Could not launch video url');
                                        }
                                      } else {
                                        _showFullScreenImage(context, imageUrl);
                                      }
                                    },
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      margin: const EdgeInsets.only(
                                          right: 12, top: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: isVideo
                                            ? Container(
                                                color: Colors.black87,
                                                child: const Center(
                                                    child: Icon(
                                                        Icons
                                                            .play_circle_fill_rounded,
                                                        color: Colors.white,
                                                        size: 40)),
                                              )
                                            : Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Container(
                                                    color: Colors.grey[100],
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: const Center(
                                                      child: Icon(
                                                          Icons
                                                              .broken_image_rounded,
                                                          color: Colors.grey,
                                                          size: 32),
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                  ),
                                  // Remove Button
                                  if (!_isReadOnly)
                                    Positioned(
                                      top: 0,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () async {
                                          setState(() => _isLoading = true);
                                          // Note: Cloud deletion requires backend.
                                          // We just unlink here.
                                          await _imageUploadService
                                              .deleteFile(imageUrl);
                                          setState(() {
                                            _imageUrls.removeAt(index);
                                            _isLoading = false;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 4,
                                              )
                                            ],
                                          ),
                                          child: const Icon(Icons.close_rounded,
                                              color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Merged Priority & Category Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Priority Section
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.translate('priority'),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children:
                                        TodoPriority.values.map((priority) {
                                      final isSelected = _priority == priority;
                                      Color color;
                                      String emoji;
                                      String label;

                                      switch (priority) {
                                        case TodoPriority.low:
                                          color = AppColors.priorityLow;
                                          emoji = '🌱';
                                          label = loc.translate('priority_low');
                                          break;
                                        case TodoPriority.medium:
                                          color = AppColors.priorityMedium;
                                          emoji = '⚡';
                                          label =
                                              loc.translate('priority_medium');
                                          break;
                                        case TodoPriority.high:
                                          color = AppColors.priorityHigh;
                                          emoji = '🔥';
                                          label =
                                              loc.translate('priority_high');
                                          break;
                                      }

                                      return GestureDetector(
                                        onTap: _isReadOnly
                                            ? null
                                            : () => setState(
                                                () => _priority = priority),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? color.withValues(alpha: 0.15)
                                                : Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? color
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(emoji,
                                                  style: const TextStyle(
                                                      fontSize: 18)),
                                              if (isSelected) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  label,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: color,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      )
                                          .animate(
                                              target: _isReadOnly
                                                  ? 0
                                                  : (isSelected ? 1 : 0))
                                          .scale(
                                              begin: const Offset(1, 1),
                                              end: const Offset(1.05, 1.05));
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Category Section
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.translate('category_title'),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: TaskCategory.values.map((cat) {
                                      final isSelected = _category == cat;
                                      String emoji;
                                      String label;
                                      Color color;

                                      switch (cat) {
                                        case TaskCategory.draw:
                                          color = Colors.purple;
                                          emoji = '🎨';
                                          label = loc.translate('cat_draw');
                                          break;
                                        case TaskCategory.code:
                                          color = Colors.blueGrey;
                                          emoji = '💻';
                                          label = loc.translate('cat_code');
                                          break;
                                        case TaskCategory.study:
                                          color = Colors.orange;
                                          emoji = '📚';
                                          label = loc.translate('cat_study');
                                          break;
                                        case TaskCategory.game:
                                          color = Colors.redAccent;
                                          emoji = '🎮';
                                          label = loc.translate('cat_game');
                                          break;
                                        case TaskCategory.other:
                                          color = Colors.grey;
                                          emoji = '📦';
                                          label = loc.translate('cat_other');
                                          break;
                                      }

                                      return GestureDetector(
                                        onTap: _isReadOnly
                                            ? null
                                            : () =>
                                                setState(() => _category = cat),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? color.withValues(alpha: 0.15)
                                                : Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isSelected
                                                  ? color
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(emoji,
                                                  style: const TextStyle(
                                                      fontSize: 16)),
                                              if (isSelected) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  label,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: color,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Due date picker (Moved to bottom)
                      GestureDetector(
                        onTap: _pickDueDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: _dueDate != null
                                ? Border.all(color: AppColors.info, width: 2)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: _dueDate != null
                                    ? AppColors.info
                                    : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _dueDate != null
                                    ? DateFormat('EEE, MMM d, y - HH:mm')
                                        .format(_dueDate!)
                                    : loc.translate('set_due_date'),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _dueDate != null
                                      ? AppColors.lightText
                                      : AppColors.lightTextSecondary,
                                  fontWeight: _dueDate != null
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (_dueDate != null && !_isReadOnly)
                                GestureDetector(
                                  onTap: () => setState(() => _dueDate = null),
                                  child: const Icon(Icons.close,
                                      size: 20,
                                      color: AppColors.lightTextSecondary),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Update button
                      if (!_isReadOnly)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lightPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    loc.translate('save_changes'),
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
      ),
    );
  }

  Widget _buildStatusBadge(LocalizationService loc) {
    Color color;
    String text;
    IconData icon;

    switch (widget.todo.status) {
      case TodoStatus.todo:
        color = AppColors.priorityMedium;
        text = loc.translate('status_todo');
        icon = Icons.assignment_outlined;
        break;
      case TodoStatus.inProgress:
        color = AppColors.info;
        text = loc.translate('status_in_progress');
        icon = Icons.rotate_right_rounded;
        break;
      case TodoStatus.completed:
        color = AppColors.success;
        text = loc.translate('status_completed');
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactedDateArea(LocalizationService loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              DateFormat('MMM d, HH:mm').format(widget.todo.createdAt),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
