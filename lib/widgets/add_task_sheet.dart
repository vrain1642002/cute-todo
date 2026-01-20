import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/todo_model.dart';
import '../core/constants/colors.dart';

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
      EnergyLevel energyLevel) onTaskCreate;

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
  EnergyLevel _energyLevel = EnergyLevel.any;
  TaskCategory _category = TaskCategory.general;
  DateTime? _dueDate;
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _createTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a title'),
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
      await widget.onTaskCreate(
        _titleController.text.trim(),
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        _dueDate,
        _priority,
        _category,
        _energyLevel,
      );

      if (mounted) {
        widget.onTaskAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Task ✨',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightText,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Title Input
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 18),
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
                borderSide:
                    const BorderSide(color: AppColors.lightPrimary, width: 2),
              ),
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          // Description Input
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Add details (optional)...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                borderSide:
                    const BorderSide(color: AppColors.lightPrimary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Priority selector
          const Text(
            'Priority',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: TodoPriority.values.map((priority) {
              final isSelected = _priority == priority;
              Color color;
              String label;
              String emoji;

              switch (priority) {
                case TodoPriority.low:
                  color = AppColors.priorityLow;
                  label = 'Low';
                  emoji = '🌱';
                  break;
                case TodoPriority.medium:
                  color = AppColors.priorityMedium;
                  label = 'Medium';
                  emoji = '⚡';
                  break;
                case TodoPriority.high:
                  color = AppColors.priorityHigh;
                  label = 'High';
                  emoji = '🔥';
                  break;
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _priority = priority),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? color
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Due date picker
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
                        ? DateFormat('EEEE, MMMM d, y').format(_dueDate!)
                        : 'Set due date (optional)',
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
                      onTap: () => setState(() => _dueDate = null),
                      child: const Icon(Icons.close,
                          size: 20, color: AppColors.lightTextSecondary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Energy Level selector 🎭
          const Text(
            'Energy Level 🎭',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EnergyLevel.values.map((energy) {
              final isSelected = _energyLevel == energy;
              String emoji;
              String label;
              Color color;

              switch (energy) {
                case EnergyLevel.any:
                  emoji = '✨';
                  label = 'Any';
                  color = Colors.grey;
                  break;
                case EnergyLevel.lowEnergy:
                  emoji = '😴';
                  label = 'Low Energy';
                  color = Colors.blueGrey;
                  break;
                case EnergyLevel.highFocus:
                  emoji = '🎯';
                  label = 'High Focus';
                  color = Colors.red;
                  break;
                case EnergyLevel.creative:
                  emoji = '🌟';
                  label = 'Creative';
                  color = Colors.amber;
                  break;
              }

              return GestureDetector(
                onTap: () => setState(() => _energyLevel = energy),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? color.withValues(alpha: 0.15) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? color : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Category selector 📁
          const Text(
            'Category 📁',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TaskCategory>(
                value: _category,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                items: TaskCategory.values.map((cat) {
                  String emoji;
                  String label;

                  switch (cat) {
                    case TaskCategory.general:
                      emoji = '📁';
                      label = 'General';
                      break;
                    case TaskCategory.study:
                      emoji = '📚';
                      label = 'Study';
                      break;
                    case TaskCategory.exercise:
                      emoji = '💪';
                      label = 'Exercise';
                      break;
                    case TaskCategory.housework:
                      emoji = '🧹';
                      label = 'Housework';
                      break;
                    case TaskCategory.creative:
                      emoji = '🎨';
                      label = 'Creative';
                      break;
                    case TaskCategory.social:
                      emoji = '💬';
                      label = 'Social';
                      break;
                    case TaskCategory.work:
                      emoji = '💼';
                      label = 'Work';
                      break;
                    case TaskCategory.selfCare:
                      emoji = '💆';
                      label = 'Self Care';
                      break;
                  }

                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text(label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 28),

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
                elevation: 4,
                shadowColor: AppColors.lightPrimary.withValues(alpha: 0.4),
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch_rounded, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Create Task',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms),
    );
  }
}
