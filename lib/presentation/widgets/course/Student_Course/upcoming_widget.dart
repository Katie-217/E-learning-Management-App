import 'package:flutter/material.dart';

class UpcomingWidget extends StatelessWidget {
  const UpcomingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.red[400]!.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.assignment_outlined,
                        color: Colors.redAccent),
                  ),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Project 1 Due',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        Text('Oct 15, 11:59 PM',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ]),
                ]),
                const Text('5 days left',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
