# Firebase Cloud Functions - Link Preview Service

Enterprise-grade link preview service using Firebase Cloud Functions.

## Features

- ✅ **No CORS Issues**: Server-side fetching eliminates CORS problems
- ✅ **Universal**: Works on Web, Mobile, and Desktop platforms
- ✅ **Reliable**: Runs on Google's infrastructure
- ✅ **Rich Metadata**: Extracts Open Graph tags, Twitter cards, and fallback HTML meta tags
- ✅ **YouTube Support**: Special handling for YouTube thumbnails
- ✅ **Error Handling**: Graceful fallbacks and comprehensive error handling

## API

### `fetchLinkPreview(url: string)`

Callable Cloud Function that fetches link preview metadata.

**Request:**
```json
{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

**Response:**
```json
{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "title": "Rick Astley - Never Gonna Give You Up",
  "description": "The official video for Rick Astley...",
  "imageUrl": "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
  "domain": "www.youtube.com",
  "success": true
}
```

**Error Response:**
```json
{
  "url": "https://invalid-url.com",
  "title": "invalid-url.com",
  "domain": "invalid-url.com",
  "success": true
}
```

## Development

### Prerequisites

- Node.js 18+ 
- Firebase CLI: `npm install -g firebase-tools`
- Firebase project with Blaze plan

### Setup

```bash
cd functions
npm install
```

### Build

```bash
npm run build
```

### Deploy

```bash
firebase deploy --only functions
```

### Local Testing

```bash
npm run serve
```

## Dependencies

- **firebase-functions**: Cloud Functions runtime
- **firebase-admin**: Admin SDK for Firebase
- **cheerio**: HTML parsing (jQuery-like syntax)
- **node-fetch**: HTTP client for fetching webpages

## Architecture

```
┌─────────────┐
│ Flutter App │
│ (Web/Mobile)│
└──────┬──────┘
       │ httpsCallable('fetchLinkPreview')
       │
       ▼
┌─────────────────────────┐
│ Cloud Function          │
│ (Google Cloud Platform) │
│                         │
│ 1. Validate URL         │
│ 2. Fetch HTML           │
│ 3. Parse with Cheerio   │
│ 4. Extract metadata     │
│ 5. Return JSON          │
└──────┬──────────────────┘
       │ HTTP GET
       │
       ▼
┌─────────────────────┐
│ Target Website      │
│ (Facebook, YouTube, │
│  news sites, etc.)  │
└─────────────────────┘
```

## Metadata Extraction Priority

1. **Open Graph tags** (og:title, og:image, og:description)
2. **Twitter Card tags** (twitter:title, twitter:image)
3. **Standard HTML meta tags** (description)
4. **HTML title tag**
5. **Domain fallback**

## Security

- Input validation for URL format
- 10-second timeout for HTTP requests
- User-Agent spoofing to avoid bot detection
- Error sanitization (no sensitive data in errors)

## Performance

- Average response time: 200-500ms
- Timeout: 10 seconds
- Memory: ~256MB per instance
- Cold start: ~1-2 seconds

## Cost Estimation

Firebase Blaze Plan (Free tier):
- 2M invocations/month
- 400,000 GB-seconds compute time/month
- 5GB network egress/month

Typical link preview:
- ~200ms compute time
- ~100KB network transfer

**Result:** Can handle ~10,000 requests/day within free tier!

## Monitoring

View logs:
```bash
firebase functions:log --only fetchLinkPreview
```

Or in [Firebase Console](https://console.firebase.google.com) → Functions → Logs

## Error Codes

| Code | Description |
|------|-------------|
| `invalid-argument` | Invalid URL format or missing URL parameter |
| `unavailable` | Failed to fetch URL (HTTP error) |
| `internal` | Generic internal error |

## Testing

Test URLs:
- YouTube: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
- Facebook: `https://www.facebook.com/...`
- News: `https://vnexpress.net/...`
- Generic: `https://github.com/...`

## Troubleshooting

**Function not found:**
- Redeploy: `firebase deploy --only functions`
- Check region matches in Flutter code

**Timeout errors:**
- Some websites are slow to respond
- Increase timeout in Flutter or Cloud Function

**No image returned:**
- Not all websites have Open Graph images
- Fallback shows domain name only

## License

MIT
