// ========================================
// LỚP: DashboardRepository
// MÔ TẢ: Repository dùng để lấy dữ liệu dashboard cho giảng viên từ API.
// ========================================
import 'package:dio/dio.dart';
import '../../features/dashboard/models.dart';

class DashboardRepository {
  final Dio dio;

  // ========================================
  // HÀM TẠO: DashboardRepository
  // MÔ TẢ: Khởi tạo repository với một instance Dio để gọi API.
  // ========================================
  DashboardRepository(this.dio);

  // ========================================
  // PHƯƠNG THỨC: fetchSemesters
  // MÔ TẢ: Lấy danh sách học kỳ từ API.
  // TRẢ VỀ: Future<List<Semester>>
  // ========================================
  Future<List<Semester>> fetchSemesters() async {
    final r = await dio.get('/api/semesters');
    return (r.data as List).map((e) => Semester.fromJson(e)).toList();
  }

  // ========================================
  // PHƯƠNG THỨC: fetchStats
  // MÔ TẢ: Lấy thống kê dashboard cho một học kỳ cụ thể từ API.
  // THAM SỐ: semesterId - ID của học kỳ cần lấy thống kê.
  // TRẢ VỀ: Future<DashboardStats>
  // ========================================
  Future<DashboardStats> fetchStats(String semesterId) async {
    final r = await dio.get('/api/instructor/dashboard', queryParameters: {'semesterId': semesterId});
    return DashboardStats.fromJson(r.data);
  }
}