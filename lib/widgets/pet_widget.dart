import 'package:flutter/material.dart';
import '../models/user_model.dart'; // For PetModel/PetMood
import '../core/constants/colors.dart';

class PetWidget extends StatefulWidget {
  final PetModel pet;
  final VoidCallback? onPetTap;
  final bool isMini;

  const PetWidget({
    super.key,
    required this.pet,
    this.onPetTap,
    this.isMini = false,
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
        padding: EdgeInsets.all(widget.isMini ? 8 : 16),
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
        child: widget.isMini ? _buildMiniContent() : _buildFullContent(),
      ),
    );
  }

  Widget _buildMiniContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value * 0.5),
                  child: Text(
                    _getPetEmoji(),
                    style: const TextStyle(fontSize: 36),
                  ),
                );
              },
            ),
            if (widget.pet.mood != PetMood.neutral)
              Positioned(
                right: -4,
                top: -4,
                child: Text(
                  _getMoodEmoji(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFullContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pet Name
        Text(
          widget.pet.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.lightText,
          ),
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
      ],
    );
  }
}
