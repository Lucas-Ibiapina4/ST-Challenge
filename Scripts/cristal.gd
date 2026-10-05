extends StaticBody2D

# Certifique-se de colocar este nó no grupo "cristals" na aba Node do editor
# Collision Layer: 4 (Optics) | Collision Mask: 0
@export var crystal_type: String = "Reflector"

func _process(delta):

	if Input.is_action_just_pressed("rotate_cristal_left"):
		rotate_crystal(deg_to_rad(45))

func rotate_crystal(angle_deg: float) -> void:
	rotation_degrees = angle_deg
