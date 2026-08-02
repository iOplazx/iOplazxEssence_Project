## [EssenceBaseMiniGame]
## Clase base de la que heredarán todos los minijuegos del proyecto.
class_name EssenceBaseMiniGame
extends Control

## Emitir cuando el minijuego termine.
## [param result_data]: Diccionario con el estado final (ej: {"victory": true, "score": 100})
signal minigame_completed(result_data: Dictionary)

## Emitir si el jugador abandona o cierra el minijuego sin terminarlo
signal minigame_cancelled

## Finaliza el minijuego informando victoria o derrota
func finish_minigame(is_victory: bool, extra_data: Dictionary = {}) -> void:
	var result: Dictionary = {
		"victory": is_victory
	}
	# Mezclamos datos adicionales si los hay (puntos, tiempo, ítems ganados, etc.)
	result.merge(extra_data, true)
	
	minigame_completed.emit(result)


## Cancela la ejecución del minijuego
func cancel_minigame() -> void:
	minigame_cancelled.emit()
