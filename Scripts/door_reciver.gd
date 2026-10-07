class_name DoorReceiver
extends StaticBody2D
## Cristal em cima da porta (Layer 4: Optics).
## Conta quantos emissores DISTINTOS estão atingindo este cristal agora
## e emite `activated` quando a cota configurada no nível é atingida.

signal beam_count_changed(current: int, required: int)
signal activated
signal deactivated

@export_range(1, 10) var required_beams: int = 1
@export_range(0.0, 5.0, 0.05) var hold_time: float = 0.3
@export var latch: bool = true
@export var debug := true

var _sources: Dictionary = {}  # LightEmitter2D -> true
var _is_active := false
var _hold_timer: Timer


func _log(msg: String) -> void:
	if debug:
		print("[RECEIVER ", name, "] ", msg)


func _ready() -> void:
	add_to_group("light_receiver")
	_hold_timer = Timer.new()
	_hold_timer.one_shot = true
	_hold_timer.timeout.connect(_activate)
	add_child(_hold_timer)
	_log("pronto | required_beams=%d hold_time=%.2f latch=%s | layer=%d (Optics deve incluir 8) | grupos=%s"
		% [required_beams, hold_time, latch, collision_layer, get_groups()])
	beam_count_changed.emit(0, required_beams)


func light_entered(source: Node) -> void:
	if _sources.has(source):
		return
	_sources[source] = true
	_log("feixe ENTROU de '%s'" % source.name)
	_on_count_changed()


func light_exited(source: Node) -> void:
	if not _sources.erase(source):
		return
	_log("feixe SAIU de '%s'" % source.name)
	_on_count_changed()


func get_beam_count() -> int:
	for s in _sources.keys():
		if not is_instance_valid(s):
			_sources.erase(s)
	return _sources.size()


func is_active() -> bool:
	return _is_active


func _on_count_changed() -> void:
	var count := get_beam_count()
	_log("contagem: %d/%d" % [count, required_beams])
	beam_count_changed.emit(count, required_beams)

	if _is_active:
		if not latch and count < required_beams:
			_is_active = false
			_log("DESATIVADO (latch=false e contagem caiu)")
			deactivated.emit()
		return

	if count >= required_beams:
		if hold_time <= 0.0:
			_activate()
		elif _hold_timer.is_stopped():
			_log("cota atingida, aguardando %.2fs..." % hold_time)
			_hold_timer.start(hold_time)
	else:
		if not _hold_timer.is_stopped():
			_log("cota perdida antes do hold_time, timer cancelado")
		_hold_timer.stop()


func _activate() -> void:
	if _is_active or get_beam_count() < required_beams:
		_log("_activate ignorado (ativo=%s, contagem=%d)" % [_is_active, get_beam_count()])
		return
	_is_active = true
	_log("ATIVADO -> emitindo 'activated' (conexões: %d)" % activated.get_connections().size())
	activated.emit()
