# Quick Start Guide - ACP Project Mobile App

## 🎯 Quick Setup (5 Minutes)

### Step 1: Verify Backend is Running
```bash
# Check if backend is running on http://localhost:8000
curl http://localhost:8000
```

If not running:
```bash
cd /home/sukithan/Desktop/ACP_Flutter/backend
php artisan serve --host=0.0.0.0 --port=8000
```

### Step 2: Configure Flutter App

**Option A - Android Emulator** (Default - No changes needed)
- Already configured to use `http://10.0.2.2:8000`

**Option B - Physical Device**
1. Find your computer's IP:
   ```bash
   ip addr show | grep "inet " | grep -v 127.0.0.1
   ```
2. Edit these files:
   - `frontend/lib/services/api_service.dart` line 11
   - `frontend/lib/services/auth_service.dart` line 8
   
   Replace `10.0.2.2` with your computer's IP address

### Step 3: Run the App
```bash
cd /home/sukithan/Desktop/ACP_Flutter/frontend
flutter pub get
flutter run
```

### Step 4: Login
Use one of these test accounts:
- **Admin:** admin@example.com / password
- **Manager:** manager@example.com / password  
- **Employee:** employee@example.com / password

## ✅ Verification Checklist

- [ ] Backend running at http://localhost:8000
- [ ] Frontend dependencies installed (`flutter pub get`)
- [ ] Device/Emulator connected (`flutter devices`)
- [ ] Network connectivity between device and backend
- [ ] Test login successful

## 🚨 Common Issues

### "Failed to load projects"
- **Cause:** Can't connect to backend
- **Fix:** 
  1. Verify backend is running
  2. Check API URL in `api_service.dart`
  3. For physical devices, ensure same WiFi network

### "Invalid email or password"
- **Cause:** User doesn't exist or wrong credentials
- **Fix:** 
  1. Check backend database is seeded
  2. Use test credentials: admin@example.com / password
  3. Check backend logs: `backend/storage/logs/laravel.log`

### "Failed to open stream: No such file"
- **Cause:** Missing bootstrap/app.php
- **Fix:** Already fixed! Run `composer install` if needed

## 📱 What You Can Do Now

### ✅ Working Features:
1. **Login/Register** - Authenticate users
2. **View Projects** - See all accessible projects
3. **View Tasks** - See assigned tasks
4. **Project Details** - View project with its tasks
5. **Pull to Refresh** - Update data
6. **Logout** - Clear session

### 🚧 To Be Implemented:
1. Create/Edit/Delete Projects
2. Create/Edit/Delete Tasks
3. Complete Task Detail Screen
4. Search and Filters
5. User Profile

## 📂 Key Files

```
frontend/lib/
├── main.dart                    # App entry & routing
├── services/
│   ├── api_service.dart        # Change API URL here
│   └── auth_service.dart       # Change Auth URL here
├── screens/
│   ├── auth/login_screen.dart  # Login UI
│   └── home/home_screen.dart   # Main app screen
└── models/                      # Data models
```

## 🔧 Configuration Files

**API Configuration:**
- File: `frontend/lib/services/api_service.dart`
- Line: 11
- Current: `http://10.0.2.2:8000/api`

**Auth Configuration:**
- File: `frontend/lib/services/auth_service.dart`
- Line: 8
- Current: `http://10.0.2.2:8000`

## 💡 Tips

1. **Hot Reload:** Press `r` in terminal after code changes
2. **Hot Restart:** Press `R` for full restart
3. **Logs:** Press `v` to show/hide logs
4. **Backend Logs:** Check `backend/storage/logs/laravel.log`
5. **Clear Cache:** `flutter clean` if issues persist

## 🎨 App Structure

```
Splash Screen
    ↓
Login/Register
    ↓
Home (Bottom Navigation)
    ├── Projects Tab → Project Detail → Task Detail
    └── Tasks Tab → Task Detail
```

## 📞 Need Help?

1. Check `FLUTTER_SETUP.md` for detailed setup
2. Check `IMPLEMENTATION_SUMMARY.md` for implementation details
3. Review Laravel logs: `backend/storage/logs/laravel.log`
4. Check Flutter logs in terminal

## 🎉 Success!

If you can:
- ✅ Login with test credentials
- ✅ See projects list
- ✅ Navigate to project details
- ✅ See tasks list

**Congratulations! Your app is working! 🎊**

---

**Next:** Start implementing create/edit forms or customize the UI to your needs!
