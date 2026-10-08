class_name World
extends Node2D
## World Shell — persistente. Mantém Player, Câmera e HUD vivos entre as fases
## e hospeda o andar ativo dentro do LevelContainer.

@export var debug := true

@onready var player: CharacterBody2D = %Player
@onready var camera: Camera2D = %Camera2D
@onready var level_container: Node2D = %LevelContainer


func _log(msg: String) -> void:
	if debug:
		print("[WORLD] ", msg)


func _ready() -> void:
	GameManager.register_world(self)
	EventBus.player_died.connect(respawn_player)


## Descarrega o andar atual e carrega o novo.
func load_floor(floor_scene: PackedScene) -> void:
	unload_floor()
	var floor_node := floor_scene.instantiate()
	level_container.add_child(floor_node)
	# O conjurer procura o andar por este grupo.
	if not floor_node.is_in_group("floor"):
		floor_node.add_to_group("floor")
	_log("andar carregado: %s" % floor_scene.resource_path)

	# Cota de cristais da fase, se o Floor exportar "quota".
	var conjurer := _find_conjurer()
	if conjurer:
		var quota = floor_node.get("quota")
		if quota != null and conjurer.has_method("load_quota"):
			conjurer.load_quota(quota)
			_log("cota da fase: %d" % quota)
		else:
			conjurer.pending_step = 0
			conjurer.active_type_index = 0

	_place_camera()
	respawn_player()


func unload_floor() -> void:
	for child in level_container.get_children():
		level_container.remove_child(child)
		child.queue_free()


## Leva a câmera ao CameraPoint do andar ativo.
func _place_camera() -> void:
	var point := get_tree().get_first_node_in_group("camera_point")
	if point == null:
		push_warning("[WORLD] nenhum nó no grupo 'camera_point' no andar atual")
		return
	camera.global_position = point.global_position
	# O Marker2D pode trazer o zoom da fase como metadado ("zoom").
	if point.has_meta("zoom"):
		var z: float = point.get_meta("zoom")
		camera.zoom = Vector2(z, z)
	camera.reset_smoothing()
	_log("câmera em %s | zoom=%s" % [camera.global_position, camera.zoom])


## Leva o Player ao SpawnPoint do andar ativo.
func respawn_player() -> void:
	var spawn := get_tree().get_first_node_in_group("spawn_point")
	if spawn == null:
		push_warning("[WORLD] nenhum nó no grupo 'spawn_point' no andar atual")
		return
	player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO
	_log("player posicionado em %s" % spawn.global_position)


func _find_conjurer() -> Node:
	for child in player.get_children():
		if child.has_method("load_quota"):
			return child
	return null
