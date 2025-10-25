# E-Learning Management System - Backend API Specification

## Tổng quan

Tài liệu này mô tả chi tiết các API endpoints và cấu trúc dữ liệu mà backend cần cung cấp cho frontend E-Learning Management System.

---

## Cấu trúc API Response

Tất cả API responses tuân theo format chuẩn:

```json
{
  "success": true/false,
  "data": {}, // hoặc []
  "message": "string",
  "error": "string" // chỉ khi success = false
}
```

---

## Authentication APIs

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
      "role": "student|teacher|admin"
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
  "role": "student|teacher"
}
```

### 3. Logout
- **Endpoint:** `POST /api/auth/logout`
- **Headers:** `Authorization: Bearer <token>`

---

## Course APIs

### 1. Get All Courses
- **Endpoint:** `GET /api/courses`
- **Query Parameters:**
  - `semester` (optional): Filter by semester
  - `status` (optional): Filter by status (active, completed, paused, archived)
  - `teacherId` (optional): Filter by teacher
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "name": "string",           // Tên khóa học
      "code": "string",          // Mã khóa học (VD: IT4409)
      "instructor": "string",     // Tên giảng viên
      "description": "string",    // Mô tả khóa học
      "credits": "number",        // Số tín chỉ
      "semester": "string",      // Học kì (VD: Spring 2025)
      "status": "string",        // active, completed, paused, archived
      "imageUrl": "string",      // URL hình ảnh
      "progress": "number",      // Tiến độ (0-100)
      "totalStudents": "number", // Tổng số sinh viên
      "sessions": "number",      // Số buổi học
      "students": "number",      // Số sinh viên hiện tại
      "group": "string",         // Nhóm lớp
      "gradient": ["color1", "color2"], // Màu gradient cho UI
      "startDate": "datetime",   // Ngày bắt đầu
      "endDate": "datetime",     // Ngày kết thúc
      "createdAt": "datetime",
      "updatedAt": "datetime"
    }
  ],
  "message": "Courses retrieved successfully"
}
```

### 2. Get Course by ID
- **Endpoint:** `GET /api/courses/:id`

### 3. Create Course
- **Endpoint:** `POST /api/courses`
- **Body:**
```json
{
  "name": "string",
  "code": "string",
  "description": "string",
  "credits": "number",
  "semester": "string",
  "teacherId": "string",
  "startDate": "datetime",
  "endDate": "datetime"
}
```

### 4. Update Course
- **Endpoint:** `PUT /api/courses/:id`

### 5. Delete Course
- **Endpoint:** `DELETE /api/courses/:id`

### 6. Get Courses by Teacher
- **Endpoint:** `GET /api/courses/teacher/:teacherId`

---

## Assignment APIs

### 1. Get All Assignments
- **Endpoint:** `GET /api/assignments`
- **Query Parameters:**
  - `courseId` (optional): Filter by course
  - `teacherId` (optional): Filter by teacher
  - `status` (optional): Filter by status
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "title": "string",         // Tiêu đề bài tập
      "description": "string",   // Mô tả chi tiết
      "courseId": "string",      // ID khóa học
      "dueDate": "datetime",     // Hạn nộp
      "createdBy": "string",      // ID giảng viên tạo
      "maxPoints": "number",     // Điểm tối đa
      "status": "string",        // pending, submitted, graded
      "grade": "string",         // Điểm số (VD: "85/100")
      "createdAt": "datetime",
      "updatedAt": "datetime"
    }
  ],
  "message": "Assignments retrieved successfully"
}
```

### 2. Get Assignment by ID
- **Endpoint:** `GET /api/assignments/:id`

### 3. Create Assignment
- **Endpoint:** `POST /api/assignments`
- **Body:**
```json
{
  "title": "string",
  "description": "string",
  "courseId": "string",
  "dueDate": "datetime",
  "maxPoints": "number"
}
```

### 4. Update Assignment
- **Endpoint:** `PUT /api/assignments/:id`

### 5. Delete Assignment
- **Endpoint:** `DELETE /api/assignments/:id`

### 6. Get Assignments by Course
- **Endpoint:** `GET /api/assignments/course/:courseId`

---

## Quiz APIs

### 1. Get All Quizzes
- **Endpoint:** `GET /api/quizzes`
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "title": "string",         // Tiêu đề quiz
      "dueDate": "datetime",     // Thời gian làm bài
      "duration": "string",      // Thời gian làm bài (VD: "45 min")
      "questions": "number",     // Số câu hỏi
      "status": "string",        // available, upcoming, scheduled
      "courseId": "string",      // ID khóa học
      "createdBy": "string",     // ID giảng viên
      "createdAt": "datetime"
    }
  ],
  "message": "Quizzes retrieved successfully"
}
```

### 2. Get Quiz by ID
- **Endpoint:** `GET /api/quizzes/:id`

### 3. Create Quiz
- **Endpoint:** `POST /api/quizzes`

### 4. Update Quiz
- **Endpoint:** `PUT /api/quizzes/:id`

### 5. Delete Quiz
- **Endpoint:** `DELETE /api/quizzes/:id`

---

## Student APIs

### 1. Get All Students
- **Endpoint:** `GET /api/students`
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "uid": "string",           // Firebase UID
      "name": "string",          // Tên sinh viên
      "email": "string",         // Email
      "studentId": "string",     // Mã sinh viên
      "classId": "string",       // ID lớp
      "semester": "string",      // Học kì
      "avatar": "string",        // URL avatar
      "createdAt": "datetime",
      "updatedAt": "datetime"
    }
  ],
  "message": "Students retrieved successfully"
}
```

### 2. Get Student by ID
- **Endpoint:** `GET /api/students/:id`

### 3. Create Student
- **Endpoint:** `POST /api/students`

### 4. Update Student
- **Endpoint:** `PUT /api/students/:id`

### 5. Delete Student
- **Endpoint:** `DELETE /api/students/:id`

### 6. Get Students by Class
- **Endpoint:** `GET /api/students/class/:classId`

### 7. Import Students from CSV
- **Endpoint:** `POST /api/students/import`
- **Body:**
```json
{
  "students": [
    {
      "name": "string",
      "email": "string",
      "studentId": "string"
    }
  ],
  "classId": "string",
  "semester": "string"
}
```

---

## Teacher APIs

### 1. Get All Teachers
- **Endpoint:** `GET /api/teachers`
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "uid": "string",           // Firebase UID
      "name": "string",          // Tên giảng viên
      "email": "string",         // Email
      "subject": "string",       // Môn học
      "department": "string",    // Khoa/Bộ môn
      "avatar": "string",        // URL avatar
      "createdAt": "datetime",
      "updatedAt": "datetime"
    }
  ],
  "message": "Teachers retrieved successfully"
}
```

### 2. Get Teacher by ID
- **Endpoint:** `GET /api/teachers/:id`

### 3. Create Teacher
- **Endpoint:** `POST /api/teachers`

### 4. Update Teacher
- **Endpoint:** `PUT /api/teachers/:id`

### 5. Delete Teacher
- **Endpoint:** `DELETE /api/teachers/:id`

### 6. Get Teacher Courses
- **Endpoint:** `GET /api/teachers/:teacherId/courses`

### 7. Get Teacher Assignments
- **Endpoint:** `GET /api/teachers/:teacherId/assignments`

---

## Dashboard APIs

### 1. Get Dashboard Statistics
- **Endpoint:** `GET /api/dashboard/stats`
- **Response:**
```json
{
  "success": true,
  "data": {
    "inProgress": "number",      // Số khóa học đang học
    "completed": "number",       // Số khóa học đã hoàn thành
    "certificates": "number",    // Số chứng chỉ
    "avgScore": "string",        // Điểm trung bình (VD: "85%")
    "activeHours": [             // Dữ liệu biểu đồ giờ học
      {"day": "M", "height": 90.0},
      {"day": "T", "height": 120.0},
      {"day": "W", "height": 70.0},
      {"day": "T", "height": 120.0},
      {"day": "F", "height": 100.0},
      {"day": "S", "height": 85.0},
      {"day": "S", "height": 110.0}
    ],
    "productivity": "number"      // Tỷ lệ năng suất (0-1)
  },
  "message": "Dashboard stats retrieved successfully"
}
```

### 2. Get Upcoming Events
- **Endpoint:** `GET /api/dashboard/upcoming`
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "title": "string",
      "type": "assignment|quiz|exam",
      "dueDate": "datetime",
      "courseName": "string",
      "description": "string"
    }
  ],
  "message": "Upcoming events retrieved successfully"
}
```

---

## Calendar APIs

### 1. Get Calendar Events
- **Endpoint:** `GET /api/calendar/events`
- **Query Parameters:**
  - `month` (optional): Filter by month
  - `year` (optional): Filter by year
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "title": "string",         // Tiêu đề sự kiện
      "date": "datetime",        // Ngày sự kiện
      "type": "string",          // assignment, quiz, exam, deadline
      "courseId": "string",      // ID khóa học liên quan
      "description": "string",   // Mô tả
      "color": "string"         // Màu hiển thị
    }
  ],
  "message": "Calendar events retrieved successfully"
}
```

### 2. Create Calendar Event
- **Endpoint:** `POST /api/calendar/events`

### 3. Update Calendar Event
- **Endpoint:** `PUT /api/calendar/events/:id`

### 4. Delete Calendar Event
- **Endpoint:** `DELETE /api/calendar/events/:id`

---

## Notification APIs

### 1. Get Notifications
- **Endpoint:** `GET /api/notifications`
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
      "title": "string",         // Tiêu đề thông báo
      "message": "string",       // Nội dung
      "type": "string",          // info, warning, success, error
      "isRead": "boolean",       // Đã đọc chưa
      "createdAt": "datetime",
      "courseId": "string"       // ID khóa học (optional)
    }
  ],
  "message": "Notifications retrieved successfully"
}
```

### 2. Mark Notification as Read
- **Endpoint:** `PUT /api/notifications/:id/read`

### 3. Mark All Notifications as Read
- **Endpoint:** `PUT /api/notifications/read-all`

### 4. Delete Notification
- **Endpoint:** `DELETE /api/notifications/:id`

---

## Class APIs

### 1. Get All Classes
- **Endpoint:** `GET /api/classes`
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "name": "string",          // Tên lớp
      "code": "string",          // Mã lớp
      "teacher": "string",       // ID giảng viên
      "description": "string",    // Mô tả lớp
      "students": "number",      // Số sinh viên
      "semester": "string",      // Học kì
      "createdAt": "datetime",
      "updatedAt": "datetime"
    }
  ],
  "message": "Classes retrieved successfully"
}
```

### 2. Get Class by ID
- **Endpoint:** `GET /api/classes/:id`

### 3. Create Class
- **Endpoint:** `POST /api/classes`

### 4. Update Class
- **Endpoint:** `PUT /api/classes/:id`

### 5. Delete Class
- **Endpoint:** `DELETE /api/classes/:id`

---

## Material APIs

### 1. Get All Materials
- **Endpoint:** `GET /api/materials`
- **Query Parameters:**
  - `courseId` (optional): Filter by course
  - `fileType` (optional): Filter by file type
- **Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "title": "string",         // Tên tài liệu
      "description": "string",   // Mô tả
      "fileUrl": "string",       // URL file
      "fileType": "string",      // pdf, doc, ppt, video
      "courseId": "string",      // ID khóa học
      "uploadedBy": "string",    // ID người upload
      "fileSize": "number",      // Kích thước file (bytes)
      "createdAt": "datetime"
    }
  ],
  "message": "Materials retrieved successfully"
}
```

### 2. Get Material by ID
- **Endpoint:** `GET /api/materials/:id`

### 3. Upload Material
- **Endpoint:** `POST /api/materials`
- **Content-Type:** `multipart/form-data`

### 4. Update Material
- **Endpoint:** `PUT /api/materials/:id`

### 5. Delete Material
- **Endpoint:** `DELETE /api/materials/:id`

### 6. Get Materials by Course
- **Endpoint:** `GET /api/materials/course/:courseId`

---

## Search APIs

### 1. Global Search
- **Endpoint:** `GET /api/search`
- **Query Parameters:**
  - `q` (required): Search query
  - `type` (optional): Search type (courses, assignments, materials)
- **Response:**
```json
{
  "success": true,
  "data": {
    "courses": [],
    "assignments": [],
    "materials": [],
    "total": "number"
  },
  "message": "Search completed successfully"
}
```

---

## Analytics APIs

### 1. Get Course Analytics
- **Endpoint:** `GET /api/analytics/courses/:courseId`
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
        "date": "datetime",
        "views": "number",
        "submissions": "number"
      }
    ]
  },
  "message": "Course analytics retrieved successfully"
}
```

### 2. Get Student Performance
- **Endpoint:** `GET /api/analytics/students/:studentId`

### 3. Get Teacher Performance
- **Endpoint:** `GET /api/analytics/teachers/:teacherId`

---

## Error Handling

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

---

## Implementation Notes

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

## API Testing

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

## Deployment

### Environment Variables
```env
NODE_ENV=production
PORT=3000
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
EXPOSE 3000
CMD ["npm", "start"]
```

---

## Support

- **Documentation:** [API Docs](https://your-api-docs.com)
- **Issues:** [GitHub Issues](https://github.com/your-repo/issues)
- **Contact:** api-support@yourcompany.com

---

*Last updated: January 2025*
