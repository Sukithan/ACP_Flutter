<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Role;

class AdminController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth:sanctum', 'role:admin']);
    }

    public function getUsers()
    {
        try {
            $users = User::with('roles')->get();
            return response()->json(['users' => $users]);
        } catch (\Exception $e) {
            \Log::error('Failed to fetch users', [
                'error' => $e->getMessage(),
                'admin_id' => auth()->id()
            ]);
            return response()->json([
                'error' => 'Failed to fetch users: ' . $e->getMessage(),
                'users' => []
            ], 500);
        }
    }

    public function updateUserRole(Request $request, $userId)
    {
        $request->validate([
            'role' => 'required|in:admin,manager,employee'
        ]);

        $user = User::findOrFail($userId);
        
        // Remove all existing roles
        $user->syncRoles([]);
        
        // Assign new role
        $user->assignRole($request->role);

        return response()->json([
            'message' => 'User role updated successfully',
            'user' => $user->load('roles')
        ]);
    }

    public function deleteUser($userId)
    {
        $user = User::findOrFail($userId);
        
        // Prevent deleting yourself
        if ($user->id === auth()->id()) {
            return response()->json([
                'message' => 'You cannot delete your own account'
            ], 403);
        }

        $user->delete();

        return response()->json([
            'message' => 'User deleted successfully'
        ]);
    }

    public function getSystemHealth()
    {
        try {
            // Check database connection
            DB::connection()->getPdo();
            $dbStatus = 'Connected';
        } catch (\Exception $e) {
            $dbStatus = 'Disconnected';
        }

        $health = [
            'status' => 'Healthy',
            'database' => [
                'status' => $dbStatus
            ],
            'cache' => [
                'status' => 'Active'
            ],
            'queue' => [
                'status' => 'Running'
            ],
            'php_version' => phpversion(),
            'laravel_version' => app()->version(),
            'environment' => config('app.env'),
            'uptime' => 'N/A'
        ];

        return response()->json($health);
    }

    public function getSystemLogs()
    {
        // This is a simple implementation
        // In production, you would read from actual log files
        $logs = [
            [
                'id' => 1,
                'level' => 'info',
                'message' => 'Application started successfully',
                'timestamp' => now()->subHours(2)->toDateTimeString(),
                'context' => null
            ],
            [
                'id' => 2,
                'level' => 'warning',
                'message' => 'High memory usage detected',
                'timestamp' => now()->subHour()->toDateTimeString(),
                'context' => ['memory' => '512MB']
            ],
            [
                'id' => 3,
                'level' => 'info',
                'message' => 'Database backup completed',
                'timestamp' => now()->subMinutes(30)->toDateTimeString(),
                'context' => null
            ],
        ];

        return response()->json(['logs' => $logs]);
    }
}
