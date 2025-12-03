<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    use HasFactory;

    protected $fillable = [
        'firestore_id',
        'project_firestore_id',
        'title',
        'description',
        'status',
        'assigned_to',
        'created_by',
        'due_date',
        'priority',
    ];

    // Since we're storing actual data in Firestore, this model is mainly for Laravel policies
    
    public function assignedUser()
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
