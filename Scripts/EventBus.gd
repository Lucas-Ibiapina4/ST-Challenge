extends Node
# --- Cristais ------------------------------------------------------------
## Emite: CrystalConjurerComponent (ao entrar no andar, conjurar ou recolher).
## Escuta: HUD → atualiza o contador e o ícone de cristal.
@warning_ignore("unused_signal")
signal crystal_inventory_changed(remaining: int, max_quota: int, crystal_type: String)

## Emite: CrystalConjurerComponent (ao entrar no andar e ao girar).
## Escuta: HUD → redesenha o dial com as rotações liberadas no andar e
##         destaca a que está selecionada.
## step: passo real escolhido (0..7, em 45°).
## allowed_steps: passos liberados neste andar, na ordem em que o ciclo anda.
@warning_ignore("unused_signal")
signal crystal_rotation_changed(step: int, allowed_steps: Array)

# --- Porta ---------------------------------------------------------------
## Emite: Door, depois de destrancar ao receber light_received do DoorReceiver.
## Escuta: HUD → feedback de porta aberta.
@warning_ignore("unused_signal")
signal door_unlocked

# --- Fluxo do andar ------------------------------------------------------
## Emite: TransitionArea2D, quando o Player entra nela (só fica ativa após destrancar).
## Escuta: GameManager → atualiza o progresso e faz o autosave.
##         World → destrói o Floor_XX atual, instancia o próximo, Player vai ao SpawnPoint.
@warning_ignore("unused_signal")
signal level_completed

## Emite: HurtboxComponent, ao colidir com a Layer 3 (Hazards).
## Escuta: World → reposiciona o Player no SpawnPoint do andar atual.
## A morte não volta ao primeiro andar.
@warning_ignore("unused_signal")
signal player_died
