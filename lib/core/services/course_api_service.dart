import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/course_model.dart';
import '../config/environment.dart';

class CourseApiService {
  
  // Lấy danh sách tất cả khóa học
  static Future<List<CourseModel>> getCourses() async {
    try {
      final response = await http.get(
        Uri.parse(Environment.coursesUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CourseModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching courses: $e');
      // Trả về danh sách trống nếu có lỗi
      return [];
    }
  }

  // Lấy khóa học theo ID
  static Future<CourseModel?> getCourseById(String id) async {
    try {
      final response = await http.get(
        Uri.parse(Environment.courseById(id)),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CourseModel.fromJson(data);
      } else {
        throw Exception('Failed to load course: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching course: $e');
      return null;
    }
  }

  // Lấy khóa học theo học kì
  static Future<List<CourseModel>> getCoursesBySemester(String semester) async {
    try {
      final response = await http.get(
        Uri.parse(Environment.coursesBySemester(semester)),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CourseModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load courses by semester: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching courses by semester: $e');
      // Trả về danh sách trống nếu có lỗi
      return [];
    }
  }

  // Lấy khóa học theo trạng thái
  static Future<List<CourseModel>> getCoursesByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse(Environment.coursesByStatus(status)),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CourseModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load courses by status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching courses by status: $e');
      // Trả về danh sách trống nếu có lỗi
      return [];
    }
  }

  // Tạo khóa học mới
  static Future<CourseModel?> createCourse(CourseModel course) async {
    try {
      final response = await http.post(
        Uri.parse(Environment.coursesUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(course.toJson()),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CourseModel.fromJson(data);
      } else {
        throw Exception('Failed to create course: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating course: $e');
      return null;
    }
  }

  // Cập nhật khóa học
  static Future<CourseModel?> updateCourse(String id, CourseModel course) async {
    try {
      final response = await http.put(
        Uri.parse(Environment.courseById(id)),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(course.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CourseModel.fromJson(data);
      } else {
        throw Exception('Failed to update course: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating course: $e');
      return null;
    }
  }

  // Xóa khóa học
  static Future<bool> deleteCourse(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(Environment.courseById(id)),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting course: $e');
      return false;
    }
  }
}
