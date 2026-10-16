class_name RotationDialSet
extends Resource
## Um estágio de desbloqueio do dial de rotação.
##
## Como cada frame do dial já vem com o círculo, o cristal e as bolinhas
## desenhados juntos, a textura não depende só do ângulo: depende também de
## quantas rotações estão liberadas. Um Resource destes agrupa os frames de
## um mesmo estágio.
##
## Exemplo (fase 2, horizontal e vertical liberadas):
##   steps  = [0, 2]
##   frames = [dial_2_0.png, dial_2_2.png]
##
## A ordem de "frames" acompanha a de "steps": frames[i] é o desenho do dial
## com o cristal no ângulo steps[i] * 45°.

## Passos de 45° liberados neste estágio. Precisa bater com o allowed_steps
## exportado no Floor_XX que usa este dial.
@export var steps: Array[int] = []

## Um frame por passo, na mesma ordem de "steps".
@export var frames: Array[Texture2D] = []


## Chave canônica do conjunto, usada para casar este Resource com o que o
## andar liberou. Ordena para que [2, 0] e [0, 2] sejam o mesmo estágio.
func key() -> String:
	var sorted := steps.duplicate()
	sorted.sort()
	return ",".join(sorted.map(func(s): return str(s)))


## Textura do ângulo pedido, ou null se este estágio não o contém.
func frame_for(step: int) -> Texture2D:
	var i := steps.find(step)
	if i < 0 or i >= frames.size():
		return null
	return frames[i]


## Avisa no editor quando o Resource está meio preenchido.
func is_valid() -> bool:
	return not steps.is_empty() and steps.size() == frames.size()
