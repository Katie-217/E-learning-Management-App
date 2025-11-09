# Tài liệu Kỹ thuật: Lựa chọn Firebase làm Backend cho Dự án E-Learning

Tài liệu này phác thảo quyết định chiến lược và lộ trình kỹ thuật cho việc sử dụng Nền tảng Firebase làm backend chính, thay vì tự xây dựng một backend Node.js riêng biệt.

---

## 1. Bối cảnh và Quyết định

Ban đầu, dự án có định hướng xây dựng một backend Node.js (thể hiện qua thư mục `backend` trong mã nguồn). Tuy nhiên, sau khi phân tích kỹ các yêu cầu bắt buộc của đề tài (FinalProject.pdf), chúng ta quyết định chuyển sang sử dụng **Firebase** làm giải pháp backend.

### Lý do chính

1.  **Giải quyết Yêu cầu Bắt buộc Phức tạp:** Đề tài có hai yêu cầu kỹ thuật rất khó, nhưng Firebase lại giải quyết chúng một cách xuất sắc:
    * **Chế độ Offline (Offline Mode):** Đề bài yêu cầu ứng dụng phải hỗ trợ xem tài liệu, dashboard khi không có mạng. Tự xây dựng tính năng đồng bộ hóa cơ sở dữ liệu online/offline (với SQLite/Hive) là vô cùng phức tạp và tốn thời gian.
        * **Giải pháp Firebase:** Cloud Firestore cung cấp tính năng **Offline Persistence** chỉ bằng *một dòng code* (`FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);`). Nó tự động cache dữ liệu và đồng bộ lại khi có mạng, đáp ứng 100% yêu cầu này.
    * **Theo dõi Thời gian thực (Real-time Tracking):** Đề bài yêu cầu giảng viên theo dõi bài nộp "theo thời gian thực". Tự xây dựng (thường dùng WebSocket) rất phức tạp.
        * **Giải pháp Firebase:** Cloud Firestore là một cơ sở dữ liệu **thời gian thực** theo bản chất. Chúng ta có thể "lắng nghe" (listen) các thay đổi trên collection `submissions` và UI sẽ tự động cập nhật ngay lập E_learninglập tức.

2.  **Tập trung vào Yêu cầu Cốt lõi (Frontend & Flutter):** Đề tài có 36+ yêu cầu chức năng (Import CSV, Dashboard, 4 loại nội dung,...). Việc dùng Firebase cho phép chúng ta tập trung toàn bộ thời gian vào việc hoàn thiện các tính năng Flutter này, thay vì tốn 50% thời gian để quản lý server, viết API và xử lý lỗi đồng bộ.

3.  **Hệ sinh thái Toàn diện:** Firebase không chỉ là database. Nó cung cấp mọi thứ chúng ta cần:
    * **Authentication:** Quản lý đăng nhập/đăng ký.
    * **Firestore:** Cơ sở dữ liệu NoSQL thời gian thực (thay cho API/database).
    * **Storage:** Lưu trữ file (thay cho việc tự cấu hình server lưu file).
    * **Cloud Functions:** Viết logic server-side (để gửi email thông báo).

### Đánh đổi

> **Đánh đổi:** Chúng ta chấp nhận không lấy 0.25-0.5 điểm thưởng cho việc "Tự xây dựng backend" để đảm bảo hoàn thành 100% các yêu cầu *bắt buộc* một cách ổn định, tránh rủi ro không hoàn thành dự án.

---

## 2. Firebase thay thế cấu hình Backend (Node.js) như thế nào?

Toàn bộ thư mục `backend` (Node.js) sẽ bị loại bỏ. Chức năng của nó được thay thế hoàn toàn bởi các dịch vụ của Firebase, được gọi trực tiếp từ code Flutter (thông qua các hàm trong "Lớp Dữ liệu" - xem Mục 4).

| Thành phần trong `backend` (Node.js) | Dịch vụ Firebase thay thế |
| :--- | :--- |
| `server.js` (Khởi động server) | Nền tảng Firebase (Bạn không cần quản lý server). |
| `routes` (ví dụ: `course.routes.js`) | **Cloud Firestore SDK.** Thay vì gọi `GET /api/courses`, bạn gọi `FirebaseFirestore.instance.collection('courses').get()`. |
| `middleware` (ví dụ: `authMiddleware.js`) | **Firebase Authentication** (trên client) và **Firestore Security Rules** (trên server) để bảo mật và phân quyền. |
| Models/Schemas (trong Node.js) | Cấu trúc **Collection** và **Document** bạn thiết lập trực quan trên Firebase Console. |
| Logic nghiệp vụ đặc biệt (Gửi mail) | **Cloud Functions.** Đây là nơi duy nhất bạn viết code Node.js, nhưng bạn deploy nó lên Firebase chứ không phải server của bạn. |

---

## 3. Thiết kế và Liên kết Dữ liệu trên Firebase

Đây là cách chúng ta cấu trúc "backend" mới trên Firebase:

1.  **Authentication (Cổng chính):**
    * Dùng dịch vụ **Authentication** để quản lý Email/Password.
    * Khi người dùng đăng nhập/đăng ký, Firebase trả về một **User ID (uid)** duy nhất.
    * **`uid` này chính là "xương sống"** dùng để liên kết tất cả dữ liệu.

2.  **Cloud Firestore (Cơ sở dữ liệu):**
    * Chúng ta sẽ tạo các Bộ sưu tập (Collections) để lưu dữ liệu. Các model (`course_model.dart`) sẽ ánh xạ với cấu trúc này.
    * **Ví dụ cấu trúc:**
        * `users/{uid}`: (Document ID chính là `uid` từ Auth). Dùng để lưu vai trò: `{ email: '...', role: 'admin' }` (Đáp ứng yêu cầu 2 vai trò).
        * `courses/{courseId}`: (ID tự tạo). Dùng để lưu thông tin khóa học: `{ name: '...', code: '...', instructorId: 'uid-cua-admin' }`.
        * `assignments/{assignmentId}`: (ID tự tạo). Dùng để lưu bài tập: `{ title: '...', courseId: '...', fileUrl: '...' }`. (Trường `fileUrl` sẽ lấy từ Storage).
        * `submissions/{submissionId}`: (ID tự tạo). Dùng để lưu bài nộp: `{ assignmentId: '...', studentId: 'uid-cua-student', status: 'submitted' }`.

3.  **Cloud Storage (Lưu trữ File):**
    * Dịch vụ này chỉ dùng để **lưu file** (PDF, ảnh, .docx).
    * **Luồng liên kết:**
        1.  Upload file (ví dụ: bài tập) lên **Cloud Storage**.
        2.  Storage trả về một chuỗi **Download URL** (link tải file).
        3.  Lưu chuỗi **Download URL** này như một trường (field) bình thường trong document của **Cloud Firestore** (ví dụ: `assignments/{id}/fileUrl`).
        4.  Khi UI cần hiển thị file, nó đọc `fileUrl` từ Firestore và mở link đó.

---

## 4. Kiến trúc Frontend (Flutter) để Bảo trì

Để tránh việc ném code logic (validation, gọi Firebase) vào file UI gây khó bảo trì, chúng ta sẽ áp dụng **Kiến trúc 3 Lớp (3-Layer Architecture)** bên trong thư mục `lib`.

Đây là cách các hàm sẽ liên kết UI với Firebase một cách "sạch":

### Lớp 1: Lớp Trình bày (Presentation Layer)
* **Thư mục:** `lib/presentation/` (Chứa `screens/`, `widgets/`).
* **Trách nhiệm:** **Chỉ chứa code UI.** (ví dụ: `Scaffold`, `TextButton`, `TextField`).
* **Quy tắc:** Cấm `import 'package:cloud_firestore/cloud_firestore.dart'`. Lớp này không được phép biết Firebase là gì. Khi người dùng nhấn nút, nó chỉ gọi một hàm từ Lớp 2 (Controller).

### Lớp 2: Lớp Ứng dụng (Application Layer)
* **Thư mục:** `lib/application/` (Chứa `providers/`, `controllers/`, `blocs/`...).
* **Trách nhiệm:** **"Bộ não" của UI.**
    * Xử lý **validation** (giống `middleware` của bạn).
    * Quản lý trạng thái (ví dụ: `isLoading`).
    * Nhận yêu cầu từ UI (ví dụ: `userClickedAddCourse()`).
* **Quy tắc:** Cấm `import 'package.../firebase'`. Lớp này cũng không biết về Firebase. Nó chỉ gọi các hàm từ Lớp 3 (Repository).

### Lớp 3: Lớp Dữ liệu (Data Layer)
* **Thư mục:** `lib/domain/` hoặc `lib/data/` (Chứa `repositories/`).
* **Trách nhiệm:** **Đây là lớp duy nhất được phép "liên kết" với Firebase.**
    * Nó là cổng giao tiếp duy nhất giữa ứng dụng và bên ngoài.
    * Ví dụ: tạo file `course_repository.dart`.
* **Quy tắc:** **Chỉ nơi này** được `import 'package:cloud_firestore/cloud_firestore.dart'`.

### Luồng hoạt động (Ví dụ: Thêm Khóa học)

1.  **UI (File `add_course_screen.dart`)**
    * Người dùng nhấn `ElevatedButton`.
    * Nút này gọi hàm `ref.read(courseControllerProvider.notifier).addCourse(name)`.

2.  **Controller (File `course_controller.dart`)**
    * Hàm `addCourse(name)` được gọi.
    * Nó kiểm tra (validate): `if (name.isEmpty) throw Exception...`.
    * Nó tạo `CourseModel` từ dữ liệu.
    * Nó gọi hàm `_repository.addCourseToDatabase(courseModel)`.

3.  **Repository (File `course_repository.dart`)**
    * Hàm `addCourseToDatabase(courseModel)` được gọi.
    * **Đây là "mối liên kết":** Hàm này chạy code Firebase:
        `await _db.collection('courses').add(courseModel.toFirestore());`

> **Lợi ích lớn nhất:** Nếu một ngày chúng ta muốn đổi sang backend Node.js (để lấy điểm bonus), chúng ta chỉ cần viết lại code bên trong các file `Repository` (Lớp 3). Toàn bộ Lớp 1 (UI) và Lớp 2 (Controller) **không cần thay đổi một dòng code nào.**