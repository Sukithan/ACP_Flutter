<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Project;
use App\Models\User;
use App\Services\FirestoreService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Kreait\Firebase\Exception\FirebaseException;

class ProjectController extends Controller
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
    public function index()
    {
        // Check if user can view projects
        $this->authorize('viewAny', Project::class);

        try {
            $firestoreProjects = $this->firestoreService->getAllProjects();
            $projects = [];
            $user = Auth::user();

            foreach ($firestoreProjects as $doc) {
                $data = $doc->data();
                $data['id'] = $doc->id();

                if ($user->hasRole('employee')) {
                    // Filter for employees: only include projects with tasks assigned to them
                    $projectTasks = $this->firestoreService->getProjectTasks($doc->id());
                    $hasAssignedTask = false;

                    foreach ($projectTasks as $taskDoc) {
                        $taskData = $taskDoc->data();
                        if (isset($taskData['assigned_to']) && (int)$taskData['assigned_to'] === (int)$user->id) {
                            $hasAssignedTask = true;
                            break;
                        }
                    }

                    if ($hasAssignedTask) {
                        $projects[] = $data;
                    }
                } elseif ($user->hasRole('manager')) {
                    // Filter for managers: only include projects they manage
                    if (isset($data['assigned_manager']) && (int)$data['assigned_manager'] === (int)$user->id) {
                        $projects[] = $data;
                    }
                } else {
                    // Admin sees all projects
                    $projects[] = $data;
                }
            }

            if (request()->expectsJson()) {
                return response()->json(['projects' => $projects]);
            }

            return view('projects.index', compact('projects'));
        } catch (FirebaseException|\Exception $e) {
            $errorMessage = 'Firebase connection failed: ' . $e->getMessage();
            \Log::warning('Project index Firebase error', [
                'error' => $e->getMessage(),
                'user_id' => Auth::id()
            ]);

            if (request()->expectsJson()) {
                return response()->json([
                    'error' => $errorMessage, 
                    'projects' => [],
                    'firebase_available' => false
                ], 200);
            }
            return view('projects.index', ['projects' => []])->with('warning', $errorMessage);
        }
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $this->authorize('create', Project::class);

        $managers = User::role('manager')->get();
        return view('projects.create', compact('managers'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $this->authorize('create', Project::class);

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'required|string|max:1000',
            'status' => 'in:active,on-hold,completed',
            'assigned_manager' => 'nullable|exists:users,id',
        ]);

        if ($validator->fails()) {
            if ($request->expectsJson()) {
                return response()->json(['errors' => $validator->errors()], 422);
            }
            return back()->withErrors($validator)->withInput();
        }

        try {
            $projectData = [
                'name' => $request->name,
                'description' => $request->description,
                'status' => $request->status ?? 'active',
                'created_by' => (int) Auth::id(),
                'assigned_manager' => (int) ($request->assigned_manager ?? Auth::id()),
            ];

            // Store in Firestore
            $firestoreDoc = $this->firestoreService->createProject($projectData);

            if ($request->expectsJson()) {
                return response()->json([
                    'message' => 'Project created successfully',
                    'project' => array_merge($projectData, ['id' => $firestoreDoc->id()])
                ], 201);
            }

            return redirect()->route('projects.index')
                ->with('success', 'Project created successfully!');
        } catch (FirebaseException $e) {
            if ($request->expectsJson()) {
                return response()->json(['error' => 'Failed to create project'], 500);
            }
            return back()->withErrors(['error' => 'Failed to create project'])->withInput();
        }
    }

    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        try {
            $firestoreProject = $this->firestoreService->getProject($id);
            
            if (!$firestoreProject->exists()) {
                abort(404, 'Project not found');
            }

            $projectData = $firestoreProject->data();
            
            // Create a temporary Project model for policy check
            $project = new Project([
                'firestore_id' => $id,
                'created_by' => $projectData['created_by'] ?? null,
                'assigned_manager' => $projectData['assigned_manager'] ?? null,
            ]);

            $this->authorize('view', $project);

            // Get project tasks
            $firestoreTasks = $this->firestoreService->getProjectTasks($id);
            $tasks = [];
            $currentUser = Auth::user();
            
            foreach ($firestoreTasks as $doc) {
                $taskData = $doc->data();
                $taskData['id'] = $doc->id();
                
                // Filter tasks for employees - only show tasks assigned to them
                if ($currentUser->hasRole('employee')) {
                    if (!isset($taskData['assigned_to']) || (int)$taskData['assigned_to'] !== (int)$currentUser->id) {
                        continue; // Skip tasks not assigned to this employee
                    }
                }
                
                // Get assigned user name
                if (isset($taskData['assigned_to'])) {
                    $user = User::find($taskData['assigned_to']);
                    $taskData['assigned_to_name'] = $user ? $user->name : 'Unknown User';
                }
                
                $tasks[] = $taskData;
            }

            $projectData['id'] = $id;
            $projectData['tasks'] = $tasks;

            if (request()->expectsJson()) {
                return response()->json(['project' => $projectData]);
            }

            return view('projects.show', compact('projectData'));
        } catch (FirebaseException $e) {
            if (request()->expectsJson()) {
                return response()->json(['error' => 'Failed to fetch project'], 500);
            }
            return back()->withErrors(['error' => 'Failed to fetch project']);
        }
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit($id)
    {
        try {
            $firestoreProject = $this->firestoreService->getProject($id);
            
            if (!$firestoreProject->exists()) {
                abort(404, 'Project not found');
            }

            $projectData = $firestoreProject->data();
            
            // Create a temporary Project model for policy check
            $project = new Project([
                'firestore_id' => $id,
                'created_by' => $projectData['created_by'] ?? null,
                'assigned_manager' => $projectData['assigned_manager'] ?? null,
            ]);

            $this->authorize('update', $project);

            $projectData['id'] = $id;
            $managers = User::role('manager')->get();

            return view('projects.edit', compact('projectData', 'managers'));
        } catch (FirebaseException $e) {
            return back()->withErrors(['error' => 'Failed to fetch project']);
        }
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
        try {
            $firestoreProject = $this->firestoreService->getProject($id);
            
            if (!$firestoreProject->exists()) {
                abort(404, 'Project not found');
            }

            $currentData = $firestoreProject->data();
            
            // Create a temporary Project model for policy check
            $project = new Project([
                'firestore_id' => $id,
                'created_by' => $currentData['created_by'] ?? null,
                'assigned_manager' => $currentData['assigned_manager'] ?? null,
            ]);

            $this->authorize('update', $project);

            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'description' => 'required|string|max:1000',
                'status' => 'in:active,on-hold,completed',
                'assigned_manager' => 'nullable|exists:users,id',
            ]);

            if ($validator->fails()) {
                if ($request->expectsJson()) {
                    return response()->json(['errors' => $validator->errors()], 422);
                }
                return back()->withErrors($validator)->withInput();
            }

            $updateData = [
                'name' => $request->name,
                'description' => $request->description,
                'status' => $request->status,
            ];

            // Only update assigned_manager if user has permission
            if ($request->has('assigned_manager') && Auth::user()->hasRole(['admin', 'manager'])) {
                $updateData['assigned_manager'] = (int) $request->assigned_manager;
            }

            // Update in Firestore
            $this->firestoreService->updateProject($id, $updateData);

            if ($request->expectsJson()) {
                return response()->json(['message' => 'Project updated successfully']);
            }

            return redirect()->route('projects.show', $id)
                ->with('success', 'Project updated successfully!');
        } catch (FirebaseException $e) {
            if ($request->expectsJson()) {
                return response()->json(['error' => 'Failed to update project'], 500);
            }
            return back()->withErrors(['error' => 'Failed to update project'])->withInput();
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        try {
            $firestoreProject = $this->firestoreService->getProject($id);
            
            if (!$firestoreProject->exists()) {
                abort(404, 'Project not found');
            }

            $projectData = $firestoreProject->data();
            
            // Create a temporary Project model for policy check
            $project = new Project([
                'firestore_id' => $id,
                'created_by' => $projectData['created_by'] ?? null,
                'assigned_manager' => $projectData['assigned_manager'] ?? null,
            ]);

            $this->authorize('delete', $project);

            // Delete from Firestore (this will also delete all tasks)
            $this->firestoreService->deleteProject($id);

            if (request()->expectsJson()) {
                return response()->json(['message' => 'Project deleted successfully']);
            }

            return redirect()->route('projects.index')
                ->with('success', 'Project deleted successfully!');
        } catch (FirebaseException $e) {
            if (request()->expectsJson()) {
                return response()->json(['error' => 'Failed to delete project'], 500);
            }
            return back()->withErrors(['error' => 'Failed to delete project']);
        }
    }
}