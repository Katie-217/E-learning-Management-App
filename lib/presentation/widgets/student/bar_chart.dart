// Bar chart widget
import 'package:flutter/material.dart';

class SimpleBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const SimpleBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxHeight = data.map((e) => e['height'] as double).reduce((a,b) => a > b ? a : b);
    return SizedBox(
      height: 270,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: data.map((d) {
          final h = (d['height'] as double);
          final pct = (h / maxHeight).clamp(0.05, 1.0);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 18,
                height:  maxHeight * pct,
                decoration: BoxDecoration(
                  color: Colors.indigo[500],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                ),
              ),
              const SizedBox(height: 6),
              Text(d['day'], style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

