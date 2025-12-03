<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Exception\FirebaseException;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class FirestoreService
{
    protected $firestore;

    public function __construct()
    {
        try {
            $credentialsPath = config('services.firebase.credentials');
            
            // Check if credentials file exists
            if (!$credentialsPath || !file_exists($credentialsPath)) {
                Log::warning('Firebase credentials file not found at: ' . $credentialsPath);
                Log::info('Please follow the setup instructions in FIREBASE_SETUP.md');
                $this->firestore = null;
                return;
            }
            
            $factory = (new Factory)->withServiceAccount($credentialsPath);
            $this->firestore = $factory->createFirestore()->database();
        } catch (FirebaseException $e) {
            Log::error('Firebase initialization failed: ' . $e->getMessage());
            $this->firestore = null;
        } catch (\Exception $e) {
            Log::error('Firebase setup error: ' . $e->getMessage());
            $this->firestore = null;
        }
    }

    // Check if Firestore is available
    private function isFirestoreAvailable()
    {
        return $this->firestore !== null;
    }
    
    // Projects CRUD
    public function createProject(array $data)
    {
        if (!$this->isFirestoreAvailable()) {
            throw new \Exception('Firestore is not configured. Please check FIREBASE_SETUP.md for setup instructions.');
        }
        
        try {
            // Add timestamps
            $data['created_at'] = Carbon::now()->toISOString();
            $data['updated_at'] = Carbon::now()->toISOString();
            
            return $this->firestore->collection('projects')->add($data);
        } catch (FirebaseException $e) {
            Log::error('Failed to create project: ' . $e->getMessage());
            throw $e;
        } catch (\Exception $e) {
            Log::error('Failed to create project: ' . $e->getMessage());
            throw new \Exception('Firestore is not configured properly. Please check FIREBASE_SETUP.md for setup instructions.');
        }
    }

    public function getAllProjects()
    {
        if (!$this->isFirestoreAvailable()) {
            Log::warning('Firestore is not available - returning empty project list');
            return collect([]); // Return empty collection instead of throwing exception
        }
        
        try {
            return $this->firestore->collection('projects')->documents();
        } catch (FirebaseException $e) {
            Log::error('Failed to fetch projects: ' . $e->getMessage());
            return collect([]); // Return empty collection on error
        } catch (\Exception $e) {
            Log::error('Failed to fetch projects: ' . $e->getMessage());
            return collect([]); // Return empty collection on error
        }
    }

    public function getProject($id)
    {
        try {
            return $this->firestore->collection('projects')->document($id)->snapshot();
        } catch (FirebaseException $e) {
            Log::error("Failed to fetch project {$id}: " . $e->getMessage());
            throw $e;
        }
    }

    public function updateProject($id, array $data)
    {
        try {
            // Add updated timestamp
            $data['updated_at'] = Carbon::now()->toISOString();
            
            return $this->firestore->collection('projects')->document($id)->set($data, ['merge' => true]);
        } catch (FirebaseException $e) {
            Log::error("Failed to update project {$id}: " . $e->getMessage());
            throw $e;
        }
    }

    public function deleteProject($id)
    {
        try {
            // Also delete all tasks in the project
            $tasks = $this->firestore->collection('projects')->document($id)->collection('tasks')->documents();
            foreach ($tasks as $task) {
                $task->reference()->delete();
            }
            
            return $this->firestore->collection('projects')->document($id)->delete();
        } catch (FirebaseException $e) {
            Log::error("Failed to delete project {$id}: " . $e->getMessage());
            throw $e;
        }
    }

    // Tasks CRUD (as subcollection)
    public function createTask($projectId, array $data)
    {
        try {
            // Add timestamps
            $data['created_at'] = Carbon::now()->toISOString();
            $data['updated_at'] = Carbon::now()->toISOString();
            $data['status'] = $data['status'] ?? 'pending';
            
            return $this->firestore->collection('projects')->document($projectId)->collection('tasks')->add($data);
        } catch (FirebaseException $e) {
            Log::error("Failed to create task in project {$projectId}: " . $e->getMessage());
            throw $e;
        }
    }

    public function getProjectTasks($projectId)
    {
        try {
            return $this->firestore->collection('projects')->document($projectId)->collection('tasks')->documents();
        } catch (FirebaseException $e) {
            Log::error("Failed to fetch tasks for project {$projectId}: " . $e->getMessage());
            throw $e;
        }
    }

    public function getTask($projectId, $taskId)
    {
        try {
            return $this->firestore->collection('projects')->document($projectId)->collection('tasks')->document($taskId)->snapshot();
        } catch (FirebaseException $e) {
            Log::error("Failed to fetch task {$taskId} in project {$projectId}: " . $e->getMessage());
            throw $e;
        }
    }

    public function updateTask($projectId, $taskId, array $data)
    {
        try {
            // Add updated timestamp
            $data['updated_at'] = Carbon::now()->toISOString();
            
            return $this->firestore->collection('projects')->document($projectId)->collection('tasks')->document($taskId)->set($data, ['merge' => true]);
        } catch (FirebaseException $e) {
            Log::error("Failed to update task {$taskId} in project {$projectId}: " . $e->getMessage());
            throw $e;
        }
    }

    public function deleteTask($projectId, $taskId)
    {
        try {
            return $this->firestore->collection('projects')->document($projectId)->collection('tasks')->document($taskId)->delete();
        } catch (FirebaseException $e) {
            Log::error("Failed to delete task {$taskId} in project {$projectId}: " . $e->getMessage());
            throw $e;
        }
    }

    public function getTasksAssignedToUser($userId)
    {
        try {
            $allTasks = [];
            $projects = $this->getAllProjects();
            
            foreach ($projects as $project) {
                $tasks = $this->getProjectTasks($project->id());
                foreach ($tasks as $task) {
                    $taskData = $task->data();
                    if (isset($taskData['assigned_to']) && $taskData['assigned_to'] == $userId) {
                        $taskData['id'] = $task->id();
                        $taskData['project_id'] = $project->id();
                        $taskData['project_name'] = $project->data()['name'] ?? 'Unknown Project';
                        $allTasks[] = $taskData;
                    }
                }
            }
            
            return $allTasks;
        } catch (FirebaseException $e) {
            Log::error("Failed to fetch tasks for user {$userId}: " . $e->getMessage());
            throw $e;
        }
    }
}