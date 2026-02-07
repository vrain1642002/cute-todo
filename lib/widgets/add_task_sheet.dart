import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/todo_model.dart';
import '../core/constants/colors.dart';
import '../services/localization_service.dart';
import '../core/utils/image_provider_util.dart';
import '../services/image_upload_service.dart';
import '../services/auth_service.dart';

class AddTaskSheet extends StatefulWidget {
  final VoidCallback onTaskAdded;
  final String? initialTitle;
  final TodoPriority? initialPriority;
  final DateTime? initialDueDate;
  final Function(
      String title,
      String? description,
      DateTime? dueDate,
      TodoPriority priority,
      TaskCategory category,
      List<String> imageUrls) onTaskCreate;

  const AddTaskSheet({
    super.key,
    required this.onTaskAdded,
    required this.onTaskCreate,
    this.initialTitle,
    this.initialPriority,
    this.initialDueDate,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late TextEditingController _titleController;
  final _descriptionController = TextEditingController();

  TodoPriority _priority = TodoPriority.medium;
  TaskCategory _category = TaskCategory.other;
  DateTime? _dueDate;
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final FocusNode _titleFocusNode = FocusNode();
  final ImageUploadService _imageUploadService = ImageUploadService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    if (widget.initialPriority != null) {
      _priority = widget.initialPriority!;
    }
    if (widget.initialDueDate != null) {
      _dueDate = widget.initialDueDate;
    }
    // Delay focus to prevent jank during opening animation
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _titleFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _createTask() async {
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
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.uid ?? 'anonymous';

      // Upload images to Cloudinary before creating task
      final List<String> remoteUrls =
          await _imageUploadService.uploadFiles(_selectedImages, userId);

      await widget.onTaskCreate(
        _titleController.text.trim(),
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        _dueDate,
        _priority,
        _category,
        remoteUrls,
      );

      if (mounted) {
        widget.onTaskAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${loc.translate('error_prefix')}${e.toString()}'),
              duration: const Duration(seconds: 4),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          child: RepaintBoundary(
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
                        loc.translate('new_task_title'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightText,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon:
                            const Icon(Icons.close_rounded, color: Colors.grey),
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
                        // Title Input
                        TextField(
                          controller: _titleController,
                          focusNode: _titleFocusNode,
                          decoration: InputDecoration(
                            hintText: loc.translate('what_needs_to_be_done'),
                            hintStyle: TextStyle(
                                color: Colors.grey[400], fontSize: 18),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.all(20),
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
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: loc.translate('add_details_optional'),
                            hintStyle: TextStyle(
                                color: Colors.grey[400], fontSize: 14),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.all(20),
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

                        // Priority Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.translate('priority'),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: TodoPriority.values.map((priority) {
                                  final isSelected = _priority == priority;
                                  Color color;
                                  String emoji;
                                  String label = '';

                                  switch (priority) {
                                    case TodoPriority.low:
                                      color = AppColors.priorityLow;
                                      emoji = '🌱';
                                      label = loc.translate('priority_low');
                                      break;
                                    case TodoPriority.medium:
                                      color = AppColors.priorityMedium;
                                      emoji = '⚡';
                                      label = loc.translate('priority_medium');
                                      break;
                                    case TodoPriority.high:
                                      color = AppColors.priorityHigh;
                                      emoji = '🔥';
                                      label = loc.translate('priority_high');
                                      break;
                                  }

                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _priority = priority),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? color.withValues(alpha: 0.15)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(14),
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
                                                  fontSize: 20)),
                                          const SizedBox(width: 8),
                                          Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? color
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Category Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.translate('category_title'),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
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
                                    onTap: () =>
                                        setState(() => _category = cat),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? color.withValues(alpha: 0.15)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(14),
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
                                                  fontSize: 20)),
                                          const SizedBox(width: 8),
                                          Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? color
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Attachments Section
                        Row(
                          children: [
                            Text(
                              loc.translate('attachments'),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            // IconButton(
                            //   onPressed: () => _pickImage(ImageSource.camera),
                            //   icon: const Icon(Icons.camera_alt_rounded,
                            //       color: AppColors.lightPrimary),
                            //   tooltip: 'Camera',
                            // ),
                            IconButton(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded,
                                  color: AppColors.lightPrimary),
                              tooltip: 'Gallery',
                            ),
                          ],
                        ),
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: getImageProvider(
                                              _selectedImages[index].path),
                                          fit: BoxFit.cover,
                                          onError: (exception, stackTrace) {
                                            debugPrint(
                                                'Image loading failed: $exception');
                                          },
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 16,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Due date picker (bottom)
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
                                if (_dueDate != null)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _dueDate = null),
                                    child: const Icon(Icons.close,
                                        size: 20,
                                        color: AppColors.lightTextSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Create button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lightPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              shadowColor:
                                  AppColors.lightPrimary.withValues(alpha: 0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.rocket_launch_rounded,
                                          color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        loc.translate('create_task'),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms, curve: Curves.easeOutQuad)
            .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOutQuad),
      ),
    );
  }
}
