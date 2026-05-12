import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Shimmer skeleton loader — used while data is loading.
// ─────────────────────────────────────────────────────────────

class VsSkeleton extends StatefulWidget {
  const VsSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<VsSkeleton> createState() => _VsSkeletonState();
}

class _VsSkeletonState extends State<VsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmer = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFE2E8F0),
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
            ],
            stops: [
              (_shimmer.value - 0.5).clamp(0.0, 1.0),
              _shimmer.value.clamp(0.0, 1.0),
              (_shimmer.value + 0.5).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Patient card skeleton
// ─────────────────────────────────────────────────────────────
class VsPatientCardSkeleton extends StatelessWidget {
  const VsPatientCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VsColors.border),
        boxShadow: VsShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          const VsSkeleton(width: 48, height: 48, borderRadius: 13),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VsSkeleton(width: 140, height: 14, borderRadius: 6),
                const SizedBox(height: 6),
                const VsSkeleton(width: 100, height: 11, borderRadius: 5),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    VsSkeleton(width: 50, height: 22, borderRadius: 6),
                    SizedBox(width: 6),
                    VsSkeleton(width: 50, height: 22, borderRadius: 6),
                    SizedBox(width: 6),
                    VsSkeleton(width: 50, height: 22, borderRadius: 6),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const VsSkeleton(width: 44, height: 44, borderRadius: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stats card skeleton
// ─────────────────────────────────────────────────────────────
class VsStatsCardSkeleton extends StatelessWidget {
  const VsStatsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VsColors.border),
        boxShadow: VsShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          VsSkeleton(width: 80, height: 11, borderRadius: 5),
          SizedBox(height: 8),
          VsSkeleton(width: 60, height: 28, borderRadius: 7),
          SizedBox(height: 8),
          VsSkeleton(width: double.infinity, height: 4, borderRadius: 99),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Full-screen loading overlay with skeleton list
// ─────────────────────────────────────────────────────────────
class VsSkeletonList extends StatelessWidget {
  const VsSkeletonList({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const VsPatientCardSkeleton(),
    );
  }
}
