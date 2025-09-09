# Render Backend Deployment Guide for Flutter App

This guide will help you deploy your Node.js backend to Render and configure your Flutter app to connect to it.

## 🚀 Backend Deployment on Render

### Step 1: Prepare Your Backend

1. **Push your backend to GitHub** (if not already done):
   ```bash
   cd backend
   git init
   git add .
   git commit -m "Initial backend commit"
   git remote add origin YOUR_GITHUB_REPO_URL
   git push -u origin main
   ```

### Step 2: Create Render Account & Service

1. Go to [render.com](https://render.com) and sign up/login
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub account and select your repository
4. Configure the service:
   - **Name**: `event-planning-backend`
   - **Root Directory**: `backend` (if backend is in a subdirectory)
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node src/server.js`

### Step 3: Configure Environment Variables

In Render dashboard, go to **Environment** tab and add these variables:

```env
NODE_ENV=production
PORT=5000
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=generate_a_secure_random_string
JWT_EXPIRES_IN=7d
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your_secure_admin_password
SUPER_ADMIN_USERNAME=superadmin
SUPER_ADMIN_PASSWORD=your_secure_superadmin_password
CORS_ORIGIN=*
```

#### Getting MongoDB URI:
1. Use [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) (free tier available)
2. Create a cluster
3. Add database user
4. Whitelist all IPs (0.0.0.0/0) for Render
5. Get connection string and replace `<password>` with your database password

### Step 4: Deploy

1. Click **"Create Web Service"**
2. Wait for deployment (first deployment takes 5-10 minutes)
3. Your backend will be available at: `https://your-service-name.onrender.com`

## 📱 Flutter App Configuration

### Step 1: Update API Service

Update `/lib/services/api_service.dart`:

```dart
class ApiService {
  // Replace with your Render backend URL
  static const String baseUrl = 'https://your-service-name.onrender.com/api';
  // Remove the /api if your backend doesn't use it as prefix
  
  static String? _token;
  // ... rest of the code
}
```

### Step 2: Rebuild Your APK

```bash
cd "Event Planning App"
flutter clean
flutter pub get
flutter build apk --release
```

### Step 3: Test the Connection

1. Install the new APK on your device
2. Try logging in with admin credentials
3. Check if data loads correctly

## 🔧 Troubleshooting

### CORS Issues
If you get CORS errors:
1. Ensure `CORS_ORIGIN=*` is set in Render environment
2. Or update server.js to explicitly allow all origins

### Connection Timeout
Render free tier sleeps after 15 minutes of inactivity:
- First request may take 30-50 seconds (cold start)
- Subsequent requests will be fast
- Consider upgrading to paid tier for always-on service

### MongoDB Connection
If database connection fails:
1. Check MongoDB Atlas IP whitelist (should be 0.0.0.0/0)
2. Verify connection string format
3. Check database user credentials

### SSL/HTTPS Issues
- Render automatically provides HTTPS
- Ensure your Flutter app uses `https://` not `http://`

## 🔒 Security Recommendations

1. **Change default passwords** before deploying
2. **Generate secure JWT_SECRET**: 
   ```bash
   openssl rand -base64 32
   ```
3. **Restrict CORS** in production (optional):
   - Update `CORS_ORIGIN` to specific domains
   - Modify server.js corsOptions for more control

## 📊 Monitoring

1. View logs in Render dashboard → **Logs** tab
2. Monitor service health → **Metrics** tab
3. Set up health check endpoint:
   ```javascript
   app.get('/health', (req, res) => {
     res.json({ status: 'OK', timestamp: new Date() });
   });
   ```

## 💡 Tips

- **Free Tier Limits**: 750 hours/month, sleeps after inactivity
- **Custom Domain**: Available in Render dashboard settings
- **Auto-Deploy**: Enabled by default for GitHub pushes
- **Scaling**: Easy horizontal scaling in paid tiers

## 📝 Example Test Commands

Test your deployed backend:

```bash
# Health check
curl https://your-service-name.onrender.com/health

# Admin login
curl -X POST https://your-service-name.onrender.com/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your_password"}'

# Get events (requires token from login)
curl https://your-service-name.onrender.com/api/events \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 🎉 Success!

Once deployed, your Event Planning App will be connected to a production backend with:
- Secure authentication
- Real-time data sync
- Scalable infrastructure
- Professional deployment

Remember to update your Flutter app with the new backend URL and rebuild the APK!