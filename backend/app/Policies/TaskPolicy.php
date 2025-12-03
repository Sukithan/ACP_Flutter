<?php

namespace App\Policies;

use Illuminate\Auth\Access\Response;
use App\Models\Task;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class TaskPolicy
{
    use HandlesAuthorization;

    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(?User $user): bool
    {
        // Unauthenticated users cannot view tasks
        if (!$user) {
            return false;
        }
        
        // Admin and Manager can view all tasks
        return $user->hasPermissionTo('view all tasks') || $user->hasPermissionTo('view own tasks');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(?User $user, Task $task): bool
    {
        // Unauthenticated users cannot view tasks
        if (!$user) {
            return false;
        }
        
        // Admin and Manager can view all tasks
        if ($user->hasPermissionTo('view all tasks')) {
            return true;
        }

        // Employee can only view tasks assigned to them
        if ($user->hasPermissionTo('view own tasks')) {
            return $task->assigned_to === $user->id;
        }

        return false;
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(?User $user): bool
    {
        // Unauthenticated users cannot create tasks
        if (!$user) {
            return false;
        }
        
        // Only Admin and Manager can create tasks
        return $user->hasPermissionTo('create tasks');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(?User $user, ?Task $task = null): bool
    {
        // Unauthenticated users cannot update tasks
        if (!$user) {
            return false;
        }
        
        // Admin and Manager can edit all tasks
        if ($user->hasPermissionTo('edit all tasks')) {
            return true;
        }

        // Employee can only edit their own tasks
        if ($user->hasPermissionTo('edit own tasks')) {
            // If no specific task is provided, allow employee to update in general
            if (!$task) {
                return true;
            }
            return $task->assigned_to === $user->id;
        }

        return false;
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(?User $user, ?Task $task = null): bool
    {
        // Unauthenticated users cannot delete tasks
        if (!$user) {
            return false;
        }
        
        // Only Admin and Manager can delete tasks
        return $user->hasPermissionTo('edit all tasks');
    }

    /**
     * Determine whether the user can assign tasks.
     */
    public function assign(User $user): bool
    {
        // Only Admin and Manager can assign tasks to users
        return $user->hasPermissionTo('assign tasks');
    }

    /**
     * Determine whether the user can restore the model.
     */
    public function restore(User $user, Task $task): bool
    {
        return $user->hasRole('admin');
    }

    /**
     * Determine whether the user can permanently delete the model.
     */
    public function forceDelete(User $user, Task $task): bool
    {
        return $user->hasRole('admin');
    }
}
