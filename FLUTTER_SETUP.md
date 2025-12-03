# ACP Project - Flutter & Laravel Full Stack Application

A complete project management system with Flutter mobile frontend and Laravel backend.

## 📱 Features

- **Authentication**: Login and Registration
- **Project Management**: Create, view, update, and delete projects
- **Task Management**: Assign and track tasks
- **Role-Based Access**: Admin, Manager, and Employee roles
- **Real-time Updates**: Pull-to-refresh functionality
- **Firebase Integration**: Backend uses Firestore for data storage

## 🏗️ Architecture

```
ACP_Flutter/
├── frontend/          # Flutter mobile app
│   ├── lib/
│   │   ├── models/           # Data models (User, Project, Task)
│   │   ├── services/         # API and Auth services
│   │   ├── screens/          # UI screens
│   │   │   ├── auth/        # Login, Register
│   │   │   ├── home/        # Home with tabs
│   │   │   └── projects/    # Project list & details
│   │   └── main.dart        # App entry point
│   └── pubspec.yaml
└── backend/           # Laravel API
    ├── app/
    │   ├── Http/Controllers/
    │   ├── Models/
    │   └── Services/
    ├── routes/
    │   ├── api.php          # API routes
    │   ├── web.php          # Web routes
    │   └── auth.php         # Auth routes
    └── .env
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.10.1 or higher
- **PHP**: 8.0.2 or higher
- **Composer**: Latest version
- **Laravel**: 9.19 or higher
- **MySQL**: Database server
- **Firebase**: Account with Firestore setup

### Backend Setup (Laravel)

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   composer install
   ```

3. **Configure environment:**
   - Copy `.env.example` to `.env` (if not exists)
   - Update database credentials in `.env`:
     ```env
     DB_CONNECTION=mysql
     DB_HOST=127.0.0.1
     DB_PORT=3306
     DB_DATABASE=your_database_name
     DB_USERNAME=your_username
     DB_PASSWORD=your_password
     ```

4. **Configure Firebase:**
   - Set up Firebase project at https://console.firebase.google.com
   - Download Firebase credentials JSON
   - Update `.env` with Firebase settings:
     ```env
     FIREBASE_CREDENTIALS=/path/to/firebase_credentials.json
     FIREBASE_PROJECT_ID=your-project-id
     ```

5. **Generate application key:**
   ```bash
   php artisan key:generate
   ```

6. **Run migrations:**
   ```bash
   php artisan migrate
   ```

7. **Seed roles and permissions:**
   ```bash
   php artisan db:seed
   ```

8. **Start Laravel server:**
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   
   Backend will be available at: http://localhost:8000

### Frontend Setup (Flutter)

1. **Navigate to frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint:**
   
   Open `lib/services/api_service.dart` and `lib/services/auth_service.dart`:
   
   - **For Android Emulator:**
     ```dart
     static const String baseUrl = 'http://10.0.2.2:8000/api';
     ```
   
   - **For iOS Simulator:**
     ```dart
     static const String baseUrl = 'http://localhost:8000/api';
     ```
   
   - **For Physical Device:**
     ```dart
     static const String baseUrl = 'http://YOUR_COMPUTER_IP:8000/api';
     ```
     
     Find your computer's IP:
     - **Linux/Mac:** `ifconfig` or `ip addr`
     - **Windows:** `ipconfig`

4. **Run the app:**
   
   **List available devices:**
   ```bash
   flutter devices
   ```
   
   **Run on connected device:**
   ```bash
   flutter run
   ```
   
   **Run on specific device:**
   ```bash
   flutter run -d device_id
   ```

## 📋 API Endpoints

### Authentication
- `POST /login` - User login
- `POST /register` - User registration
- `POST /logout` - User logout
- `GET /api/user` - Get authenticated user

### Projects
- `GET /api/projects` - List all projects
- `GET /api/projects/{id}` - Get project details
- `POST /api/projects` - Create new project
- `PUT /api/projects/{id}` - Update project
- `DELETE /api/projects/{id}` - Delete project

### Tasks
- `GET /api/tasks` - List all tasks
- `GET /api/projects/{projectId}/tasks/{taskId}` - Get task details
- `POST /api/projects/{projectId}/tasks` - Create new task
- `PUT /api/projects/{projectId}/tasks/{taskId}` - Update task
- `DELETE /api/projects/{projectId}/tasks/{taskId}` - Delete task

## 🔐 Authentication

The app uses Laravel Sanctum for API authentication:

1. User logs in through the mobile app
2. Laravel creates a session
3. Session is stored securely in Flutter using `flutter_secure_storage`
4. All API requests include authentication headers

## 🎨 Flutter Packages Used

- **http** (^1.2.0) - HTTP client for API calls
- **provider** (^6.1.1) - State management
- **flutter_secure_storage** (^9.0.0) - Secure token storage
- **intl** (^0.19.0) - Date formatting

## 📱 App Screens

1. **Splash Screen** - Checks authentication status
2. **Login Screen** - User login
3. **Register Screen** - New user registration
4. **Home Screen** - Tab navigation (Projects & Tasks)
5. **Projects Screen** - List all projects
6. **Project Detail Screen** - View project with tasks
7. **Task Detail Screen** - View task details (placeholder)

## 🔧 Troubleshooting

### Backend Issues

**Port already in use:**
```bash
# Use a different port
php artisan serve --port=8001
```

**Database connection error:**
- Check MySQL is running
- Verify `.env` database credentials
- Run `php artisan config:clear`

**Firebase errors:**
- Ensure Firebase credentials file exists
- Check FIREBASE_PROJECT_ID in `.env`
- Verify Firestore rules allow read/write

### Frontend Issues

**Can't connect to backend:**
- Verify backend server is running
- Check API URL in `api_service.dart` matches your setup
- For physical devices, ensure device and computer are on same network
- Check firewall settings

**Package errors:**
```bash
# Clean and reinstall
flutter clean
flutter pub get
```

**Build errors:**
```bash
# Clear build cache
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
flutter run
```

## 👤 Default Users

After seeding, you can login with:

**Admin:**
- Email: admin@example.com
- Password: password

**Manager:**
- Email: manager@example.com
- Password: password

**Employee:**
- Email: employee@example.com
- Password: password

## 🛠️ Development

### Backend Development

**Watch for changes:**
```bash
# In development, Laravel auto-reloads on file changes
php artisan serve
```

**Clear caches:**
```bash
php artisan cache:clear
php artisan config:clear
php artisan route:clear
```

### Frontend Development

**Hot reload:**
- Press `r` in terminal
- Or save files in your IDE

**Hot restart:**
- Press `R` in terminal

**Run tests:**
```bash
flutter test
```

## 📦 Project Structure Details

### Flutter Models
- **User**: User data with roles
- **Project**: Project information
- **Task**: Task details with status and priority

### Laravel Controllers
- **ProjectController**: CRUD operations for projects
- **TaskController**: CRUD operations for tasks
- **AuthenticatedSessionController**: Authentication logic

### Services
- **ApiService**: Handles all HTTP requests to backend
- **AuthService**: Manages authentication and token storage
- **FirestoreService**: Backend service for Firestore operations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a pull request

## 📄 License

This project is licensed under the MIT License.

## 🐛 Known Issues

- Task detail screen is a placeholder (needs implementation)
- Create project and task forms not yet implemented
- No update/delete functionality in mobile UI yet

## 🚧 Future Enhancements

- [ ] Complete CRUD operations in mobile app
- [ ] Add image upload for projects
- [ ] Push notifications for task assignments
- [ ] Offline mode with local storage
- [ ] Dark mode support
- [ ] Task comments and attachments
- [ ] Calendar view for tasks
- [ ] Task filtering and sorting

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Check existing documentation
- Review Laravel and Flutter official docs

---

**Built with ❤️ using Flutter & Laravel**
