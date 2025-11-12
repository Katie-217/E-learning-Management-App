import 'package:flutter/material.dart';
// import '../../../instructors/presentation/widgets/instructor_card.dart';

class PeopleTab extends StatelessWidget {
  const PeopleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Instructor',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        const SizedBox(height: 8),
        // const InstructorCard(),
        const SizedBox(height: 24),
        const Text('Classmates',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            4,
            (i) => Container(
              width: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!)),
              child: Row(children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        gradient:
                            LinearGradient(colors: [Colors.indigo, Colors.purple]),
                        shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Student Name',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('Group 1',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ]),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
