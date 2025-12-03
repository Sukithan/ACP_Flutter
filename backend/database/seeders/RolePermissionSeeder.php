<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class RolePermissionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create permissions
        $permissions = [
            // Project permissions
            'create projects',
            'edit projects',
            'delete projects',
            'view all projects',
            
            // Task permissions
            'create tasks',
            'assign tasks',
            'edit all tasks',
            'view all tasks',
            'view own tasks',
            'edit own tasks',
            
            // User management permissions
            'manage users',
            'assign roles',
            'view system logs',
            
            // General permissions
            'access admin panel',
            'access manager panel',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission]);
        }

        // Create roles and assign permissions
        
        // Admin Role - Full access
        $adminRole = Role::firstOrCreate(['name' => 'admin']);
        $adminRole->syncPermissions(Permission::all());

        // Manager Role - Project and task management
        $managerRole = Role::firstOrCreate(['name' => 'manager']);
        $managerRole->syncPermissions([
            'create projects',
            'edit projects',
            'view all projects',
            'create tasks',
            'assign tasks',
            'edit all tasks',
            'view all tasks',
            'access manager panel',
        ]);

        // Employee Role - Limited to own tasks
        $employeeRole = Role::firstOrCreate(['name' => 'employee']);
        $employeeRole->syncPermissions([
            'view all projects', // Can view projects but not edit
            'view own tasks',
            'edit own tasks',
        ]);

        // Create sample users
        
        // Admin user
        $admin = User::firstOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'System Administrator',
                'password' => Hash::make('password123'),
                'email_verified_at' => now(),
            ]
        );
        $admin->syncRoles(['admin']);

        // Manager user
        $manager = User::firstOrCreate(
            ['email' => 'manager@example.com'],
            [
                'name' => 'Project Manager',
                'password' => Hash::make('password123'),
                'email_verified_at' => now(),
            ]
        );
        $manager->syncRoles(['manager']);

        // Employee users
        $employee1 = User::firstOrCreate(
            ['email' => 'john@example.com'],
            [
                'name' => 'John Employee',
                'password' => Hash::make('password123'),
                'email_verified_at' => now(),
            ]
        );
        $employee1->syncRoles(['employee']);

        $employee2 = User::firstOrCreate(
            ['email' => 'jane@example.com'],
            [
                'name' => 'Jane Employee',
                'password' => Hash::make('password123'),
                'email_verified_at' => now(),
            ]
        );
        $employee2->syncRoles(['employee']);

        $this->command->info('Roles, permissions, and sample users created successfully!');
        $this->command->info('Sample login credentials:');
        $this->command->info('Admin: admin@example.com / password123');
        $this->command->info('Manager: manager@example.com / password123');
        $this->command->info('Employee: john@example.com / password123');
        $this->command->info('Employee: jane@example.com / password123');
    }
}