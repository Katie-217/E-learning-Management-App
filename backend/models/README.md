# Backend Models

Thư mục này chứa tất cả các models cho E-Learning Management System backend.

## 📁 Cấu trúc Models

### Core Models
- **`User.js`** - Quản lý users (students, teachers, admins)
- **`Course.js`** - Quản lý khóa học với full data aggregation
- **`Assignment.js`** - Quản lý bài tập và submissions
- **`Submission.js`** - Quản lý bài nộp và grading

### Quiz Models
- **`Quiz.js`** - Quản lý quiz
- **`QuizQuestion.js`** - Quản lý câu hỏi quiz
- **`QuizAttempt.js`** - Quản lý lần làm quiz

### Content Models
- **`Material.js`** - Quản lý tài liệu
- **`Group.js`** - Quản lý nhóm sinh viên
- **`Notification.js`** - Quản lý thông báo
- **`Enrollment.js`** - Quản lý đăng ký khóa học

## 🚀 Cách sử dụng

### Import Models
```javascript
// Import tất cả models
const { User, Course, Assignment, Quiz } = require('./models');

// Hoặc import từng model riêng lẻ
const User = require('./models/User');
const Course = require('./models/Course');
```

### Ví dụ sử dụng
```javascript
const { User, Course, Assignment } = require('./models');

// Tạo user mới
const user = await User.create({
  uid: 'user123',
  email: 'user@example.com',
  name: 'John Doe',
  role: 'student'
});

// Lấy course với full data
const courseData = await Course.findByIdWithFullData('course123');
// Trả về: course, teacher, assignments, quizzes, materials, students, groups

// Lấy assignments của student
const assignments = await Assignment.findByStudent('student123', 'course123');
```

## 📊 Data Aggregation

### Course Page Data
```javascript
const courseData = await Course.findByIdWithFullData(courseId);
// Kết quả:
{
  course: { /* course info */ },
  teacher: { /* teacher info */ },
  assignments: [ /* assignments array */ ],
  quizzes: [ /* quizzes array */ ],
  materials: [ /* materials array */ ],
  students: [ /* enrolled students */ ],
  groups: [ /* course groups */ ]
}
```

### Student Dashboard Data
```javascript
// Lấy courses của student
const courses = await Course.findByStudent(studentId);

// Lấy assignments với submission info
const assignments = await Assignment.findByStudent(studentId, courseId);

// Lấy quizzes với attempt info
const quizzes = await Quiz.findByStudent(studentId, courseId);
```

## 🔗 Relationships

- **User-Course**: Through enrollments
- **Course-Assignments**: One-to-Many
- **Course-Quizzes**: One-to-Many
- **Course-Materials**: One-to-Many
- **Course-Groups**: One-to-Many
- **Assignment-Submissions**: One-to-Many
- **Quiz-Questions-Attempts**: Complex relationships

## 📝 Methods Available

### Common Methods
- `create(data)` - Tạo mới
- `findById(id)` - Tìm theo ID
- `findAll(filters)` - Lấy tất cả với filters
- `update(id, data)` - Cập nhật
- `delete(id)` - Xóa

### Special Methods
- `Course.findByIdWithFullData(id)` - Lấy course với tất cả data liên quan
- `Assignment.findByStudent(studentId, courseId)` - Lấy assignments với submission info
- `Quiz.findByStudent(studentId, courseId)` - Lấy quizzes với attempt info
- `User.findStudentsByCourse(courseId)` - Lấy students của course

## 🎯 Next Steps

1. **Chạy seeder** để tạo dữ liệu mẫu: `npm run seed`
2. **Implement controllers** sử dụng models
3. **Tạo API routes** cho tất cả endpoints
4. **Test API** với sample data
5. **Connect Flutter app** với backend
6. **Mockup UI** với real data
