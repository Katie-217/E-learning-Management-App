# 📁 Cấu Trúc Dự Án E-Learning Management System

## 🏗️ Kiến Trúc Clean Architecture

Dự án được tổ chức theo **Clean Architecture** với 5 lớp chính:
1. **Domain** - Business logic và models
2. **Data** - Data sources và repositories
3. **Application** - Controllers và state management
4. **Presentation** - UI (Screens và Widgets)
5. **Navigation** - Routing và navigation

---

## 📂 Cấu Trúc Cây Thư Mục Chi Tiết

```
lib/
│
├── main.dart                                    # Entry point của ứng dụng - Khởi tạo Firebase và ProviderScope
├── firebase_options.dart                        # Cấu hình Firebase cho các platform
│
├── domain/                                      # 🎯 DOMAIN LAYER - Business Logic & Models
│   └── models/                                  # Định nghĩa cấu trúc dữ liệu
│       ├── assignment_model.dart                # Model cho bài tập (Assignment)
│       ├── course_model.dart                    # Model cho khóa học (Course)
│       ├── quiz_model.dart                     # Model cho bài kiểm tra (Quiz)
│       ├── sidebar_model.dart                  # Model cho sidebar navigation
│       └── task_model.dart                     # Model cho công việc (Task)
│
├── data/                                        # 💾 DATA LAYER - Data Sources & Repositories
│   └── repositories/                            # Tất cả repositories giao tiếp với Firebase/API
│       │
│       ├── auth/                                # Authentication & Authorization
│       │   ├── auth_api_service.dart            # API service cho authentication
│       │   ├── auth_repository.dart             # Repository xử lý đăng nhập/đăng ký
│       │   ├── auth_service.dart                # Service xử lý logic authentication
│       │   ├── firebase_auth_helper.dart        # Helper functions cho Firebase Auth
│       │   ├── google_auth_repository.dart      # Repository cho Google Sign-In
│       │   ├── google_auth_service.dart         # Service cho Google Sign-In
│       │   └── user_session_service.dart        # Quản lý session người dùng (SharedPreferences)
│       │
│       ├── course/                              # Course Management
│       │   ├── course_api_service.dart          # API service cho courses
│       │   └── firestore_course_service.dart    # Firestore service cho courses
│       │
│       ├── assignment/                          # Assignment Management
│       │   └── assignment_repository.dart       # Repository CRUD cho assignments
│       │
│       ├── quiz/                                # Quiz Management
│       │   └── quiz_repository.dart             # Repository CRUD cho quizzes
│       │
│       ├── material/                            # Material Management
│       │   └── material_repository.dart         # Repository CRUD cho materials
│       │
│       ├── group/                                # Group Management
│       │   └── group_repository.dart            # Repository CRUD cho groups
│       │
│       ├── instructor/                           # Instructor Features
│       │   ├── instructor_profile_repository.dart  # Repository quản lý profile instructor
│       │   ├── instructor_repository.dart       # Repository cho instructor operations
│       │   └── task_repository.dart             # Repository quản lý tasks
│       │
│       ├── student/                              # Student Features
│       │   └── student_repository.dart          # Repository cho student operations
│       │
│       ├── notification/                         # Notification System
│       │   └── notification_repository.dart     # Repository quản lý notifications
│       │
│       ├── announcement/                         # Announcement System
│       │   └── announcement_repository.dart     # Repository quản lý announcements
│       │
│       └── common/                               # Common Services
│           ├── api_client.dart                  # HTTP client wrapper (Dio)
│           ├── api_service.dart                 # Base API service
│           ├── cache_service.dart                # Cache service cho API responses
│           ├── firebase_connection_service.dart # Kiểm tra kết nối Firebase
│           └── firestore_service.dart           # Base Firestore service
│
├── application/                                  # 🧠 APPLICATION LAYER - State Management
│   └── controllers/                             # Controllers/Providers quản lý state
│       │
│       ├── auth/                                # Authentication Controllers
│       │   ├── auth_provider.dart               # Provider quản lý auth state
│       │   └── login_controller.dart            # Controller xử lý logic đăng nhập
│       │
│       ├── course/                               # Course Controllers
│       │   ├── course_provider.dart             # Provider quản lý courses state
│       │   ├── firestore_course_provider.dart   # Provider cho Firestore courses
│       │   └── semester_provider.dart           # Provider quản lý học kỳ
│       │
│       ├── assignment/                           # Assignment Controllers
│       │   └── assignment_provider.dart        # Provider quản lý assignments state
│       │
│       ├── quiz/                                 # Quiz Controllers
│       │   └── quiz_provider.dart               # Provider quản lý quizzes state
│       │
│       ├── material/                             # Material Controllers
│       │   └── material_provider.dart           # Provider quản lý materials state
│       │
│       ├── group/                                # Group Controllers
│       │   └── group_provider.dart              # Provider quản lý groups state
│       │
│       ├── instructor/                           # Instructor Controllers
│       │   ├── instructor_profile_provider.dart # Provider quản lý instructor profile
│       │   └── task_provider.dart               # Provider quản lý tasks state
│       │
│       ├── notification/                         # Notification Controllers
│       │   └── notification_provider.dart      # Provider quản lý notifications state
│       │
│       └── announcement/                         # Announcement Controllers
│           └── announcement_provider.dart      # Provider quản lý announcements state
│
├── presentation/                                 # 🎨 PRESENTATION LAYER - UI
│   │
│   ├── screens/                                 # Màn hình đầy đủ (Pages)
│   │   │
│   │   ├── auth/                                # Authentication Screens
│   │   │   ├── auth_overlay_screen.dart         # Màn hình overlay đăng nhập/đăng ký
│   │   │   ├── forgot_password_page.dart        # Màn hình quên mật khẩu
│   │   │   ├── login_page.dart                  # Màn hình đăng nhập
│   │   │   ├── register_form.dart               # Form đăng ký
│   │   │   └── register_page.dart               # Màn hình đăng ký
│   │   │
│   │   ├── course/                               # Course Screens
│   │   │   ├── course_detail_page.dart          # Chi tiết khóa học
│   │   │   └── course_page.dart                 # Danh sách khóa học
│   │   │
│   │   ├── assignment/                          # Assignment Screens
│   │   │   ├── assignment_detail_page.dart     # Chi tiết bài tập
│   │   │   ├── assignments_page.dart           # Danh sách bài tập
│   │   │   ├── create_assignment_page.dart      # Tạo bài tập mới
│   │   │   └── submissions_page.dart            # Danh sách bài nộp
│   │   │
│   │   ├── quiz/                                 # Quiz Screens
│   │   │   ├── create_quiz_page.dart           # Tạo quiz mới
│   │   │   ├── quiz_detail_page.dart           # Chi tiết quiz
│   │   │   ├── quiz_results_page.dart          # Kết quả quiz
│   │   │   └── quizzes_page.dart               # Danh sách quizzes
│   │   │
│   │   ├── material/                             # Material Screens
│   │   │   ├── material_detail_page.dart       # Chi tiết tài liệu
│   │   │   ├── materials_page.dart              # Danh sách tài liệu
│   │   │   └── upload_material_page.dart        # Upload tài liệu
│   │   │
│   │   ├── group/                                # Group Screens
│   │   │   ├── group_detail_page.dart           # Chi tiết nhóm
│   │   │   ├── group_page.dart                  # Danh sách nhóm
│   │   │   └── manage_group_page.dart           # Quản lý nhóm
│   │   │
│   │   ├── instructor/                           # Instructor Screens
│   │   │   ├── instructor_calendar_tasks_page.dart  # Lịch và tasks của instructor
│   │   │   ├── instructor_dashboard.dart        # Dashboard instructor
│   │   │   ├── instructor_grades_page.dart      # Quản lý điểm
│   │   │   └── instructor_students_page.dart     # Danh sách sinh viên
│   │   │
│   │   ├── student/                              # Student Screens
│   │   │   ├── management_view.dart             # View quản lý của student
│   │   │   └── student_dashboard_page.dart       # Dashboard student
│   │   │
│   │   ├── notification/                         # Notification Screens
│   │   │   └── notification_page.dart          # Màn hình thông báo
│   │   │
│   │   ├── announcement/                         # Announcement Screens
│   │   │   └── announcements_page.dart          # Màn hình thông báo chung
│   │   │
│   │   ├── analytics/                            # Analytics Screens
│   │   │   ├── analytics_page.dart              # Trang phân tích
│   │   │   └── analytics_view.dart               # View phân tích
│   │   │
│   │   └── profile/                              # Profile Screens
│   │       ├── avatar_uploader.dart             # Upload avatar
│   │       ├── profile_page.dart                 # Trang profile
│   │       └── profile_view.dart                # View profile
│   │
│   └── widgets/                                 # Widgets tái sử dụng
│       │
│       ├── auth/                                # Authentication Widgets
│       │   ├── auth_form_widgets.dart           # Widgets form authentication
│       │   ├── auth_wrapper.dart                # Wrapper kiểm tra auth state
│       │   └── login_form.dart                 # Form đăng nhập
│       │
│       ├── course/                               # Course Widgets
│       │   ├── classmate_card.dart              # Card hiển thị bạn học
│       │   ├── classwork_tab.dart               # Tab bài tập trên lớp
│       │   ├── course_card_widget.dart          # Card khóa học (widget)
│       │   ├── course_card.dart                 # Card khóa học
│       │   ├── course_detail.dart               # Chi tiết khóa học widget
│       │   ├── course_filter_widget.dart        # Widget lọc khóa học
│       │   ├── course_tabs_widget.dart          # Tabs widget cho course
│       │   ├── people_tab.dart                  # Tab danh sách người
│       │   ├── stream_tab.dart                  # Tab stream
│       │   └── upcoming_widget.dart             # Widget sự kiện sắp tới
│       │
│       ├── assignment/                          # Assignment Widgets
│       │   ├── assignment_card.dart             # Card bài tập
│       │   ├── assignment_form.dart             # Form bài tập
│       │   └── submission_tile.dart            # Tile bài nộp
│       │
│       ├── quiz/                                 # Quiz Widgets
│       │   ├── quiz_card.dart                   # Card quiz
│       │   ├── quiz_form.dart                    # Form quiz
│       │   └── quiz_question_tile.dart          # Tile câu hỏi quiz
│       │
│       ├── material/                             # Material Widgets
│       │   ├── material_card.dart               # Card tài liệu
│       │   ├── material_form.dart               # Form tài liệu
│       │   └── material_preview.dart            # Preview tài liệu
│       │
│       ├── group/                                # Group Widgets
│       │   ├── group_card.dart                  # Card nhóm
│       │   ├── group_form.dart                  # Form nhóm
│       │   └── member_tile.dart                 # Tile thành viên
│       │
│       ├── instructor/                           # Instructor Widgets
│       │   ├── calendar_widget.dart             # Widget lịch
│       │   └── task_list_widget.dart            # Widget danh sách task
│       │
│       ├── student/                              # Student Widgets
│       │   ├── bar_chart.dart                   # Biểu đồ cột
│       │   ├── circular_progress_widget.dart    # Widget tiến trình tròn
│       │   ├── semester-widget.dart              # Widget học kỳ
│       │   ├── stats_card.dart                  # Card thống kê
│       │   └── upcoming_events_widget.dart      # Widget sự kiện sắp tới
│       │
│       ├── notification/                         # Notification Widgets
│       │   └── notifications_view.dart          # View danh sách thông báo
│       │
│       ├── announcement/                         # Announcement Widgets
│       │   └── announcement_card.dart          # Card thông báo
│       │
│       └── common/                               # Common/Shared Widgets
│           ├── main_shell.dart                  # Shell layout chính
│           ├── png_icon.dart                    # Icon PNG helper
│           ├── role_based_dashboard.dart        # Dashboard theo role
│           ├── semester_switcher.dart           # Widget chuyển học kỳ
│           ├── sidebar_model.dart               # Sidebar navigation
│           └── skeleton_loader.dart            # Loading skeleton
│
├── navigation/                                   # 🧭 NAVIGATION LAYER
│   └── app_router.dart                         # Định nghĩa routes và navigation logic
│
└── core/                                         # ⚙️ CORE - Shared Utilities
    │
    ├── config/                                   # Configuration
    │   ├── api_config.dart                      # Cấu hình API
    │   ├── app_constants.dart                   # Constants của app
    │   ├── app_theme.dart                      # Theme configuration
    │   ├── environment.dart                    # Environment variables
    │   └── users-role.dart                     # Định nghĩa user roles
    │
    ├── services/                                 # Core Services
    │   ├── cache_manager.dart                  # Quản lý cache (Hive)
    │   └── local_storage.dart                 # Local storage (Hive)
    │
    ├── theme/                                    # Theme
    │   └── app_colors.dart                     # Định nghĩa màu sắc
    │
    └── utils/                                    # Utilities
        ├── format_utils.dart                   # Format helpers (date, number, etc.)
        ├── responsive_helper.dart              # Responsive design helpers
        └── validators.dart                     # Form validators
```

---

## 🔄 Luồng Dữ Liệu (Data Flow)

### Ví dụ: Tạo Bài Tập Mới

```
1. presentation/screens/assignment/create_assignment_page.dart
   ↓ (User nhấn "Lưu")
   
2. application/controllers/assignment/assignment_provider.dart
   ↓ (Validation & tạo Assignment object)
   
3. domain/models/assignment_model.dart
   ↓ (Sử dụng model để tạo object)
   
4. data/repositories/assignment/assignment_repository.dart
   ↓ (Chuyển đổi sang Map và gọi Firebase)
   
5. Firebase Firestore
   ↓ (Lưu dữ liệu)
   
6. navigation/app_router.dart
   ↓ (Điều hướng về danh sách)
```

---

## 📋 Quy Tắc Đặt Tên

### Models
- Format: `{entity}_model.dart`
- Ví dụ: `course_model.dart`, `assignment_model.dart`

### Repositories
- Format: `{entity}_repository.dart` hoặc `{entity}_service.dart`
- Ví dụ: `course_api_service.dart`, `auth_repository.dart`

### Controllers/Providers
- Format: `{entity}_provider.dart` hoặc `{entity}_controller.dart`
- Ví dụ: `course_provider.dart`, `login_controller.dart`

### Screens
- Format: `{entity}_page.dart` hoặc `{entity}_screen.dart`
- Ví dụ: `course_page.dart`, `auth_overlay_screen.dart`

### Widgets
- Format: `{entity}_widget.dart` hoặc `{entity}_card.dart` hoặc `{entity}_form.dart`
- Ví dụ: `course_card.dart`, `assignment_form.dart`

---

## 🎯 Trách Nhiệm Của Từng Lớp

### Domain Layer (`domain/`)
- **Trách nhiệm**: Định nghĩa business logic và data models
- **Không phụ thuộc**: Không import từ các layer khác
- **Chứa**: Models với `fromFirestore()`, `toFirestore()`, `toMap()`, `fromMap()`

### Data Layer (`data/repositories/`)
- **Trách nhiệm**: Giao tiếp với Firebase/API, xử lý dữ liệu
- **Phụ thuộc**: Domain models
- **Chứa**: Repositories, API services, Firebase helpers

### Application Layer (`application/controllers/`)
- **Trách nhiệm**: Quản lý state, validation, business logic
- **Phụ thuộc**: Domain models, Data repositories
- **Chứa**: Providers, Controllers (Riverpod)

### Presentation Layer (`presentation/`)
- **Trách nhiệm**: UI, hiển thị dữ liệu, tương tác người dùng
- **Phụ thuộc**: Application controllers, Domain models
- **Chứa**: Screens, Widgets

### Navigation Layer (`navigation/`)
- **Trách nhiệm**: Định nghĩa routes, điều hướng
- **Phụ thuộc**: Presentation screens
- **Chứa**: Router configuration

### Core (`core/`)
- **Trách nhiệm**: Utilities, config, theme - được sử dụng bởi tất cả layers
- **Chứa**: Config, utils, theme, core services

---

## 📝 Ghi Chú

- **Clean Architecture**: Mỗi layer chỉ phụ thuộc vào layer bên trong
- **Feature-based grouping**: Files được nhóm theo feature để dễ quản lý
- **Separation of Concerns**: Mỗi file có trách nhiệm rõ ràng
- **Reusability**: Widgets và utilities có thể tái sử dụng

---

