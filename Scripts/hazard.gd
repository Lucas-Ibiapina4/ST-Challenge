class_name Hazard
extends Area2D


## Identifica a causa da morte (útil para animação/som diferentes)
@export var cause: StringName = &"generic"

func _ready() -> void:
	collision_layer = 1 << 2   # Layer 3: Hazards
	collision_mask = 0         # o perigo não precisa detectar nada
	monitoring = false         # quem monitora é a Hurtbox
	monitorable = true
	print("[HAZARD ", name, "] pronto | layer=", collision_layer, " (deve ser 4)",
			" | monitorable=", monitorable)
