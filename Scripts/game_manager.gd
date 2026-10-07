extends Node
## Autoload "GameManager": sabe a ordem dos níveis e troca de cena.
## Versão simples (sem World/LevelContainer): troca a cena inteira.

## Ordem dos níveis. Ajuste os caminhos para os seus arquivos .tscn.
const LEVELS: Array[String] = [
	"res://Scenes/level_01.tscn",
	"res://Scenes/level_02.tscn",
	"res://Scenes/level_03.tscn",
]

var current_level := 0


func _ready() -> void:
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.player_died.connect(reload_level)
	# Descobre em qual nível o jogo começou (útil ao rodar com F6 num nível qualquer).
	_sync_index.call_deferred()


func _sync_index() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var i := LEVELS.find(scene.scene_file_path)
	if i != -1:
		current_level = i
	print("[GAME] nível atual: %d (%s)" % [current_level, scene.scene_file_path])


func _on_level_completed() -> void:
	print("[GAME] nível %d concluído" % current_level)
	go_to_level(current_level + 1)


func go_to_level(index: int) -> void:
	if index >= LEVELS.size():
		print("[GAME] fim do jogo, a princesa está livre!")
		return  # aqui depois entra a tela de vitória
	current_level = index
	print("[GAME] carregando ", LEVELS[index])
	# deferred: não troca a cena no meio do callback de física da porta
	get_tree().change_scene_to_file.call_deferred(LEVELS[index])


func reload_level() -> void:
	print("[GAME] recarregando nível %d" % current_level)
	get_tree().reload_current_scene.call_deferred()
