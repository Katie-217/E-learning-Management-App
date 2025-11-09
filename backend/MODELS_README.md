# Backend Models Documentation

## 📋 Tổng quan

Tài liệu này mô tả cách sử dụng các models đã được tạo cho E-Learning Management System backend.

## 🗄️ Models Available

### 1. **User Model** (`models/User.js`)
Quản lý thông tin người dùng (students, teachers, admins)

```javascript
const { User } = require('./models');

// Tạo user mới
const user = await User.create({
  uid: 'user_123',
  email: 'user@example.com',
  name: 'John Doe',
  role: 'student',
  studentId: 'SV001'
});

// Lấy user theo ID
const user = await User.findById('user_123');

// Lấy tất cả students
const students = await User.findStudents();

// Lấy tất cả teachers
const teachers = await User.findTeachers();
```

### 2. **Course Model** (`models/Course.js`)
Quản lý khóa học

```javascript
const { Course } = require('./models');

// Tạo course mới
const course = await Course.create({
  code: 'IT4409',
  name: 'Web Programming',
  teacherId: 'teacher_123',
  semester: 'Spring 2025'
});

// Lấy course với full data
const courseData = await Course.findByIdWithFullData('course_123');
// Trả về: course, teacher, assignments, quizzes, materials, students, groups

// Lấy courses của student
const courses = await Course.findByStudent('student_123');
```

### 3. **Assignment Model** (`models/Assignment.js`)
Quản lý bài tập

```javascript
const { Assignment } = require('./models');

// Tạo assignment mới
const assignment = await Assignment.create({
  title: 'Assignment 1',
  courseId: 'course_123',
  teacherId: 'teacher_123',
  dueDate: new Date('2025-01-15')
});

// Lấy assignments của student
const assignments = await Assignment.findByStudent('student_123', 'course_123');
```

### 4. **Submission Model** (`models/Submission.js`)
Quản lý bài nộp

```javascript
const { Submission } = require('./models');

// Tạo submission mới
const submission = await Submission.create({
  assignmentId: 'assignment_123',
  studentId: 'student_123',
  content: 'My submission content'
});

// Grade submission
await Submission.grade('submission_123', {
  grade: 85,
  feedback: 'Good work!',
  gradedBy: 'teacher_123'
});
```

### 5. **Quiz Models**
- **`Quiz.js`** - Quản lý quiz
- **`QuizQuestion.js`** - Quản lý câu hỏi
- **`QuizAttempt.js`** - Quản lý lần làm quiz

```javascript
const { Quiz, QuizQuestion, QuizAttempt } = require('./models');

// Tạo quiz
const quiz = await Quiz.create({
  title: 'Quiz 1',
  courseId: 'course_123',
  duration: 60
});

// Tạo câu hỏi
const question = await QuizQuestion.create({
  quizId: 'quiz_123',
  question: 'What is JavaScript?',
  options: ['A', 'B', 'C', 'D'],
  correctAnswer: 'A'
});

// Submit quiz attempt
await QuizAttempt.submit('attempt_123', answers, timeSpent);
```

### 6. **Other Models**
- **`Material.js`** - Quản lý tài liệu
- **`Group.js`** - Quản lý nhóm sinh viên
- **`Notification.js`** - Quản lý thông báo
- **`Enrollment.js`** - Quản lý đăng ký khóa học

## 🚀 Cách sử dụng

### Import Models
```javascript
// Import tất cả models
const { User, Course, Assignment, Quiz, Material, Group, Notification, Enrollment } = require('./models');

// Hoặc import từng model riêng lẻ
const User = require('./models/User');
const Course = require('./models/Course');
```

### Data Aggregation
```javascript
// Course page data
const courseData = await Course.findByIdWithFullData(courseId);
// Trả về: course, teacher, assignments, quizzes, materials, students, groups

// Student dashboard data
const assignments = await Assignment.findByStudent(studentId, courseId);
const quizzes = await Quiz.findByStudent(studentId, courseId);
```

## 📊 Relationships

- **User-Course**: Through enrollments
- **Course-Assignments**: One-to-Many
- **Course-Quizzes**: One-to-Many
- **Course-Materials**: One-to-Many
- **Course-Groups**: One-to-Many
- **Assignment-Submissions**: One-to-Many
- **Quiz-Questions-Attempts**: Complex relationships

## 🎯 Next Steps

1. **Tạo dữ liệu trên Firestore** theo cấu trúc models
2. **Implement controllers** sử dụng models
3. **Tạo API routes** cho tất cả endpoints
4. **Test API** với dữ liệu thực
5. **Connect Flutter app** với backend
6. **Mockup UI** với real data