import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated shimmering effect that sweeps across child skeleton shapes
class SkeletonShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Primitive rounded rectangle/circle skeleton box
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? shape;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: shape == null
          ? BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(borderRadius),
            )
          : ShapeDecoration(
              color: const Color(0xFFE2E8F0),
              shape: shape!,
            ),
    );
  }
}

/// Skeleton placeholder for Master Profile Experience Card
class SkeletonExperienceCard extends StatelessWidget {
  const SkeletonExperienceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 44, height: 44, borderRadius: 12),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 180, height: 16),
                        SizedBox(height: 6),
                        SkeletonBox(width: 120, height: 13),
                        SizedBox(height: 6),
                        SkeletonBox(width: 150, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bullets
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 140, height: 12),
                  SizedBox(height: 12),
                  SkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: 8),
                  SkeletonBox(width: 240, height: 12),
                  SizedBox(height: 10),
                  SkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: 8),
                  SkeletonBox(width: 200, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder for Parsing & Document Extraction Screen
class SkeletonDocumentParserCard extends StatelessWidget {
  final int stage; // 0, 1, 2, 3

  const SkeletonDocumentParserCard({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                SkeletonBox(width: 36, height: 36, borderRadius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 140, height: 14),
                      SizedBox(height: 6),
                      SkeletonBox(width: 90, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const SkeletonBox(width: double.infinity, height: 12),
            const SizedBox(height: 8),
            const SkeletonBox(width: 220, height: 12),
            if (stage >= 1) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: const [
                  SkeletonBox(width: 70, height: 24, borderRadius: 6),
                  SkeletonBox(width: 85, height: 24, borderRadius: 6),
                  SkeletonBox(width: 60, height: 24, borderRadius: 6),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

