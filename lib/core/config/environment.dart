class Environment {
  // Development environment
  static const String devBaseUrl = 'http://localhost:3000/api';
  
  // Production environment
  static const String prodBaseUrl = 'https://your-api-domain.com/api';
  
  // Current environment (change this to switch between dev/prod)
  static const bool isDevelopment = true;
  
  // Get current base URL
  static String get baseUrl => isDevelopment ? devBaseUrl : prodBaseUrl;
  
  // API endpoints
  static String get coursesUrl => '$baseUrl/courses';
  static String get studentsUrl => '$baseUrl/students';
  static String get teachersUrl => '$baseUrl/teachers';
  static String get assignmentsUrl => '$baseUrl/assignments';
  static String get submissionsUrl => '$baseUrl/submissions';
  
  // Helper methods
  static String courseById(String id) => '$coursesUrl/$id';
  static String coursesBySemester(String semester) => '$coursesUrl?semester=$semester';
  static String coursesByStatus(String status) => '$coursesUrl?status=$status';
  static String studentById(String id) => '$studentsUrl/$id';
  static String teacherById(String id) => '$teachersUrl/$id';
  static String assignmentById(String id) => '$assignmentsUrl/$id';
  static String submissionById(String id) => '$submissionsUrl/$id';
}
