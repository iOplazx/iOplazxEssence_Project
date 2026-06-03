class_name MyGameSave extends EssenceSaveData


# ==========================================
# NUEVAS VARIABLES PARA TEST MAIN GAME
# ==========================================
var escena_actual: String = "MainRoom"
var fase_actual: int = 0 # Usamos int porque los enum (TestPhase.INTRO) se guardan como números
var ropa_estado_personaje: Dictionary = {}
var habitacion_actual: int = 0
var story_flags: Dictionary = {}

# 2. Empaquetado: El Manager llamará a esto para crear el JSON
func _get_child_data() -> Dictionary:
	return {
		"escena_actual": escena_actual,
		"fase_actual": fase_actual,
		"habitacion_actual": habitacion_actual,
		"ropa_estado_personaje": ropa_estado_personaje,
		"story_flags": story_flags
	}

# 3. Desempaquetado: Se llama al cargar una partida existente
func _load_child_data(data: Dictionary) -> void:
	escena_actual = data.get("escena_actual", "MainRoom")
	fase_actual = int(data.get("fase_actual", 0))
	ropa_estado_personaje = data.get("ropa_estado_personaje", {})
	
	habitacion_actual = int(data.get("habitacion_actual", 0))
	story_flags = data.get("story_flags", {})
	
	# Imprimimos un log completo para asegurarnos que la RAM tiene los datos reales
	#print("[MyGameSave] ¡DATOS DE DISCO DESEMPAQUETADOS CON ÉXITO!")
	#print(" -> Habitación Recuperada: ", habitacion_actual)
	#print(" -> Fase: ", fase_actual)
	#print(" -> Banderas de Historia: ", story_flags)
