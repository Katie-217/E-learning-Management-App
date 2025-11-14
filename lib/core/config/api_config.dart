class ApiConfig {
  // Base URL cho backend API
  static const String baseUrl = 'http://localhost:3000/api';

  // Endpoints
  static const String coursesEndpoint = '/courses';
  static const String studentsEndpoint = '/students';
  static const String teachersEndpoint = '/teachers';
  static const String assignmentsEndpoint = '/assignments';
  static const String submissionsEndpoint = '/submissions';

  // Full URLs
  static String get coursesUrl => '$baseUrl$coursesEndpoint';
  static String get studentsUrl => '$baseUrl$studentsEndpoint';
  static String get teachersUrl => '$baseUrl$teachersEndpoint';
  static String get assignmentsUrl => '$baseUrl$assignmentsEndpoint';
  static String get submissionsUrl => '$baseUrl$submissionsEndpoint';

  // Helper methods
  static String courseById(String id) => '$coursesUrl/$id';
  static String coursesBySemester(String semester) =>
      '$coursesUrl?semester=$semester';
  static String coursesByStatus(String status) => '$coursesUrl?status=$status';
  static String studentById(String id) => '$studentsUrl/$id';
  static String teacherById(String id) => '$teachersUrl/$id';
  static String assignmentById(String id) => '$assignmentsUrl/$id';
  static String submissionById(String id) => '$submissionsUrl/$id';
}
