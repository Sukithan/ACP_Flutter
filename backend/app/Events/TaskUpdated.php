<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class TaskUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $task;
    public $projectId;
    public $action; // 'created', 'updated', 'deleted', 'status_changed'
    public $userId;

    /**
     * Create a new event instance.
     */
    public function __construct($task, $projectId, $action = 'updated', $userId = null)
    {
        $this->task = $task;
        $this->projectId = $projectId;
        $this->action = $action;
        $this->userId = $userId;
    }

    /**
     * Get the channels the event should broadcast on.
     */
    public function broadcastOn(): array
    {
        return [
            new Channel('tasks'),
            new Channel('project.' . $this->projectId),
            new PrivateChannel('user.' . $this->userId),
        ];
    }

    /**
     * The event's broadcast name.
     */
    public function broadcastAs(): string
    {
        return 'task.updated';
    }

    /**
     * Get the data to broadcast.
     */
    public function broadcastWith(): array
    {
        return [
            'task' => $this->task,
            'project_id' => $this->projectId,
            'action' => $this->action,
            'timestamp' => now()->toISOString(),
        ];
    }
}