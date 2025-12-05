<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\FirestoreService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class TeamController extends Controller
{
    protected $firestoreService;

    public function __construct(FirestoreService $firestoreService)
    {
        $this->middleware('auth');
        $this->firestoreService = $firestoreService;
    }

    /**
     * Get team members based on user role
     */
    public function getTeamMembers(Request $request)
    {
        try {
            $user = Auth::user();
            $teamMembers = [];

            if ($user->hasRole('admin')) {
                // Admins see all users with their roles
                $teamMembers = User::with('roles')
                    ->where('id', '!=', $user->id) // Exclude self
                    ->get(['id', 'name', 'email', 'created_at'])
                    ->map(function ($member) {
                        return [
                            'id' => $member->id,
                            'name' => $member->name,
                            'email' => $member->email,
                            'role' => $member->roles->first()->name ?? 'No Role',
                            'joined_at' => $member->created_at->format('M d, Y'),
                            'projects_count' => $this->getUserProjectsCount($member->id),
                            'tasks_count' => $this->getUserTasksCount($member->id),
                        ];
                    });

            } elseif ($user->hasRole('manager')) {
                // Managers see employees in their projects + other managers
                $managerProjects = $this->getManagerProjects($user->id);
                $employeeIds = $this->getEmployeesFromProjects($managerProjects);
                
                // Get employees from managed projects
                $employees = User::whereIn('id', $employeeIds)
                    ->with('roles')
                    ->get(['id', 'name', 'email', 'created_at']);

                // Get other managers
                $otherManagers = User::whereHas('roles', function ($query) {
                        $query->where('name', 'manager');
                    })
                    ->where('id', '!=', $user->id)
                    ->with('roles')
                    ->get(['id', 'name', 'email', 'created_at']);

                $allMembers = $employees->merge($otherManagers);

                $teamMembers = $allMembers->map(function ($member) {
                    return [
                        'id' => $member->id,
                        'name' => $member->name,
                        'email' => $member->email,
                        'role' => $member->roles->first()->name ?? 'No Role',
                        'joined_at' => $member->created_at->format('M d, Y'),
                        'projects_count' => $this->getUserProjectsCount($member->id),
                        'tasks_count' => $this->getUserTasksCount($member->id),
                    ];
                });

            } elseif ($user->hasRole('employee')) {
                // Employees see colleagues from the same projects
                $userProjects = $this->getEmployeeProjects($user->id);
                $colleagueIds = $this->getColleaguesFromProjects($userProjects, $user->id);
                
                $colleagues = User::whereIn('id', $colleagueIds)
                    ->with('roles')
                    ->get(['id', 'name', 'email', 'created_at']);

                $teamMembers = $colleagues->map(function ($member) {
                    return [
                        'id' => $member->id,
                        'name' => $member->name,
                        'email' => $member->email,
                        'role' => $member->roles->first()->name ?? 'No Role',
                        'joined_at' => $member->created_at->format('M d, Y'),
                        'shared_projects' => $this->getSharedProjectsCount($member->id, Auth::id()),
                        'tasks_count' => $this->getUserTasksCount($member->id),
                    ];
                });
            }

            return response()->json([
                'team_members' => $teamMembers->values(),
                'total_count' => $teamMembers->count(),
                'user_role' => $user->roles->first()->name ?? 'No Role'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to fetch team members', [
                'error' => $e->getMessage(),
                'user_id' => $user->id ?? null
            ]);
            
            return response()->json([
                'error' => 'Failed to fetch team members: ' . $e->getMessage(),
                'team_members' => [],
                'total_count' => 0
            ], 500);
        }
    }

    /**
     * Get projects managed by a manager
     */
    private function getManagerProjects($managerId)
    {
        try {
            $projects = $this->firestoreService->getAllProjects();
            $managerProjects = [];

            foreach ($projects as $project) {
                $data = $project->data();
                if (isset($data['assigned_manager']) && (int)$data['assigned_manager'] === (int)$managerId) {
                    $managerProjects[] = $project->id();
                }
            }

            return $managerProjects;
        } catch (\Exception $e) {
            Log::error('Failed to get manager projects', ['error' => $e->getMessage()]);
            return [];
        }
    }

    /**
     * Get projects where an employee has tasks
     */
    private function getEmployeeProjects($employeeId)
    {
        try {
            $projects = $this->firestoreService->getAllProjects();
            $employeeProjects = [];

            foreach ($projects as $project) {
                $tasks = $this->firestoreService->getProjectTasks($project->id());
                
                foreach ($tasks as $task) {
                    $taskData = $task->data();
                    if (isset($taskData['assigned_to']) && (int)$taskData['assigned_to'] === (int)$employeeId) {
                        $employeeProjects[] = $project->id();
                        break; // Found at least one task, move to next project
                    }
                }
            }

            return array_unique($employeeProjects);
        } catch (\Exception $e) {
            Log::error('Failed to get employee projects', ['error' => $e->getMessage()]);
            return [];
        }
    }

    /**
     * Get employee IDs from projects
     */
    private function getEmployeesFromProjects($projectIds)
    {
        try {
            $employeeIds = [];

            foreach ($projectIds as $projectId) {
                $tasks = $this->firestoreService->getProjectTasks($projectId);
                
                foreach ($tasks as $task) {
                    $taskData = $task->data();
                    if (isset($taskData['assigned_to'])) {
                        $employeeIds[] = (int)$taskData['assigned_to'];
                    }
                }
            }

            return array_unique($employeeIds);
        } catch (\Exception $e) {
            Log::error('Failed to get employees from projects', ['error' => $e->getMessage()]);
            return [];
        }
    }

    /**
     * Get colleague IDs from shared projects
     */
    private function getColleaguesFromProjects($projectIds, $currentUserId)
    {
        try {
            $colleagueIds = [];

            foreach ($projectIds as $projectId) {
                $tasks = $this->firestoreService->getProjectTasks($projectId);
                
                foreach ($tasks as $task) {
                    $taskData = $task->data();
                    if (isset($taskData['assigned_to']) && (int)$taskData['assigned_to'] !== (int)$currentUserId) {
                        $colleagueIds[] = (int)$taskData['assigned_to'];
                    }
                }

                // Also get the project manager
                $project = $this->firestoreService->getProject($projectId);
                if ($project->exists()) {
                    $projectData = $project->data();
                    if (isset($projectData['assigned_manager']) && (int)$projectData['assigned_manager'] !== (int)$currentUserId) {
                        $colleagueIds[] = (int)$projectData['assigned_manager'];
                    }
                }
            }

            return array_unique($colleagueIds);
        } catch (\Exception $e) {
            Log::error('Failed to get colleagues from projects', ['error' => $e->getMessage()]);
            return [];
        }
    }

    /**
     * Get count of projects for a user
     */
    private function getUserProjectsCount($userId)
    {
        try {
            $projects = $this->firestoreService->getAllProjects();
            $count = 0;

            foreach ($projects as $project) {
                $data = $project->data();
                
                // Count if user is manager
                if (isset($data['assigned_manager']) && (int)$data['assigned_manager'] === (int)$userId) {
                    $count++;
                    continue;
                }

                // Count if user has tasks in project
                $tasks = $this->firestoreService->getProjectTasks($project->id());
                foreach ($tasks as $task) {
                    $taskData = $task->data();
                    if (isset($taskData['assigned_to']) && (int)$taskData['assigned_to'] === (int)$userId) {
                        $count++;
                        break;
                    }
                }
            }

            return $count;
        } catch (\Exception $e) {
            return 0;
        }
    }

    /**
     * Get count of tasks for a user
     */
    private function getUserTasksCount($userId)
    {
        try {
            $projects = $this->firestoreService->getAllProjects();
            $count = 0;

            foreach ($projects as $project) {
                $tasks = $this->firestoreService->getProjectTasks($project->id());
                foreach ($tasks as $task) {
                    $taskData = $task->data();
                    if (isset($taskData['assigned_to']) && (int)$taskData['assigned_to'] === (int)$userId) {
                        $count++;
                    }
                }
            }

            return $count;
        } catch (\Exception $e) {
            return 0;
        }
    }

    /**
     * Get count of shared projects between two users
     */
    private function getSharedProjectsCount($userId1, $userId2)
    {
        try {
            $user1Projects = $this->getEmployeeProjects($userId1);
            $user2Projects = $this->getEmployeeProjects($userId2);
            
            return count(array_intersect($user1Projects, $user2Projects));
        } catch (\Exception $e) {
            return 0;
        }
    }
}