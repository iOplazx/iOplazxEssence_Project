extends EssenceSaveManager

# ==============================================================================
# GAME SAVE MANAGER (AUTOLOAD)
# ==============================================================================

func _ready():
	super._ready()
	# Aquí es donde el Addon confirma que está listo para recibir datos
	print("GameSaveManager: Sistema de persistencia listo para la Demo.")

# ==============================================================================
# INTEGRATION HOOKS
# ==============================================================================

func _on_before_save_hook(game_data: Dictionary, meta_data: Dictionary):
	# Este método se dispara tanto en guardados manuales como en Checkpoints.
	# Es el lugar ideal para "empaquetar" el estado del juego.
	
	# Ejemplo de Metadata para que el menú de carga se vea profesional:
	meta_data["location"] = "Pantalla de Inicio"
	meta_data["playtime"] = "00:00:00" # Aquí iría el tiempo real de juego
	meta_data["player_level"] = 1
	
	# Ejemplo de datos de juego (simulados para la demo):
	game_data["demo_progress"] = "Visto el menú principal"
	game_data["unlocked_gallery"] = false
	
	# Si hubiera gameplay, aquí recolectarías los grupos:
	# var persist_nodes = get_tree().get_nodes_in_group("Persist")
	# ... lógica de recolección ...

func _on_after_load_hook(game_data: Dictionary):
	# Este método se dispara después de que los datos físicos se leen del disco.
	# Es el lugar para "desempaquetar" y aplicar los datos al juego.
	
	if game_data.has("demo_progress"):
		print("Carga completa: El progreso detectado es: ", game_data["demo_progress"])
	
	# Si el Checkpoint o el Back cargan una partida, aquí restaurarías:
	# 1. Posición del jugador
	# 2. Estado de la historia
	# 3. Inventario
	
	# Emitir señal para avisar al resto del juego que la carga terminó
	# on_load_completed.emit("slot_id", game_data)
