<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Project extends Model
{
    use HasFactory;

    protected $fillable = [
        'firestore_id',
        'name',
        'description',
        'status',
        'created_by',
        'assigned_manager',
    ];

    // Since we're storing actual data in Firestore, this model is mainly for Laravel policies
    // We'll use firestore_id to reference the document in Firestore
    
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function manager()
    {
        return $this->belongsTo(User::class, 'assigned_manager');
    }
}
