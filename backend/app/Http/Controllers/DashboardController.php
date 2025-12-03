<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Kreait\Firebase\Exception\FirebaseException;

class DashboardController extends Controller
{
    protected $firestoreService;

    public function __construct(FirestoreService $firestoreService)
    {
        $this->firestoreService = $firestoreService;
    }

    public function stats(Request $request)
    {
        $user = $request->user();
        $stats = [];

        try {
            // Check user roles
            $roles = $user->roles->pluck('name')->toArray();
            
            if (in_array('admin', $roles)) {
                // Admin stats - count from Firestore
                $projects = $this->firestoreService->getAllProjects();
                
                $totalProjects = 0;
                $totalTasks = 0;
                $completedTasks = 0;
                $inProgressTasks = 0;
                $pendingTasks = 0;
                
                foreach ($projects as $project) {
                    $totalProjects++;
                    $tasks = $this->firestoreService->getProjectTasks($project->id());
                    foreach ($tasks as $taskDoc) {
                        $taskData = $taskDoc->data();
                        $totalTasks++;
                        
                        $status = $taskData['status'] ?? 'pending';
                        if ($status === 'completed') $completedTasks++;
                        elseif ($status === 'in-progress') $inProgressTasks++;
                        elseif ($status === 'pending') $pendingTasks++;
                    }
                }
                
                $stats = [
                    'total_users' => User::count(),
                    'total_projects' => $totalProjects,
                    'total_tasks' => $totalTasks,
                    'completed_tasks' => $completedTasks,
                    'in_progress_tasks' => $inProgressTasks,
                    'pending_tasks' => $pendingTasks,
                ];
            } elseif (in_array('manager', $roles)) {
                // Manager stats
                $projects = $this->firestoreService->getAllProjects();
                $myProjects = 0;
                $activeProjects = 0;
                $totalTasks = 0;
                $completedTasks = 0;
                $inProgressTasks = 0;
                $pendingTasks = 0;
                
                foreach ($projects as $project) {
                    $projectData = $project->data();
                    $assignedManager = $projectData['assigned_manager'] ?? null;
                    
                    if ($assignedManager && (int)$assignedManager === (int)$user->id) {
                        $myProjects++;
                        if (($projectData['status'] ?? '') === 'active') {
                            $activeProjects++;
                        }
                        
                        // Count tasks for this manager's projects
                        $tasks = $this->firestoreService->getProjectTasks($project->id());
                        foreach ($tasks as $taskDoc) {
                            $taskData = $taskDoc->data();
                            $totalTasks++;
                            
                            $status = $taskData['status'] ?? 'pending';
                            if ($status === 'completed') $completedTasks++;
                            elseif ($status === 'in-progress') $inProgressTasks++;
                            elseif ($status === 'pending') $pendingTasks++;
                        }
                    }
                }
                
                $stats = [
                    'my_projects' => $myProjects,
                    'active_projects' => $activeProjects,
                    'total_tasks' => $totalTasks,
                    'completed_tasks' => $completedTasks,
                    'in_progress_tasks' => $inProgressTasks,
                    'pending_tasks' => $pendingTasks,
                    'team_members' => User::whereHas('roles', function ($query) {
                        $query->where('name', 'employee');
                    })->count(),
                ];
            } else {
                // Employee stats
                $myTasks = 0;
                $completedTasks = 0;
                $inProgressTasks = 0;
                $pendingTasks = 0;
                $highPriorityTasks = 0;
                $mediumPriorityTasks = 0;
                $lowPriorityTasks = 0;
                
                $projects = $this->firestoreService->getAllProjects();
                
                foreach ($projects as $project) {
                    $tasks = $this->firestoreService->getProjectTasks($project->id());
                    foreach ($tasks as $taskDoc) {
                        $taskData = $taskDoc->data();
                        $assignedTo = $taskData['assigned_to'] ?? null;
                        
                        if ($assignedTo && (int)$assignedTo === (int)$user->id) {
                            $myTasks++;
                            
                            $status = $taskData['status'] ?? 'pending';
                            if ($status === 'completed') $completedTasks++;
                            elseif ($status === 'in-progress') $inProgressTasks++;
                            elseif ($status === 'pending') $pendingTasks++;
                            
                            $priority = $taskData['priority'] ?? 'medium';
                            if ($priority === 'high') $highPriorityTasks++;
                            elseif ($priority === 'medium') $mediumPriorityTasks++;
                            elseif ($priority === 'low') $lowPriorityTasks++;
                        }
                    }
                }
                
                $stats = [
                    'my_tasks' => $myTasks,
                    'completed_tasks' => $completedTasks,
                    'in_progress_tasks' => $inProgressTasks,
                    'pending_tasks' => $pendingTasks,
                    'high_priority_tasks' => $highPriorityTasks,
                    'medium_priority_tasks' => $mediumPriorityTasks,
                    'low_priority_tasks' => $lowPriorityTasks,
                ];
            }
        } catch (FirebaseException|\Exception $e) {
            // Return empty stats if Firebase is not configured
            \Log::warning('Firebase connection failed in dashboard stats', [
                'error' => $e->getMessage(),
                'user_id' => $user->id
            ]);
            
            $stats = [
                'error' => 'Firebase connection failed: ' . $e->getMessage(),
                'total_users' => User::count(),
                'total_projects' => 0,
                'total_tasks' => 0,
                'completed_tasks' => 0,
                'in_progress_tasks' => 0,
                'pending_tasks' => 0,
            ];
        }

        return response()->json($stats);
    }
}
