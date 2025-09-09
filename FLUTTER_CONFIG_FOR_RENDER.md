# Quick Flutter Configuration for Render Backend

## 📱 Update Your Flutter App

### 1. Update API URL
Edit `/lib/services/api_service.dart`:

```dart
class ApiService {
  // Replace 'your-app-name' with your actual Render service name
  static const String baseUrl = 'https://your-app-name.onrender.com/api';
  
  // Rest of your code remains the same...
}
```

### 2. Rebuild APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 3. Test Endpoints
Your backend URLs will be:
- Root: `https://your-app-name.onrender.com/`
- Health: `https://your-app-name.onrender.com/health`
- Admin Login: `https://your-app-name.onrender.com/api/auth/admin/login`
- Events: `https://your-app-name.onrender.com/api/events`

### 4. Important Notes
- ✅ Render provides HTTPS automatically (no http://)
- ✅ No need to specify port (Render handles it)
- ⏱️ First request may be slow (30-50 seconds) on free tier
- 🔒 Make sure to set secure passwords in Render environment variables

## 🧪 Quick Test
After updating the URL, test in your app:
1. Try admin login
2. Check if events load
3. Test user registration

That's it! Your app should now connect to your Render backend.