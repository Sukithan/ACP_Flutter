<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Task;
use App\Models\User;
use App\Services\FirestoreService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Kreait\Firebase\Exception\FirebaseException;

class TaskController extends Controller
{
    protected $firestoreService;

    public function __construct(FirestoreService $firestoreService)
    {
        $this->middleware('auth');
        $this->firestoreService = $firestoreService;
    }

    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $this->authorize('viewAny', Task::class);

        try {
            $user = Auth::user();
            $tasks = [];
            
            if ($user->hasRole('employee')) {
                // Employees only see their own tasks
                $tasks = $this->firestoreService->getTasksAssignedToUser($user->id);
            } elseif ($user->hasRole('manager')) {
                // Managers only see tasks from their assigned projects
                $projects = $this->firestoreService->getAllProjects();
                
                foreach ($projects as $project) {
                    $projectData = $project->data();
                    $assignedManager = $projectData['assigned_manager'] ?? null;
                    
                    // Only include tasks from projects this manager is assigned to
                    if ($assignedManager && (int)$assignedManager === (int)$user->id) {
                        $projectTasks = $this->firestoreService->getProjectTasks($project->id());
                        foreach ($projectTasks as $taskDoc) {
                            $taskData = $taskDoc->data();
                            $taskData['id'] = $taskDoc->id();
                            $taskData['project_id'] = $project->id();
                            $taskData['project_name'] = $projectData['name'] ?? 'Unknown Project';
                            
                            // Get assigned user name
                            if (isset($taskData['assigned_to'])) {
                                $taskUser = User::find($taskData['assigned_to']);
                                $taskData['assigned_to_name'] = $taskUser ? $taskUser->name : 'Unknown User';
                            }
                            
                            $tasks[] = $taskData;
                        }
                    }
                }
            } else {
                // Admin sees all tasks
                $projects = $this->firestoreService->getAllProjects();
                
                foreach ($projects as $project) {
                    $projectTasks = $this->firestoreService->getProjectTasks($project->id());
                    foreach ($projectTasks as $taskDoc) {
                        $taskData = $taskDoc->data();
                        $taskData['id'] = $taskDoc->id();
                        $taskData['project_id'] = $project->id();
                        $taskData['project_name'] = $project->data()['name'] ?? 'Unknown Project';
                        
                        // Get assigned user name
                        if (isset($taskData['assigned_to'])) {
                            $taskUser = User::find($taskData['assigned_to']);
                            $taskData['assigned_to_name'] = $taskUser ? $taskUser->name : 'Unknown User';
                        }
                        
                        $tasks[] = $taskData;
                    }
                }
            }

            if ($request->expectsJson()) {
                return response()->json(['tasks' => $tasks]);
            }

            return view('tasks.index', compact('tasks'));
        } catch (FirebaseException|\Exception $e) {
            $errorMessage = 'Firebase configuration incomplete. Please follow FIREBASE_SETUP.md to configure Firebase properly.';
            $tasks = [];
            
            if ($request->expectsJson()) {
                return response()->json(['tasks' => $tasks], 200);
            }
            return view('tasks.index', compact('tasks'))->with('warning', $errorMessage);
        }
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create($projectId)
    {
        $this->authorize('create', Task::class);

        try {
            $firestoreProject = $this->firestoreService->getProject($projectId);
            
            if (!$firestoreProject->exists()) {
                abort(404, 'Project not found');
            }

            $projectData = $firestoreProject->data();
            $employees = User::role('employee')->get();
            
            return view('tasks.create', compact('projectId', 'projectData', 'employees'));
        } catch (FirebaseException $e) {
            return back()->withErrors(['error' => 'Failed to fetch project']);
        }
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request, $projectId)
    {
        $this->authorize('create', Task::class);

        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'required|string|max:1000',
            'assigned_to' => 'required|exists:users,id',
            'due_date' => 'nullable|date|after:today',
            'priority' => 'in:low,medium,high',
            'status' => 'in:pending,in-progress,completed',
        ]);

        if ($validator->fails()) {
            if ($request->expectsJson()) {
                return response()->json(['errors' => $validator->errors()], 422);
            }
            return back()->withErrors($validator)->withInput();
        }

        // Verify assigned user has employee role
        $assignedUser = User::find($request->assigned_to);
        if (!$assignedUser->hasRole('employee')) {
            if ($request->expectsJson()) {
                return response()->json(['error' => 'Tasks can only be assigned to employees'], 422);
            }
            return back()->withErrors(['assigned_to' => 'Tasks can only be assigned to employees'])->withInput();
        }

        try {
            $taskData = [
                'title' => $request->title,
                'description' => $request->description,
                'assigned_to' => (int) $request->assigned_to,
                'created_by' => (int) Auth::id(),
                'due_date' => $request->due_date,
                'priority' => $request->priority ?? 'medium',
                'status' => $request->status ?? 'pending',
            ];

            // Store in Firestore
            $firestoreDoc = $this->firestoreService->createTask($projectId, $taskData);

            if ($request->expectsJson()) {
                return response()->json([
                    'message' => 'Task created successfully',
                    'task' => array_merge($taskData, ['id' => $firestoreDoc->id()])
                ], 201);
            }

            return redirect()->route('projects.show', $projectId)
                ->with('success', 'Task created successfully!');
        } catch (FirebaseException $e) {
            if ($request->expectsJson()) {
                return response()->json(['error' => 'Failed to create task'], 500);
            }
            return back()->withErrors(['error' => 'Failed to create task'])->withInput();
        }
    }

    /**
     * Display the specified resource.
     */
    public function show($projectId, $taskId)
    {
        try {
            $firestoreTask = $this->firestoreService->getTask($projectId, $taskId);
            
            if (!$firestoreTask->exists()) {
                abort(404, 'Task not found');
            }

            $taskData = $firestoreTask->data();
            
            // Create a temporary Task model for policy check
            $task = new Task([
                'firestore_id' => $taskId,
                'project_firestore_id' => $projectId,
                'assigned_to' => $taskData['assigned_to'] ?? null,
                'created_by' => $taskData['created_by'] ?? null,
            ]);

            $this->authorize('view', $task);

            $taskData['id'] = $taskId;
            $taskData['project_id'] = $projectId;

            // Get assigned user name
            if (isset($taskData['assigned_to'])) {
                $user = User::find($taskData['assigned_to']);
                $taskData['assigned_to_name'] = $user ? $user->name : 'Unknown User';
            }

            // Get created by user name
            if (isset($taskData['created_by'])) {
                $createdByUser = User::find($taskData['created_by']);
                $taskData['created_by_name'] = $createdByUser ? $createdByUser->name : 'Unknown User';
            }

            // Get project details
            $firestoreProject = $this->firestoreService->getProject($projectId);
            $projectData = $firestoreProject->exists() ? $firestoreProject->data() : null;
            $taskData['project_name'] = $projectData ? ($projectData['name'] ?? 'Unknown Project') : 'Unknown Project';

            if (request()->expectsJson()) {
                return response()->json([
                    'task' => $taskData,
                    'project' => $projectData
                ]);
            }

            return view('tasks.show', compact('taskData', 'projectData'));
        } catch (FirebaseException $e) {
            if (request()->expectsJson()) {
                return response()->json(['error' => 'Failed to fetch task'], 500);
            }
            return back()->withErrors(['error' => 'Failed to fetch task']);
        }
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $projectId, $taskId)
    {
        try {
            $firestoreTask = $this->firestoreService->getTask($projectId, $taskId);
            
            if (!$firestoreTask->exists()) {
                abort(404, 'Task not found');
            }

            $currentData = $firestoreTask->data();
            
            // Create a temporary Task model for policy check
            $task = new Task([
                'firestore_id' => $taskId,
                'project_firestore_id' => $projectId,
                'assigned_to' => $currentData['assigned_to'] ?? null,
                'created_by' => $currentData['created_by'] ?? null,
            ]);

            $this->authorize('update', $task);

            $validator = Validator::make($request->all(), [
                'title' => 'sometimes|required|string|max:255',
                'description' => 'sometimes|required|string|max:1000',
                'assigned_to' => 'sometimes|required|exists:users,id',
                'due_date' => 'nullable|date|after:today',
                'priority' => 'sometimes|in:low,medium,high',
                'status' => 'sometimes|in:pending,in-progress,completed',
            ]);

            if ($validator->fails()) {
                if ($request->expectsJson()) {
                    return response()->json(['errors' => $validator->errors()], 422);
                }
                return back()->withErrors($validator)->withInput();
            }

            $updateData = $request->only(['title', 'description', 'due_date', 'priority', 'status']);

            // Only managers/admins can reassign tasks
            if ($request->has('assigned_to') && Auth::user()->hasPermissionTo('assign tasks')) {
                $assignedUser = User::find($request->assigned_to);
                if (!$assignedUser->hasRole('employee')) {
                    if ($request->expectsJson()) {
                        return response()->json(['error' => 'Tasks can only be assigned to employees'], 422);
                    }
                    return back()->withErrors(['assigned_to' => 'Tasks can only be assigned to employees'])->withInput();
                }
                $updateData['assigned_to'] = (int) $request->assigned_to;
            }

            // Update in Firestore
            $this->firestoreService->updateTask($projectId, $taskId, $updateData);

            if ($request->expectsJson()) {
                return response()->json(['message' => 'Task updated successfully']);
            }

            return redirect()->route('tasks.show', [$projectId, $taskId])
                ->with('success', 'Task updated successfully!');
        } catch (FirebaseException $e) {
            if ($request->expectsJson()) {
                return response()->json(['error' => 'Failed to update task'], 500);
            }
            return back()->withErrors(['error' => 'Failed to update task'])->withInput();
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($projectId, $taskId)
    {
        try {
            $firestoreTask = $this->firestoreService->getTask($projectId, $taskId);
            
            if (!$firestoreTask->exists()) {
                abort(404, 'Task not found');
            }

            $taskData = $firestoreTask->data();
            
            // Create a temporary Task model for policy check
            $task = new Task([
                'firestore_id' => $taskId,
                'project_firestore_id' => $projectId,
                'assigned_to' => $taskData['assigned_to'] ?? null,
                'created_by' => $taskData['created_by'] ?? null,
            ]);

            $this->authorize('delete', $task);

            // Delete from Firestore
            $this->firestoreService->deleteTask($projectId, $taskId);

            if (request()->expectsJson()) {
                return response()->json(['message' => 'Task deleted successfully']);
            }

            return redirect()->route('projects.show', $projectId)
                ->with('success', 'Task deleted successfully!');
        } catch (FirebaseException $e) {
            if (request()->expectsJson()) {
                return response()->json(['error' => 'Failed to delete task'], 500);
            }
            return back()->withErrors(['error' => 'Failed to delete task']);
        }
    }
}
