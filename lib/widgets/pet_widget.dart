import 'package:flutter/material.dart';
import '../models/user_model.dart'; // For PetModel/PetMood
import '../core/constants/colors.dart';

class PetWidget extends StatefulWidget {
  final PetModel pet;
  final VoidCallback? onPetTap;

  const PetWidget({
    super.key,
    required this.pet,
    this.onPetTap,
  });

  @override
  State<PetWidget> createState() => _PetWidgetState();
}

class _PetWidgetState extends State<PetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getPetEmoji() {
    switch (widget.pet.type) {
      case PetType.cat:
        return '🐱';
      case PetType.dog:
        return '🐶';
    }
  }

  String _getMoodEmoji() {
    switch (widget.pet.mood) {
      case PetMood.happy:
        return '✨';
      case PetMood.sad:
        return '💧';
      case PetMood.sleeping:
        return '💤';
      case PetMood.neutral:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPetTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pet Name & Level
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.pet.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.lightText,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.lightPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Lv.${widget.pet.level}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animated Pet
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -_bounceAnimation.value),
                      child: Text(
                        _getPetEmoji(),
                        style: const TextStyle(fontSize: 64),
                      ),
                    );
                  },
                ),
                // Mood bubble
                if (widget.pet.mood != PetMood.neutral)
                  Positioned(
                    right: -10,
                    top: -10,
                    child: AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _bounceAnimation.value),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _getMoodEmoji(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Status Bars
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBar(
                  icon: Icons.favorite_rounded,
                  color: Colors.redAccent,
                  value: widget.pet.health,
                  label: 'Health',
                ),
                const SizedBox(width: 12),
                _buildStatBar(
                  icon: Icons.sentiment_satisfied_rounded,
                  color: Colors.orangeAccent,
                  value: widget.pet.happiness,
                  label: 'Joy',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar({
    required IconData icon,
    required Color color,
    required int value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
