class Assignment {
  final String id;
  final String title;
  final String dueDate; 
  final String grade;
  final String status; 

  const Assignment({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.grade,
    required this.status,
  });

  factory Assignment.fromMap(String id, Map<String, dynamic> m) {
    return Assignment(
      id: id,
      title: m['title'] ?? '',
      dueDate: m['dueDate'] ?? '',
      grade: m['grade'] ?? '',
      status: m['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'dueDate': dueDate,
      'grade': grade,
      'status': status,
    };
  }
}