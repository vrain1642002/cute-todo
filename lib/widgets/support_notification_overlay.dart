import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/support_action_model.dart';

/// A beautiful animated overlay that appears when support is received
class SupportNotificationOverlay extends StatelessWidget {
  final SupportAction support;
  final VoidCallback onDismiss;

  const SupportNotificationOverlay({
    super.key,
    required this.support,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onDismiss,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getMainColor().withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: support.fromUserPhotoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(support.fromUserPhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  child: support.fromUserPhotoUrl == null
                      ? Center(
                          child: Text(
                            support.fromUserName.isNotEmpty
                                ? support.fromUserName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        support.fromUserName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        support.actionDisplayName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Emoji
                Text(
                  support.actionEmoji,
                  style: const TextStyle(fontSize: 36),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 500.ms,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.2, 1.2),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                    ),
              ],
            ),
          )
              .animate()
              .slideY(
                  begin: -1,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutBack)
              .fadeIn(),
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (support.actionType) {
      case 'love':
        return [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)];
      case 'encourage':
        return [const Color(0xFFFFAA5C), const Color(0xFFFFCC80)];
      case 'pet':
        return [const Color(0xFF8D6E63), const Color(0xFFA1887F)];
      default:
        return [const Color(0xFF9C27B0), const Color(0xFFBA68C8)];
    }
  }

  Color _getMainColor() {
    switch (support.actionType) {
      case 'love':
        return const Color(0xFFFF6B6B);
      case 'encourage':
        return const Color(0xFFFFAA5C);
      case 'pet':
        return const Color(0xFF8D6E63);
      default:
        return const Color(0xFF9C27B0);
    }
  }
}

/// Widget to manage showing support notifications
class SupportNotificationManager extends StatefulWidget {
  final Widget child;
  final Stream<List<SupportAction>> supportsStream;
  final String userId;

  const SupportNotificationManager({
    super.key,
    required this.child,
    required this.supportsStream,
    required this.userId,
  });

  @override
  State<SupportNotificationManager> createState() =>
      _SupportNotificationManagerState();
}

class _SupportNotificationManagerState
    extends State<SupportNotificationManager> {
  final List<SupportAction> _pendingNotifications = [];
  SupportAction? _currentNotification;
  DateTime? _lastNotificationTime;

  @override
  void initState() {
    super.initState();
    _listenToSupports();
  }

  void _listenToSupports() {
    widget.supportsStream.listen((supports) {
      // Find new unseen supports
      for (final support in supports) {
        if (!support.seen &&
            support.fromUserId != widget.userId &&
            (_lastNotificationTime == null ||
                support.timestamp.isAfter(_lastNotificationTime!))) {
          if (!_pendingNotifications.any((n) => n.id == support.id)) {
            _pendingNotifications.add(support);
          }
        }
      }
      _showNextNotification();
    });
  }

  void _showNextNotification() {
    if (_currentNotification != null || _pendingNotifications.isEmpty) return;

    setState(() {
      _currentNotification = _pendingNotifications.removeAt(0);
      _lastNotificationTime = DateTime.now();
    });

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _currentNotification != null) {
        _dismissNotification();
      }
    });
  }

  void _dismissNotification() {
    setState(() {
      _currentNotification = null;
    });
    // Show next if any
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _showNextNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentNotification != null)
          SupportNotificationOverlay(
            support: _currentNotification!,
            onDismiss: _dismissNotification,
          ),
      ],
    );
  }
}
