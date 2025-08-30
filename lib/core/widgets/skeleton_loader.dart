import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 20, width: double.infinity, color: Colors.white),
                    SizedBox(height: 8),
                    Container(height: 16, width: 120, color: Colors.white),
                    SizedBox(height: 8),
                    Container(height: 14, width: 100, color: Colors.white),
                    Spacer(),
                    Container(height: 12, width: double.infinity, color: Colors.white),
                    SizedBox(height: 4),
                    Container(height: 4, width: double.infinity, color: Colors.white),
                  ],
                ),
              ),
            ),
            Container(height: 40, padding: EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)))),
          ],
        ),
      ),
    );
  }
}
