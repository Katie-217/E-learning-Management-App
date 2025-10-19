# Backend API

Node.js + Express API with Firebase Admin SDK for the E-Learning Management System.

## Structure

```
backend/
├── src/
│   ├── config/            # Firebase admin configuration
│   ├── models/            # Data models (Teacher, Class, Assignment, Submission)
│   ├── controllers/        # Business logic controllers
│   ├── routes/            # API route definitions
│   └── middlewares/       # Authentication, authorization middleware
├── tests/                 # Test files
├── package.json
└── server.js
```

## Features

- Firebase Admin SDK integration
- JWT token verification
- Role-based authorization
- RESTful API endpoints
- CORS enabled for Flutter/web access
- Error handling and logging

## API Endpoints

### Authentication
All protected routes require Firebase ID token in Authorization header:
```
Authorization: Bearer <firebase-id-token>
```

### Teachers
- `GET /api/teachers` - Get all teachers
- `GET /api/teachers/:id` - Get teacher by ID
- `POST /api/teachers` - Create teacher (Teacher role required)
- `PUT /api/teachers/:id` - Update teacher (Teacher role required)
- `DELETE /api/teachers/:id` - Delete teacher (Teacher role required)
- `POST /api/teachers/:id/assign-class` - Assign class to teacher

### Classes
- `GET /api/classes` - Get all classes
- `GET /api/classes/:id` - Get class by ID
- `GET /api/classes/teacher/:teacherId` - Get classes by teacher
- `POST /api/classes` - Create class (Teacher role required)
- `PUT /api/classes/:id` - Update class (Teacher role required)
- `DELETE /api/classes/:id` - Delete class (Teacher role required)

### Assignments
- `GET /api/assignments` - Get all assignments
- `GET /api/assignments/:id` - Get assignment by ID
- `GET /api/assignments/class/:classId` - Get assignments by class
- `POST /api/assignments` - Create assignment (Teacher role required)
- `PUT /api/assignments/:id` - Update assignment (Teacher role required)
- `DELETE /api/assignments/:id` - Delete assignment (Teacher role required)

### Submissions
- `GET /api/submissions` - Get all submissions
- `GET /api/submissions/:id` - Get submission by ID
- `GET /api/submissions/assignment/:assignmentId` - Get submissions by assignment
- `GET /api/submissions/student/:studentId` - Get submissions by student
- `POST /api/submissions` - Create submission (Authenticated users)
- `PUT /api/submissions/:id` - Update submission (Authenticated users)
- `PUT /api/submissions/:id/grade` - Grade submission (Teacher role required)
- `DELETE /api/submissions/:id` - Delete submission (Authenticated users)

## Development

### Prerequisites
- Node.js 16.x or higher
- Firebase project with Admin SDK
- Service account key file

### Installation
```bash
npm install
```

### Environment Setup
Create a `.env` file:
```
PORT=4000
FIREBASE_SERVICE_ACCOUNT=./serviceAccountKey.json
```

### Running the Server
```bash
# Development
npm run dev

# Production
npm start
```

### Testing
```bash
# Run tests
npm test
```

## Firebase Configuration

1. Create a Firebase project
2. Generate a service account key
3. Download the JSON key file
4. Place it as `serviceAccountKey.json` in the backend root
5. Configure Firestore security rules

## Security

- All routes are protected with Firebase token verification
- Role-based access control for teacher-specific operations
- CORS configured for Flutter/web applications
- Input validation and sanitization
- Error handling without sensitive information exposure

## Error Handling

The API returns consistent error responses:
```json
{
  "message": "Error description",
  "error": "Error type"
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Deployment

### Environment Variables
- `PORT` - Server port (default: 4000)
- `FIREBASE_SERVICE_ACCOUNT` - Path to service account key

### Production Considerations
- Use environment variables for sensitive data
- Implement rate limiting
- Add request logging
- Set up monitoring and alerting
- Use HTTPS in production
- Configure proper CORS origins