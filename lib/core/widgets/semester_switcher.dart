import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../core/providers/semester_provider.dart';
// import '../core/providers/course_provider.dart';

class SemesterSwitcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final currentSemester = ref.watch(semesterProvider);
    // final semesterNotifier = ref.read(semesterProvider.notifier);
    // final availableSemesters = semesterNotifier.getAvailableSemesters();

    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          Icon(Icons.school, size: 20, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 20),
          Text('Semester:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
          SizedBox(width: 8),
          // DropdownButtonHideUnderline(
          //   child: DropdownButton<String>(
          //     value: currentSemester,
          //     isExpanded: false,
          //     isDense: true,
          //     icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary),
          //     style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
          //     menuMaxHeight: 260,
          //     borderRadius: BorderRadius.circular(8),
          //     items: availableSemesters.map((semester) {
          //       return DropdownMenuItem(value: semester, child: Text(semester, overflow: TextOverflow.ellipsis));
          //     }).toList(),
          //     onChanged: (newSemester) {
          //       if (newSemester != null) {
          //         semesterNotifier.changeSemester(newSemester);
          //         ref.read(courseProvider.notifier).filterCoursesBySemester(newSemester);
          //       }
          //     },
          //   ),
          // ),
        ],
      ),
    ));
  }
}
