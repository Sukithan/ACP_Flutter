<?php

namespace App\Policies;

use Illuminate\Auth\Access\Response;
use App\Models\Project;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class ProjectPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(?User $user): bool
    {
        // Unauthenticated users cannot view projects
        if (!$user) {
            return false;
        }
        
        // Admin and Manager can view all projects, Employee can view projects but not manage
        return $user->hasPermissionTo('view all projects');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(?User $user, Project $project): bool
    {
        // Unauthenticated users cannot view projects
        if (!$user) {
            return false;
        }
        
        // Admin can view all projects
        if ($user->hasRole('admin')) {
            return true;
        }
        
        // Manager can view projects they're assigned to
        if ($user->hasRole('manager')) {
            return $project->assigned_manager === $user->id || $project->created_by === $user->id;
        }
        
        // Employees can view projects (filtering is done in controller based on task assignments)
        return $user->hasPermissionTo('view all projects');
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(?User $user): bool
    {
        // Unauthenticated users cannot create projects
        if (!$user) {
            return false;
        }
        
        // Only Admin and Manager can create projects
        return $user->hasPermissionTo('create projects');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(?User $user, ?Project $project = null): bool
    {
        // Unauthenticated users cannot update projects
        if (!$user) {
            return false;
        }
        
        // Admin can update all, Manager can update projects they're assigned to or created
        if ($user->hasRole('admin')) {
            return true;
        }

        if ($user->hasRole('manager') && $user->hasPermissionTo('edit projects')) {
            // If no specific project is provided, allow manager to update in general
            if (!$project) {
                return true;
            }
            // Manager can edit if they created it or are assigned as manager
            return $project->created_by === $user->id || $project->assigned_manager === $user->id;
        }

        return false;
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(?User $user, ?Project $project = null): bool
    {
        // Unauthenticated users cannot delete projects
        if (!$user) {
            return false;
        }
        
        // Only Admin can delete projects
        return $user->hasRole('admin') && $user->hasPermissionTo('delete projects');
    }

    /**
     * Determine whether the user can restore the model.
     */
    public function restore(User $user, Project $project): bool
    {
        return $user->hasRole('admin');
    }

    /**
     * Determine whether the user can permanently delete the model.
     */
    public function forceDelete(User $user, Project $project): bool
    {
        return $user->hasRole('admin');
    }
}
