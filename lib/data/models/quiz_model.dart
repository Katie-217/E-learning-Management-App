class Quiz {
  final String id;
  final String title;
  final String dueDate;
  final String duration;
  final int questions;
  final String status; // available, upcoming, scheduled

  const Quiz({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.duration,
    required this.questions,
    required this.status,
  });

  factory Quiz.fromMap(String id, Map<String, dynamic> m) {
    return Quiz(
      id: id,
      title: m['title'] ?? '',
      dueDate: m['dueDate'] ?? '',
      duration: m['duration'] ?? '',
      questions: (m['questions'] ?? 0) as int,
      status: m['status'] ?? 'upcoming',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'dueDate': dueDate,
      'duration': duration,
      'questions': questions,
      'status': status,
    };
  }
}
