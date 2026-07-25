import 'package:flutter/material.dart';

class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({
    super.key,
    this.height = 20,
    this.width = double.infinity,
    this.borderRadius = 12,
  });

  final double height;
  final double width;
  final double borderRadius;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.75).animate(
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
    final Color color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

class DashboardHeaderSkeleton extends StatelessWidget {
  const DashboardHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ShimmerSkeleton(height: 14, width: 120, borderRadius: 6),
        SizedBox(height: 10),
        ShimmerSkeleton(height: 28, width: 220, borderRadius: 8),
        SizedBox(height: 8),
        ShimmerSkeleton(height: 16, width: 280, borderRadius: 6),
      ],
    );
  }
}

class HeroCardSkeleton extends StatelessWidget {
  const HeroCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ShimmerSkeleton(height: 14, width: 140, borderRadius: 6),
                  SizedBox(height: 14),
                  ShimmerSkeleton(height: 40, width: 180, borderRadius: 10),
                  SizedBox(height: 12),
                  ShimmerSkeleton(height: 14, width: 160, borderRadius: 6),
                ],
              ),
            ),
            SizedBox(width: 16),
            ShimmerSkeleton(height: 130, width: 130, borderRadius: 65),
          ],
        ),
      ),
    );
  }
}

class ProgressCardSkeleton extends StatelessWidget {
  const ProgressCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ShimmerSkeleton(height: 40, width: 40, borderRadius: 12),
            SizedBox(height: 16),
            ShimmerSkeleton(height: 14, width: 100, borderRadius: 6),
            SizedBox(height: 10),
            ShimmerSkeleton(height: 26, width: 140, borderRadius: 8),
            SizedBox(height: 8),
            ShimmerSkeleton(height: 14, width: 180, borderRadius: 6),
            SizedBox(height: 16),
            ShimmerSkeleton(height: 8, width: double.infinity, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

class QuickStatsSkeleton extends StatelessWidget {
  const QuickStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: 4,
      itemBuilder: (_, __) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ShimmerSkeleton(height: 12, width: 90, borderRadius: 4),
                SizedBox(height: 10),
                ShimmerSkeleton(height: 24, width: 70, borderRadius: 6),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ActivityListSkeleton extends StatelessWidget {
  const ActivityListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(3, (_) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: <Widget>[
              ShimmerSkeleton(height: 44, width: 44, borderRadius: 14),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ShimmerSkeleton(height: 14, width: 160, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerSkeleton(height: 12, width: 110, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class DashboardShimmerView extends StatelessWidget {
  const DashboardShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DashboardHeaderSkeleton(),
          SizedBox(height: 24),
          HeroCardSkeleton(),
          SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(child: ProgressCardSkeleton()),
              SizedBox(width: 12),
              Expanded(child: ProgressCardSkeleton()),
            ],
          ),
          SizedBox(height: 20),
          QuickStatsSkeleton(),
          SizedBox(height: 20),
          ActivityListSkeleton(),
        ],
      ),
    );
  }
}
