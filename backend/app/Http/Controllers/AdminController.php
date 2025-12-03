<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Services\FirestoreService;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Kreait\Firebase\Exception\FirebaseException;

class AdminController extends Controller
{
    protected $firestoreService;

    public function __construct(FirestoreService $firestoreService)
    {
        $this->middleware(['auth', 'role:admin']);
        $this->firestoreService = $firestoreService;
    }

    /**
     * Show the admin dashboard
     */
    public function dashboard()
    {
        try {
            // Get system statistics
            $stats = [
                'total_users' => User::count(),
                'admin_users' => User::role('admin')->count(),
                'manager_users' => User::role('manager')->count(),
                'employee_users' => User::role('employee')->count(),
                'total_roles' => Role::count(),
                'total_permissions' => Permission::count(),
            ];

            // Get Firestore statistics
            try {
                $projects = $this->firestoreService->getAllProjects();
                $projectCount = 0;
                $taskCount = 0;
                $activeProjects = 0;
                $completedProjects = 0;

                foreach ($projects as $project) {
                    $projectCount++;
                    $projectData = $project->data();
                    
                    if (($projectData['status'] ?? 'active') === 'active') {
                        $activeProjects++;
                    } else if (($projectData['status'] ?? '') === 'completed') {
                        $completedProjects++;
                    }

                    // Count tasks in this project
                    $tasks = $this->firestoreService->getProjectTasks($project->id());
                    foreach ($tasks as $task) {
                        $taskCount++;
                    }
                }

                $stats['total_projects'] = $projectCount;
                $stats['total_tasks'] = $taskCount;
                $stats['active_projects'] = $activeProjects;
                $stats['completed_projects'] = $completedProjects;
            } catch (FirebaseException $e) {
                Log::error('Failed to fetch Firestore stats: ' . $e->getMessage());
                $stats['total_projects'] = 'N/A';
                $stats['total_tasks'] = 'N/A';
                $stats['active_projects'] = 'N/A';
                $stats['completed_projects'] = 'N/A';
            }

            // Get recent users
            $recentUsers = User::with('roles')
                ->orderBy('created_at', 'desc')
                ->take(5)
                ->get();

            return view('admin.dashboard', compact('stats', 'recentUsers'));
        } catch (\Exception $e) {
            Log::error('Admin dashboard error: ' . $e->getMessage());
            return back()->withErrors(['error' => 'Failed to load admin dashboard']);
        }
    }

    /**
     * Show all users with role management
     */
    public function users(Request $request)
    {
        $query = User::with('roles', 'permissions');

        // Filter by role if specified
        if ($request->has('role') && $request->role !== '') {
            $query->role($request->role);
        }

        // Search by name or email
        if ($request->has('search') && $request->search !== '') {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $users = $query->orderBy('created_at', 'desc')->paginate(15);
        $roles = Role::all();

        if ($request->expectsJson()) {
            return response()->json([
                'users' => $users,
                'roles' => $roles
            ]);
        }

        return view('admin.users', compact('users', 'roles'));
    }

    /**
     * Assign role to user
     */
    public function assignRole(Request $request, User $user)
    {
        $validator = Validator::make($request->all(), [
            'role' => 'required|exists:roles,name'
        ]);

        if ($validator->fails()) {
            if ($request->expectsJson()) {
                return response()->json(['errors' => $validator->errors()], 422);
            }
            return back()->withErrors($validator);
        }

        try {
            // Remove all existing roles and assign the new one
            $user->syncRoles([$request->role]);

            $message = "Role '{$request->role}' assigned to {$user->name} successfully.";
            Log::info("Admin role assignment: {$message}", [
                'admin_id' => auth()->id(),
                'user_id' => $user->id,
                'new_role' => $request->role
            ]);

            if ($request->expectsJson()) {
                return response()->json(['message' => $message]);
            }

            return back()->with('success', $message);
        } catch (\Exception $e) {
            Log::error('Role assignment failed: ' . $e->getMessage());
            
            if ($request->expectsJson()) {
                return response()->json(['error' => 'Failed to assign role'], 500);
            }
            
            return back()->withErrors(['error' => 'Failed to assign role']);
        }
    }

    /**
     * Delete a user
     */
    public function deleteUser(User $user)
    {
        try {
            // Prevent deleting yourself
            if ($user->id === auth()->id()) {
                if (request()->expectsJson()) {
                    return response()->json(['error' => 'You cannot delete your own account'], 403);
                }
                return back()->withErrors(['error' => 'You cannot delete your own account']);
            }

            // Prevent deleting other admins
            if ($user->hasRole('admin')) {
                if (request()->expectsJson()) {
                    return response()->json(['error' => 'Cannot delete admin users'], 403);
                }
                return back()->withErrors(['error' => 'Cannot delete admin users']);
            }

            $userName = $user->name;
            $user->delete();

            Log::info("User deleted: {$userName}", [
                'admin_id' => auth()->id(),
                'deleted_user_id' => $user->id
            ]);

            if (request()->expectsJson()) {
                return response()->json(['message' => "User '{$userName}' deleted successfully"]);
            }

            return back()->with('success', "User '{$userName}' deleted successfully");
        } catch (\Exception $e) {
            Log::error('User deletion failed: ' . $e->getMessage());
            
            if (request()->expectsJson()) {
                return response()->json(['error' => 'Failed to delete user'], 500);
            }
            
            return back()->withErrors(['error' => 'Failed to delete user']);
        }
    }

    /**
     * Show system logs
     */
    public function logs(Request $request)
    {
        try {
            $logFile = storage_path('logs/laravel.log');
            $logs = [];

            if (file_exists($logFile)) {
                $logContent = file_get_contents($logFile);
                $logLines = explode("\n", $logContent);
                
                // Get last 100 log entries
                $logLines = array_slice(array_reverse($logLines), 0, 100);
                
                foreach ($logLines as $line) {
                    if (empty(trim($line))) continue;
                    
                    // Parse log line (basic parsing)
                    if (preg_match('/\[(.*?)\] (.+?)\.(.+?): (.+)/', $line, $matches)) {
                        $logs[] = [
                            'timestamp' => $matches[1],
                            'level' => $matches[3],
                            'message' => $matches[4],
                            'full_line' => $line
                        ];
                    } else {
                        $logs[] = [
                            'timestamp' => 'Unknown',
                            'level' => 'info',
                            'message' => $line,
                            'full_line' => $line
                        ];
                    }
                }
            }

            // Filter by level if specified
            if ($request->has('level') && $request->level !== '') {
                $logs = array_filter($logs, function ($log) use ($request) {
                    return stripos($log['level'], $request->level) !== false;
                });
            }

            if ($request->expectsJson()) {
                return response()->json(['logs' => $logs]);
            }

            return view('admin.logs', compact('logs'));
        } catch (\Exception $e) {
            Log::error('Failed to read logs: ' . $e->getMessage());
            
            if ($request->expectsJson()) {
                return response()->json(['error' => 'Failed to read logs'], 500);
            }
            
            return back()->withErrors(['error' => 'Failed to read system logs']);
        }
    }

    /**
     * Get system health status
     */
    public function systemHealth(Request $request)
    {
        $health = [
            'database' => $this->checkDatabaseConnection(),
            'firebase' => $this->checkFirebaseConnection(),
            'storage' => $this->checkStorageHealth(),
            'logs' => $this->checkLogHealth()
        ];

        $overallHealth = array_reduce($health, function ($carry, $status) {
            return $carry && $status['status'] === 'ok';
        }, true);

        if ($request->expectsJson()) {
            return response()->json([
                'overall' => $overallHealth ? 'healthy' : 'issues',
                'components' => $health
            ]);
        }

        return view('admin.health', compact('health', 'overallHealth'));
    }

    private function checkDatabaseConnection()
    {
        try {
            User::count();
            return ['status' => 'ok', 'message' => 'Database connection successful'];
        } catch (\Exception $e) {
            return ['status' => 'error', 'message' => 'Database connection failed: ' . $e->getMessage()];
        }
    }

    private function checkFirebaseConnection()
    {
        try {
            $this->firestoreService->getAllProjects();
            return ['status' => 'ok', 'message' => 'Firebase connection successful'];
        } catch (FirebaseException $e) {
            return ['status' => 'error', 'message' => 'Firebase connection failed: ' . $e->getMessage()];
        }
    }

    private function checkStorageHealth()
    {
        try {
            $testFile = 'health_check.txt';
            Storage::put($testFile, 'Health check');
            $exists = Storage::exists($testFile);
            Storage::delete($testFile);
            
            return $exists ? 
                ['status' => 'ok', 'message' => 'Storage is working correctly'] :
                ['status' => 'error', 'message' => 'Storage write/read failed'];
        } catch (\Exception $e) {
            return ['status' => 'error', 'message' => 'Storage check failed: ' . $e->getMessage()];
        }
    }

    private function checkLogHealth()
    {
        try {
            $logFile = storage_path('logs/laravel.log');
            $writable = is_writable(dirname($logFile));
            
            return $writable ?
                ['status' => 'ok', 'message' => 'Log directory is writable'] :
                ['status' => 'warning', 'message' => 'Log directory is not writable'];
        } catch (\Exception $e) {
            return ['status' => 'error', 'message' => 'Log check failed: ' . $e->getMessage()];
        }
    }
}
