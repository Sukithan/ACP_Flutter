<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ProjectController;
use App\Http\Controllers\TaskController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\TeamController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

// Health check route (public)
Route::get('/', function () {
    return response()->json(['message' => 'ACP API is running', 'version' => '1.0']);
});

// Database connection test route (public for debugging)
Route::get('/test-connections', function () {
    $results = [];
    
    // Test MySQL connection
    try {
        \DB::connection()->getPdo();
        $results['mysql'] = [
            'status' => 'connected',
            'message' => 'MySQL connection successful',
            'database' => config('database.connections.mysql.database')
        ];
        
        // Test if we can actually query
        $userCount = \App\Models\User::count();
        $results['mysql']['user_count'] = $userCount;
    } catch (\Exception $e) {
        $results['mysql'] = [
            'status' => 'failed', 
            'message' => $e->getMessage()
        ];
    }
    
    // Test Firestore connection
    try {
        $firestoreService = app(\App\Services\FirestoreService::class);
        $projects = $firestoreService->getAllProjects();
        $projectCount = 0;
        if ($projects instanceof \Illuminate\Support\Collection) {
            $projectCount = $projects->count();
        } else {
            // It's a Firestore QuerySnapshot
            foreach ($projects as $project) {
                $projectCount++;
            }
        }
        $results['firestore'] = [
            'status' => 'connected',
            'message' => 'Firestore connection successful',
            'project_count' => $projectCount
        ];
    } catch (\Exception $e) {
        $results['firestore'] = [
            'status' => 'failed',
            'message' => $e->getMessage()
        ];
    }
    
    return response()->json($results);
});

// Public Auth Routes for Mobile App
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);
    
    // Dashboard
    Route::get('/dashboard/stats', [DashboardController::class, 'stats']);
    
    // Users
    Route::get('/users/managers', [UserController::class, 'getManagers']);
    Route::get('/users/employees', [UserController::class, 'getEmployees']);
    Route::get('/users/all', [UserController::class, 'getAllUsers'])->middleware('role:admin');
    
    // Team Members
    Route::get('/team/members', [TeamController::class, 'getTeamMembers']);
    
    // Projects
    Route::get('/projects', [ProjectController::class, 'index']);
    Route::get('/projects/{id}', [ProjectController::class, 'show']);
    Route::post('/projects', [ProjectController::class, 'store']);
    Route::put('/projects/{id}', [ProjectController::class, 'update']);
    Route::delete('/projects/{id}', [ProjectController::class, 'destroy']);
    
    // Tasks
    Route::get('/tasks', [TaskController::class, 'index']);
    Route::get('/projects/{projectId}/tasks/{taskId}', [TaskController::class, 'show']);
    Route::post('/projects/{projectId}/tasks', [TaskController::class, 'store']);
    Route::put('/projects/{projectId}/tasks/{taskId}', [TaskController::class, 'update']);
    Route::delete('/projects/{projectId}/tasks/{taskId}', [TaskController::class, 'destroy']);
    
    // Admin Routes (protected by admin role)
    Route::prefix('admin')->middleware('role:admin')->group(function () {
        Route::get('/users', [\App\Http\Controllers\Admin\AdminController::class, 'getUsers']);
        Route::put('/users/{userId}/role', [\App\Http\Controllers\Admin\AdminController::class, 'updateUserRole']);
        Route::delete('/users/{userId}', [\App\Http\Controllers\Admin\AdminController::class, 'deleteUser']);
        Route::get('/health', [\App\Http\Controllers\Admin\AdminController::class, 'getSystemHealth']);
        Route::get('/logs', [\App\Http\Controllers\Admin\AdminController::class, 'getSystemLogs']);
    });
});
