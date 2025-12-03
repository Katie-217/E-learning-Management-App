import * as functions from "firebase-functions";
import * as functionsV2 from "firebase-functions/v2";
import * as admin from "firebase-admin";
import * as cheerio from "cheerio";
import fetch from "node-fetch";

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
