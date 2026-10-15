extends Control

#@export_file() var first_fase : String

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://World/world.tscn")
