import 'package:flutter/material.dart';

// Semester Option Model
class SemesterOption {
  final String id;
  final String label;
  final bool isReadonly;

  const SemesterOption({
    required this.id,
    required this.label,
    required this.isReadonly,
  });
}

// Summary Metric Model
class SummaryMetric {
  final IconData icon;
  final String title;
  final String value;
  final Color bgStart;
  final Color bgEnd;
  final Color iconColor;

  const SummaryMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.bgStart,
    required this.bgEnd,
    required this.iconColor,
  });
}

// Submission Type Enum (for dashboard UI)
enum DashboardSubmissionType {
  assignment,
  quiz,
}

// Submission Status Enum (for dashboard UI)
enum DashboardSubmissionStatus {
  onTime,
  early,
  late,
}

// Submission Item Model
class SubmissionItem {
  final String title;
  final String timeLabel;
  final DashboardSubmissionType type;
  final DashboardSubmissionStatus status;

  const SubmissionItem({
    required this.title,
    required this.timeLabel,
    required this.type,
    required this.status,
  });
}

// Completed Quiz Item Model
class CompletedQuizItem {
  final String title;
  final String courseName;
  final int score;
  final int maxScore;
  final String completedDate;

  const CompletedQuizItem({
    required this.title,
    required this.courseName,
    required this.score,
    required this.maxScore,
    required this.completedDate,
  });

  double get percentage => (score / maxScore) * 100;
}

