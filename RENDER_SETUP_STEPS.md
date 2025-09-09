# 🚀 Render Deployment Steps

Now that your `render.yaml` is properly configured, follow these exact steps:

## Step 1: Retry Render Deployment

1. **Click "Retry" button** in your current Render screen
   - Or refresh the page and start over
   - Render should now find the `render.yaml` file

## Step 2: Configure Environment Variables

Once Render detects the configuration, you'll need to set these environment variables:

### Required Environment Variables:

```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/event_planning_app?retryWrites=true&w=majority
ADMIN_PASSWORD=your_secure_admin_password  
SUPER_ADMIN_PASSWORD=your_secure_superadmin_password
```

### Getting MongoDB URI:

1. **Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)**
2. **Create free cluster** (if you don't have one)
3. **Create database user**:
   - Go to Database Access → Add New Database User
   - Username: `eventplanning`
   - Password: Generate secure password
4. **Whitelist all IPs**:
   - Go to Network Access → Add IP Address
   - Enter: `0.0.0.0/0` (allow from anywhere)
5. **Get connection string**:
   - Go to Clusters → Connect → Connect your application
   - Copy the connection string
   - Replace `<password>` with your database user password
   - Replace `<database>` with `event_planning_app`

## Step 3: Set Environment Variables in Render

In the Render dashboard:

1. **MONGODB_URI**: Paste your MongoDB Atlas connection string
2. **ADMIN_PASSWORD**: Set a secure password (e.g., `SecureAdmin123!`)
3. **SUPER_ADMIN_PASSWORD**: Set a secure password (e.g., `SuperSecure456!`)

## Step 4: Deploy

1. **Click "Create Web Service"**
2. **Wait for deployment** (5-10 minutes first time)
3. **Your backend will be available at**: `https://event-planning-backend.onrender.com`

## Step 5: Test Deployment

Test these endpoints:

```bash
# Health check
curl https://event-planning-backend.onrender.com/health

# Root endpoint  
curl https://event-planning-backend.onrender.com/

# Admin login
curl -X POST https://event-planning-backend.onrender.com/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"YOUR_ADMIN_PASSWORD"}'
```

## Step 6: Update Flutter App

Once backend is deployed, update your Flutter app:

```dart
// In lib/services/api_service.dart
static const String baseUrl = 'https://event-planning-backend.onrender.com/api';
```

Then rebuild your APK:
```bash
flutter build apk --release
```

## 🔧 Troubleshooting

### If deployment fails:
1. Check Render logs for error messages
2. Verify MongoDB URI is correct
3. Ensure environment variables are set

### If MongoDB connection fails:
1. Check IP whitelist includes `0.0.0.0/0`
2. Verify database user credentials
3. Test connection string format

## ✅ Success Indicators

- ✅ Render build completes successfully
- ✅ `/health` endpoint returns healthy status
- ✅ Admin login works with your credentials
- ✅ Flutter app connects to backend

Your backend will be live at: `https://event-planning-backend.onrender.com`