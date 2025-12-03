<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class UserController extends Controller
{
    public function getManagers()
    {
        try {
            $managers = User::whereHas('roles', function ($query) {
                $query->where('name', 'manager');
            })->get(['id', 'name', 'email']);

            return response()->json(['managers' => $managers]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch managers', ['error' => $e->getMessage()]);
            return response()->json([
                'error' => 'Failed to fetch managers: ' . $e->getMessage(),
                'managers' => []
            ], 500);
        }
    }

    public function getEmployees()
    {
        try {
            $employees = User::whereHas('roles', function ($query) {
                $query->where('name', 'employee');
            })->get(['id', 'name', 'email']);

            return response()->json(['employees' => $employees]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch employees', ['error' => $e->getMessage()]);
            return response()->json([
                'error' => 'Failed to fetch employees: ' . $e->getMessage(),
                'employees' => []
            ], 500);
        }
    }

    /**
     * Get all users (for admin panel)
     */
    public function getAllUsers()
    {
        try {
            $users = User::with('roles')->orderBy('created_at', 'desc')->get();
            return response()->json(['users' => $users]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch all users', ['error' => $e->getMessage()]);
            return response()->json([
                'error' => 'Failed to fetch users: ' . $e->getMessage(),
                'users' => []
            ], 500);
        }
    }
}
