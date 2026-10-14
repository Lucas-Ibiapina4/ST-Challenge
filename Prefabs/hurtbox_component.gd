class_name HurtboxComponent
extends Area2D

var _dead := false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var shape_info := str(shape_node.shape) if shape_node else "SEM CollisionShape2D"
	var disabled_info := str(shape_node.disabled) if shape_node else "-"
	print("[HURTBOX] pronto | mask=", collision_mask, " (deve ser 4)",
			" | monitoring=", monitoring,
			" | shape=", shape_info,
			" | disabled=", disabled_info)

func _on_area_entered(area: Area2D) -> void:
	print("[HURTBOX] area: ", area.name, " | é Hazard? ", area is Hazard,
			" | layer: ", area.collision_layer)
	if area is Hazard:
		_die(area.cause)

func _on_body_entered(body: Node2D) -> void:
	print("[HURTBOX] body: ", body.name)
	_die(&"spikes")

func _die(cause: StringName) -> void:
	print("[HURTBOX] _die chamado | _dead = ", _dead)
	if _dead:
		return
	_dead = true
	EventBus.player_died.emit(cause)

func reset() -> void:
	_dead = false
