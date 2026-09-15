import 'package:flutter/material.dart';

/// Reusable shimmer/skeleton loading effect.
/// Wraps content in an animated placeholder while data loads.
class LoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  /// Convenience constructor for a card-shaped shimmer
  const LoadingShimmer.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
    this.borderRadius = 12,
  });

  /// Convenience constructor for a circle-shaped shimmer (avatar)
  const LoadingShimmer.circle({
    super.key,
    this.width = 48,
    this.height = 48,
  }) : borderRadius = 24;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value,
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built shimmer layout for a prayer time list item.
class PrayerShimmer extends StatelessWidget {
  const PrayerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const LoadingShimmer.circle(width: 40, height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingShimmer(width: 100, height: 14),
                const SizedBox(height: 6),
                const LoadingShimmer(width: 60, height: 10),
              ],
            ),
          ),
          const LoadingShimmer(width: 60, height: 18),
        ],
      ),
    );
  }
}

/// Pre-built shimmer layout for an event card.
class EventShimmer extends StatelessWidget {
  const EventShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: LoadingShimmer.card(height: 100, borderRadius: 12),
    );
  }
}
