extends Node2D
## CrystalConjurerComponent — instancia e recolhe cristais no andar.
## Escolhe a rotação ANTES de conjurar; depois de conjurado o cristal é estático.
## Controla a cota do andar e emite crystal_inventory_changed.
## Não faz: calcular a luz, abrir a porta.
const STEP_DEG := 45.0
const STEPS := 8                 # 360 / 45
const REPEAT_DELAY := 0.25       # espera antes de começar a repetir
const REPEAT_RATE := 0.12        # intervalo entre passos com a tecla segurada
const SPAWN_OFFSET_X := 15.0     # distância do cristal à frente da princesa
const PICKUP_RANGE := 48.0       # alcance para recolher um cristal
const CRYSTAL_GROUP := "cristals"

@export var crystal_scene: PackedScene
@export var crystal_types: Array[String] = ["Reflector", "Refractor"]
@onready var shape_cast: ShapeCast2D = $SpawnMarker/ShapeCast2D
@onready var spawn_marker: Marker2D = $SpawnMarker
@onready var mover: Node = get_parent().get_node("PlayerMoverComponent")
@onready var player: CharacterBody2D = $".."

@export var remaining_count := 5         # cristais que ainda podem ser conjurados
var active_type_index := 0       # índice em crystal_types
var pending_step := 0            # 0..7 — rotação escolhida, em passos de 45°
var _next_step_in := 0.0

func active_type() -> String:
	return crystal_types[active_type_index]
	
func pending_rotation_degrees() -> float:
	return pending_step * STEP_DEG
	
## Chamado pelo World/Floor ao entrar no andar, com a cota exportada do Floor_XX.
func load_quota(quota: int) -> void:
	remaining_count = quota
	pending_step = 0
	_emit_inventory()
	
func _physics_process(delta: float) -> void:
	_update_spawn_position()
	_handle_rotation_input(delta)
	if Input.is_action_just_pressed("chose_cristal_up"):
		_cycle_type()
	if Input.is_action_just_pressed("create_cristal"):
		_try_conjure()
	#if Input.is_action_just_pressed("retrieve_crystal"):
		#_try_retrieve()
		
# --- Posição -------------------------------------------------------------
func _update_spawn_position() -> void:
	spawn_marker.position.x = SPAWN_OFFSET_X * mover.facing
	
# --- Rotação (antes de conjurar) ----------------------------------------
func _handle_rotation_input(delta: float) -> void:
	var dir := int(Input.is_action_pressed("rotate_cristal_right")) \
			- int(Input.is_action_pressed("rotate_cristal_left"))
	if dir == 0:
		_next_step_in = 0.0
		return
	if Input.is_action_just_pressed("rotate_cristal_right") \
			or Input.is_action_just_pressed("rotate_cristal_left"):
		_step_rotation(dir)
		_next_step_in = REPEAT_DELAY
		return
	_next_step_in -= delta
	if _next_step_in <= 0.0:
		_step_rotation(dir)
		_next_step_in = REPEAT_RATE
		
func _step_rotation(dir: int) -> void:
	pending_step = wrapi(pending_step + dir, 0, STEPS)
	
# --- Tipo de cristal -----------------------------------------------------
func _cycle_type() -> void:
	active_type_index = wrapi(active_type_index + 1, 0, crystal_types.size())
	_emit_inventory()
	
# --- Conjurar ------------------------------------------------------------
func _try_conjure() -> void:
	if crystal_scene == null:
		push_warning("crystal_scene não atribuído no Inspector")
		return
	if remaining_count <= 0:
		push_warning("cota esgotada (remaining_count = %d)" % remaining_count)
		return
	var floor_node := _current_floor()
	if floor_node == null:
		push_warning("nenhum nó no grupo 'floor'")
		return
	if not _space_is_free():
		push_warning("espaço ocupado em %s" % spawn_marker.global_position)
		return

	var crystal := crystal_scene.instantiate() as Node2D
	print("[CONJURER] spawnando '%s' de %s | layer=%d | grupos=%s"
	% [crystal.name, crystal_scene.resource_path, crystal.collision_layer, crystal.get_groups()])
	crystal.crystal_type = active_type()
	floor_node.add_child(crystal)
	crystal.global_position = spawn_marker.global_position
	crystal.rotation_degrees = pending_rotation_degrees()

	remaining_count -= 1
	_emit_inventory()
	
## Usa o ShapeCast2D para não deixar o cristal nascer dentro de uma parede
## ou de outro cristal. Testa já com a rotação escolhida, porque uma forma
## não circular ocupa espaços diferentes em cada ângulo.
func _space_is_free() -> bool:
	shape_cast.rotation_degrees = pending_rotation_degrees()
	shape_cast.force_shapecast_update()
	return not shape_cast.is_colliding()
	
# --- Recolher ------------------------------------------------------------
func _try_retrieve() -> void:
	var crystal := _closest_crystal()
	if crystal == null:
		return
	crystal.queue_free()
	remaining_count += 1
	_emit_inventory()
	
func _closest_crystal() -> Node2D:
	var origin := spawn_marker.global_position
	var closest: Node2D = null
	var best := PICKUP_RANGE
	for node in get_tree().get_nodes_in_group(CRYSTAL_GROUP):
		var c := node as Node2D
		if c == null:
			continue
		var d := origin.distance_to(c.global_position)
		if d <= best:
			best = d
			closest = c
	return closest
	
# --- Helpers -------------------------------------------------------------
func _current_floor() -> Node:
	# O andar ativo é o único filho do LevelContainer.
	return get_tree().get_first_node_in_group("floor")
	
func _emit_inventory() -> void:
	EventBus.crystal_inventory_changed.emit(remaining_count, active_type())
