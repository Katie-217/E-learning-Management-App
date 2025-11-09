# E-Learning Management System - Backend API Specification

# Tài liệu này mô tả chi tiết các API endpoints, cấu trúc dữ liệu Firestore collections và cách kết hợp dữ liệu cho hệ thống E-Learning Management System.
## 🗄️ Cấu trúc Firestore Collections

### 1. **users** Collection
Lưu trữ thông tin người dùng (students, teachers, admins)

```javascript
{
  "uid": "string",                    // Firebase UID (Document ID)
  "email": "string",                  // Email đăng nhập
  "name": "string",                   // Tên đầy đủ
  "role": "student|teacher|admin",    // Vai trò người dùng
  "avatar": "string",                 // URL avatar
  "department": "string",             // Khoa/Bộ môn (cho teacher)
  "studentId": "string",             // Mã sinh viên (cho student)
  "isActive": "boolean",             // Trạng thái hoạt động
  "createdAt": "timestamp",          // Ngày tạo
  "updatedAt": "timestamp"           // Ngày cập nhật
}
```

### 2. **courses** Collection
Lưu trữ thông tin khóa học

```javascript
{
  "id": "string",                     // Document ID
  "code": "string",                   // Mã khóa học (VD: IT4409)
  "name": "string",                   // Tên khóa học
  "description": "string",           // Mô tả chi tiết
  "teacherId": "string",             // ID giảng viên (reference to users)
  "teacherName": "string",           // Tên giảng viên (denormalized)
  "semester": "string",              // Học kì (VD: Spring 2025)
  "year": "number",                   // Năm học
  "credits": "number",               // Số tín chỉ
  "status": "active|completed|paused|archived", // Trạng thái
  "imageUrl": "string",              // URL hình ảnh
  "startDate": "timestamp",          // Ngày bắt đầu
  "endDate": "timestamp",            // Ngày kết thúc
  "group": "string",                 // Nhóm lớp
  "sessions": "number",              // Số buổi học
  "maxStudents": "number",           // Số sinh viên tối đa
  "students": ["string"],            // Array of student IDs
  "progress": "number",              // Tiến độ (0-100)
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 3. **assignments** Collection
Lưu trữ bài tập

```javascript
{
  "id": "string",                    // Document ID
  "title": "string",                 // Tiêu đề bài tập
  "description": "string",           // Mô tả chi tiết
  "courseId": "string",              // ID khóa học (reference to courses)
  "courseName": "string",            // Tên khóa học (denormalized)
  "teacherId": "string",             // ID giảng viên
  "teacherName": "string",           // Tên giảng viên (denormalized)
  "dueDate": "timestamp",            // Hạn nộp
  "maxPoints": "number",             // Điểm tối đa
  "instructions": "string",           // Hướng dẫn làm bài
  "attachments": ["string"],         // Array of file URLs
  "allowedFileTypes": ["string"],     // Các loại file được phép
  "maxFileSize": "number",           // Kích thước file tối đa (MB)
  "isPublished": "boolean",         // Đã xuất bản chưa
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 4. **submissions** Collection
Lưu trữ bài nộp của sinh viên

```javascript
{
  "id": "string",                    // Document ID
  "assignmentId": "string",          // ID bài tập (reference to assignments)
  "studentId": "string",             // ID sinh viên (reference to users)
  "studentName": "string",           // Tên sinh viên (denormalized)
  "courseId": "string",              // ID khóa học
  "content": "string",               // Nội dung bài nộp
  "attachments": ["string"],         // Array of file URLs
  "submittedAt": "timestamp",        // Thời gian nộp
  "grade": "number",                 // Điểm số
  "feedback": "string",              // Nhận xét của giảng viên
  "gradedAt": "timestamp",           // Thời gian chấm điểm
  "gradedBy": "string",              // ID giảng viên chấm
  "status": "submitted|graded|late", // Trạng thái
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 5. **quizzes** Collection
Lưu trữ bài kiểm tra

```javascript
{
  "id": "string",                    // Document ID
  "title": "string",                 // Tiêu đề quiz
  "description": "string",           // Mô tả
  "courseId": "string",              // ID khóa học
  "courseName": "string",            // Tên khóa học (denormalized)
  "teacherId": "string",             // ID giảng viên
  "teacherName": "string",           // Tên giảng viên (denormalized)
  "duration": "number",              // Thời gian làm bài (phút)
  "maxAttempts": "number",           // Số lần làm tối đa
  "dueDate": "timestamp",            // Hạn làm bài
  "startDate": "timestamp",          // Thời gian bắt đầu
  "endDate": "timestamp",            // Thời gian kết thúc
  "questions": ["string"],           // Array of question IDs
  "totalQuestions": "number",         // Tổng số câu hỏi
  "maxPoints": "number",             // Điểm tối đa
  "isPublished": "boolean",          // Đã xuất bản chưa
  "isRandomized": "boolean",         // Câu hỏi có random không
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 6. **quiz_questions** Collection
Lưu trữ câu hỏi quiz

```javascript
{
  "id": "string",                    // Document ID
  "quizId": "string",                // ID quiz (reference to quizzes)
  "question": "string",              // Nội dung câu hỏi
  "questionType": "multiple_choice|true_false|essay|fill_blank", // Loại câu hỏi
  "options": ["string"],             // Các lựa chọn (cho multiple choice)
  "correctAnswer": "string",         // Đáp án đúng
  "points": "number",                // Điểm số
  "order": "number",                 // Thứ tự câu hỏi
  "explanation": "string",           // Giải thích đáp án
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 7. **quiz_attempts** Collection
Lưu trữ lần làm quiz của sinh viên

```javascript
{
  "id": "string",                    // Document ID
  "quizId": "string",                // ID quiz
  "studentId": "string",             // ID sinh viên
  "studentName": "string",           // Tên sinh viên (denormalized)
  "courseId": "string",              // ID khóa học
  "answers": "object",               // Object chứa câu trả lời
  "score": "number",                 // Điểm số
  "maxScore": "number",              // Điểm tối đa
  "timeSpent": "number",             // Thời gian làm bài (phút)
  "attemptNumber": "number",          // Số lần làm
  "startedAt": "timestamp",         // Thời gian bắt đầu
  "submittedAt": "timestamp",        // Thời gian nộp bài
  "status": "in_progress|completed|expired", // Trạng thái
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 8. **materials** Collection
Lưu trữ tài liệu khóa học

```javascript
{
  "id": "string",                    // Document ID
  "title": "string",                 // Tên tài liệu
  "description": "string",           // Mô tả
  "courseId": "string",              // ID khóa học
  "courseName": "string",            // Tên khóa học (denormalized)
  "uploadedBy": "string",            // ID người upload
  "uploadedByName": "string",        // Tên người upload (denormalized)
  "fileUrl": "string",               // URL file
  "fileName": "string",              // Tên file gốc
  "fileType": "pdf|doc|docx|ppt|pptx|mp4|jpg|png", // Loại file
  "fileSize": "number",              // Kích thước file (bytes)
  "category": "lecture|assignment|resource|video", // Danh mục
  "isPublic": "boolean",             // Công khai hay không
  "downloadCount": "number",         // Số lần tải xuống
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 9. **groups** Collection
Lưu trữ nhóm sinh viên

```javascript
{
  "id": "string",                    // Document ID
  "name": "string",                  // Tên nhóm
  "courseId": "string",              // ID khóa học
  "courseName": "string",            // Tên khóa học (denormalized)
  "teacherId": "string",             // ID giảng viên
  "teacherName": "string",           // Tên giảng viên (denormalized)
  "members": ["string"],             // Array of student IDs
  "memberNames": ["string"],         // Array of student names (denormalized)
  "leaderId": "string",              // ID trưởng nhóm
  "leaderName": "string",            // Tên trưởng nhóm (denormalized)
  "description": "string",           // Mô tả nhóm
  "maxMembers": "number",            // Số thành viên tối đa
  "isActive": "boolean",             // Trạng thái hoạt động
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 10. **notifications** Collection
Lưu trữ thông báo

```javascript
{
  "id": "string",                    // Document ID
  "userId": "string",                // ID người nhận
  "title": "string",                 // Tiêu đề thông báo
  "message": "string",               // Nội dung
  "type": "assignment|quiz|announcement|grade|system", // Loại thông báo
  "courseId": "string",              // ID khóa học (optional)
  "courseName": "string",            // Tên khóa học (denormalized)
  "relatedId": "string",              // ID liên quan (assignment, quiz, etc.)
  "isRead": "boolean",               // Đã đọc chưa
  "priority": "low|medium|high",     // Mức độ ưu tiên
  "createdAt": "timestamp",
  "readAt": "timestamp"
}
```

### 11. **enrollments** Collection
Lưu trữ đăng ký khóa học

```javascript
{
  "id": "string",                    // Document ID
  "studentId": "string",             // ID sinh viên
  "studentName": "string",           // Tên sinh viên (denormalized)
  "courseId": "string",              // ID khóa học
  "courseName": "string",            // Tên khóa học (denormalized)
  "teacherId": "string",             // ID giảng viên
  "teacherName": "string",           // Tên giảng viên (denormalized)
  "enrolledAt": "timestamp",         // Thời gian đăng ký
  "status": "active|completed|dropped", // Trạng thái
  "grade": "string",                 // Điểm tổng kết
  "progress": "number",              // Tiến độ (0-100)
  "lastAccessed": "timestamp",       // Lần truy cập cuối
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

---

## 🔗 Relationships & Data Aggregation

### Course Page Data Structure
Để hiển thị course page với đầy đủ thông tin, cần kết hợp dữ liệu từ nhiều collections:

```javascript
// Course Card Data (cho course list)
{
  "course": {
    "id": "string",
    "code": "string",
    "name": "string",
    "instructor": "string",          // teacherName từ users collection
    "semester": "string",
    "sessions": "number",
    "students": "number",             // Count từ enrollments
    "group": "string",
    "progress": "number",             // Tính từ enrollments
    "status": "string",
    "imageUrl": "string",
    "startDate": "timestamp",
    "endDate": "timestamp"
  },
  "teacher": {                        // Từ users collection
    "id": "string",
    "name": "string",
    "avatar": "string",
    "department": "string"
  },
  "stats": {                         // Aggregated data
    "totalStudents": "number",
    "totalAssignments": "number",
    "totalQuizzes": "number",
    "totalMaterials": "number",
    "avgGrade": "number"
  }
}
```

### Course Detail Data Structure
```javascript
{
  "course": { /* course data */ },
  "teacher": { /* teacher data */ },
  "assignments": [                   // Từ assignments collection
    {
      "id": "string",
      "title": "string",
      "dueDate": "timestamp",
      "maxPoints": "number",
      "submissionsCount": "number",  // Count từ submissions
      "status": "string"
    }
  ],
  "quizzes": [                       // Từ quizzes collection
    {
      "id": "string",
      "title": "string",
      "dueDate": "timestamp",
      "duration": "number",
      "questions": "number",
      "status": "string"
    }
  ],
  "materials": [                     // Từ materials collection
    {
      "id": "string",
      "title": "string",
      "fileType": "string",
      "fileSize": "number",
      "uploadedAt": "timestamp"
    }
  ],
  "students": [                      // Từ enrollments + users
    {
      "id": "string",
      "name": "string",
      "avatar": "string",
      "studentId": "string",
      "enrolledAt": "timestamp",
      "progress": "number"
    }
  ],
  "groups": [                        // Từ groups collection
    {
      "id": "string",
      "name": "string",
      "members": "number",
      "leaderName": "string"
    }
  ]
}
```

---

## 🚀 API Endpoints Specification

### Base URL
```
http://localhost:4000/api
```

### Authentication
Tất cả protected endpoints cần header:
```
Authorization: Bearer <firebase_token>
```

---

## 🔐 Authentication APIs

### 1. Login
- **Endpoint:** `POST /api/auth/login`
- **Body:**
```json
{
  "email": "string",
  "password": "string"
}
```
- **Response:**
```json
{
  "success": true,
  "data": {
    "token": "string",
    "user": {
      "uid": "string",
      "name": "string",
      "email": "string",
      "role": "student|teacher|admin",
      "avatar": "string"
    }
  },
  "message": "Login successful"
}
```

### 2. Register
- **Endpoint:** `POST /api/auth/register`
- **Body:**
```json
{
  "name": "string",
  "email": "string",
  "password": "string",
  "role": "student|teacher",
  "studentId": "string",
  "department": "string"
}
```

### 3. Get User Profile
- **Endpoint:** `GET /api/auth/profile`
- **Headers:** `Authorization: Bearer <token>`

### 4. Update Profile
- **Endpoint:** `PUT /api/auth/profile`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "name": "string",
  "phone": "string",
  "avatar": "string"
}
```

---

## 📚 Course APIs

### 1. Get All Courses
- **Endpoint:** `GET /api/courses`
- **Query Parameters:**
  - `semester` (optional): Filter by semester
  - `status` (optional): Filter by status
  - `teacherId` (optional): Filter by teacher
  - `studentId` (optional): Filter by enrolled student
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "course": {
      "id": "string",
        "code": "string",
        "name": "string",
        "instructor": "string",
        "semester": "string",
        "sessions": "number",
        "students": "number",
        "group": "string",
        "progress": "number",
        "status": "string",
        "imageUrl": "string",
        "startDate": "timestamp",
        "endDate": "timestamp"
      },
      "teacher": {
        "id": "string",
        "name": "string",
        "avatar": "string",
        "department": "string"
      },
      "stats": {
        "totalStudents": "number",
        "totalAssignments": "number",
        "totalQuizzes": "number",
        "totalMaterials": "number"
      }
    }
  ],
  "message": "Courses retrieved successfully"
}
```

### 2. Get Course by ID
- **Endpoint:** `GET /api/courses/:id`
- **Response:** Full course detail with all related data

### 3. Create Course
- **Endpoint:** `POST /api/courses`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "code": "string",
  "name": "string",
  "description": "string",
  "credits": "number",
  "semester": "string",
  "year": "number",
  "startDate": "timestamp",
  "endDate": "timestamp",
  "maxStudents": "number",
  "group": "string"
}
```

### 4. Update Course
- **Endpoint:** `PUT /api/courses/:id`
- **Headers:** `Authorization: Bearer <token>`

### 5. Delete Course
- **Endpoint:** `DELETE /api/courses/:id`
- **Headers:** `Authorization: Bearer <token>`

### 6. Enroll in Course
- **Endpoint:** `POST /api/courses/:id/enroll`
- **Headers:** `Authorization: Bearer <token>`

### 7. Unenroll from Course
- **Endpoint:** `DELETE /api/courses/:id/enroll`
- **Headers:** `Authorization: Bearer <token>`

---

## 📝 Assignment APIs

### 1. Get Assignments
- **Endpoint:** `GET /api/assignments`
- **Query Parameters:**
  - `courseId` (optional): Filter by course
  - `teacherId` (optional): Filter by teacher
  - `studentId` (optional): Filter by student submissions
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "title": "string",
      "description": "string",
      "courseId": "string",
      "courseName": "string",
      "teacherName": "string",
      "dueDate": "timestamp",
      "maxPoints": "number",
      "isPublished": "boolean",
      "submissionsCount": "number",
      "mySubmission": {
        "id": "string",
        "grade": "number",
        "status": "string",
        "submittedAt": "timestamp"
      }
    }
  ],
  "message": "Assignments retrieved successfully"
}
```

### 2. Get Assignment by ID
- **Endpoint:** `GET /api/assignments/:id`

### 3. Create Assignment
- **Endpoint:** `POST /api/assignments`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "title": "string",
  "description": "string",
  "courseId": "string",
  "dueDate": "timestamp",
  "maxPoints": "number",
  "instructions": "string",
  "allowedFileTypes": ["string"],
  "maxFileSize": "number"
}
```

### 4. Update Assignment
- **Endpoint:** `PUT /api/assignments/:id`
- **Headers:** `Authorization: Bearer <token>`

### 5. Delete Assignment
- **Endpoint:** `DELETE /api/assignments/:id`
- **Headers:** `Authorization: Bearer <token>`

### 6. Submit Assignment
- **Endpoint:** `POST /api/assignments/:id/submit`
- **Headers:** `Authorization: Bearer <token>`
- **Content-Type:** `multipart/form-data`
- **Body:**
```json
{
  "content": "string",
  "attachments": "file[]"
}
```

### 7. Grade Assignment
- **Endpoint:** `PUT /api/assignments/:id/grade`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "submissionId": "string",
  "grade": "number",
  "feedback": "string"
}
```

---

## 🧠 Quiz APIs

### 1. Get Quizzes
- **Endpoint:** `GET /api/quizzes`
- **Query Parameters:**
  - `courseId` (optional): Filter by course
  - `teacherId` (optional): Filter by teacher
  - `studentId` (optional): Filter by student attempts
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "title": "string",
      "description": "string",
      "courseId": "string",
      "courseName": "string",
      "teacherName": "string",
      "duration": "number",
      "dueDate": "timestamp",
      "totalQuestions": "number",
      "maxPoints": "number",
      "isPublished": "boolean",
      "myAttempts": [
        {
          "id": "string",
          "score": "number",
          "attemptNumber": "number",
          "submittedAt": "timestamp"
        }
      ]
    }
  ],
  "message": "Quizzes retrieved successfully"
}
```

### 2. Get Quiz by ID
- **Endpoint:** `GET /api/quizzes/:id`

### 3. Create Quiz
- **Endpoint:** `POST /api/quizzes`
- **Headers:** `Authorization: Bearer <token>`

### 4. Start Quiz Attempt
- **Endpoint:** `POST /api/quizzes/:id/start`
- **Headers:** `Authorization: Bearer <token>`

### 5. Submit Quiz Attempt
- **Endpoint:** `POST /api/quizzes/:id/submit`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "attemptId": "string",
  "answers": {
    "questionId": "answer"
  }
}
```

---

## 📁 Material APIs

### 1. Get Materials
- **Endpoint:** `GET /api/materials`
- **Query Parameters:**
  - `courseId` (optional): Filter by course
  - `fileType` (optional): Filter by file type
  - `category` (optional): Filter by category
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "title": "string",
      "description": "string",
      "courseId": "string",
      "courseName": "string",
      "uploadedByName": "string",
      "fileUrl": "string",
      "fileName": "string",
      "fileType": "string",
      "fileSize": "number",
      "category": "string",
      "downloadCount": "number",
      "createdAt": "timestamp"
    }
  ],
  "message": "Materials retrieved successfully"
}
```

### 2. Upload Material
- **Endpoint:** `POST /api/materials`
- **Headers:** `Authorization: Bearer <token>`
- **Content-Type:** `multipart/form-data`
- **Body:**
```json
{
  "title": "string",
  "description": "string",
  "courseId": "string",
  "category": "string",
  "file": "file"
}
```

### 3. Download Material
- **Endpoint:** `GET /api/materials/:id/download`
- **Headers:** `Authorization: Bearer <token>`

---

## 👥 Group APIs

### 1. Get Groups
- **Endpoint:** `GET /api/groups`
- **Query Parameters:**
  - `courseId` (optional): Filter by course
  - `studentId` (optional): Filter by student membership
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "name": "string",
      "courseId": "string",
      "courseName": "string",
      "teacherName": "string",
      "members": [
        {
          "id": "string",
          "name": "string",
          "avatar": "string",
          "studentId": "string"
        }
      ],
      "leaderName": "string",
      "description": "string",
      "maxMembers": "number",
      "isActive": "boolean"
    }
  ],
  "message": "Groups retrieved successfully"
}
```

### 2. Create Group
- **Endpoint:** `POST /api/groups`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "name": "string",
  "courseId": "string",
  "description": "string",
  "maxMembers": "number"
}
```

### 3. Join Group
- **Endpoint:** `POST /api/groups/:id/join`
- **Headers:** `Authorization: Bearer <token>`

### 4. Leave Group
- **Endpoint:** `DELETE /api/groups/:id/leave`
- **Headers:** `Authorization: Bearer <token>`

---

## 🔔 Notification APIs

### 1. Get Notifications
- **Endpoint:** `GET /api/notifications`
- **Headers:** `Authorization: Bearer <token>`
- **Query Parameters:**
  - `isRead` (optional): Filter by read status
  - `type` (optional): Filter by notification type
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "title": "string",
      "message": "string",
      "type": "string",
      "courseId": "string",
      "courseName": "string",
      "isRead": "boolean",
      "priority": "string",
      "createdAt": "timestamp"
    }
  ],
  "message": "Notifications retrieved successfully"
}
```

### 2. Mark as Read
- **Endpoint:** `PUT /api/notifications/:id/read`
- **Headers:** `Authorization: Bearer <token>`

### 3. Mark All as Read
- **Endpoint:** `PUT /api/notifications/read-all`
- **Headers:** `Authorization: Bearer <token>`

---

## 📊 Dashboard APIs

### 1. Get Dashboard Stats
- **Endpoint:** `GET /api/dashboard/stats`
- **Headers:** `Authorization: Bearer <token>`
- **Response:**
```json
{
  "success": true,
  "data": {
    "inProgress": "number",
    "completed": "number",
    "certificates": "number",
    "avgScore": "string",
    "activeHours": [
      {"day": "M", "height": 90.0},
      {"day": "T", "height": 120.0},
      {"day": "W", "height": 70.0},
      {"day": "T", "height": 120.0},
      {"day": "F", "height": 100.0},
      {"day": "S", "height": 85.0},
      {"day": "S", "height": 110.0}
    ],
    "productivity": "number"
  },
  "message": "Dashboard stats retrieved successfully"
}
```

### 2. Get Upcoming Events
- **Endpoint:** `GET /api/dashboard/upcoming`
- **Headers:** `Authorization: Bearer <token>`

---

## 🔍 Search APIs

### 1. Global Search
- **Endpoint:** `GET /api/search`
- **Query Parameters:**
  - `q` (required): Search query
  - `type` (optional): Search type (courses, assignments, materials, users)
- **Response:**
```json
{
  "success": true,
  "data": {
    "courses": [],
    "assignments": [],
    "materials": [],
    "users": [],
    "total": "number"
  },
  "message": "Search completed successfully"
}
```

---

## 📈 Analytics APIs

### 1. Get Course Analytics
- **Endpoint:** `GET /api/analytics/courses/:courseId`
- **Headers:** `Authorization: Bearer <token>`
- **Response:**
```json
{
  "success": true,
  "data": {
    "enrollment": "number",
    "completionRate": "number",
    "avgScore": "number",
    "activity": [
      {
        "date": "timestamp",
        "views": "number",
        "submissions": "number"
      }
    ]
  },
  "message": "Course analytics retrieved successfully"
}
```

---

## ⚠️ Error Handling

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

### Error Response Format
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message",
  "code": "ERROR_CODE"
}
```

### Common Error Codes
- `INVALID_TOKEN` - Token không hợp lệ
- `USER_NOT_FOUND` - User không tồn tại
- `COURSE_NOT_FOUND` - Khóa học không tồn tại
- `ASSIGNMENT_NOT_FOUND` - Bài tập không tồn tại
- `PERMISSION_DENIED` - Không có quyền truy cập
- `VALIDATION_ERROR` - Lỗi validation dữ liệu

---

## 🚀 Implementation Notes

### 1. Authentication
- Sử dụng Firebase Authentication
- JWT tokens cho API access
- Role-based access control (student, teacher, admin)

### 2. Database
- Firebase Firestore cho NoSQL data
- Real-time listeners cho live updates
- Offline support với local caching

### 3. File Storage
- Firebase Storage cho file uploads
- Support các format: PDF, DOC, PPT, MP4, images
- File size limits: 100MB per file

### 4. Performance
- Pagination cho large datasets
- Caching với Redis (optional)
- CDN cho static assets

### 5. Security
- Input validation và sanitization
- Rate limiting
- CORS configuration
- HTTPS only

---

## 🧪 Testing

### Test Endpoints
```bash
# Health check
GET /api/health

# API version
GET /api/version
```

### Postman Collection
- Import collection từ `docs/postman/`
- Environment variables cho different stages
- Automated testing scripts

---

## 🚀 Deployment

### Environment Variables
```env
NODE_ENV=production
PORT=4000
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
```

### Docker Support
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 4000
CMD ["npm", "start"]
```

---

## 📞 Support

- **Documentation:** [API Docs](https://your-api-docs.com)
- **Issues:** [GitHub Issues](https://github.com/your-repo/issues)
- **Contact:** api-support@yourcompany.com

---

*Last updated: January 2025*