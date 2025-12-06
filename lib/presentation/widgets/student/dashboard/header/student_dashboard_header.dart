import 'package:flutter/material.dart';
import 'package:elearning_management_app/presentation/widgets/student/dashboard/common/student_dashboard_models.dart';

class StudentDashboardHeader extends StatelessWidget {
  final String userName;
  final List<SemesterOption> semesters;
  final String? selectedSemesterId;
  final bool isReadonlySemester;
  final ValueChanged<String?> onSemesterChanged;

  const StudentDashboardHeader({
    super.key,
    required this.userName,
    required this.semesters,
    required this.selectedSemesterId,
    required this.isReadonlySemester,
    required this.onSemesterChanged,
  });

  SemesterOption get _activeSemester {
    SemesterOption? matched;
    final currentId = selectedSemesterId;
    if (currentId != null) {
      for (final option in semesters) {
        if (option.id == currentId) {
          matched = option;
          break;
        }
      }
    }
    matched ??= semesters.isNotEmpty
        ? semesters.first
        : const SemesterOption(
            id: 'default',
            label: 'Current Semester',
            isReadonly: false,
          );
    return matched;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isNarrow = screenWidth < 600;
        
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello $userName',
                style: TextStyle(
                  fontSize: screenWidth > 400 ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isReadonlySemester
                    ? 'Viewing past semester (read-only)'
                    : "Let's learn something new today!",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: screenWidth > 400 ? 14 : 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_outlined, size: 20),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF1F2937),
                        value: selectedSemesterId ?? _activeSemester.id,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(
                          Icons.expand_more,
                          color: Colors.white70,
                        ),
                        items: semesters
                            .map(
                              (semester) => DropdownMenuItem(
                                value: semester.id,
                                child: Text(
                                  semester.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: onSemesterChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello $userName',
                    style: TextStyle(
                      fontSize: screenWidth > 800 ? 24 : 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isReadonlySemester
                        ? 'Viewing past semester (read-only)'
                        : "Let's learn something new today!",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: screenWidth > 800 ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: screenWidth > 800 ? 16 : 12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 800 ? 16 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined, size: screenWidth > 800 ? 20 : 18),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: const Color(0xFF1F2937),
                      value: selectedSemesterId ?? _activeSemester.id,
                      borderRadius: BorderRadius.circular(12),
                      icon: const Icon(
                        Icons.expand_more,
                        color: Colors.white70,
                      ),
                      items: semesters
                          .map(
                            (semester) => DropdownMenuItem(
                              value: semester.id,
                              child: Text(
                                semester.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: onSemesterChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

