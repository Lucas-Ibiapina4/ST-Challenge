class_name Floor
extends Node2D

@export var quota: int = 3

@export var allowed_steps: Array[int] = [0, 1, 2, 3]

@onready var spawn_point: Marker2D = $SpawnPoint


func get_spawn_position() -> Vector2:
	return spawn_point.global_position
