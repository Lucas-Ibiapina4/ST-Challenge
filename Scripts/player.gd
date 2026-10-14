class_name Player
extends CharacterBody2D

@onready var hurtbox: HurtboxComponent = $HurtboxComponent


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	hurtbox.reset()
	_set_components_active(true)


func freeze() -> void:
	velocity = Vector2.ZERO
	_set_components_active(false)


## Liga/desliga o processamento do Player e de todos os componentes filhos,
## para que nenhum leia input (mover, conjurar, girar) enquanto está morta.
func _set_components_active(active: bool) -> void:
	set_physics_process(active)
	for child in get_children():
		child.set_physics_process(active)
		child.set_process(active)
