# E-Learning Management System - Backend API

## 📋 Tổng quan

Backend API cho hệ thống E-Learning Management System được xây dựng với Node.js, Express.js và Firebase Firestore. API cung cấp các endpoints để quản lý khóa học, bài tập, quiz, tài liệu, nhóm và người dùng.

## 🛠 Technology Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: Firebase Firestore
- **Authentication**: Firebase Admin SDK
- **File Storage**: Firebase Storage
- **Middleware**: CORS, Morgan, Firebase Auth

## 📁 Cấu trúc Project

```
backend/
├── src/
│   ├── config/
│   │   └── firebase.js              # Firebase configuration
│   ├── controllers/
│   │   ├── assignment.controller.js # Assignment business logic
│   │   ├── course.controller.js     # Course business logic
│   │   ├── student.controller.js    # Student business logic
│   │   └── teacher.controller.js     # Teacher business logic
│   ├── models/
│   │   ├── assignment.js            # Assignment model
│   │   ├── class.js                 # Class model
│   │   ├── submission.js            # Submission model
│   │   └── Teacher.js               # Teacher model
│   └── app.js                       # Express app configuration
├── routes/
│   ├── assignment.routes.js          # Assignment routes
│   ├── auth.js                       # Authentication routes
│   ├── classes.js                    # Class routes
│   ├── course.routes.js              # Course routes
│   ├── student.routes.js             # Student routes
│   ├── submissions.js                # Submission routes
│   └── teacher.routes.js             # Teacher routes
├── middleware/
│   ├── authMiddleware.js             # Authentication middleware
│   └── firebaseAuth.js               # Firebase auth middleware
├── tests/                            # Test files
├── package.json                      # Dependencies
├── server.js                         # Server entry point
├── serviceAccountKey.json           # Firebase service account
└── README_API_SPECIFICATION.md      # Detailed API documentation
```

## 🚀 Quick Start

### 1. Installation

```bash
# Clone repository
git clone <repository-url>
cd Final-pro/backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env
```

### 2. Environment Configuration

Tạo file `.env` với nội dung:

```env
NODE_ENV=development
PORT=4000
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
FIREBASE_SERVICE_ACCOUNT=./serviceAccountKey.json
```

### 3. Firebase Setup

1. Tạo Firebase project tại [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication và Firestore Database
3. Tạo Service Account và download key file
4. Đặt file key vào `serviceAccountKey.json`

### 4. Run Development Server

```bash
# Development mode
npm run dev

# Production mode
npm start
```

Server sẽ chạy tại `http://localhost:4000`

## 📚 API Documentation

### Base URL
```
http://localhost:4000/api
```

### Authentication
Tất cả protected endpoints cần header:
```
Authorization: Bearer <firebase_token>
```

### Main Endpoints

#### 🔐 Authentication
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/register` - Đăng ký
- `GET /api/auth/profile` - Lấy thông tin profile
- `PUT /api/auth/profile` - Cập nhật profile

#### 📚 Courses
- `GET /api/courses` - Lấy danh sách khóa học
- `GET /api/courses/:id` - Lấy chi tiết khóa học
- `POST /api/courses` - Tạo khóa học mới
- `PUT /api/courses/:id` - Cập nhật khóa học
- `DELETE /api/courses/:id` - Xóa khóa học
- `POST /api/courses/:id/enroll` - Đăng ký khóa học

#### 📝 Assignments
- `GET /api/assignments` - Lấy danh sách bài tập
- `GET /api/assignments/:id` - Lấy chi tiết bài tập
- `POST /api/assignments` - Tạo bài tập mới
- `PUT /api/assignments/:id` - Cập nhật bài tập
- `DELETE /api/assignments/:id` - Xóa bài tập
- `POST /api/assignments/:id/submit` - Nộp bài tập

#### 🧠 Quizzes
- `GET /api/quizzes` - Lấy danh sách quiz
- `GET /api/quizzes/:id` - Lấy chi tiết quiz
- `POST /api/quizzes` - Tạo quiz mới
- `POST /api/quizzes/:id/start` - Bắt đầu làm quiz
- `POST /api/quizzes/:id/submit` - Nộp bài quiz

#### 📁 Materials
- `GET /api/materials` - Lấy danh sách tài liệu
- `POST /api/materials` - Upload tài liệu
- `GET /api/materials/:id/download` - Tải xuống tài liệu

#### 👥 Groups
- `GET /api/groups` - Lấy danh sách nhóm
- `POST /api/groups` - Tạo nhóm mới
- `POST /api/groups/:id/join` - Tham gia nhóm
- `DELETE /api/groups/:id/leave` - Rời khỏi nhóm

#### 🔔 Notifications
- `GET /api/notifications` - Lấy thông báo
- `PUT /api/notifications/:id/read` - Đánh dấu đã đọc
- `PUT /api/notifications/read-all` - Đánh dấu tất cả đã đọc

#### 📊 Dashboard
- `GET /api/dashboard/stats` - Lấy thống kê dashboard
- `GET /api/dashboard/upcoming` - Lấy sự kiện sắp tới

## 🗄️ Database Schema

### Firestore Collections

1. **users** - Thông tin người dùng
2. **courses** - Khóa học
3. **assignments** - Bài tập
4. **submissions** - Bài nộp
5. **quizzes** - Quiz
6. **quiz_questions** - Câu hỏi quiz
7. **quiz_attempts** - Lần làm quiz
8. **materials** - Tài liệu
9. **groups** - Nhóm
10. **notifications** - Thông báo
11. **enrollments** - Đăng ký khóa học

### Relationships

```
users (1) ←→ (n) courses
courses (1) ←→ (n) assignments
courses (1) ←→ (n) quizzes
courses (1) ←→ (n) materials
courses (1) ←→ (n) groups
assignments (1) ←→ (n) submissions
quizzes (1) ←→ (n) quiz_attempts
```

## 🔧 Development

### Scripts

```bash
# Development
npm run dev

# Production
npm start

# Test
npm test

# Lint
npm run lint
```

### Code Structure

- **Controllers**: Business logic và xử lý request/response
- **Models**: Data models và database operations
- **Routes**: API route definitions
- **Middleware**: Authentication, validation, error handling

### Error Handling

Tất cả API responses tuân theo format:

```json
{
  "success": true/false,
  "data": {}, // hoặc []
  "message": "string",
  "error": "string" // chỉ khi success = false
}
```

### HTTP Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## 🧪 Testing

### Manual Testing

1. **Authentication**
   - Test login/register
   - Test token validation
   - Test role-based access

2. **Course Management**
   - Test CRUD operations
   - Test enrollment
   - Test data relationships

3. **Assignment System**
   - Test assignment creation
   - Test submission
   - Test grading

4. **Quiz System**
   - Test quiz creation
   - Test quiz attempts
   - Test scoring

### Test Data

```javascript
// Sample course data
{
  "code": "IT4409",
  "name": "Web Programming",
  "description": "Learn web development with modern technologies",
  "credits": 3,
  "semester": "Spring 2025",
  "teacherId": "teacher_uid_here"
}
```

## 🚀 Deployment

### Environment Variables

```env
NODE_ENV=production
PORT=4000
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
```

### Docker Deployment

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 4000
CMD ["npm", "start"]
```

### Production Checklist

- [ ] Environment variables configured
- [ ] Firebase service account setup
- [ ] CORS configured for production domains
- [ ] Rate limiting enabled
- [ ] Error logging configured
- [ ] Health check endpoint working
- [ ] SSL certificate installed

## 📖 Detailed Documentation

Để xem tài liệu chi tiết về API endpoints, database schema và data relationships, vui lòng tham khảo:

**[📋 README_API_SPECIFICATION.md](./README_API_SPECIFICATION.md)**

File này chứa:
- Chi tiết tất cả API endpoints
- Cấu trúc Firestore collections
- Relationships giữa các collections
- Cách kết hợp dữ liệu cho course page
- Error handling và status codes
- Testing và deployment guides

## 🤝 Contributing

1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Documentation**: [API Docs](./README_API_SPECIFICATION.md)
- **Contact**: backend-support@yourcompany.com

---

*Made with ❤️ by the E-Learning Development Team*