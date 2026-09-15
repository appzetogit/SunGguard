import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable Shimmer Wrapper
class AppShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? const Color(0xFFE2E8F0),
      highlightColor: highlightColor ?? const Color(0xFFF8FAFC),
      child: child,
    );
  }
}

/// Generic Skeleton Box Widget
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Generic Skeleton Circle Widget
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton Card matching Waybill History Card
class WaybillCardSkeleton extends StatelessWidget {
  const WaybillCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonBox(width: 80.0, height: 18.0, borderRadius: 12.0),
                const SkeletonBox(width: 60.0, height: 14.0, borderRadius: 6.0),
              ],
            ),
            const SizedBox(height: 14.0),
            Row(
              children: [
                const SkeletonCircle(size: 36.0),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 120.0, height: 14.0),
                      SizedBox(height: 6.0),
                      SkeletonBox(width: double.infinity, height: 12.0),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                const SkeletonCircle(size: 36.0),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 100.0, height: 14.0),
                      SizedBox(height: 6.0),
                      SkeletonBox(width: 180.0, height: 12.0),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 90.0, height: 20.0, borderRadius: 6.0),
                SkeletonBox(width: 100.0, height: 26.0, borderRadius: 4.0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton Card matching Saved Address Item
class AddressCardSkeleton extends StatelessWidget {
  const AddressCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const SkeletonCircle(size: 40.0),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 80.0, height: 14.0),
                  SizedBox(height: 6.0),
                  SkeletonBox(width: double.infinity, height: 12.0),
                  SizedBox(height: 4.0),
                  SkeletonBox(width: 120.0, height: 10.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton Card matching Home Active Shipment Card
class HomeShipmentCardSkeleton extends StatelessWidget {
  const HomeShipmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 110.0, height: 16.0),
                SkeletonBox(width: 70.0, height: 20.0, borderRadius: 12.0),
              ],
            ),
            const SizedBox(height: 14.0),
            const SkeletonBox(width: double.infinity, height: 14.0),
            const SizedBox(height: 8.0),
            const SkeletonBox(width: 160.0, height: 12.0),
          ],
        ),
      ),
    );
  }
}
