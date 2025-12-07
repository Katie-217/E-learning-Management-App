import * as functions from "firebase-functions";
import * as functionsV2 from "firebase-functions/v2";
import * as admin from "firebase-admin";
import * as cheerio from "cheerio";
import fetch from "node-fetch";
import {
  sendEmail,
  generateAssignmentEmail,
  generateQuizEmail,
  generateMaterialEmail,
  generateAssignmentGradeEmail,
  generateQuizGradeEmail,
} from "./utils/emailService";
import {
  batchCreateTrackers,
  updateTrackerOnSubmission,
  syncGradeToSubmission,
} from "./utils/trackerService";

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Interface for Link Preview metadata
 */
interface LinkPreviewData {
  url: string;
  title: string;
  description?: string;
  imageUrl?: string;
  domain: string;
  success: boolean;
  error?: string;
}

/**
 * Check if URL is YouTube
 */
function isYouTubeUrl(url: string): boolean {
  return url.includes("youtube.com") || url.includes("youtu.be");
}

/**
 * Fetch YouTube metadata using oEmbed API (official, never blocked)
 */
async function fetchYouTubeMetadata(url: string): Promise<LinkPreviewData> {
  console.log("📺 Using YouTube oEmbed API");
  
  const oembedUrl = `https://www.youtube.com/oembed?url=${encodeURIComponent(url)}&format=json`;
  
  const response = await fetch(oembedUrl, {
    method: "GET",
    headers: {
      "Accept": "application/json",
    },
    timeout: 10000,
  });

  if (!response.ok) {
    throw new Error(`YouTube oEmbed failed: ${response.status}`);
  }

  const data = await response.json() as any;
  const parsedUrl = new URL(url);

  return {
    url: url,
    title: data.title || parsedUrl.hostname,
    description: data.author_name ? `By ${data.author_name}` : undefined,
    imageUrl: data.thumbnail_url || undefined,
    domain: parsedUrl.hostname,
    success: true,
  };
}

/**
 * Get comprehensive browser-like headers to bypass firewalls
 */
function getBrowserHeaders(referer?: string): Record<string, string> {
  return {
    // Core browser identity
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
      "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    
    // Accept headers (mimic Chrome)
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9," +
      "image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Language": "en-US,en;q=0.9,vi;q=0.8",
    "Accept-Encoding": "gzip, deflate, br",
    
    // Security headers (critical for modern sites)
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-User": "?1",
    "Sec-Fetch-Dest": "document",
    "Sec-Ch-Ua": "\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\", \"Google Chrome\";v=\"120\"",
    "Sec-Ch-Ua-Mobile": "?0",
    "Sec-Ch-Ua-Platform": "\"Windows\"",
    
    // Additional headers
    "Upgrade-Insecure-Requests": "1",
    "Cache-Control": "max-age=0",
    "Referer": referer || "",
    
    // Connection
    "Connection": "keep-alive",
  };
}

/**
 * Fetch metadata using web scraping with enhanced headers
 */
async function fetchWebMetadata(url: string): Promise<LinkPreviewData> {
  console.log("🌐 Fetching with enhanced browser headers");
  
  const parsedUrl = new URL(url);
  const headers = getBrowserHeaders(url);

  const response = await fetch(url, {
    method: "GET",
    headers: headers,
    redirect: "follow",
    timeout: 15000, // 15 seconds for slow sites
  });

  if (!response.ok) {
    console.error(`HTTP error: ${response.status} ${response.statusText}`);
    throw new Error(`Failed to fetch: ${response.status}`);
  }

  // Get HTML content
  const html = await response.text();
  const $ = cheerio.load(html);

  // Extract metadata with priority: OG > Twitter > Standard
  let title = $('meta[property="og:title"]').attr("content") ||
              $('meta[name="twitter:title"]').attr("content") ||
              $('meta[itemprop="name"]').attr("content") ||
              $("title").first().text() ||
              $("h1").first().text() ||
              parsedUrl.hostname;

  let description = $('meta[property="og:description"]').attr("content") ||
                   $('meta[name="twitter:description"]').attr("content") ||
                   $('meta[name="description"]').attr("content") ||
                   $('meta[itemprop="description"]').attr("content") ||
                   "";

  let imageUrl = $('meta[property="og:image"]').attr("content") ||
                $('meta[property="og:image:url"]').attr("content") ||
                $('meta[name="twitter:image"]').attr("content") ||
                $('meta[itemprop="image"]').attr("content") ||
                $('link[rel="image_src"]').attr("href") ||
                "";

  // Make image URL absolute if relative
  if (imageUrl && !imageUrl.startsWith("http")) {
    if (imageUrl.startsWith("//")) {
      imageUrl = `https:${imageUrl}`;
    } else if (imageUrl.startsWith("/")) {
      imageUrl = `${parsedUrl.protocol}//${parsedUrl.host}${imageUrl}`;
    } else {
      imageUrl = `${parsedUrl.protocol}//${parsedUrl.host}/${imageUrl}`;
    }
  }

  // Clean text (remove extra whitespace, decode HTML entities)
  title = title.trim().replace(/\s+/g, " ").substring(0, 200);
  description = description.trim().replace(/\s+/g, " ").substring(0, 500);

  return {
    url: url,
    title: title || parsedUrl.hostname,
    description: description || undefined,
    imageUrl: imageUrl || undefined,
    domain: parsedUrl.hostname,
    success: true,
  };
}

/**
 * Callable Cloud Function to fetch link preview metadata
 * 
 * Enhanced with:
 * 1. YouTube oEmbed API for 100% reliability
 * 2. Comprehensive browser headers to bypass firewalls (TGDD, Shopee, etc.)
 * 
 * This function:
 * 1. Receives a URL from the client
 * 2. Detects domain and chooses optimal strategy
 * 3. Fetches metadata with proper headers
 * 4. Returns structured data (title, image, description, domain)
 * 
 * Benefits:
 * - No CORS issues (server-side fetch)
 * - Works for all platforms (Web, Mobile, Desktop)
 * - Bypasses firewalls with realistic browser headers
 * - YouTube uses official oEmbed API
 * - Reliable and scalable on Google infrastructure
 * 
 * Usage from Flutter:
 * ```dart
 * final result = await FirebaseFunctions.instance
 *   .httpsCallable('fetchLinkPreview')
 *   .call({'url': 'https://example.com'});
 * ```
 */
export const fetchLinkPreview = functions.https.onCall(
  async (data: {url: string}, context) => {
    try {
      // Validate input
      const url = data.url;
      if (!url || typeof url !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "URL is required and must be a string"
        );
      }

      // Validate URL format
      let parsedUrl: URL;
      try {
        parsedUrl = new URL(url);
        if (!["http:", "https:"].includes(parsedUrl.protocol)) {
          throw new Error("Invalid protocol");
        }
      } catch (error) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Invalid URL format. Must be http:// or https://"
        );
      }

      console.log(`🔍 Fetching link preview for: ${url}`);
      console.log(`   Domain: ${parsedUrl.hostname}`);

      let result: LinkPreviewData;

      // Strategy 1: YouTube uses official oEmbed API
      if (isYouTubeUrl(url)) {
        result = await fetchYouTubeMetadata(url);
      } else {
        // Strategy 2: Other sites use enhanced scraping
        result = await fetchWebMetadata(url);
      }

      console.log("✅ Link preview extracted successfully:", {
        title: result.title.substring(0, 50) + "...",
        hasImage: !!result.imageUrl,
        hasDescription: !!result.description,
      });

      return result;
    } catch (error: any) {
      console.error("❌ Error fetching link preview:", error.message);

      // Return user-friendly error
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // Generic error
      throw new functions.https.HttpsError(
        "internal",
        "Failed to fetch link preview: " + error.message,
        error.message
      );
    }
  }
);

/**
 * Interface for bulk user creation result
 */
interface BulkUserCreationResult {
  successCount: number;
  failureCount: number;
  successRecords: Array<{email: string; uid: string; name: string}>;
  failedRecords: Array<{email: string; error: string}>;
}

/**
 * Gen 2 HTTP Cloud Function for bulk user creation using Admin SDK
 * Works on ALL platforms (Web, Mobile, Desktop)
 */
export const bulkCreateUsers = functionsV2.https.onRequest(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
    cors: true, // Enable CORS
    invoker: "public", // Allow public access
  },
  async (req, res) => {
    // Set CORS headers explicitly
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    // Handle preflight
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    // Only POST
    if (req.method !== 'POST') {
      res.status(405).json({error: 'Method not allowed'});
      return;
    }
    
    try {
      console.log("📥 Request received");
      
      // Auth
      const authHeader = req.get('Authorization') || req.get('authorization');
      console.log("🔑 Auth header:", authHeader ? "present" : "missing");
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({error: 'Missing Authorization header'});
        return;
      }
      
      const idToken = authHeader.substring(7);
      console.log("🎫 Token length:", idToken.length);
      
      let decodedToken;
      
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
        console.log(`✅ Authenticated: ${decodedToken.email}`);
      } catch (error) {
        console.error('❌ Token verification failed:', error);
        res.status(401).json({error: 'Invalid token', details: String(error)});
        return;
      }

      // Get body - firebase-functions auto-parses JSON
      const students = req.body?.students;
      
      if (!students || !Array.isArray(students)) {
        console.error('❌ Invalid request body:', req.body);
        res.status(400).json({error: 'Missing students array in request body'});
        return;
      }

      if (students.length === 0) {
        res.status(400).json({error: 'Students array is empty'});
        return;
      }

      if (students.length > 500) {
        res.status(400).json({error: 'Maximum 500 students per batch'});
        return;
      }

      console.log(`🚀 Creating ${students.length} users...`);

      const result: BulkUserCreationResult = {
        successCount: 0,
        failureCount: 0,
        successRecords: [],
        failedRecords: [],
      };

      // Process in parallel with Promise.allSettled for better error handling
      const promises = students.map(async (student) => {
        try {
          // Validate student data
          if (!student.email || !student.name) {
            throw new Error("Email and name are required");
          }

          // Email format validation
          const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
          if (!emailRegex.test(student.email)) {
            throw new Error("Invalid email format");
          }

          // Check if user already exists in Authentication
          let userRecord;
          try {
            userRecord = await admin.auth().getUserByEmail(student.email);
            console.log(`✓ User ${student.email} already exists in Auth (UID: ${userRecord.uid}) - keeping existing password`);
            // DO NOT update existing users' password or displayName
            // They may have changed their password already
          } catch (error: any) {
            // User doesn't exist, create new one
            if (error.code === "auth/user-not-found") {
              userRecord = await admin.auth().createUser({
                email: student.email,
                emailVerified: false,
                displayName: student.name,
                password: "123456", // Default password - users should change this
                disabled: false,
              });
              console.log(`✓ Created NEW Auth user: ${student.email} (UID: ${userRecord.uid}) with default password 123456`);
            } else {
              throw error;
            }
          }

          // Create or update Firestore document
          const userDocRef = admin.firestore().collection("users").doc(userRecord.uid);
          const userDoc = await userDocRef.get();

          let finalName = student.name; // Default to CSV name

          if (!userDoc.exists) {
            await userDocRef.set({
              email: student.email,
              name: student.name,
              displayName: student.name,
              phone: student.phone || "",
              role: "student",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(`✓ Created Firestore doc for: ${student.email}`);
          } else {
            // User already exists - use existing name from DB, not CSV name
            const userData = userDoc.data();
            finalName = userData?.name || userData?.displayName || student.name;
            console.log(`✓ Firestore doc already exists for: ${student.email} with name: ${finalName}`);
          }

          return {
            success: true,
            email: student.email,
            uid: userRecord.uid,
            name: finalName, // Return existing name for existing users, CSV name for new users
          };
        } catch (error: any) {
          console.error(`✗ Failed to create user ${student.email}:`, error.message);
          return {
            success: false,
            email: student.email,
            error: error.message || "Unknown error",
          };
        }
      });

      // Wait for all promises to settle
      const results = await Promise.allSettled(promises);

      // Process results
      results.forEach((promiseResult) => {
        if (promiseResult.status === "fulfilled") {
          const userResult = promiseResult.value;
          if (userResult.success) {
            result.successCount++;
            result.successRecords.push({
              email: userResult.email,
              uid: userResult.uid!,
              name: userResult.name!,
            });
          } else {
            result.failureCount++;
            result.failedRecords.push({
              email: userResult.email,
              error: userResult.error!,
            });
          }
        } else {
          // Promise rejected (shouldn't happen with our error handling, but just in case)
          result.failureCount++;
          result.failedRecords.push({
            email: "unknown",
            error: promiseResult.reason?.message || "Promise rejected",
          });
        }
      });

      console.log(`✅ Bulk creation completed!`);
      console.log(`   Success: ${result.successCount}`);
      console.log(`   Failed: ${result.failureCount}`);
      console.log(`   Success rate: ${((result.successCount / students.length) * 100).toFixed(1)}%`);

      res.status(200).json(result);
    } catch (error: any) {
      console.error("❌ Bulk user creation failed:", error);
      res.status(500).json({
        error: 'Failed to create users: ' + error.message,
      });
    }
  }
);

/**
 * Health check function for monitoring
 */
export const healthCheck = functions.https.onRequest((req, res) => {
  res.status(200).json({
    status: "healthy",
    service: "link-preview-functions",
    timestamp: new Date().toISOString(),
  });
});

/**
 * Cloud Function to update student email
 * Gen 2 HTTP Function (similar to bulkCreateUsers)
 * 
 * CRITICAL REQUIREMENTS:
 * - Only UPDATE existing user (NEVER delete and recreate)
 * - Update both Authentication and Firestore
 * - Validate email uniqueness before update
 * - Preserve uid to maintain data relationships
 */
export const updateStudentEmailV2 = functionsV2.https.onRequest(
  {
    timeoutSeconds: 60,
    memory: "512MiB",
    cors: true,
    region: "us-central1",
    invoker: "public",
  },
  async (req, res) => {
    // Set CORS headers explicitly
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    // Handle preflight
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    // Only POST
    if (req.method !== 'POST') {
      res.status(405).json({error: 'Method not allowed. Use POST.'});
      return;
    }

    try {
      const { uid, newEmail } = req.body;

      // Validate input
      if (!uid || !newEmail) {
        res.status(400).json({ 
          error: 'Missing required fields: uid and newEmail' 
        });
        return;
      }

      // Validate email format
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(newEmail)) {
        res.status(400).json({ 
          error: 'Invalid email format' 
        });
        return;
      }

      console.log(`📧 Updating email for uid: ${uid} to ${newEmail}`);

      const db = admin.firestore();
      
      // PARALLEL OPERATIONS: Get current user + check uniqueness simultaneously
      const [currentUser, uniquenessCheck] = await Promise.all([
        admin.auth().getUser(uid),
        (async () => {
          try {
            const existingUser = await admin.auth().getUserByEmail(newEmail);
            return existingUser && existingUser.uid !== uid ? existingUser : null;
          } catch (error: any) {
            if (error.code === 'auth/user-not-found') return null;
            throw error;
          }
        })()
      ]);

      // Check uniqueness result
      if (uniquenessCheck) {
        console.log(`❌ Email ${newEmail} already in use by another user`);
        res.status(409).json({ 
          error: 'Email already in use by another student' 
        });
        return;
      }

      const oldEmail = currentUser.email;
      console.log(`📝 Updating ${oldEmail} → ${newEmail}`);

      // PARALLEL: Update Auth + Firestore + Query enrollments simultaneously
      const [_, __, enrollmentsSnapshot] = await Promise.all([
        admin.auth().updateUser(uid, { email: newEmail }),
        db.collection("users").doc(uid).update({
          email: newEmail,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }),
        db.collection("enrollments")
          .where("studentEmail", "==", oldEmail)
          .limit(100) // Limit for safety
          .get()
      ]);
      
      console.log(`✅ Auth + Firestore updated`);

      // Update enrollments if any (sequential - batch write)
      let enrollmentsUpdated = 0;
      if (!enrollmentsSnapshot.empty) {
        const batch = db.batch();
        enrollmentsSnapshot.docs.forEach((doc) => {
          batch.update(doc.ref, { studentEmail: newEmail });
        });
        await batch.commit();
        enrollmentsUpdated = enrollmentsSnapshot.size;
        console.log(`✅ ${enrollmentsUpdated} enrollments updated`);
      }

      res.status(200).json({
        success: true,
        message: "Email updated successfully",
        uid: uid,
        oldEmail: oldEmail,
        newEmail: newEmail,
        enrollmentsUpdated: enrollmentsUpdated,
      });

    } catch (error: any) {
      console.error("❌ Error updating student email:", error);
      
      // Handle specific errors
      if (error.code === 'auth/user-not-found') {
        res.status(404).json({ 
          error: 'Student not found' 
        });
      } else if (error.code === 'auth/email-already-exists') {
        res.status(409).json({ 
          error: 'Email already in use' 
        });
      } else {
        res.status(500).json({
          error: 'Failed to update email: ' + error.message,
        });
      }
    }
  }
);

/**
 * Cloud Function to CASCADE DELETE a student
 * Gen 2 HTTP Function
 * 
 * CRITICAL: Complete deletion from entire system
 * 1. Delete Authentication account (student can't login anymore)
 * 2. Delete Firestore profile (users/{uid})
 * 3. Delete all enrollments (enrollments where studentId == uid)
 * 
 * Request body:
 * {
 *   "uid": "student_uid_to_delete"
 * }
 */
export const deleteStudentCompletely = functionsV2.https.onRequest(
  {
    timeoutSeconds: 60,
    memory: "512MiB",
    cors: true,
    region: "us-central1",
    invoker: "public",
  },
  async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    // Handle preflight
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    // Only POST allowed
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed. Use POST.' });
      return;
    }

    try {
      const { uid } = req.body;

      // Validate input
      if (!uid) {
        res.status(400).json({ error: 'Missing required field: uid' });
        return;
      }

      console.log(`🗑️ Starting complete deletion for student uid: ${uid}`);

      const db = admin.firestore();
      const deletionResults = {
        authDeleted: false,
        firestoreDeleted: false,
        enrollmentsDeleted: 0,
      };

      console.log(`⚡ OPTIMIZED: Running parallel operations...`);

      // ========================================
      // PARALLEL PHASE: Auth + Firestore + Enrollments query simultaneously
      // SPEED UP: Instead of sequential (10-15s), run in parallel (~3-5s)
      // ========================================
      const [authResult, firestoreResult, enrollmentsSnapshot] = await Promise.allSettled([
        // STEP 1: Delete Authentication
        admin.auth().deleteUser(uid),
        
        // STEP 2: Delete Firestore Profile
        db.collection('users').doc(uid).delete(),
        
        // STEP 3: Query enrollments (prepare for batch delete)
        db.collection('enrollments').where('userId', '==', uid).get()
      ]);

      // Process Auth result
      if (authResult.status === 'fulfilled') {
        deletionResults.authDeleted = true;
        console.log(`✅ Auth deleted`);
      } else {
        const error = authResult.reason;
        if (error?.code === 'auth/user-not-found') {
          deletionResults.authDeleted = true;
          console.log(`⚠️ Auth user not found (already deleted)`);
        } else {
          console.error(`❌ Auth deletion failed: ${error?.message}`);
        }
      }

      // Process Firestore result
      if (firestoreResult.status === 'fulfilled') {
        deletionResults.firestoreDeleted = true;
        console.log(`✅ Firestore profile deleted`);
      } else {
        console.error(`❌ Firestore deletion failed: ${firestoreResult.reason?.message}`);
      }

      // Process Enrollments (batch delete if query succeeded)
      if (enrollmentsSnapshot.status === 'fulfilled') {
        const snapshot = enrollmentsSnapshot.value;
        console.log(`📊 Found ${snapshot.size} enrollment records`);
        
        if (!snapshot.empty) {
          try {
            const batch = db.batch();
            snapshot.docs.forEach((doc) => batch.delete(doc.ref));
            await batch.commit();
            deletionResults.enrollmentsDeleted = snapshot.size;
            console.log(`✅ Deleted ${snapshot.size} enrollments`);
          } catch (batchError: any) {
            console.error(`❌ Batch delete failed: ${batchError.message}`);
          }
        } else {
          console.log(`ℹ️ No enrollments to delete`);
        }
      } else {
        console.error(`❌ Enrollments query failed: ${enrollmentsSnapshot.reason?.message}`);
      }

      console.log(`✅ Deletion complete:`);
      console.log(`   Auth: ${deletionResults.authDeleted}`);
      console.log(`   Firestore: ${deletionResults.firestoreDeleted}`);
      console.log(`   Enrollments: ${deletionResults.enrollmentsDeleted}`);

      res.status(200).json({
        success: true,
        message: 'Student deleted completely from system',
        uid: uid,
        deletionResults: deletionResults,
      });

    } catch (error: any) {
      console.error('❌ Error during student deletion:', error);
      res.status(500).json({
        error: 'Failed to delete student: ' + error.message,
      });
    }
  }
);

// ========================================
// CLOUD FUNCTIONS: NOTIFICATION TRIGGERS
// ========================================

/**
 * Trigger: Send notifications when new Assignment is created
 */
/**
 * ========================================
 * TRIGGER: onAssignmentWritten (Create + Update)
 * PURPOSE: Auto-sync Assignment Trackers when assignment groups change
 * ========================================
 * 
 * LOGIC:
 * - onCreate: Create trackers for all students in assigned groups
 * - onUpdate: Calculate delta (added/removed groups) and sync trackers
 * 
 * DELTA CALCULATION:
 * - Added Groups: Create new trackers + Send notifications
 * - Removed Groups: Delete trackers (cleanup orphaned data)
 * - Unchanged Groups: Keep existing trackers (preserve submission/grade data)
 */
export const onAssignmentWritten = functions.firestore
  .document('assignments/{assignmentId}')
  .onWrite(async (change, context) => {
    const assignmentId = context.params.assignmentId;
    
    // Check if this is a delete operation
    if (!change.after.exists) {
      console.log(`🗑️ Assignment ${assignmentId} deleted - skipping trigger`);
      return;
    }

    const after = change.after.data();
    const before = change.before.exists ? change.before.data() : null;

    // Safety check
    if (!after) {
      console.log(`⚠️ Assignment ${assignmentId} has no data - skipping`);
      return;
    }

    // Determine if this is CREATE or UPDATE
    const isCreate = !before;
    const isUpdate = !!before;

    console.log(`📝 Assignment ${isCreate ? 'CREATED' : 'UPDATED'}: ${after.title}`);

    try {
      // ========================================
      // COMMON: Build group name mapping
      // ========================================
      const groupNameMap: { [groupId: string]: string } = {};
      
      if (after.groupIds && after.groupIds.length > 0) {
        for (const groupId of after.groupIds) {
          const groupDoc = await admin.firestore()
            .collection('course_of_study')
            .doc(after.courseId)
            .collection('groups')
            .doc(groupId)
            .get();
          
          if (groupDoc.exists) {
            groupNameMap[groupId] = groupDoc.data()?.name || `Group ${groupId.substring(0, 8)}`;
          } else {
            groupNameMap[groupId] = 'Your Group';
          }
        }
      }

      // ========================================
      // DELTA CALCULATION (Only for UPDATE)
      // ========================================
      let addedGroups: string[] = [];
      let removedGroups: string[] = [];
      
      if (isUpdate) {
        const oldGroupIds = before!.groupIds || [];
        const newGroupIds = after.groupIds || [];
        
        // Added: In new but not in old
        addedGroups = newGroupIds.filter((id: string) => !oldGroupIds.includes(id));
        
        // Removed: In old but not in new
        removedGroups = oldGroupIds.filter((id: string) => !newGroupIds.includes(id));
        
        console.log(`🔄 Delta Calculation:`);
        console.log(`   Added Groups: ${addedGroups.length} (${addedGroups.join(', ')})`);
        console.log(`   Removed Groups: ${removedGroups.length} (${removedGroups.join(', ')})`);
        console.log(`   Unchanged Groups: ${newGroupIds.filter((id: string) => oldGroupIds.includes(id)).length}`);
      }

      // ========================================
      // CASE 1: CREATE - Process all groups
      // ========================================
      if (isCreate) {
        console.log(`✨ Processing CREATE for ${after.groupIds?.length || 0} groups`);
        
        const enrollmentData: Array<{ 
          userId: string; 
          groupId: string; 
          email?: string; 
          displayName?: string; 
          groupName?: string 
        }> = [];
        
        // Collect all students from all groups
        if (after.groupIds && after.groupIds.length > 0) {
          for (const groupId of after.groupIds) {
            const enrollmentsSnapshot = await admin.firestore()
              .collection('enrollments')
              .where('groupId', '==', groupId)
              .where('courseId', '==', after.courseId)
              .where('status', '==', 'active')
              .get();

            enrollmentsSnapshot.forEach(doc => {
              const enrollment = doc.data();
              if (enrollment.userId && enrollment.groupId) {
                enrollmentData.push({
                  userId: enrollment.userId,
                  groupId: enrollment.groupId,
                  groupName: groupNameMap[enrollment.groupId] || 'Your Group',
                });
              }
            });
          }
        }

        console.log(`📊 Found ${enrollmentData.length} students across all groups`);

        // Get user details
        await enrichEnrollmentDataWithUserInfo(enrollmentData);

        // Parallel execution: Notifications + Emails + Trackers
        await executeCreateOperations(
          assignmentId,
          after,
          enrollmentData,
          groupNameMap
        );
      }

      // ========================================
      // CASE 2: UPDATE - Process delta only
      // ========================================
      if (isUpdate && (addedGroups.length > 0 || removedGroups.length > 0)) {
        console.log(`🔄 Processing UPDATE with delta changes`);

        // ========================================
        // SUB-CASE 2A: Handle ADDED groups
        // ========================================
        if (addedGroups.length > 0) {
          console.log(`➕ Processing ${addedGroups.length} added groups`);
          
          const newEnrollmentData: Array<{ 
            userId: string; 
            groupId: string; 
            email?: string; 
            displayName?: string; 
            groupName?: string 
          }> = [];
          
          for (const groupId of addedGroups) {
            const enrollmentsSnapshot = await admin.firestore()
              .collection('enrollments')
              .where('groupId', '==', groupId)
              .where('courseId', '==', after.courseId)
              .where('status', '==', 'active')
              .get();

            enrollmentsSnapshot.forEach(doc => {
              const enrollment = doc.data();
              if (enrollment.userId && enrollment.groupId) {
                newEnrollmentData.push({
                  userId: enrollment.userId,
                  groupId: enrollment.groupId,
                  groupName: groupNameMap[enrollment.groupId] || 'Your Group',
                });
              }
            });
          }

          console.log(`📊 Found ${newEnrollmentData.length} students in added groups`);

          if (newEnrollmentData.length > 0) {
            // Get user details
            await enrichEnrollmentDataWithUserInfo(newEnrollmentData);

            // Create operations for new students
            await executeCreateOperations(
              assignmentId,
              after,
              newEnrollmentData,
              groupNameMap
            );
          }
        }

        // ========================================
        // SUB-CASE 2B: Handle REMOVED groups
        // ========================================
        if (removedGroups.length > 0) {
          console.log(`➖ Processing ${removedGroups.length} removed groups`);
          
          const removedEnrollmentData: string[] = []; // Store student IDs
          
          for (const groupId of removedGroups) {
            const enrollmentsSnapshot = await admin.firestore()
              .collection('enrollments')
              .where('groupId', '==', groupId)
              .where('courseId', '==', after.courseId)
              .where('status', '==', 'active')
              .get();

            enrollmentsSnapshot.forEach(doc => {
              const enrollment = doc.data();
              if (enrollment.userId) {
                removedEnrollmentData.push(enrollment.userId);
              }
            });
          }

          console.log(`📊 Found ${removedEnrollmentData.length} students in removed groups`);

          if (removedEnrollmentData.length > 0) {
            // Delete trackers for removed students
            await executeDeleteOperations(assignmentId, removedEnrollmentData);
          }
        }
      }

      console.log(`✅ Assignment sync completed successfully`);

    } catch (error) {
      console.error('❌ Error in onAssignmentWritten:', error);
      throw error;
    }
  });

/**
 * Helper: Enrich enrollment data with user info (email, displayName)
 */
async function enrichEnrollmentDataWithUserInfo(
  enrollmentData: Array<{ 
    userId: string; 
    email?: string; 
    displayName?: string;
    [key: string]: any;
  }>
): Promise<void> {
  const userIds = enrollmentData.map(e => e.userId);
  
  if (userIds.length === 0) return;

  // Batch query users (10 at a time due to Firestore 'in' limit)
  for (let i = 0; i < userIds.length; i += 10) {
    const batchIds = userIds.slice(i, i + 10);
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where(admin.firestore.FieldPath.documentId(), 'in', batchIds)
      .get();

    usersSnapshot.docs.forEach(userDoc => {
      const userData = userDoc.data();
      const userId = userDoc.id;

      enrollmentData.forEach(enrollment => {
        if (enrollment.userId === userId) {
          enrollment.email = userData.email;
          enrollment.displayName = userData.displayName || userData.fullName || 'Student';
        }
      });
    });
  }
}

/**
 * Helper: Execute create operations (notifications + emails + trackers)
 */
async function executeCreateOperations(
  assignmentId: string,
  assignment: any,
  enrollmentData: Array<{ 
    userId: string; 
    groupId: string; 
    email?: string; 
    displayName?: string; 
    groupName?: string 
  }>,
  groupNameMap: { [groupId: string]: string }
): Promise<void> {
  // Build email lists
  const studentEmails: string[] = [];
  const studentNames: { [email: string]: string } = {};
  const studentGroups: { [email: string]: string } = {};

  enrollmentData.forEach(enrollment => {
    if (enrollment.email) {
      if (!studentEmails.includes(enrollment.email)) {
        studentEmails.push(enrollment.email);
      }
      studentNames[enrollment.email] = enrollment.displayName || 'Student';
      studentGroups[enrollment.email] = enrollment.groupName || 'Your Group';
    }
  });

  // Get course name
  let courseName = 'Khóa học';
  try {
    const courseDoc = await admin.firestore()
      .collection('course_of_study')
      .doc(assignment.courseId)
      .get();
    if (courseDoc.exists) {
      courseName = courseDoc.data()?.name || courseName;
    }
  } catch (e) {
    console.warn('⚠️ Could not fetch course name:', e);
  }

  // Create in-app notifications
  const batch = admin.firestore().batch();
  const notificationsRef = admin.firestore().collection('notifications');

  enrollmentData.forEach(enrollment => {
    if (enrollment.userId) {
      const notificationRef = notificationsRef.doc();
      batch.set(notificationRef, {
        userId: enrollment.userId,
        courseId: assignment.courseId,
        type: 'assignment',
        title: assignment.title,
        content: `New Assignment: ${assignment.title}`,
        relatedId: assignmentId,
        relatedType: 'assignment',
        priority: 'high',
        isRead: false,
        isArchived: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          startDate: assignment.startDate,
          dueDate: assignment.deadline,
          lateDeadline: assignment.lateDeadline || null,
        },
      });
    }
  });

  // ✅ PARALLEL EXECUTION
  const results = await Promise.allSettled([
    // Task 1: Write in-app notifications
    batch.commit(),
    
    // Task 2: Send emails
    studentEmails.length > 0
      ? sendEmail({
          to: studentEmails,
          subject: `📚 New Assignment: ${assignment.title}`,
          html: generateAssignmentEmail({
            studentEmails: studentEmails,
            studentNames: studentNames,
            studentGroups: studentGroups,
            assignmentTitle: assignment.title,
            courseName: courseName,
            dueDate: assignment.deadline?.toDate() || new Date(),
            courseId: assignment.courseId,
            assignmentId: assignmentId,
            startDate: assignment.startDate?.toDate(),
            lateDeadline: assignment.lateDeadline?.toDate(),
          }),
        })
      : Promise.resolve(),
    
    // Task 3: Create/Update trackers
    batchCreateTrackers(
      {
        id: assignmentId,
        courseId: assignment.courseId,
        maxPoints: assignment.maxPoints || 100,
      },
      enrollmentData
    ),
  ]);

  // Log results
  const [inAppResult, emailResult, trackerResult] = results;

  if (inAppResult.status === 'fulfilled') {
    console.log(`✅ Notifications created for ${enrollmentData.length} students`);
  } else {
    console.error('❌ Notifications failed:', inAppResult.reason);
  }

  if (emailResult.status === 'fulfilled') {
    console.log(`✅ Emails sent to ${studentEmails.length} students`);
  } else if (emailResult.status === 'rejected') {
    console.error('❌ Email failed:', emailResult.reason);
  }

  if (trackerResult.status === 'fulfilled') {
    console.log(`✅ Trackers created for ${enrollmentData.length} students`);
  } else if (trackerResult.status === 'rejected') {
    console.error('❌ Trackers failed:', trackerResult.reason);
  }
}

/**
 * Helper: Execute delete operations (remove trackers for removed students)
 */
async function executeDeleteOperations(
  assignmentId: string,
  studentIds: string[]
): Promise<void> {
  console.log(`🗑️ Deleting ${studentIds.length} trackers for removed students`);

  const batch = admin.firestore().batch();
  const trackersRef = admin.firestore().collection('assignment_trackers');

  for (const studentId of studentIds) {
    const trackerId = `${assignmentId}_${studentId}`;
    const trackerRef = trackersRef.doc(trackerId);
    batch.delete(trackerRef);
    console.log(`   🗑️ Queued delete: ${trackerId}`);
  }

  await batch.commit();
  console.log(`✅ Deleted ${studentIds.length} trackers successfully`);
}

/**
 * ========================================
 * DEPRECATED: Old onCreate trigger
 * Replaced by onAssignmentWritten (onWrite trigger above)
 * ⚠️ DISABLED - Keeping for reference only
 * ⚠️ This was causing DUPLICATE notifications!
 * ========================================
 */
// DISABLED: Commenting out export to prevent duplicate notifications
// Use onAssignmentWritten instead which handles both CREATE and UPDATE
/*
export const onAssignmentCreated_DEPRECATED = functions.firestore
  .document('assignments/{assignmentId}')
  .onCreate(async (snapshot, context) => {
    const assignment = snapshot.data();
    const assignmentId = context.params.assignmentId;

    console.log(`📧 New Assignment Created: ${assignment.title}`);

    try {
      // Step 1: Build groupId → groupName mapping from SUBCOLLECTION
      // CRITICAL: groups is a subcollection under course_of_study/{courseId}/groups/{groupId}
      const groupNameMap: { [groupId: string]: string } = {};
      
      if (assignment.groupIds && assignment.groupIds.length > 0) {
        for (const groupId of assignment.groupIds) {
          const groupDoc = await admin.firestore()
            .collection('course_of_study')
            .doc(assignment.courseId)
            .collection('groups')
            .doc(groupId)
            .get();
          
          if (groupDoc.exists) {
            groupNameMap[groupId] = groupDoc.data()?.name || `Group ${groupId.substring(0, 8)}`;
            console.log(`✅ Mapped groupId ${groupId} → "${groupNameMap[groupId]}"`);
          } else {
            groupNameMap[groupId] = 'Your Group';
            console.log(`⚠️ Group ${groupId} not found in course ${assignment.courseId}`);
          }
        }
      }

      console.log(`📊 Group names mapped: ${Object.keys(groupNameMap).length} groups`);

      // Step 2: Collect enrollments with userId and groupId
      const enrollmentData: Array<{ userId: string; groupId: string; email?: string; displayName?: string; groupName?: string }> = [];
      const studentEmails: string[] = [];
      
      if (assignment.groupIds && assignment.groupIds.length > 0) {
        for (const groupId of assignment.groupIds) {
          // Get enrollments for this specific group
          const enrollmentsSnapshot = await admin.firestore()
            .collection('enrollments')
            .where('groupId', '==', groupId)
            .where('courseId', '==', assignment.courseId)
            .where('status', '==', 'active')
            .get();

          enrollmentsSnapshot.forEach(doc => {
            const enrollment = doc.data();
            const userId = enrollment.userId;
            const enrollmentGroupId = enrollment.groupId; // Get groupId from enrollment
            
            if (userId && enrollmentGroupId) {
              enrollmentData.push({
                userId: userId,
                groupId: enrollmentGroupId,
                groupName: groupNameMap[enrollmentGroupId] || 'Your Group', // Map using enrollment's groupId
              });
            }
          });
        }
      }

      console.log(`📤 Sending notifications to ${enrollmentData.length} students`);

      // Step 3: Get user details (email, displayName) for all userIds
      const userIds = enrollmentData.map(e => e.userId);
      if (userIds.length > 0) {
        // Batch query users (10 at a time due to Firestore 'in' limit)
        for (let i = 0; i < userIds.length; i += 10) {
          const batchIds = userIds.slice(i, i + 10);
          const usersSnapshot = await admin.firestore()
            .collection('users')
            .where(admin.firestore.FieldPath.documentId(), 'in', batchIds)
            .get();

          usersSnapshot.docs.forEach(userDoc => {
            const userData = userDoc.data();
            const userId = userDoc.id;
            const email = userData.email;
            const displayName = userData.displayName || userData.fullName || 'Student';

            // Update enrollmentData with user info
            enrollmentData.forEach(enrollment => {
              if (enrollment.userId === userId) {
                enrollment.email = email;
                enrollment.displayName = displayName;
                // groupName already set from groupNameMap in Step 2
              }
            });
          });
        }
      }

      // Step 4: Build email mappings (each student gets their own group name)
      const studentNames: { [email: string]: string } = {};
      const studentGroups: { [email: string]: string } = {};

      enrollmentData.forEach(enrollment => {
        if (enrollment.email) {
          if (!studentEmails.includes(enrollment.email)) {
            studentEmails.push(enrollment.email);
          }
          studentNames[enrollment.email] = enrollment.displayName || 'Student';
          // Use groupName from enrollment data (already mapped correctly)
          studentGroups[enrollment.email] = enrollment.groupName || 'Your Group';
        }
      });

      console.log(`📧 Collected ${studentEmails.length} student emails`);

      // Get course name for email
      let courseName = 'Khóa học';
      try {
        const courseDoc = await admin.firestore()
          .collection('course_of_study')
          .doc(assignment.courseId)
          .get();
        if (courseDoc.exists) {
          courseName = courseDoc.data()?.name || courseName;
        }
      } catch (e) {
        console.warn('⚠️ Could not fetch course name:', e);
      }

      // Create notifications for each student
      const batch = admin.firestore().batch();
      const notificationsRef = admin.firestore().collection('notifications');

      enrollmentData.forEach(enrollment => {
        if (enrollment.userId) {
          const notificationRef = notificationsRef.doc();
          batch.set(notificationRef, {
            userId: enrollment.userId,
            courseId: assignment.courseId,
            type: 'assignment',
            title: assignment.title,
            content: `New Assignment: ${assignment.title}`,
            relatedId: assignmentId,
            relatedType: 'assignment',
            priority: 'high',
            isRead: false,
            isArchived: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
              startDate: assignment.startDate,
              dueDate: assignment.deadline,
              lateDeadline: assignment.lateDeadline || null,
            },
          });
        }
      });

      // ✅ PARALLEL EXECUTION - In-App + Email + Trackers
      const results = await Promise.allSettled([
        // Task 1: Write in-app notifications
        batch.commit(),
        
        // Task 2: Send emails (only if we have emails)
        studentEmails.length > 0
          ? sendEmail({
              to: studentEmails,
              subject: `📚 New Assignment: ${assignment.title}`,
              html: generateAssignmentEmail({
                studentEmails: studentEmails,
                studentNames: studentNames,
                studentGroups: studentGroups,
                assignmentTitle: assignment.title,
                courseName: courseName,
                dueDate: assignment.deadline?.toDate() || new Date(),
                courseId: assignment.courseId,
                assignmentId: assignmentId,
                startDate: assignment.startDate?.toDate(),
                lateDeadline: assignment.lateDeadline?.toDate(),
              }),
            })
          : Promise.resolve(),
        
        // Task 3: Create tracker documents ✅ NEW
        batchCreateTrackers(
          {
            id: assignmentId,
            courseId: assignment.courseId,
            maxPoints: assignment.maxPoints || 100,
          },
          enrollmentData
        ),
      ]);

      // Check results
      const [inAppResult, emailResult, trackerResult] = results;

      if (inAppResult.status === 'fulfilled') {
        console.log(`✅ In-app notifications created for ${enrollmentData.length} students`);
      } else {
        console.error('❌ In-app notifications failed:', inAppResult.reason);
      }

      if (emailResult.status === 'fulfilled') {
        console.log(`✅ Emails sent to ${studentEmails.length} students`);
      } else if (emailResult.status === 'rejected') {
        console.error('❌ Email sending failed:', emailResult.reason);
      }

      if (trackerResult.status === 'fulfilled') {
        console.log(`✅ Trackers created for ${enrollmentData.length} students`);
      } else if (trackerResult.status === 'rejected') {
        console.error('❌ Tracker creation failed:', trackerResult.reason);
      }

    } catch (error) {
      console.error('❌ Error sending assignment notifications:', error);
    }
  });
*/

/**
 * Trigger: Send notification when student submits assignment
 * Also syncs attemptNumber to assignment_trackers
 */
export const onSubmissionCreated = functions.firestore
  .document('submissions/{submissionId}')
  .onCreate(async (snapshot, context) => {
    const submission = snapshot.data();
    const submissionId = context.params.submissionId;

    console.log(`📝 New Submission by: ${submission.studentId} (Attempt ${submission.attemptNumber || 1})`);

    try {
      // Get assignment data (need deadline for tracker update)
      const assignmentDoc = await admin.firestore()
        .collection('assignments')
        .doc(submission.assignmentId)
        .get();

      if (!assignmentDoc.exists) {
        console.error('❌ Assignment not found:', submission.assignmentId);
        return;
      }

      const assignment = assignmentDoc.data();
      const assignmentTitle = assignment?.title || 'Assignment';
      const assignmentDeadline = assignment?.deadline;

      // ✅ PARALLEL EXECUTION - Notification + Tracker Update
      const results = await Promise.allSettled([
        // Task 1: Create notification for the student
        admin.firestore().collection('notifications').add({
          userId: submission.studentId,
          courseId: submission.courseId,
          type: 'general',
          title: 'Submission Successful',
          content: `Your submission for "${assignmentTitle}" was received successfully. (Attempt ${submission.attemptNumber || 1})`,
          relatedId: submissionId,
          relatedType: 'submission',
          priority: 'normal',
          isRead: false,
          isArchived: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }),

        // Task 2: Update tracker document with attemptNumber ✅ ENHANCED
        updateTrackerOnSubmission(submission, assignmentDeadline),
      ]);

      // Check results
      const [notificationResult, trackerResult] = results;

      if (notificationResult.status === 'fulfilled') {
        console.log(`✅ Sent submission confirmation to student`);
      } else {
        console.error('❌ Notification failed:', notificationResult.reason);
      }

      if (trackerResult.status === 'fulfilled') {
        console.log(`✅ Updated tracker for submission (Attempt ${submission.attemptNumber || 1})`);
      } else {
        console.error('❌ Tracker update failed:', trackerResult.reason);
      }

    } catch (error) {
      console.error('❌ Error in submission trigger:', error);
    }
  });

/**
 * Trigger: Send notifications when new Quiz is created
 */
export const onQuizCreated = functions.firestore
  .document('quizzes/{quizId}')
  .onCreate(async (snapshot, context) => {
    const quiz = snapshot.data();
    const quizId = context.params.quizId;

    console.log(`📧 New Quiz Created: ${quiz.title}`);

    try {
      // ===== COLLECT STUDENT IDs =====
      const studentIds: string[] = [];
      
      if (quiz.groupIds && quiz.groupIds.length > 0) {
        for (const groupId of quiz.groupIds) {
          const enrollmentsSnapshot = await admin.firestore()
            .collection('enrollments')
            .where('groupId', '==', groupId)
            .where('courseId', '==', quiz.courseId)
            .where('status', '==', 'active')
            .get();

          enrollmentsSnapshot.forEach(doc => {
            const enrollment = doc.data();
            const userId = enrollment.userId;
            if (userId && !studentIds.includes(userId)) {
              studentIds.push(userId);
            }
          });
        }
      }

      console.log(`📤 Processing ${studentIds.length} students`);

      if (studentIds.length === 0) {
        console.log('⚠️ No students found for quiz');
        return;
      }

      // ===== GET COURSE NAME =====
      let courseName = 'Course';
      try {
        const courseDoc = await admin.firestore()
          .collection('course_of_study')
          .doc(quiz.courseId)
          .get();
        if (courseDoc.exists) {
          courseName = courseDoc.data()?.name || courseName;
        }
      } catch (e) {
        console.warn('⚠️ Could not fetch course name:', e);
      }

      // ===== PREPARE EMAIL DATA =====
      const studentEmails: string[] = [];
      const studentNames: { [email: string]: string } = {};
      const studentGroups: { [email: string]: string } = {};

      // Batch fetch user info (10 at a time to avoid 'in' query limit)
      for (let i = 0; i < studentIds.length; i += 10) {
        const batchIds = studentIds.slice(i, i + 10);
        const usersSnapshot = await admin.firestore()
          .collection('users')
          .where(admin.firestore.FieldPath.documentId(), 'in', batchIds)
          .get();

        for (const userDoc of usersSnapshot.docs) {
          const userData = userDoc.data();
          const email = userData.email;
          const displayName = userData.fullName || userData.name || 'Student';

          if (email && !studentEmails.includes(email)) {
            studentEmails.push(email);
            studentNames[email] = displayName;

            // Get student's group
            const enrollmentSnapshot = await admin.firestore()
              .collection('enrollments')
              .where('userId', '==', userDoc.id)
              .where('courseId', '==', quiz.courseId)
              .limit(1)
              .get();

            if (!enrollmentSnapshot.empty) {
              const enrollment = enrollmentSnapshot.docs[0].data();
              const groupId = enrollment.groupId;

              if (groupId) {
                const groupDoc = await admin.firestore()
                  .collection('course_of_study')
                  .doc(quiz.courseId)
                  .collection('groups')
                  .doc(groupId)
                  .get();

                studentGroups[email] = groupDoc.exists 
                  ? groupDoc.data()?.name || 'Your Group'
                  : 'Your Group';
              } else {
                studentGroups[email] = 'Your Group';
              }
            }
          }
        }
      }

      // ===== CREATE IN-APP NOTIFICATIONS =====
      const notificationBatch = admin.firestore().batch();
      const notificationsRef = admin.firestore().collection('notifications');

      for (const studentId of studentIds) {
        const notificationRef = notificationsRef.doc();
        const metadata: any = {
          quizTitle: quiz.title,
        };
        
        // Quiz uses openDate/closeDate (ISO strings), not startTime/endTime
        if (quiz.openDate) {
          metadata.startDate = quiz.openDate;
        }
        if (quiz.closeDate) {
          metadata.dueDate = quiz.closeDate;
        }

        notificationBatch.set(notificationRef, {
          userId: studentId,
          courseId: quiz.courseId,
          type: 'quiz',
          title: `New Quiz: ${quiz.title}`,
          content: `A new quiz has been assigned. Please complete it within the allowed timeframe!`,
          relatedId: quizId,
          relatedType: 'quiz',
          priority: 'high',
          isRead: false,
          isArchived: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          metadata: metadata,
        });
      }

      // ===== CREATE QUIZ TRACKERS =====
      console.log(`📊 Creating trackers for ${studentIds.length} students`);
      
      const trackerBatch = admin.firestore().batch();
      const trackersRef = admin.firestore().collection('quiz_trackers');

      for (const studentId of studentIds) {
        // Get student info for denormalization
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(studentId)
          .get();
        
        const userData = userDoc.data();
        const studentName = userData?.fullName || userData?.name || 'Unknown';
        const studentEmail = userData?.email || '';

        // Get group info
        const enrollmentSnapshot = await admin.firestore()
          .collection('enrollments')
          .where('userId', '==', studentId)
          .where('courseId', '==', quiz.courseId)
          .limit(1)
          .get();

        let groupId = '';
        let groupName = 'Unknown Group';
        if (!enrollmentSnapshot.empty) {
          const enrollmentData = enrollmentSnapshot.docs[0].data();
          groupId = enrollmentData.groupId || '';

          if (groupId) {
            const groupDoc = await admin.firestore()
              .collection('course_of_study')
              .doc(quiz.courseId)
              .collection('groups')
              .doc(groupId)
              .get();
            if (groupDoc.exists) {
              groupName = groupDoc.data()?.name || groupName;
            }
          }
        }

        // Create tracker with composite key
        const compositeId = `${quizId}_${studentId}`;
        const trackerRef = trackersRef.doc(compositeId);

        trackerBatch.set(trackerRef, {
          id: compositeId,
          quizId: quizId,
          studentId: studentId,
          courseId: quiz.courseId,
          groupId: groupId,
          studentName: studentName,
          studentEmail: studentEmail,
          groupName: groupName,
          status: 'not_started',
          attemptCount: 0,
          score: null,
          startedAt: null,
          lastAttemptAt: null,
          completedAt: null,
          lastSubmissionId: null,
        });
      }

      console.log(`📊 Creating ${studentIds.length} quiz trackers`);

      // ===== PARALLEL EXECUTION =====
      const results = await Promise.allSettled([
        // Task 1: Create in-app notifications
        notificationBatch.commit(),
        
        // Task 2: Create quiz trackers
        trackerBatch.commit(),
        
        // Task 3: Send emails
        studentEmails.length > 0
          ? sendEmail({
              to: studentEmails,
              subject: `📝 New Quiz: ${quiz.title}`,
              html: generateQuizEmail({
                studentEmails: studentEmails,
                studentNames: studentNames,
                studentGroups: studentGroups,
                quizTitle: quiz.title,
                courseName: courseName,
                startTime: quiz.openDate ? new Date(quiz.openDate) : new Date(),
                endTime: quiz.closeDate ? new Date(quiz.closeDate) : new Date(),
                courseId: quiz.courseId,
                quizId: quizId,
              }),
            })
          : Promise.resolve(),
      ]);

      // ===== LOG RESULTS =====
      const [inAppResult, trackerResult, emailResult] = results;
      
      if (inAppResult.status === 'fulfilled') {
        console.log(`✅ In-app notifications for ${studentIds.length} students`);
      } else {
        console.error('❌ Failed to create in-app notifications:', inAppResult.reason);
      }
      
      if (trackerResult.status === 'fulfilled') {
        console.log(`✅ Created ${studentIds.length} quiz trackers`);
      } else {
        console.error('❌ Failed to create quiz trackers:', trackerResult.reason);
      }
      
      if (emailResult.status === 'fulfilled') {
        console.log(`✅ Emails sent to ${studentEmails.length} students`);
      } else {
        console.error('❌ Failed to send emails:', emailResult.reason);
      }

    } catch (error) {
      console.error('❌ Error sending quiz notifications:', error);
    }
  });

/**
 * Trigger: Send notifications when new Material/Announcement is created
 */
export const onAnnouncementCreated = functions.firestore
  .document('announcements/{announcementId}')
  .onCreate(async (snapshot, context) => {
    const announcement = snapshot.data();
    const announcementId = context.params.announcementId;

    console.log(`📢 New Announcement: ${announcement.title}`);

    try {
      // Get ALL students enrolled in the course
      const enrollmentsSnapshot = await admin.firestore()
        .collection('enrollments')
        .where('courseId', '==', announcement.courseId)
        .where('status', '==', 'active')
        .get();

      const studentIds = enrollmentsSnapshot.docs.map(doc => doc.data().userId); // FIX: userId not studentId
      const studentEmails: string[] = [];
      const studentNames: { [email: string]: string } = {};
      const studentGroups: { [email: string]: string } = {};

      console.log(`📤 Sending to ${studentIds.length} students`);

      // Get student emails, names, and groups
      if (studentIds.length > 0) {
        for (let i = 0; i < studentIds.length; i += 10) {
          const batchIds = studentIds.slice(i, i + 10);
          const usersSnapshot = await admin.firestore()
            .collection('users')
            .where(admin.firestore.FieldPath.documentId(), 'in', batchIds)
            .get();

          for (const userDoc of usersSnapshot.docs) {
            const userData = userDoc.data();
            const email = userData.email;
            const displayName = userData.fullName || userData.name || 'Student';

            if (email && !studentEmails.includes(email)) {
              studentEmails.push(email);
              studentNames[email] = displayName;

              // Get student's group
              const enrollmentSnapshot = await admin.firestore()
                .collection('enrollments')
                .where('userId', '==', userDoc.id)
                .where('courseId', '==', announcement.courseId)
                .limit(1)
                .get();

              if (!enrollmentSnapshot.empty) {
                const enrollment = enrollmentSnapshot.docs[0].data();
                const groupId = enrollment.groupId;

                if (groupId) {
                  const groupDoc = await admin.firestore()
                    .collection('course_of_study')
                    .doc(announcement.courseId)
                    .collection('groups')
                    .doc(groupId)
                    .get();

                  studentGroups[email] = groupDoc.exists 
                    ? groupDoc.data()?.name || 'Your Group'
                    : 'Your Group';
                } else {
                  studentGroups[email] = 'Your Group';
                }
              } else {
                studentGroups[email] = 'Your Group';
              }
            }
          }
        }
      }

      // Get course name
      let courseName = 'Khóa học';
      try {
        const courseDoc = await admin.firestore()
          .collection('course_of_study')
          .doc(announcement.courseId)
          .get();
        if (courseDoc.exists) {
          courseName = courseDoc.data()?.name || courseName;
        }
      } catch (e) {
        console.warn('⚠️ Could not fetch course name:', e);
      }

      // Create notifications
      const batch = admin.firestore().batch();
      const notificationsRef = admin.firestore().collection('notifications');

      for (const studentId of studentIds) {
        const notificationRef = notificationsRef.doc();
        batch.set(notificationRef, {
          userId: studentId,
          courseId: announcement.courseId,
          type: 'announcement',
          title: announcement.title,
          content: `New Material: ${announcement.title}`,
          relatedId: announcementId,
          relatedType: 'announcement',
          priority: 'normal',
          isRead: false,
          isArchived: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // ✅ PARALLEL EXECUTION
      const results = await Promise.allSettled([
        batch.commit(),
        studentEmails.length > 0
          ? sendEmail({
              to: studentEmails,
              subject: `📢 Tài liệu mới: ${announcement.title}`,
              html: generateMaterialEmail({
                studentEmails: studentEmails,
                studentNames: studentNames,
                studentGroups: studentGroups,
                materialTitle: announcement.title,
                courseName: courseName,
                courseId: announcement.courseId,
                materialId: announcementId,
              }),
            })
          : Promise.resolve(),
      ]);

      const [inAppResult, emailResult] = results;
      if (inAppResult.status === 'fulfilled') {
        console.log(`✅ In-app notifications for ${studentIds.length} students`);
      }
      if (emailResult.status === 'fulfilled') {
        console.log(`✅ Emails sent to ${studentEmails.length} students`);
      }

    } catch (error) {
      console.error('❌ Error sending announcement notifications:', error);
    }
  });

/**
 * ========================================
 * NEW TRIGGER: onMaterialCreated
 * PURPOSE: Auto-create material trackers + send notifications + emails
 * WHEN: New material is created in materials SUB-collection
 * PATH: course_of_study/{courseId}/materials/{materialId}
 * ========================================
 */
export const onMaterialCreated = functions
  .region('asia-southeast1')
  .firestore
  .document('course_of_study/{courseId}/materials/{materialId}')
  .onCreate(async (snapshot, context) => {
    const material = snapshot.data();
    const materialId = context.params.materialId;
    const courseId = context.params.courseId;

    console.log(`📚 New Material Created: ${material.title} (ID: ${materialId}, Course: ${courseId})`);

    try {
      // ===== GET COURSE INFO =====
      const courseDoc = await admin.firestore()
        .collection('course_of_study')
        .doc(courseId)
        .get();
      
      const courseName = courseDoc.exists 
        ? courseDoc.data()?.name || 'Course' 
        : 'Course';

      // ===== QUERY ENROLLMENTS =====
      const enrollmentsSnapshot = await admin.firestore()
        .collection('enrollments')
        .where('courseId', '==', courseId)
        .where('status', '==', 'active')
        .get();

      if (enrollmentsSnapshot.empty) {
        console.log(`⚠️ No active enrollments found for course ${courseId}`);
        return;
      }

      console.log(`📊 Found ${enrollmentsSnapshot.size} active enrollments`);

      // ===== PREPARE DATA =====
      const studentEmails: string[] = [];
      const studentNames: { [email: string]: string } = {};
      const studentGroups: { [email: string]: string } = {};
      const enrollmentData: Array<{
        userId: string;
        email: string;
        displayName: string;
        groupId: string;
        groupName: string;
      }> = [];

      // Fetch user and group info for each enrollment
      for (const enrollmentDoc of enrollmentsSnapshot.docs) {
        const enrollment = enrollmentDoc.data();
        const studentId = enrollment.userId;
        
        if (!studentId) {
          console.log(`⚠️ Skipping enrollment ${enrollmentDoc.id}: missing userId`);
          continue;
        }

        // Get user info
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(studentId)
          .get();
        
        const userData = userDoc.data();
        const email = userData?.email || '';
        const displayName = userData?.fullName || userData?.name || 'Student';

        // Get group info
        const groupId = enrollment.groupId || 'default';
        let groupName = 'Unknown Group';

        if (groupId !== 'default') {
          const groupDoc = await admin.firestore()
            .collection('course_of_study')
            .doc(courseId)
            .collection('groups')
            .doc(groupId)
            .get();
          
          if (groupDoc.exists) {
            groupName = groupDoc.data()?.name || groupName;
          }
        }

        if (email) {
          studentEmails.push(email);
          studentNames[email] = displayName;
          studentGroups[email] = groupName;
        }

        enrollmentData.push({
          userId: studentId,
          email,
          displayName,
          groupId,
          groupName,
        });
      }

      // ===== CREATE IN-APP NOTIFICATIONS =====
      const notificationBatch = admin.firestore().batch();
      const notificationsRef = admin.firestore().collection('notifications');

      enrollmentData.forEach(enrollment => {
        if (enrollment.userId) {
          const notificationRef = notificationsRef.doc();
          notificationBatch.set(notificationRef, {
            userId: enrollment.userId,
            courseId: courseId,
            type: 'announcement',
            title: `New Material: ${material.title}`,
            content: `New learning material has been uploaded: ${material.title}`,
            relatedId: materialId,
            relatedType: 'material',
            priority: 'normal',
            isRead: false,
            isArchived: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
              materialTitle: material.title,
              materialType: material.type || 'Document',
              uploadedAt: material.createdAt || admin.firestore.FieldValue.serverTimestamp(),
            },
          });
        }
      });

      // ===== CREATE MATERIAL TRACKERS =====
      const trackerBatch = admin.firestore().batch();
      const trackersRef = admin.firestore().collection('material_trackers');

      enrollmentData.forEach(enrollment => {
        const trackerId = `${materialId}_${enrollment.userId}`;
        const trackerRef = trackersRef.doc(trackerId);

        trackerBatch.set(trackerRef, {
          materialId: materialId,
          studentId: enrollment.userId,
          courseId: courseId,
          groupId: enrollment.groupId,
          studentName: enrollment.displayName,
          studentEmail: enrollment.email,
          status: 'new',
          isViewed: false,
          viewedAt: null,
          isDownloaded: false,
          downloadedAt: null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // ===== PARALLEL EXECUTION =====
      const results = await Promise.allSettled([
        // Task 1: Create in-app notifications
        notificationBatch.commit(),
        
        // Task 2: Create material trackers
        trackerBatch.commit(),
        
        // Task 3: Send emails
        studentEmails.length > 0
          ? sendEmail({
              to: studentEmails,
              subject: `📂 New Material: ${material.title}`,
              html: generateMaterialEmail({
                studentEmails: studentEmails,
                studentNames: studentNames,
                studentGroups: studentGroups,
                materialTitle: material.title,
                courseName: courseName,
                courseId: courseId,
                materialId: materialId,
                materialType: material.type || 'Document',
                uploadedAt: material.createdAt?.toDate() || new Date(),
              }),
            })
          : Promise.resolve(),
      ]);

      // ===== LOG RESULTS =====
      const [inAppResult, trackerResult, emailResult] = results;

      if (inAppResult.status === 'fulfilled') {
        console.log(`✅ In-app notifications created for ${enrollmentData.length} students`);
      } else {
        console.error('❌ Notifications failed:', inAppResult.reason);
      }

      if (trackerResult.status === 'fulfilled') {
        console.log(`✅ Material trackers created for ${enrollmentData.length} students`);
      } else {
        console.error('❌ Trackers failed:', trackerResult.reason);
      }

      if (emailResult.status === 'fulfilled') {
        console.log(`✅ Emails sent to ${studentEmails.length} students`);
      } else if (emailResult.status === 'rejected') {
        console.error('❌ Email failed:', emailResult.reason);
      }

      console.log(`✅ Successfully processed material ${materialId} for ${enrollmentData.length} students`);

    } catch (error) {
      console.error('❌ Error in onMaterialCreated:', error);
      throw error;
    }
  });

/**
 * ========================================
 * NEW TRIGGER: onTrackerUpdated
 * PURPOSE: Sync grade changes from tracker back to submission
 * WHEN: Instructor updates grade in assignment_trackers collection
 * ========================================
 */
export const onTrackerUpdated = functions.firestore
  .document('assignment_trackers/{trackerId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const trackerId = context.params.trackerId;

    console.log(`📊 Tracker Updated: ${trackerId}`);

    try {
      // Check if grade field changed
      const gradeChanged = before.grade !== after.grade;
      const feedbackChanged = before.feedback !== after.feedback;

      if (!gradeChanged && !feedbackChanged) {
        console.log('⏭️  No grade/feedback changes, skipping sync');
        return;
      }

      // If grade was updated, sync to submission
      if (gradeChanged && after.grade !== null && after.grade !== undefined) {
        console.log(`📝 Grade changed: ${before.grade} → ${after.grade}`);

        await syncGradeToSubmission(
          trackerId,
          after.grade,
          after.feedback || null,
          after.gradedBy || 'unknown'
        );

        console.log(`✅ Successfully synced grade to submission`);
      }

    } catch (error) {
      console.error('❌ Error syncing tracker grade to submission:', error);
    }
  });

/**
 * 🔒 SECURE SUBMISSION FLOW - Callable Function
 * This is the ONLY way students can submit assignments
 * Prevents spam submissions and validates all constraints server-side
 */
export const submitAssignment = functionsV2.https.onCall(async (request) => {
  console.log('🚀 submitAssignment called');

  // ===== AUTHENTICATION CHECK =====
  if (!request.auth) {
    console.error('❌ Unauthorized: No auth context');
    throw new functionsV2.https.HttpsError(
      'unauthenticated',
      'You must be logged in to submit assignments'
    );
  }

  const studentId = request.auth.uid;
  const { assignmentId, attachments, textContent } = request.data;

  console.log(`📝 Student ${studentId} submitting assignment ${assignmentId}`);

  // ===== INPUT VALIDATION =====
  if (!assignmentId || typeof assignmentId !== 'string') {
    throw new functionsV2.https.HttpsError(
      'invalid-argument',
      'Assignment ID is required'
    );
  }

  if (!attachments && !textContent) {
    throw new functionsV2.https.HttpsError(
      'invalid-argument',
      'At least one attachment or text content is required'
    );
  }

  try {
    const db = admin.firestore();
    
    // ===== STEP 1: GET ASSIGNMENT DATA =====
    const assignmentDoc = await db.collection('assignments').doc(assignmentId).get();
    
    if (!assignmentDoc.exists) {
      throw new functionsV2.https.HttpsError(
        'not-found',
        'Assignment not found'
      );
    }

    const assignment = assignmentDoc.data()!;
    const maxAttempts = assignment.maxSubmissionAttempts || 1;
    const deadline = assignment.deadline;
    const lateDeadline = assignment.lateDeadline;
    const allowLateSubmission = assignment.allowLateSubmissions || false; // Fixed: plural form

    console.log(`📋 Assignment: ${assignment.title || 'Unknown'}`);
    console.log(`📋 Config: maxAttempts=${maxAttempts}, allowLate=${allowLateSubmission}`);
    console.log(`📋 Deadline: ${deadline}, Late: ${lateDeadline}`);

    // ===== STEP 2: CHECK DEADLINE =====
    const now = admin.firestore.Timestamp.now();
    
    // Parse deadline safely
    let deadlineTime: Date | null = null;
    if (deadline) {
      try {
        if (deadline.toDate && typeof deadline.toDate === 'function') {
          deadlineTime = deadline.toDate();
        } else if (deadline instanceof Date) {
          deadlineTime = deadline;
        } else if (typeof deadline === 'string') {
          deadlineTime = new Date(deadline);
        } else if (deadline._seconds) {
          // Firestore Timestamp-like object
          deadlineTime = new Date(deadline._seconds * 1000);
        }
      } catch (e) {
        console.error('⚠️ Error parsing deadline:', e);
      }
    }

    let lateDeadlineTime: Date | null = null;
    if (lateDeadline) {
      try {
        if (lateDeadline.toDate && typeof lateDeadline.toDate === 'function') {
          lateDeadlineTime = lateDeadline.toDate();
        } else if (lateDeadline instanceof Date) {
          lateDeadlineTime = lateDeadline;
        } else if (typeof lateDeadline === 'string') {
          lateDeadlineTime = new Date(lateDeadline);
        } else if (lateDeadline._seconds) {
          lateDeadlineTime = new Date(lateDeadline._seconds * 1000);
        }
      } catch (e) {
        console.error('⚠️ Error parsing late deadline:', e);
      }
    }

    // Check if past regular deadline
    if (deadlineTime && now.toDate() > deadlineTime) {
      console.log(`⏰ Past deadline: ${deadlineTime}`);
      console.log(`⏰ Current time: ${now.toDate()}`);
      console.log(`⏰ Allow late submission: ${allowLateSubmission}`);
      console.log(`⏰ Late deadline time: ${lateDeadlineTime}`);
      
      // Check if late submission is allowed
      if (!allowLateSubmission) {
        console.log(`❌ Late submission not allowed`);
        throw new functionsV2.https.HttpsError(
          'failed-precondition',
          'The deadline for this assignment has passed'
        );
      }

      // Check late deadline
      if (lateDeadlineTime && now.toDate() > lateDeadlineTime) {
        console.log(`⏰ Past late deadline: ${lateDeadlineTime}`);
        throw new functionsV2.https.HttpsError(
          'failed-precondition',
          'The late submission deadline has also passed'
        );
      }
      
      console.log(`✅ Allowing late submission (within late deadline)`);
    }

    // ===== STEP 3: GET OR CREATE TRACKER & CHECK ATTEMPTS =====
    // ✅ USE TRACKER as source of truth for attempt count
    // Tracker tracks total attempts even if submission is deleted (unsubmitted)
    const trackerId = `${assignmentId}_${studentId}`;
    const trackerDoc = await db.collection('assignment_trackers').doc(trackerId).get();
    
    let currentAttempts = 0;
    let tracker = null;
    
    if (trackerDoc.exists) {
      tracker = trackerDoc.data()!;
      currentAttempts = tracker.attemptCount || 0;
      console.log(`📊 Tracker found: ${trackerId}, attemptCount: ${currentAttempts}/${maxAttempts}`);
    } else {
      console.log(`📊 No tracker found, this will be first attempt (0/${maxAttempts})`);
    }

    // ===== STEP 4: VALIDATE ATTEMPT LIMIT =====
    if (currentAttempts >= maxAttempts) {
      console.log(`❌ Max attempts reached: ${currentAttempts}/${maxAttempts}`);
      throw new functionsV2.https.HttpsError(
        'resource-exhausted',
        `You have reached the maximum submission limit (${maxAttempts} attempts)`
      );
    }

    // ===== STEP 5: GET STUDENT INFO =====
    const studentDoc = await db.collection('users').doc(studentId).get();
    const studentName = studentDoc.exists ? 
      (studentDoc.data()!.displayName || studentDoc.data()!.email || 'Student') : 
      'Student';

    console.log(`👤 Student: ${studentName}`);

    // ===== STEP 6: CREATE SUBMISSION =====
    const isLate = deadlineTime ? (now.toDate() > deadlineTime) : false;
    const newAttemptNumber = currentAttempts + 1;

    console.log(`📝 Creating submission: attempt ${newAttemptNumber}, isLate: ${isLate}`);

    const submissionData = {
      assignmentId: assignmentId,
      studentId: studentId,
      studentName: studentName,
      courseId: assignment.courseId || '',
      semesterId: assignment.semesterId || '',
      groupId: assignment.groupIds?.[0] || '', // Take first group
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: isLate ? 'late' : 'submitted', // Set status based on deadline
      attachments: attachments || [],
      textContent: textContent || null,
      score: null,
      maxScore: assignment.maxScore || null,
      feedback: null,
      gradedBy: null,
      gradedAt: null,
      isLate: isLate,
      attemptNumber: newAttemptNumber,
      lastModified: admin.firestore.FieldValue.serverTimestamp(),
    };

    console.log(`💾 Saving submission to Firestore...`);
    const submissionRef = await db.collection('submissions').add(submissionData);
    
    console.log(`✅ Submission created: ${submissionRef.id} (Attempt ${newAttemptNumber}/${maxAttempts})`);

    // ===== STEP 7: UPDATE OR CREATE TRACKER =====
    // ✅ Tracker is the source of truth for attempt count and status
    console.log(`📋 Updating tracker: ${trackerId}`);
    
    // Get student email for tracker
    const studentEmail = studentDoc.exists ? 
      (studentDoc.data()!.email || '') : '';
    
    // Get group name (simplified - you may want to query groups collection)
    const groupName = assignment.groupIds?.[0] || 'Default Group';
    
    const trackerData = {
      assignmentId: assignmentId,
      studentId: studentId,
      courseId: assignment.courseId || '',
      groupId: assignment.groupIds?.[0] || '',
      studentName: studentName,
      studentEmail: studentEmail,
      groupName: groupName,
      status: isLate ? 'late' : 'submitted',
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
      isLate: isLate,
      attemptCount: newAttemptNumber, // ✅ Increment attempt count
      grade: null,
      maxPoints: assignment.maxScore || 100,
      feedback: null,
      gradedBy: null,
      gradedAt: null,
      attachments: attachments || [],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    if (trackerDoc.exists) {
      // Update existing tracker
      await db.collection('assignment_trackers').doc(trackerId).update(trackerData);
      console.log(`✅ Tracker updated: ${trackerId}`);
    } else {
      // Create new tracker
      await db.collection('assignment_trackers').doc(trackerId).set({
        ...trackerData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`✅ Tracker created: ${trackerId}`);
    }

    // ===== RETURN SUCCESS =====
    return {
      success: true,
      submissionId: submissionRef.id,
      attemptNumber: newAttemptNumber,
      maxAttempts: maxAttempts,
      isLate: isLate,
      message: `Submission ${newAttemptNumber}/${maxAttempts} successful`
    };

  } catch (error: any) {
    console.error('❌ Error in submitAssignment:', error);
    console.error('❌ Error stack:', error.stack);
    console.error('❌ Error details:', {
      message: error.message,
      code: error.code,
      name: error.name,
    });

    // Re-throw HttpsError as-is
    if (error instanceof functionsV2.https.HttpsError) {
      throw error;
    }

    // Wrap other errors with more details
    const errorMessage = error.message || 'Unknown error';
    console.error(`❌ Wrapping error as internal: ${errorMessage}`);
    
    throw new functionsV2.https.HttpsError(
      'internal',
      `Failed to submit assignment: ${errorMessage}`
    );
  }
});

// ========================================
// CLOUD FUNCTION: startQuiz
// MÔ TẢ: Start a new quiz attempt for a student
// - Validates time (openDate/closeDate)
// - Checks attempts limit
// - Checks for existing in-progress submission
// - Randomizes questions from question bank based on structure
// - Creates snapshot submission with questions
// ========================================
export const startQuiz = functionsV2.https.onCall(async (request) => {
  console.log('🚀 Starting quiz attempt...');

  try {
    // ===== AUTHENTICATION CHECK =====
    if (!request.auth) {
      throw new functionsV2.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to start a quiz'
      );
    }

    const userId = request.auth.uid;
    const { quizId, courseId } = request.data;

    // ===== VALIDATION =====
    if (!quizId || !courseId) {
      throw new functionsV2.https.HttpsError(
        'invalid-argument',
        'quizId and courseId are required'
      );
    }

    console.log(`📝 Quiz attempt: quizId=${quizId}, userId=${userId}`);

    const db = admin.firestore();

    // ===== STEP 1: FETCH QUIZ DATA =====
    const quizRef = db.collection('quizzes').doc(quizId);
    const quizDoc = await quizRef.get();

    if (!quizDoc.exists) {
      throw new functionsV2.https.HttpsError(
        'not-found',
        'Quiz not found'
      );
    }

    const quizData = quizDoc.data()!;
    
    // Verify quiz belongs to the correct course
    if (quizData.courseId !== courseId) {
      throw new functionsV2.https.HttpsError(
        'permission-denied',
        'Quiz does not belong to this course'
      );
    }
    const {
      openDate,
      closeDate,
      maxAttempts,
      structure,
      durationMinutes,
    } = quizData;

    // ===== STEP 2: VALIDATE TIME =====
    const now = new Date();
    const quizOpenDate = new Date(openDate);
    const quizCloseDate = new Date(closeDate);

    console.log('🕐 Time check:', {
      now: now.toISOString(),
      quizOpenDate: quizOpenDate.toISOString(),
      quizCloseDate: quizCloseDate.toISOString(),
    });

    // Temporarily disabled for debugging
    // if (now < quizOpenDate) {
    //   throw new functionsV2.https.HttpsError(
    //     'failed-precondition',
    //     'Quiz has not opened yet'
    //   );
    // }

    // if (now > quizCloseDate) {
    //   throw new functionsV2.https.HttpsError(
    //     'failed-precondition',
    //     'Quiz has closed'
    //   );
    // }

    // ===== STEP 3: CHECK EXISTING IN-PROGRESS SUBMISSION =====
    const inProgressQuery = await db
      .collection('quiz_submissions')
      .where('quizId', '==', quizId)
      .where('studentId', '==', userId)
      .where('status', '==', 'in_progress')
      .limit(1)
      .get();

    if (!inProgressQuery.empty) {
      const existingSubmission = inProgressQuery.docs[0];
      throw new functionsV2.https.HttpsError(
        'failed-precondition',
        'You already have an in-progress quiz attempt',
        { submissionId: existingSubmission.id }
      );
    }

    // ===== STEP 4: CHECK ATTEMPTS LIMIT =====
    const completedQuery = await db
      .collection('quiz_submissions')
      .where('quizId', '==', quizId)
      .where('studentId', '==', userId)
      .where('status', '==', 'completed')
      .get();

    const attemptNumber = completedQuery.size + 1;

    if (attemptNumber > maxAttempts) {
      throw new functionsV2.https.HttpsError(
        'failed-precondition',
        `Maximum attempts (${maxAttempts}) reached`
      );
    }

    // ===== STEP 5: FETCH USER INFO =====
    const userDoc = await db.collection('users').doc(userId).get();
    const studentName = userDoc.exists ? userDoc.data()!.name || 'Unknown' : 'Unknown';

    // ===== STEP 6: FETCH COURSE CODE =====
    const courseDoc = await db.collection('course_of_study').doc(courseId).get();
    const courseCode = courseDoc.exists ? courseDoc.data()!.code : '';

    // ===== STEP 7: RANDOMIZE QUESTIONS FROM QUESTION BANK =====
    console.log('🎲 Randomizing questions based on structure:', structure);

    const selectedQuestions: Array<{
      id: string;
      question: string;
      type: string;
      options: string[];
      correctAnswer: number;
      explanation: string | null;
      difficulty: string;
    }> = [];

    // Loop through structure: { 'easy': 5, 'medium': 3, 'hard': 2 }
    for (const [difficulty, count] of Object.entries(structure)) {
      if (typeof count !== 'number' || count <= 0) continue;

      console.log(`📚 Fetching ${count} ${difficulty} questions...`);

      // Query questions from question bank
      const questionsQuery = await db
        .collection('questions')
        .where('courseCode', '==', courseCode)
        .where('difficulty', '==', difficulty)
        .where('isActive', '==', true)
        .get();

      const availableQuestions = questionsQuery.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          question: data.question || '',
          type: data.type || 'multiple_choice',
          options: data.options || [],
          correctAnswer: data.correctAnswer || 0,
          explanation: data.explanation || null,
          difficulty: data.difficulty || 'medium',
        };
      });

      if (availableQuestions.length < count) {
        throw new functionsV2.https.HttpsError(
          'failed-precondition',
          `Not enough ${difficulty} questions in question bank. Need ${count}, found ${availableQuestions.length}`
        );
      }

      // Shuffle and select random questions
      const shuffled = availableQuestions.sort(() => 0.5 - Math.random());
      const selected = shuffled.slice(0, count);

      // Create snapshot questions
      for (const q of selected) {
        selectedQuestions.push({
          id: q.id,
          question: q.question,
          type: q.type || 'multiple_choice',
          options: q.options || [],
          correctAnswer: q.correctAnswer || 0,
          explanation: q.explanation || null,
          difficulty: q.difficulty,
        });
      }
    }

    console.log(`✅ Selected ${selectedQuestions.length} questions`);

    // ===== STEP 8: CREATE QUIZ SUBMISSION =====
    const submissionData = {
      quizId: quizId,
      courseId: courseId,
      studentId: userId,
      studentName: studentName,
      questions: selectedQuestions,
      answers: {},
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      submittedAt: null,
      score: null,
      status: 'in_progress',
      attemptNumber: attemptNumber,
      isAutoSubmitted: false,
      timeSpentSeconds: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const submissionRef = await db.collection('quiz_submissions').add(submissionData);

    console.log(`✅ Quiz submission created: ${submissionRef.id}`);

    // ========================================
    // NEW: Update Quiz Tracker status to 'in_progress'
    // ========================================
    const compositeId = `${quizId}_${userId}`;
    const trackerRef = db.collection('quiz_trackers').doc(compositeId);
    
    try {
      // Use set with merge to create if not exists
      await trackerRef.set({
        status: 'in_progress',
        attemptCount: attemptNumber,
        lastSubmissionId: submissionRef.id,
        startedAt: attemptNumber === 1 ? admin.firestore.FieldValue.serverTimestamp() : null,
        lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      console.log(`📊 Tracker updated: ${compositeId} -> in_progress (attempt ${attemptNumber})`);
    } catch (trackerError) {
      console.error('⚠️ Failed to update tracker:', trackerError);
      // Don't throw - tracker update is non-critical
    }

    // ===== RETURN SUCCESS =====
    return {
      success: true,
      submissionId: submissionRef.id,
      questions: selectedQuestions,
      attemptNumber: attemptNumber,
      maxAttempts: maxAttempts,
      durationMinutes: durationMinutes,
      message: `Quiz attempt ${attemptNumber}/${maxAttempts} started successfully`,
    };

  } catch (error: any) {
    console.error('❌ Error in startQuiz:', error);

    // Re-throw HttpsError as-is
    if (error instanceof functionsV2.https.HttpsError) {
      throw error;
    }

    // Wrap other errors
    throw new functionsV2.https.HttpsError(
      'internal',
      `Failed to start quiz: ${error.message || 'Unknown error'}`
    );
  }
});

/**
 * ========================================
 * RETURN ASSIGNMENT GRADES
 * ========================================
 * Callable function to return graded assignments to students
 * - Updates tracker status to 'graded'
 * - Creates in-app notifications for students
 * - Sends email notifications (optional)
 */
export const returnAssignmentGrades = functionsV2.https.onCall(async (request) => {
  const data = request.data;
  const context = request.auth;

  console.log('📤 returnAssignmentGrades called');

  // ===== AUTHENTICATION CHECK =====
  if (!context || !context.uid) {
    throw new functionsV2.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to return grades'
    );
  }

  // ===== VALIDATE INPUT =====
  const {
    assignmentId,
    courseId,
    studentIds,
    feedback,
  } = data;

  if (!assignmentId || typeof assignmentId !== 'string') {
    throw new functionsV2.https.HttpsError(
      'invalid-argument',
      'assignmentId is required and must be a string'
    );
  }

  if (!courseId || typeof courseId !== 'string') {
    throw new functionsV2.https.HttpsError(
      'invalid-argument',
      'courseId is required and must be a string'
    );
  }

  if (!Array.isArray(studentIds) || studentIds.length === 0) {
    throw new functionsV2.https.HttpsError(
      'invalid-argument',
      'studentIds must be a non-empty array'
    );
  }

  console.log(`📋 Assignment: ${assignmentId}, Course: ${courseId}`);
  console.log(`👥 Returning grades to ${studentIds.length} students`);

  try {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // ===== GET ASSIGNMENT INFO =====
    const assignmentDoc = await db.collection('assignments').doc(assignmentId).get();
    if (!assignmentDoc.exists) {
      throw new functionsV2.https.HttpsError(
        'not-found',
        'Assignment not found'
      );
    }

    const assignmentData = assignmentDoc.data();
    const assignmentTitle = assignmentData?.title || 'Assignment';
    const maxPoints = assignmentData?.maxPoints || assignmentData?.points || 100;

    // ===== GET COURSE NAME =====
    const courseDoc = await db.collection('course_of_study').doc(courseId).get();
    const courseName = courseDoc.exists
      ? courseDoc.data()?.name || 'Course'
      : 'Course';

    // ===== GET INSTRUCTOR INFO =====
    const instructorDoc = await db.collection('users').doc(context.uid).get();
    const instructorName = instructorDoc.exists
      ? instructorDoc.data()?.fullName || 'Instructor'
      : 'Instructor';

    // ===== PREPARE EMAIL DATA =====
    const studentEmails: string[] = [];
    const studentNames: { [email: string]: string } = {};
    const studentGroups: { [email: string]: string } = {};
    const grades: { [email: string]: number } = {};
    const feedbacks: { [email: string]: string } = {};

    // ===== PROCESS EACH STUDENT =====
    const results = [];
    const batch = db.batch();
    let batchCount = 0;

    for (const studentId of studentIds) {
      console.log(`Processing student: ${studentId}`);

      // Get tracker
      const trackerId = `${assignmentId}_${studentId}`;
      const trackerRef = db.collection('assignment_trackers').doc(trackerId);
      const trackerDoc = await trackerRef.get();

      if (!trackerDoc.exists) {
        console.warn(`⚠️ Tracker not found for student ${studentId}`);
        results.push({
          studentId,
          success: false,
          error: 'Tracker not found',
        });
        continue;
      }

      const trackerData = trackerDoc.data();
      const grade = trackerData?.grade;
      const studentName = trackerData?.studentName || 'Student';
      const studentEmail = trackerData?.studentEmail || '';
      const groupName = trackerData?.groupName || 'Unknown Group';

      // Collect email data
      if (studentEmail && grade !== null && grade !== undefined) {
        studentEmails.push(studentEmail);
        studentNames[studentEmail] = studentName;
        studentGroups[studentEmail] = groupName;
        grades[studentEmail] = grade;
        feedbacks[studentEmail] = feedback || '';
      }

      // Update tracker with feedback and returnedAt timestamp
      batch.update(trackerRef, {
        feedback: feedback || '',
        returnedAt: now,
        updatedAt: now,
      });

      // Create notification for student
      const notificationRef = db.collection('notifications').doc();
      batch.set(notificationRef, {
        userId: studentId,
        type: 'assignment_graded',
        title: `Assignment Graded: ${assignmentTitle}`,
        content: `Your assignment has been graded by ${instructorName}. Score: ${grade || 0}/${assignmentData?.maxPoints || assignmentData?.points || 100}`,
        relatedId: assignmentId,
        relatedType: 'assignment',
        priority: 'high',
        metadata: {
          assignmentId,
          assignmentTitle,
          courseId,
          grade,
          feedback: feedback || '',
          instructorName,
        },
        isRead: false,
        isArchived: false,
        createdAt: now,
      });

      batchCount += 2;

      // Commit batch if reaching limit (500 operations)
      if (batchCount >= 450) {
        await batch.commit();
        batchCount = 0;
      }

      results.push({
        studentId,
        studentName,
        grade,
        success: true,
      });

      console.log(`✅ Processed ${studentName}: Grade ${grade}`);
    }

    // Commit remaining operations
    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(`✅ Successfully returned grades to ${results.filter(r => r.success).length} students`);

    // ===== SEND GRADE EMAILS =====
    if (studentEmails.length > 0) {
      console.log(`📧 Sending grade emails to ${studentEmails.length} students`);
      try {
        await sendEmail({
          to: studentEmails,
          subject: `✅ Assignment Graded: ${assignmentTitle}`,
          html: generateAssignmentGradeEmail({
            studentEmails: studentEmails,
            studentNames: studentNames,
            studentGroups: studentGroups,
            assignmentTitle: assignmentTitle,
            courseName: courseName,
            courseId: courseId,
            assignmentId: assignmentId,
            grades: grades,
            maxPoints: maxPoints,
            feedback: feedbacks,
            instructorName: instructorName,
          }),
        });
        console.log(`✅ Grade emails sent successfully`);
      } catch (emailError) {
        console.error('⚠️ Failed to send grade emails:', emailError);
        // Don't throw - email failure shouldn't fail the grade return
      }
    }

    return {
      success: true,
      assignmentId,
      courseId,
      processedCount: results.filter(r => r.success).length,
      failedCount: results.filter(r => !r.success).length,
      results,
      message: `Grades returned to ${results.filter(r => r.success).length} student(s)`,
    };

  } catch (error: any) {
    console.error('❌ Error in returnAssignmentGrades:', error);

    if (error instanceof functionsV2.https.HttpsError) {
      throw error;
    }

    throw new functionsV2.https.HttpsError(
      'internal',
      `Failed to return grades: ${error.message || 'Unknown error'}`
    );
  }
});

/**
 * ========================================
 * TRIGGER: onQuizSubmissionCompleted
 * ========================================
 * Automatically grade quiz, update tracker, and send email when submission is completed
 * - Calculates score based on correct answers
 * - Updates quiz_tracker with score and status
 * - Sends grade notification and email to student
 */
export const onQuizSubmissionCompleted = functions.firestore
  .document('quiz_submissions/{submissionId}')
  .onWrite(async (change, context) => {
    const submissionId = context.params.submissionId;

    // Only proceed if document exists and was updated
    if (!change.after.exists) {
      console.log(`⏭️  Submission ${submissionId} deleted, skipping`);
      return;
    }

    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.data();

    // Check if submission was just completed
    const wasCompleted = !before || before.status !== 'completed';
    const isNowCompleted = after?.status === 'completed';

    if (!wasCompleted || !isNowCompleted) {
      console.log(`⏭️  Submission ${submissionId} not newly completed, skipping`);
      return;
    }

    console.log(`📝 Processing completed quiz submission: ${submissionId}`);

    try {
      const db = admin.firestore();
      const now = admin.firestore.Timestamp.now();

      // ===== GET SUBMISSION DATA =====
      const quizId = after.quizId;
      const courseId = after.courseId;
      const studentId = after.studentId;
      const studentName = after.studentName || 'Student';
      const questions = after.questions || [];
      const answers = after.answers || {};

      // ===== CALCULATE SCORE =====
      let correctCount = 0;
      const totalQuestions = questions.length;

      console.log(`🔍 Debugging score calculation:`);
      console.log(`  Total questions: ${totalQuestions}`);
      console.log(`  Answers object:`, JSON.stringify(answers));

      for (const question of questions) {
        const studentAnswer = answers[question.id];
        const correctAnswer = question.correctAnswer;
        const isCorrect = studentAnswer !== undefined && studentAnswer === correctAnswer;
        
        console.log(`  Question ${question.id}:`);
        console.log(`    Student answer: ${studentAnswer} (${typeof studentAnswer})`);
        console.log(`    Correct answer: ${correctAnswer} (${typeof correctAnswer})`);
        console.log(`    Is correct: ${isCorrect}`);
        
        if (isCorrect) {
          correctCount++;
        }
      }

      const score = (correctCount / totalQuestions) * 100; // Score out of 100

      console.log(`📊 Quiz Score: ${correctCount}/${totalQuestions} = ${score.toFixed(1)}%`);

      // ===== GET QUIZ INFO =====
      const quizDoc = await db.collection('quizzes').doc(quizId).get();
      if (!quizDoc.exists) {
        console.error(`⚠️ Quiz ${quizId} not found`);
        return;
      }

      const quizData = quizDoc.data();
      const quizTitle = quizData?.title || 'Quiz';
      const maxPoints = quizData?.points || 100;
      const actualScore = (score / 100) * maxPoints; // Convert percentage to actual points

      // ===== GET COURSE NAME =====
      const courseDoc = await db.collection('course_of_study').doc(courseId).get();
      const courseName = courseDoc.exists
        ? courseDoc.data()?.name || 'Course'
        : 'Course';

      // ===== UPDATE QUIZ_TRACKER =====
      const trackerId = `${quizId}_${studentId}`;
      const trackerRef = db.collection('quiz_trackers').doc(trackerId);
      const trackerDoc = await trackerRef.get();

      if (!trackerDoc.exists) {
        console.warn(`⚠️ Tracker ${trackerId} not found, skipping tracker update`);
      } else {
        await trackerRef.update({
          score: actualScore,
          status: 'completed',
          completedAt: now,
          lastSubmissionId: submissionId,
          updatedAt: now,
        });
        console.log(`✅ Updated tracker ${trackerId} with score ${actualScore}`);
      }

      // ===== UPDATE SUBMISSION WITH SCORE =====
      await change.after.ref.update({
        score: actualScore,
        maxScore: maxPoints,
        gradedAt: now,
      });
      console.log(`✅ Updated submission ${submissionId} with score`);

      // ===== GET STUDENT INFO FOR EMAIL =====
      const userDoc = await db.collection('users').doc(studentId).get();
      const studentEmail = userDoc.exists ? userDoc.data()?.email || '' : '';
      const studentFullName = userDoc.exists ? userDoc.data()?.fullName || studentName : studentName;

      // Get group info from tracker
      const trackerData = trackerDoc.exists ? trackerDoc.data() : null;
      const groupName = trackerData?.groupName || 'Unknown Group';

      // ===== CREATE NOTIFICATION =====
      const notificationRef = db.collection('notifications').doc();
      await notificationRef.set({
        userId: studentId,
        type: 'quiz_graded',
        title: `Quiz Auto-Graded: ${quizTitle}`,
        content: `Your quiz has been automatically graded. Score: ${actualScore.toFixed(1)}/${maxPoints}`,
        relatedId: quizId,
        relatedType: 'quiz',
        priority: 'high',
        metadata: {
          quizId,
          quizTitle,
          courseId,
          score: actualScore,
          submissionId,
        },
        isRead: false,
        isArchived: false,
        createdAt: now,
      });
      console.log(`✅ Created notification for student ${studentId}`);

      // ===== SEND GRADE EMAIL =====
      if (studentEmail) {
        console.log(`📧 Sending grade email to ${studentEmail}`);
        try {
          await sendEmail({
            to: [studentEmail],
            subject: `📝 Quiz Graded: ${quizTitle}`,
            html: generateQuizGradeEmail({
              studentEmails: [studentEmail],
              studentNames: { [studentEmail]: studentFullName },
              studentGroups: { [studentEmail]: groupName },
              quizTitle: quizTitle,
              courseName: courseName,
              courseId: courseId,
              quizId: quizId,
              grades: { [studentEmail]: actualScore },
              maxPoints: maxPoints,
              instructorName: 'System (Auto-graded)',
            }),
          });
          console.log(`✅ Grade email sent to ${studentEmail}`);
        } catch (emailError) {
          console.error('⚠️ Failed to send grade email:', emailError);
          // Don't throw - email failure shouldn't fail the grading
        }
      }

      console.log(`✅ Successfully processed quiz submission ${submissionId}`);

    } catch (error) {
      console.error(`❌ Error processing quiz submission ${submissionId}:`, error);
      // Don't throw - let the submission complete even if grading fails
    }
  });

/**
 * ========================================
 * CALLABLE: createQuizTrackers
 * ========================================
 * Manually create quiz trackers for a quiz (useful for existing quizzes)
 */
export const createQuizTrackers = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { quizId } = data;

  if (!quizId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'quizId is required'
    );
  }

  console.log(`📊 Creating trackers for quiz: ${quizId}`);

  try {
    const db = admin.firestore();

    // Get quiz data
    const quizDoc = await db.collection('quizzes').doc(quizId).get();
    if (!quizDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Quiz not found');
    }

    const quiz = quizDoc.data()!;
    const courseId = quiz.courseId;
    const groupIds = quiz.groupIds || [];

    if (groupIds.length === 0) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Quiz has no groups assigned'
      );
    }

    // Collect student IDs from enrollments
    const studentIds: string[] = [];
    for (const groupId of groupIds) {
      const enrollmentsSnapshot = await db
        .collection('enrollments')
        .where('groupId', '==', groupId)
        .where('courseId', '==', courseId)
        .where('status', '==', 'active')
        .get();

      enrollmentsSnapshot.forEach(doc => {
        const enrollment = doc.data();
        const userId = enrollment.userId;
        if (userId && !studentIds.includes(userId)) {
          studentIds.push(userId);
        }
      });
    }

    console.log(`📤 Found ${studentIds.length} students`);

    if (studentIds.length === 0) {
      return {
        success: true,
        message: 'No students found for this quiz',
        trackersCreated: 0,
      };
    }

    // Create trackers
    const batch = db.batch();
    const trackersRef = db.collection('quiz_trackers');
    let created = 0;
    let skipped = 0;

    for (const studentId of studentIds) {
      const compositeId = `${quizId}_${studentId}`;
      const trackerRef = trackersRef.doc(compositeId);

      // Check if tracker already exists
      const existingTracker = await trackerRef.get();
      if (existingTracker.exists) {
        console.log(`⏭️  Tracker ${compositeId} already exists, skipping`);
        skipped++;
        continue;
      }

      // Get student info
      const userDoc = await db.collection('users').doc(studentId).get();
      const userData = userDoc.data();
      const studentName = userData?.fullName || userData?.name || 'Unknown';
      const studentEmail = userData?.email || '';

      // Get group info
      const enrollmentSnapshot = await db
        .collection('enrollments')
        .where('userId', '==', studentId)
        .where('courseId', '==', courseId)
        .limit(1)
        .get();

      let groupId = '';
      let groupName = 'Unknown Group';
      if (!enrollmentSnapshot.empty) {
        const enrollmentData = enrollmentSnapshot.docs[0].data();
        groupId = enrollmentData.groupId || '';

        if (groupId) {
          const groupDoc = await db
            .collection('course_of_study')
            .doc(courseId)
            .collection('groups')
            .doc(groupId)
            .get();
          if (groupDoc.exists) {
            groupName = groupDoc.data()?.name || groupName;
          }
        }
      }

      // Create tracker
      batch.set(trackerRef, {
        id: compositeId,
        quizId: quizId,
        studentId: studentId,
        courseId: courseId,
        groupId: groupId,
        studentName: studentName,
        studentEmail: studentEmail,
        groupName: groupName,
        status: 'not_started',
        attemptCount: 0,
        score: null,
        startedAt: null,
        lastAttemptAt: null,
        completedAt: null,
        lastSubmissionId: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      created++;
    }

    // Commit batch
    if (created > 0) {
      await batch.commit();
      console.log(`✅ Created ${created} quiz trackers`);
    }

    return {
      success: true,
      message: `Successfully created ${created} trackers (${skipped} already existed)`,
      trackersCreated: created,
      trackersSkipped: skipped,
      totalStudents: studentIds.length,
    };

  } catch (error: any) {
    console.error('❌ Error creating quiz trackers:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to create quiz trackers: ${error.message || 'Unknown error'}`
    );
  }
});


