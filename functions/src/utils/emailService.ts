// ========================================
// FILE: emailService.ts
// MÔ TẢ: Email service cho việc gửi thông báo qua email
// ========================================

import * as nodemailer from 'nodemailer';
import * as functions from 'firebase-functions';

// ========================================
// CONFIGURATION
// ========================================
const getTransporter = () => {
  // Đọc từ process.env (từ .env file)
  const user = process.env.EMAIL_USER || functions.config().email?.user;
  const pass = process.env.EMAIL_PASSWORD || functions.config().email?.password;
  
  console.log('🔧 Email config check:', {
    hasUser: !!user,
    hasPass: !!pass,
    userEmail: user ? `${user.substring(0, 5)}...` : 'not set'
  });
  
  return nodemailer.createTransport({
    service: 'gmail',
    auth: { user, pass },
  });
};

// ========================================
// INTERFACES
// ========================================
export interface EmailData {
  to: string[];
  subject: string;
  html: string | ((email: string) => string); // Can be string or function
}

export interface AssignmentEmailData {
  studentEmails: string[];
  studentNames: { [email: string]: string }; // email -> displayName
  studentGroups: { [email: string]: string }; // email -> groupName
  assignmentTitle: string;
  courseName: string;
  dueDate: Date;
  courseId: string;
  assignmentId: string;
  startDate?: Date;
  lateDeadline?: Date;
}

export interface QuizEmailData {
  studentEmails: string[];
  studentNames: { [email: string]: string }; // email -> displayName
  studentGroups: { [email: string]: string }; // email -> groupName
  quizTitle: string;
  courseName: string;
  startTime: Date;
  endTime: Date;
  courseId: string;
  quizId: string;
}

export interface MaterialEmailData {
  studentEmails: string[];
  studentNames: { [email: string]: string }; // email -> displayName
  studentGroups: { [email: string]: string }; // email -> groupName
  materialTitle: string;
  courseName: string;
  courseId: string;
  materialId: string;
  materialType?: string; // PDF, Video, Document, etc.
  uploadedAt?: Date;
}

export interface AssignmentGradeEmailData {
  studentEmails: string[];
  studentNames: { [email: string]: string }; // email -> displayName
  studentGroups: { [email: string]: string }; // email -> groupName
  assignmentTitle: string;
  courseName: string;
  courseId: string;
  assignmentId: string;
  grades: { [email: string]: number }; // email -> grade
  maxPoints: number;
  feedback?: { [email: string]: string }; // email -> feedback
  instructorName: string;
}

export interface QuizGradeEmailData {
  studentEmails: string[];
  studentNames: { [email: string]: string }; // email -> displayName
  studentGroups: { [email: string]: string }; // email -> groupName
  quizTitle: string;
  courseName: string;
  courseId: string;
  quizId: string;
  grades: { [email: string]: number }; // email -> grade
  maxPoints: number;
  instructorName: string;
}

// ========================================
// CORE FUNCTION: Send Email
// ========================================
export async function sendEmail(data: EmailData): Promise<void> {
  try {
    const transporter = getTransporter();
    const user = process.env.EMAIL_USER || functions.config().email?.user;
    const pass = process.env.EMAIL_PASSWORD || functions.config().email?.password;

    // Validate email configuration
    if (!user || !pass) {
      console.warn('⚠️ Email credentials not configured. Skipping email send.');
      return;
    }

    // Filter valid emails
    const validEmails = data.to.filter(email => 
      email && email.includes('@') && email.includes('.')
    );

    if (validEmails.length === 0) {
      console.warn('⚠️ No valid email addresses found');
      return;
    }

    // Send individual emails to preserve personalization
    for (const email of validEmails) {
      const mailOptions = {
        from: `E-Learning Management System <${user}>`,
        to: email,
        subject: data.subject,
        html: typeof data.html === 'function' ? data.html(email) : data.html,
      };
      await transporter.sendMail(mailOptions);
    }

    
    console.log(`✅ Email sent successfully to ${validEmails.length} recipients`);
  } catch (error) {
    console.error('❌ Error sending email:', error);
    // Don't throw - email failure shouldn't break in-app notifications
  }
}

// ========================================
// TEMPLATE: New Assignment Email
// ========================================
export function generateAssignmentEmail(data: AssignmentEmailData): (email: string) => string {
  return (email: string) => {
    // Format date to UTC+7 (Vietnam timezone)
    const formatDate = (date: Date) => {
      const utc7Date = new Date(date.getTime() + (7 * 60 * 60 * 1000));
      return utc7Date.toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true,
      });
    };

    const dueDate = formatDate(data.dueDate);
    const startDate = data.startDate ? formatDate(data.startDate) : null;
    const lateDeadline = data.lateDeadline ? formatDate(data.lateDeadline) : null;

    // Get student name and group for THIS email
    const studentName = data.studentNames[email] || 'Student';
    const studentGroup = data.studentGroups[email] || 'Your Group';

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
               line-height: 1.6; color: #333; background: #f4f4f4; }
        .container { max-width: 600px; margin: 20px auto; background: white; 
                     border-radius: 10px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                  color: white; padding: 30px 20px; text-align: center; }
        .header h1 { font-size: 28px; margin-bottom: 10px; }
        .header p { font-size: 16px; opacity: 0.9; }
        .content { padding: 30px 20px; }
        .content h2 { color: #667eea; margin-bottom: 15px; font-size: 22px; }
        .info-box { background: #f9f9f9; border-left: 4px solid #667eea; 
                    padding: 15px; margin: 15px 0; border-radius: 5px; }
        .info-box strong { color: #667eea; display: block; margin-bottom: 5px; }
        .button { display: inline-block; background: #667eea; color: white; 
                  padding: 12px 30px; text-decoration: none; border-radius: 5px; 
                  margin-top: 20px; font-weight: 600; }
        .button:hover { background: #5568d3; }
        .footer { background: #f9f9f9; padding: 20px; text-align: center; 
                  border-top: 1px solid #e0e0e0; }
        .footer p { color: #666; font-size: 12px; margin: 5px 0; }
        .warning { background: #fff3cd; border-left-color: #ffc107; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>📚 New Assignment</h1>
          <p>${data.courseName}</p>
        </div>
        
        <div class="content">
          <p style="margin-bottom: 20px;">Dear <strong>${studentName}</strong>,</p>
          
          <h2>${data.assignmentTitle}</h2>
          
          <p style="margin: 15px 0;">A new assignment has been assigned to your course. Please complete it on time to achieve the highest score!</p>
          
          <div class="info-box">
            <strong>👥 Your Group:</strong>
            ${studentGroup}
          </div>
          
          ${startDate ? `
          <div class="info-box">
            <strong>🕐 Start Date:</strong>
            ${startDate}
          </div>
          ` : ''}
          
          <div class="info-box warning">
            <strong>⏰ Due Date:</strong>
            ${dueDate}
          </div>
          
          ${lateDeadline ? `
          <div class="info-box">
            <strong>⚠️ Late Deadline (with penalty):</strong>
            ${lateDeadline}
          </div>
          ` : ''}
          
          <p style="color: #e74c3c; font-weight: 600; margin-top: 20px;">
            ⚠️ Note: Submissions after the due date may incur point deductions or may not be accepted.
          </p>
          
          <center>
            <a href="https://your-app-url.com/course/${data.courseId}/assignment/${data.assignmentId}" 
               class="button">View Assignment Details</a>
          </center>
        </div>
        
        <div class="footer">
          <p><strong>E-Learning Management System</strong></p>
          <p>This email was sent automatically. Please do not reply.</p>
          <p>If you have any questions, please contact your instructor or support team</p>
        </div>
      </div>
    </body>
    </html>
  `;
  };
}

// ========================================
// TEMPLATE: New Quiz Email (matches Assignment format)
// ========================================
export function generateQuizEmail(data: QuizEmailData): (email: string) => string {
  return (email: string) => {
    // Format date to UTC+7 (Vietnam timezone)
    const formatDate = (date: Date) => {
      const utc7Date = new Date(date.getTime() + (7 * 60 * 60 * 1000));
      return utc7Date.toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true,
      });
    };

    const startTime = formatDate(data.startTime);
    const endTime = formatDate(data.endTime);

    // Get student name and group for THIS email
    const studentName = data.studentNames[email] || 'Student';
    const studentGroup = data.studentGroups[email] || 'Your Group';

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
               line-height: 1.6; color: #333; background: #f4f4f4; }
        .container { max-width: 600px; margin: 20px auto; background: white; 
                     border-radius: 10px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #10b981 0%, #059669 100%); 
                  color: white; padding: 30px 20px; text-align: center; }
        .header h1 { font-size: 28px; margin-bottom: 10px; }
        .header p { font-size: 16px; opacity: 0.9; }
        .content { padding: 30px 20px; }
        .content h2 { color: #10b981; margin-bottom: 15px; font-size: 22px; }
        .info-box { background: #f0fdf4; border-left: 4px solid #10b981; 
                    padding: 15px; margin: 15px 0; border-radius: 5px; }
        .info-box strong { color: #10b981; display: block; margin-bottom: 5px; }
        .button { display: inline-block; background: #10b981; color: white; 
                  padding: 12px 30px; text-decoration: none; border-radius: 5px; 
                  margin-top: 20px; font-weight: 600; }
        .button:hover { background: #059669; }
        .footer { background: #f9f9f9; padding: 20px; text-align: center; 
                  border-top: 1px solid #e0e0e0; }
        .footer p { color: #666; font-size: 12px; margin: 5px 0; }
        .warning { background: #fff3cd; border-left-color: #ffc107; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>📝 New Quiz</h1>
          <p>${data.courseName}</p>
        </div>
        
        <div class="content">
          <p style="margin-bottom: 20px;">Dear <strong>${studentName}</strong>,</p>
          
          <h2>${data.quizTitle}</h2>
          
          <p style="margin: 15px 0;">A new quiz has been assigned to your course. Please complete it within the timeframe to achieve the best score!</p>
          
          <div class="info-box">
            <strong>👥 Your Group:</strong>
            ${studentGroup}
          </div>
          
          <div class="info-box">
            <strong>🕐 Start Time:</strong>
            ${startTime}
          </div>
          
          <div class="info-box warning">
            <strong>⏰ End Time:</strong>
            ${endTime}
          </div>
          
          <p style="color: #dc2626; font-weight: 600; margin-top: 20px;">
            ⚠️ Note: The quiz must be completed before the end time. Late submissions will not be accepted.
          </p>
          
          <center>
            <a href="https://your-app-url.com/course/${data.courseId}/quiz/${data.quizId}" 
               class="button">Start Quiz</a>
          </center>
        </div>
        
        <div class="footer">
          <p><strong>E-Learning Management System</strong></p>
          <p>This email was sent automatically. Please do not reply.</p>
          <p>If you have any questions, please contact your instructor or support team</p>
        </div>
      </div>
    </body>
    </html>
  `;
  };
}

// ========================================
// TEMPLATE: New Material Email (matches Assignment format)
// ========================================
export function generateMaterialEmail(data: MaterialEmailData): (email: string) => string {
  return (email: string) => {
    // Format date to UTC+7 (Vietnam timezone)
    const formatDate = (date: Date) => {
      const utc7Date = new Date(date.getTime() + (7 * 60 * 60 * 1000));
      return utc7Date.toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true,
      });
    };

    const uploadedAt = data.uploadedAt ? formatDate(data.uploadedAt) : null;

    // Get student name and group for THIS email
    const studentName = data.studentNames[email] || 'Student';
    const studentGroup = data.studentGroups[email] || 'Your Group';

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
               line-height: 1.6; color: #333; background: #f4f4f4; }
        .container { max-width: 600px; margin: 20px auto; background: white; 
                     border-radius: 10px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); 
                  color: white; padding: 30px 20px; text-align: center; }
        .header h1 { font-size: 28px; margin-bottom: 10px; }
        .header p { font-size: 16px; opacity: 0.9; }
        .content { padding: 30px 20px; }
        .content h2 { color: #f59e0b; margin-bottom: 15px; font-size: 22px; }
        .info-box { background: #fff7ed; border-left: 4px solid #f59e0b; 
                    padding: 15px; margin: 15px 0; border-radius: 5px; }
        .info-box strong { color: #f59e0b; display: block; margin-bottom: 5px; }
        .button { display: inline-block; background: #f59e0b; color: white; 
                  padding: 12px 30px; text-decoration: none; border-radius: 5px; 
                  margin-top: 20px; font-weight: 600; }
        .button:hover { background: #d97706; }
        .footer { background: #f9f9f9; padding: 20px; text-align: center; 
                  border-top: 1px solid #e0e0e0; }
        .footer p { color: #666; font-size: 12px; margin: 5px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>📂 New Learning Material</h1>
          <p>${data.courseName}</p>
        </div>
        
        <div class="content">
          <p style="margin-bottom: 20px;">Dear <strong>${studentName}</strong>,</p>
          
          <h2>${data.materialTitle}</h2>
          
          <p style="margin: 15px 0;">A new learning material has been uploaded to your course. Please review it to enhance your learning experience!</p>
          
          <div class="info-box">
            <strong>👥 Your Group:</strong>
            ${studentGroup}
          </div>
          
          ${data.materialType ? `
          <div class="info-box">
            <strong>📄 Material Type:</strong>
            ${data.materialType}
          </div>
          ` : ''}
          
          ${uploadedAt ? `
          <div class="info-box">
            <strong>📅 Uploaded:</strong>
            ${uploadedAt}
          </div>
          ` : ''}
          
          <p style="color: #0891b2; font-weight: 600; margin-top: 20px;">
            💡 Tip: Review materials regularly to stay up-to-date with course content.
          </p>
          
          <center>
            <a href="https://your-app-url.com/course/${data.courseId}/material/${data.materialId}" 
               class="button">View Material Details</a>
          </center>
        </div>
        
        <div class="footer">
          <p><strong>E-Learning Management System</strong></p>
          <p>This email was sent automatically. Please do not reply.</p>
          <p>If you have any questions, please contact your instructor or support team</p>
        </div>
      </div>
    </body>
    </html>
  `;
  };
}

// ========================================
// TEMPLATE: Assignment Grade Email (matches Assignment format)
// ========================================
export function generateAssignmentGradeEmail(data: AssignmentGradeEmailData): (email: string) => string {
  return (email: string) => {
    // Get student-specific data
    const studentName = data.studentNames[email] || 'Student';
    const studentGroup = data.studentGroups[email] || 'Your Group';
    const grade = data.grades[email] || 0;
    const feedback = data.feedback?.[email] || '';
    const percentage = ((grade / data.maxPoints) * 100).toFixed(1);

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; 
                     border-radius: 10px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #10b981 0%, #059669 100%); 
                  color: white; padding: 30px 20px; text-align: center; }
        .header h1 { font-size: 24px; margin-bottom: 5px; }
        .header p { font-size: 14px; opacity: 0.9; }
        .content { padding: 30px 20px; color: #333; line-height: 1.6; }
        .content h2 { color: #10b981; margin: 20px 0 10px; font-size: 20px; }
        .info-box { background: #d1fae5; border-left: 4px solid #10b981; 
                    padding: 15px; margin: 15px 0; border-radius: 5px; }
        .info-box strong { color: #059669; display: block; margin-bottom: 5px; }
        .grade-box { background: linear-gradient(135deg, #10b981 0%, #059669 100%);
                     color: white; padding: 20px; margin: 20px 0; border-radius: 8px;
                     text-align: center; }
        .grade-box .score { font-size: 36px; font-weight: bold; margin: 10px 0; }
        .grade-box .percentage { font-size: 18px; opacity: 0.9; }
        .feedback-box { background: #f0fdf4; border: 1px solid #10b981;
                        padding: 15px; margin: 15px 0; border-radius: 5px; }
        .feedback-box strong { color: #059669; display: block; margin-bottom: 10px; }
        .button { display: inline-block; background: #10b981; color: white; 
                  padding: 12px 30px; text-decoration: none; border-radius: 5px; 
                  margin-top: 20px; font-weight: 600; }
        .button:hover { background: #059669; }
        .footer { background: #f9f9f9; padding: 20px; text-align: center; 
                  border-top: 1px solid #e0e0e0; }
        .footer p { color: #666; font-size: 12px; margin: 5px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>✅ Assignment Graded</h1>
          <p>${data.courseName}</p>
        </div>
        
        <div class="content">
          <p style="margin-bottom: 20px;">Dear <strong>${studentName}</strong>,</p>
          
          <h2>${data.assignmentTitle}</h2>
          
          <p style="margin: 15px 0;">Your assignment has been graded by <strong>${data.instructorName}</strong>. Here are your results:</p>
          
          <div class="info-box">
            <strong>👥 Your Group:</strong>
            ${studentGroup}
          </div>
          
          <div class="grade-box">
            <div>Your Score</div>
            <div class="score">${grade} / ${data.maxPoints}</div>
            <div class="percentage">${percentage}%</div>
          </div>
          
          ${feedback ? `
          <div class="feedback-box">
            <strong>💬 Instructor Feedback:</strong>
            <p style="color: #333; margin: 0;">${feedback}</p>
          </div>
          ` : ''}
          
          <p style="color: #10b981; font-weight: 600; margin-top: 20px;">
            🎯 Keep up the great work! Review your submission to learn and improve.
          </p>
          
          <center>
            <a href="https://your-app-url.com/course/${data.courseId}/assignment/${data.assignmentId}" 
               class="button">View Assignment Details</a>
          </center>
        </div>
        
        <div class="footer">
          <p><strong>E-Learning Management System</strong></p>
          <p>This email was sent automatically. Please do not reply.</p>
          <p>If you have any questions about your grade, please contact your instructor</p>
        </div>
      </div>
    </body>
    </html>
  `;
  };
}

// ========================================
// TEMPLATE: Quiz Grade Email (matches Quiz format)
// ========================================
export function generateQuizGradeEmail(data: QuizGradeEmailData): (email: string) => string {
  return (email: string) => {
    // Get student-specific data
    const studentName = data.studentNames[email] || 'Student';
    const studentGroup = data.studentGroups[email] || 'Your Group';
    const grade = data.grades[email] || 0;
    const percentage = ((grade / data.maxPoints) * 100).toFixed(1);

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; 
                     border-radius: 10px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); 
                  color: white; padding: 30px 20px; text-align: center; }
        .header h1 { font-size: 24px; margin-bottom: 5px; }
        .header p { font-size: 14px; opacity: 0.9; }
        .content { padding: 30px 20px; color: #333; line-height: 1.6; }
        .content h2 { color: #8b5cf6; margin: 20px 0 10px; font-size: 20px; }
        .info-box { background: #f3e8ff; border-left: 4px solid #8b5cf6; 
                    padding: 15px; margin: 15px 0; border-radius: 5px; }
        .info-box strong { color: #7c3aed; display: block; margin-bottom: 5px; }
        .grade-box { background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
                     color: white; padding: 20px; margin: 20px 0; border-radius: 8px;
                     text-align: center; }
        .grade-box .score { font-size: 36px; font-weight: bold; margin: 10px 0; }
        .grade-box .percentage { font-size: 18px; opacity: 0.9; }
        .button { display: inline-block; background: #8b5cf6; color: white; 
                  padding: 12px 30px; text-decoration: none; border-radius: 5px; 
                  margin-top: 20px; font-weight: 600; }
        .button:hover { background: #7c3aed; }
        .footer { background: #f9f9f9; padding: 20px; text-align: center; 
                  border-top: 1px solid #e0e0e0; }
        .footer p { color: #666; font-size: 12px; margin: 5px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>📝 Quiz Graded</h1>
          <p>${data.courseName}</p>
        </div>
        
        <div class="content">
          <p style="margin-bottom: 20px;">Dear <strong>${studentName}</strong>,</p>
          
          <h2>${data.quizTitle}</h2>
          
          <p style="margin: 15px 0;">Your quiz has been graded by <strong>${data.instructorName}</strong>. Here are your results:</p>
          
          <div class="info-box">
            <strong>👥 Your Group:</strong>
            ${studentGroup}
          </div>
          
          <div class="grade-box">
            <div>Your Score</div>
            <div class="score">${grade} / ${data.maxPoints}</div>
            <div class="percentage">${percentage}%</div>
          </div>
          
          <p style="color: #8b5cf6; font-weight: 600; margin-top: 20px;">
            🎯 Great job! Review the quiz to understand any missed questions.
          </p>
          
          <center>
            <a href="https://your-app-url.com/course/${data.courseId}/quiz/${data.quizId}" 
               class="button">View Quiz Details</a>
          </center>
        </div>
        
        <div class="footer">
          <p><strong>E-Learning Management System</strong></p>
          <p>This email was sent automatically. Please do not reply.</p>
          <p>If you have any questions about your score, please contact your instructor</p>
        </div>
      </div>
    </body>
    </html>
  `;
  };
}
