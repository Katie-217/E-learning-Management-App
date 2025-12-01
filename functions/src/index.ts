import * as functions from "firebase-functions";
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
 * Health check function for monitoring
 */
export const healthCheck = functions.https.onRequest((req, res) => {
  res.status(200).json({
    status: "healthy",
    service: "link-preview-functions",
    timestamp: new Date().toISOString(),
  });
});
