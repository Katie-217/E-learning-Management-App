// Stats card widget
import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color bgStart;
  final Color bgEnd;
  final Color iconColor;

  const StatsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.bgStart,
    required this.bgEnd,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = bgStart.withOpacity(0.3);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgStart.withOpacity(0.18), bgEnd.withOpacity(0.18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgStart.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(color: Colors.grey[300], fontSize: 23)),
          ]),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontSize: 33, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
