/**
 * ========================================
 * FILE: trackerService.ts
 * PURPOSE: Assignment Tracking System - Helper Functions
 * DESCRIPTION: Denormalized tracking for fast queries and gradebook operations
 * ========================================
 */

import * as admin from "firebase-admin";

/**
 * Interface for Assignment Tracker Document
 */
export interface AssignmentTracker {
  // Primary Keys
  assignmentId: string;
  studentId: string;
  courseId: string;
  groupId: string;

  // Denormalized Student Info (for Sort/Search without JOIN)
  studentName: string;
  studentEmail: string;
  groupName: string;

  // Status & Tracking
  status: "missing" | "submitted" | "late" | "graded";
  submittedAt: admin.firestore.Timestamp | null;
  isLate: boolean;
  attemptCount: number;

  // Grading
  grade: number | null;
  maxPoints: number;
  feedback: string | null;
  gradedBy: string | null;
  gradedAt: admin.firestore.Timestamp | null;

  // Submission Data
  attachments: Array<{
    id: string;
    name: string;
    url: string;
    mimeType: string;
    sizeInBytes: number;
  }>;

  // Timestamps
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

/**
 * Generate composite trackerId: ${assignmentId}_${studentId}
 * This ensures 1 tracker per student per assignment
 */
export function getTrackerId(assignmentId: string, studentId: string): string {
  return `${assignmentId}_${studentId}`;
}

/**
 * Create tracker document for a student when assignment is created
 * 
 * @param assignment - Assignment data
 * @param student - Student enrollment data with user info
 * @returns Promise<void>
 */
export async function createTrackerDocument(
  assignment: any,
  student: {
    userId: string;
    groupId: string;
    email?: string;
    displayName?: string;
    groupName?: string;
  }
): Promise<void> {
  const trackerId = getTrackerId(assignment.id || assignment.assignmentId, student.userId);

  const trackerData: AssignmentTracker = {
    // Primary Keys
    assignmentId: assignment.id || assignment.assignmentId,
    studentId: student.userId,
    courseId: assignment.courseId,
    groupId: student.groupId,

    // Denormalized Info
    studentName: student.displayName || "Student",
    studentEmail: student.email || "",
    groupName: student.groupName || "Unknown Group",

    // Initial Status (Missing - chưa nộp)
    status: "missing",
    submittedAt: null,
    isLate: false,
    attemptCount: 0,

    // Grading (chưa có)
    grade: null,
    maxPoints: assignment.maxPoints || 100,
    feedback: null,
    gradedBy: null,
    gradedAt: null,

    // Attachments (chưa có)
    attachments: [],

    // Timestamps
    createdAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
    updatedAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
  };

  await admin.firestore()
    .collection("assignment_trackers")
    .doc(trackerId)
    .set(trackerData);

  console.log(`✅ Created tracker: ${trackerId} for ${student.displayName}`);
}

/**
 * Update tracker status when student submits assignment
 * 
 * @param submission - Submission data (with attemptNumber from callable function)
 * @param assignmentDeadline - Assignment deadline to check if late
 * @returns Promise<void>
 */
export async function updateTrackerOnSubmission(
  submission: any,
  assignmentDeadline: admin.firestore.Timestamp
): Promise<void> {
  const trackerId = getTrackerId(submission.assignmentId, submission.studentId);

  console.log(`🔄 Updating tracker: ${trackerId}`);
  console.log(`📅 Submission data:`, {
    assignmentId: submission.assignmentId,
    studentId: submission.studentId,
    attemptNumber: submission.attemptNumber,
    submittedAt: submission.submittedAt,
    submittedAtType: typeof submission.submittedAt,
  });

  // ✅ PARSE submittedAt - Handle both ISO8601 string and Timestamp
  let submittedAt: admin.firestore.Timestamp;
  
  if (typeof submission.submittedAt === 'string') {
    // Convert ISO8601 string to Timestamp
    // ✅ FIX: Ensure string is parsed as UTC by adding 'Z' if missing
    let dateString = submission.submittedAt;
    if (!dateString.endsWith('Z') && !dateString.includes('+') && !dateString.includes('-', 10)) {
      dateString = dateString + 'Z'; // Force UTC interpretation
      console.log(`⚠️ Added 'Z' suffix to force UTC parsing: ${dateString}`);
    }
    const submittedDate = new Date(dateString);
    submittedAt = admin.firestore.Timestamp.fromDate(submittedDate);
    console.log(`✅ Parsed submittedAt from ISO8601 string: ${submission.submittedAt} → ${submittedDate.toISOString()}`);
  } else if (submission.submittedAt?._seconds !== undefined) {
    // Already a Timestamp object
    submittedAt = submission.submittedAt;
    console.log(`✅ Using existing Timestamp`);
  } else {
    // Fallback to current time
    submittedAt = admin.firestore.Timestamp.now();
    console.log(`⚠️ Using current time as fallback`);
  }

  const isLate = submittedAt.toMillis() > assignmentDeadline.toMillis();
  console.log(`📊 Deadline check: submitted=${submittedAt.toDate()}, deadline=${assignmentDeadline.toDate()}, isLate=${isLate}`);

  // Determine status
  let status: "submitted" | "late" | "graded" = isLate ? "late" : "submitted";
  
  // If already graded, keep graded status
  if (submission.score !== null && submission.score !== undefined) {
    status = "graded";
  }

  // ✅ Use attemptNumber from submission (set by submitAssignment callable function)
  // This is more reliable than counting, as callable function validates max attempts
  const attemptNumber = submission.attemptNumber || 1;

  // Parse attachments from submission
  const attachments = (submission.attachments || []).map((att: any) => ({
    id: att.id || "",
    name: att.name || "",
    url: att.url || "",
    mimeType: att.mimeType || "",
    sizeInBytes: att.sizeInBytes || 0,
  }));

  // ✅ Use set() with merge instead of update() to handle non-existent trackers
  try {
    await admin.firestore()
      .collection("assignment_trackers")
      .doc(trackerId)
      .set({
        status: status,
        submittedAt: submittedAt,
        isLate: isLate,
        attemptCount: attemptNumber,
        attachments: attachments,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true }); // ✅ Merge to preserve existing fields

    console.log(`✅ Updated tracker: ${trackerId} - Status: ${status}, Attempt: ${attemptNumber}, IsLate: ${isLate}`);
  } catch (error) {
    console.error(`❌ Failed to update tracker ${trackerId}:`, error);
    throw error;
  }
}

/**
 * Sync grade from tracker back to submission document
 * Called when instructor updates grade in tracker
 * 
 * @param trackerId - Tracker document ID
 * @param grade - Grade value
 * @param feedback - Optional feedback
 * @param gradedBy - Instructor UID
 * @returns Promise<void>
 */
export async function syncGradeToSubmission(
  trackerId: string,
  grade: number,
  feedback: string | null,
  gradedBy: string
): Promise<void> {
  // Parse trackerId to get assignmentId and studentId
  const [assignmentId, studentId] = trackerId.split("_");

  // Find the latest submission for this student + assignment
  const submissionsSnapshot = await admin.firestore()
    .collection("submissions")
    .where("assignmentId", "==", assignmentId)
    .where("studentId", "==", studentId)
    .orderBy("attemptNumber", "desc")
    .limit(1)
    .get();

  if (submissionsSnapshot.empty) {
    console.warn(`⚠️ No submission found for tracker ${trackerId}`);
    return;
  }

  const latestSubmissionDoc = submissionsSnapshot.docs[0];

  // Update submission with grade
  await latestSubmissionDoc.ref.update({
    score: grade,
    feedback: feedback,
    gradedBy: gradedBy,
    gradedAt: admin.firestore.FieldValue.serverTimestamp(),
    status: "graded",
    lastModified: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`✅ Synced grade ${grade} to submission ${latestSubmissionDoc.id}`);
}

/**
 * Batch create trackers for all students in assignment groups
 * Used in onAssignmentCreated trigger
 * 
 * @param assignment - Assignment data with id
 * @param enrollmentData - Array of student enrollment data
 * @returns Promise<void>
 */
export async function batchCreateTrackers(
  assignment: any,
  enrollmentData: Array<{
    userId: string;
    groupId: string;
    email?: string;
    displayName?: string;
    groupName?: string;
  }>
): Promise<void> {
  const batch = admin.firestore().batch();
  const trackersRef = admin.firestore().collection("assignment_trackers");

  for (const student of enrollmentData) {
    const trackerId = getTrackerId(assignment.id, student.userId);
    const trackerRef = trackersRef.doc(trackerId);

    const trackerData: AssignmentTracker = {
      assignmentId: assignment.id,
      studentId: student.userId,
      courseId: assignment.courseId,
      groupId: student.groupId,
      studentName: student.displayName || "Student",
      studentEmail: student.email || "",
      groupName: student.groupName || "Unknown Group",
      status: "missing",
      submittedAt: null,
      isLate: false,
      attemptCount: 0,
      grade: null,
      maxPoints: assignment.maxPoints || 100,
      feedback: null,
      gradedBy: null,
      gradedAt: null,
      attachments: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
      updatedAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
    };

    batch.set(trackerRef, trackerData);
  }

  await batch.commit();
  console.log(`✅ Batch created ${enrollmentData.length} trackers`);
}
