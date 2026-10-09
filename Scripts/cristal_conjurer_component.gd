extends Node2D
## CrystalConjurerComponent — instancia e recolhe cristais no andar.
## Escolhe a rotação ANTES de conjurar; depois de conjurado o cristal é estático.
## Controla a cota do andar e emite crystal_inventory_changed.
## Não faz: calcular a luz, abrir a porta.
##
## As setas têm duas funções:
##   - normalmente: giram a rotação pendente (antes de conjurar)
##   - com "remove_cristal" (E) SEGURADO: percorrem os cristais já colocados
##     no andar. Ao soltar o E, o cristal destacado é removido.
const STEP_DEG := 45.0
const STEPS := 8                 # 360 / 45
const REPEAT_DELAY := 0.25       # espera antes de começar a repetir
const REPEAT_RATE := 0.12        # intervalo entre passos com a tecla segurada
const SPAWN_OFFSET_X := 15.0     # distância do cristal à frente da princesa
const PICKUP_RANGE := 48.0       # alcance para recolher um cristal
const CRYSTAL_GROUP := "cristals"
const HIGHLIGHT := Color(1.4, 1.4, 1.8)   # cor do cristal destacado para remoção
@export var crystal_scenes: Array[PackedScene]
@export var crystal_types: Array[String] = ["Reflector", "Refractor"]
@onready var shape_cast: ShapeCast2D = $SpawnMarker/ShapeCast2D
@onready var spawn_marker: Marker2D = $SpawnMarker
@onready var mover: Node = get_parent().get_node("PlayerMoverComponent")
@onready var player: CharacterBody2D = $".."
@export var remaining_count := 5         # cristais que ainda podem ser conjurados
var active_type_index := 0       # índice em crystal_types
var pending_step := 0            # 0..7 — rotação escolhida, em passos de 45°
var _next_step_in := 0.0
# --- Modo de remoção -----------------------------------------------------
var _removing := false           # true enquanto "remove_cristal" está segurado
var _targets: Array[Node2D] = [] # cristais do andar, na ordem de seleção
var _target_index := 0           # qual deles está destacado
var _original_modulate := Color.WHITE
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
	# O E manda: enquanto estiver segurado, as setas selecionam em vez de girar.
	if Input.is_action_just_pressed("remove_cristal"):
		_enter_remove_mode()
	elif Input.is_action_just_released("remove_cristal"):
		_confirm_remove()
	if _removing:
		_handle_target_input(delta)
		return   # nada de girar nem conjurar enquanto seleciona
	_handle_rotation_input(delta)
	if Input.is_action_just_pressed("chose_cristal_up"):
		_cycle_type()
	if Input.is_action_just_pressed("create_cristal"):
		_try_conjure()
		
# --- Posição -------------------------------------------------------------
func _update_spawn_position() -> void:
	spawn_marker.position.x = SPAWN_OFFSET_X * mover.facing
	
# --- Rotação (antes de conjurar) ----------------------------------------
func _handle_rotation_input(delta: float) -> void:
	var dir := _arrow_dir()
	if dir == 0:
		_next_step_in = 0.0
		return
	if _arrow_just_pressed():
		_step_rotation(dir)
		_next_step_in = REPEAT_DELAY
		return
	_next_step_in -= delta
	if _next_step_in <= 0.0:
		_step_rotation(dir)
		_next_step_in = REPEAT_RATE
		
func _step_rotation(dir: int) -> void:
	pending_step = wrapi(pending_step + dir, 0, STEPS)
# --- Setas (compartilhadas entre girar e selecionar) ---------------------
func _arrow_dir() -> int:
	return int(Input.is_action_pressed("rotate_cristal_right")) \
			- int(Input.is_action_pressed("rotate_cristal_left"))
func _arrow_just_pressed() -> bool:
	return Input.is_action_just_pressed("rotate_cristal_right") \
			or Input.is_action_just_pressed("rotate_cristal_left")
	
# --- Tipo de cristal -----------------------------------------------------
func _cycle_type() -> void:
	active_type_index = wrapi(active_type_index + 1, 0, crystal_types.size())
	_emit_inventory()
	
# --- Conjurar ------------------------------------------------------------
func _try_conjure() -> void:
	if crystal_scenes.is_empty():
		push_warning("crystal_scenes não atribuído no Inspector")
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
	var crystal_scene := crystal_scenes[active_type_index]
	var crystal := crystal_scene.instantiate() as Node2D
	crystal.crystal_type = active_type()
	floor_node.add_child(crystal)
	crystal.global_position = spawn_marker.global_position
	crystal.rotation_degrees += pending_rotation_degrees()
	remaining_count -= 1
	_emit_inventory()
	
## Usa o ShapeCast2D para não deixar o cristal nascer dentro de uma parede
## ou de outro cristal. Testa já com a rotação escolhida, porque uma forma
## não circular ocupa espaços diferentes em cada ângulo.
func _space_is_free() -> bool:
	shape_cast.rotation_degrees = pending_rotation_degrees()
	shape_cast.force_shapecast_update()
	return not shape_cast.is_colliding()
	
# --- Remover (segurando E) ----------------------------------------------
## Monta a lista de cristais do andar e destaca o mais próximo da princesa.
func _enter_remove_mode() -> void:
	_targets = _crystals_sorted_by_distance()
	if _targets.is_empty():
		return
	_removing = true
	_target_index = 0
	_next_step_in = 0.0
	_apply_highlight()
## Com o E segurado, as setas andam pela lista.
func _handle_target_input(delta: float) -> void:
	_clean_targets()
	if _targets.is_empty():
		_exit_remove_mode()
		return
	var dir := _arrow_dir()
	if dir == 0:
		_next_step_in = 0.0
		return
	if _arrow_just_pressed():
		_step_target(dir)
		_next_step_in = REPEAT_DELAY
		return
	_next_step_in -= delta
	if _next_step_in <= 0.0:
		_step_target(dir)
		_next_step_in = REPEAT_RATE
func _step_target(dir: int) -> void:
	_clear_highlight()
	_target_index = wrapi(_target_index + dir, 0, _targets.size())
	_apply_highlight()
## Soltar o E remove o cristal destacado e devolve ele à cota.
func _confirm_remove() -> void:
	if not _removing:
		return
	var target := _current_target()
	_clear_highlight()
	if target != null:
		target.queue_free()
		remaining_count += 1
		_emit_inventory()
	_exit_remove_mode()
func _exit_remove_mode() -> void:
	_clear_highlight()
	_removing = false
	_targets.clear()
	_next_step_in = 0.0
func _current_target() -> Node2D:
	if _target_index < 0 or _target_index >= _targets.size():
		return null
	var t := _targets[_target_index]
	return t if is_instance_valid(t) else null
func _apply_highlight() -> void:
	var t := _current_target()
	if t == null:
		return
	_original_modulate = t.modulate
	t.modulate = HIGHLIGHT
func _clear_highlight() -> void:
	var t := _current_target()
	if t != null:
		t.modulate = _original_modulate
## Tira da lista os cristais que já foram destruídos.
func _clean_targets() -> void:
	var before := _targets.size()
	_targets = _targets.filter(func(c): return is_instance_valid(c))
	if _targets.size() != before:
		_target_index = clampi(_target_index, 0, maxi(_targets.size() - 1, 0))
## Cristais do andar, do mais perto ao mais longe da princesa.
func _crystals_sorted_by_distance() -> Array[Node2D]:
	var origin := player.global_position
	var list: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(CRYSTAL_GROUP):
		var c := node as Node2D
		if c != null:
			list.append(c)
	list.sort_custom(func(a, b):
		return origin.distance_to(a.global_position) < origin.distance_to(b.global_position))
	return list
	
# --- Helpers -------------------------------------------------------------
func _current_floor() -> Node:
	# O andar ativo é o único filho do LevelContainer.
	return get_tree().get_first_node_in_group("floor")
	
func _emit_inventory() -> void:
	EventBus.crystal_inventory_changed.emit(remaining_count, active_type())
