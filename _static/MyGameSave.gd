class_name MyGameSave extends EssenceSaveData

# 1. Variables con tipado fuerte (Mejora el autocompletado y rendimiento)
var box_color: String = "ffffff"
var player_hp: int = 100

# ==========================================
# NUEVAS VARIABLES PARA TEST MAIN GAME
# ==========================================
var escena_actual: String = "MainRoom"
var fase_actual: int = 0 # Usamos int porque los enum (TestPhase.INTRO) se guardan como números
var ropa_estado_personaje: Dictionary = {}
var habitacion_actual: String
var story_flags: Dictionary

# 2. Empaquetado: El Manager llamará a esto para crear el JSON
func _get_child_data() -> Dictionary:
	return {
		"box_color": box_color,
		"player_hp": player_hp,
		# Empaquetamos los nuevos datos
		"escena_actual": escena_actual,
		"fase_actual": fase_actual,
		"habitacion_actual": habitacion_actual,
		"ropa_estado_personaje": ropa_estado_personaje,
		"story_flags": story_flags
	}

# 3. Desempaquetado: Se llama al cargar una partida existente
func _load_child_data(data: Dictionary):
	# Usamos el segundo parámetro de .get() para asegurar el tipo de dato correcto
	box_color = data.get("box_color", "ffffff")
	player_hp = int(data.get("player_hp", 100))
	
	# Desempaquetamos los nuevos datos con sus valores por defecto
	escena_actual = data.get("escena_actual", "MainRoom")
	fase_actual = int(data.get("fase_actual", 0))
	ropa_estado_personaje = data.get("ropa_estado_personaje", {})
	
	print("[MyGameSave] Datos cargados -> Fase: ", fase_actual, " | Ropa: ", ropa_estado_personaje)
	
