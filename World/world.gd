class_name World
extends Node2D
## World Shell — persistente. Mantém Player, Câmera e HUD vivos entre as fases
## e hospeda o andar ativo dentro do LevelContainer.
##
## Morte: o andar inteiro é recarregado do zero (cristais, porta, inimigos),
## e a configuração do andar (cota + rotações liberadas) volta aos valores
## exportados no Floor_XX.

const DEFAULT_QUOTA := 3
const DEFAULT_STEPS: Array[int] = [0, 1, 2, 3]

@export var debug := true
@export var respawn_delay := 0.4

@onready var player: Player = %Player
@onready var camera: Camera2D = %Camera2D
@onready var level_container: Node2D = %LevelContainer

var _current_floor_scene: PackedScene   # cena do andar ativo, para recarregar na morte
var _reloading := false                 # evita recarregar duas vezes na mesma morte


func _log(msg: String) -> void:
	if debug:
		print("[WORLD] ", msg)


func _ready() -> void:
	GameManager.register_world(self)
	EventBus.player_died.connect(_on_player_died)


## Descarrega o andar atual e carrega o novo.
func load_floor(floor_scene: PackedScene) -> void:
	_current_floor_scene = floor_scene
	unload_floor()
	var floor_node := floor_scene.instantiate()
	level_container.add_child(floor_node)
	if not floor_node.is_in_group("floor"):
		floor_node.add_to_group("floor")
	_log("andar carregado: %s" % floor_scene.resource_path)

	_apply_floor_config(floor_node)
	_place_camera()
	respawn_player()


## Repassa ao conjurador o que o andar exporta: cota e rotações liberadas.
## Também sai do modo de remoção e reseta a rotação pendente.
## Os fallbacks existem porque isto roda a cada morte: um andar mal
## configurado não pode travar a sessão no meio do teste.
func _apply_floor_config(floor_node: Node) -> void:
	var conjurer := _find_conjurer()
	if conjurer == null:
		push_warning("[WORLD] nenhum componente com load_floor_config no Player")
		return

	var quota = floor_node.get("quota")
	if quota == null:
		push_warning("[WORLD] andar sem 'quota' exportada; usando %d" % DEFAULT_QUOTA)
		quota = DEFAULT_QUOTA

	var steps = floor_node.get("allowed_steps")
	if steps == null:
		push_warning("[WORLD] andar sem 'allowed_steps' exportada; liberando todas")
		steps = DEFAULT_STEPS

	conjurer.load_floor_config(int(quota), steps)
	_log("cota: %d | rotações liberadas: %s" % [int(quota), steps])


## Recarrega o andar atual do zero. Os cristais conjurados são filhos do
## andar, então somem junto com ele.
func reload_floor() -> void:
	if _current_floor_scene == null:
		push_warning("[WORLD] nenhum andar para recarregar")
		return
	_log("reiniciando o andar")
	load_floor(_current_floor_scene)


func unload_floor() -> void:
	for child in level_container.get_children():
		level_container.remove_child(child)
		child.queue_free()


## Procura um nó por grupo só dentro do andar ativo.
func _find_in_floor(group: StringName) -> Node2D:
	for node in get_tree().get_nodes_in_group(group):
		if level_container.is_ancestor_of(node):
			return node
	return null


func _place_camera() -> void:
	var point := _find_in_floor(&"camera_point")
	if point == null:
		push_warning("[WORLD] nenhum nó no grupo 'camera_point' no andar atual")
		return
	camera.global_position = point.global_position
	if point.has_meta("zoom"):
		var z: float = point.get_meta("zoom")
		camera.zoom = Vector2(z, z)
	camera.reset_smoothing()
	_log("câmera em %s | zoom=%s" % [camera.global_position, camera.zoom])


## Leva o Player ao SpawnPoint do andar ativo e reativa os componentes.
func respawn_player() -> void:
	var spawn := _find_in_floor(&"spawn_point")
	if spawn == null:
		push_warning("[WORLD] nenhum nó no grupo 'spawn_point' no andar atual")
		return
	player.respawn(spawn.global_position)   # também reseta a hurtbox
	_log("player posicionado em %s" % spawn.global_position)


func _find_conjurer() -> Node:
	for child in player.get_children():
		if child.has_method("load_floor_config"):
			return child
	return null


func _on_player_died(cause: StringName) -> void:
	if _reloading:
		return
	_reloading = true
	_log("player morreu: %s" % cause)
	player.freeze()
	await get_tree().create_timer(respawn_delay).timeout
	reload_floor()   # recria o andar, recarrega a config e faz o respawn
	_reloading = false
