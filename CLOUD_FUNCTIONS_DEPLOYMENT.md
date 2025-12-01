# Link Preview Cloud Functions - Deployment Guide

## 🎯 Tổng quan

Cloud Functions để fetch link preview metadata từ bất kỳ URL nào (Facebook, YouTube, báo chí, etc.) mà không gặp lỗi CORS. Giải pháp này hoạt động đồng nhất trên tất cả nền tảng (Web, Mobile, Desktop).

## 📁 Cấu trúc

```
functions/
├── src/
│   └── index.ts          # Cloud Function fetchLinkPreview
├── lib/                   # Compiled JavaScript (auto-generated)
├── package.json          # Dependencies
├── tsconfig.json         # TypeScript config
└── .eslintrc.js         # ESLint config
```

## 🚀 Deployment

### Bước 1: Cài Firebase CLI (nếu chưa có)

```bash
npm install -g firebase-tools
firebase login
```

### Bước 2: Deploy Functions

```bash
cd functions
npm run build      # Build TypeScript
cd ..
firebase deploy --only functions
```

### Bước 3: Kiểm tra Deploy thành công

```bash
firebase functions:log
```

Bạn sẽ thấy output:
```
✔  functions[fetchLinkPreview(us-central1)] Successful create operation.
✔  functions[healthCheck(us-central1)] Successful create operation.
```

## 🔧 Functions đã Deploy

### 1. `fetchLinkPreview` (Callable Function)

**Chức năng:** Fetch metadata từ URL

**Input:**
```json
{
  "url": "https://example.com"
}
```

**Output:**
```json
{
  "url": "https://example.com",
  "title": "Example Domain",
  "description": "This domain is for use in examples...",
  "imageUrl": "https://example.com/image.jpg",
  "domain": "example.com",
  "success": true
}
```

**Sử dụng từ Flutter:**
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('fetchLinkPreview')
  .call({'url': 'https://example.com'});
  
final metadata = LinkMetadata.fromJson(result.data);
```

### 2. `healthCheck` (HTTP Request)

**Chức năng:** Kiểm tra health của Functions

**Test:**
```bash
curl https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/healthCheck
```

## 📊 Monitoring & Logs

### Xem logs real-time
```bash
firebase functions:log --only fetchLinkPreview
```

### Xem logs trong Firebase Console
1. Mở [Firebase Console](https://console.firebase.google.com)
2. Chọn project
3. **Functions** → **Logs**

## 💰 Pricing (Firebase Blaze Plan)

- **Free tier:** 2 triệu invocations/tháng
- **Network egress:** 5GB/tháng miễn phí
- **Compute time:** 400,000 GB-seconds/tháng miễn phí

Link preview thường chỉ tốn:
- ~200ms compute time
- ~100KB network egress

→ Có thể handle **hàng chục nghìn requests/ngày** trong free tier!

## 🔐 Security Rules

Functions tự động require Firebase Authentication nếu cần. Hiện tại `fetchLinkPreview` là public (bất kỳ ai cũng gọi được).

Để bảo mật thêm, thêm authentication check:

```typescript
export const fetchLinkPreview = functions.https.onCall(
  async (data: {url: string}, context) => {
    // Require authenticated user
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }
    
    // ... rest of code
  }
);
```

## 🐛 Troubleshooting

### Lỗi: "Function not found"
- Chạy `firebase deploy --only functions` lại
- Kiểm tra region trong Flutter code match với deployed region

### Lỗi: "CORS error"
- Cloud Functions không bị CORS vì chạy server-side
- Nếu vẫn lỗi, kiểm tra bạn đang dùng `httpsCallable` (không phải HTTP request thông thường)

### Lỗi: "Timeout"
- Tăng timeout trong Flutter:
  ```dart
  final functions = FirebaseFunctions.instance;
  functions.httpsCallableOptions = HttpsCallableOptions(
    timeout: const Duration(seconds: 30),
  );
  ```

### Link preview không có image
- Một số website không có Open Graph tags
- YouTube/Facebook thường có đầy đủ metadata
- Function sẽ fallback về title và domain nếu thiếu image

## 📝 Update Functions

Sau khi sửa code trong `src/index.ts`:

```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

## 🎯 Next Steps

1. ✅ Deploy functions lên Firebase
2. ✅ Test với URL thật (YouTube, Facebook, VNExpress, etc.)
3. ✅ Monitor logs để xem performance
4. 🔄 Thêm caching (Redis/Firestore) nếu cần optimize
5. 🔄 Thêm rate limiting nếu cần chống abuse

## 📞 Support

Nếu gặp vấn đề:
1. Check logs: `firebase functions:log`
2. Test function trực tiếp từ Firebase Console
3. Verify Firebase Blaze plan đã active
4. Check quotas trong Firebase Console

---

**⚡ Lợi ích của giải pháp này:**
- ✅ Không CORS issues
- ✅ Đồng nhất trên mọi platform (Web/Mobile/Desktop)
- ✅ Scalable và reliable (Google infrastructure)
- ✅ Support mọi website (Facebook, YouTube, news, etc.)
- ✅ Free tier hào phóng
- ✅ Easy to maintain và update
