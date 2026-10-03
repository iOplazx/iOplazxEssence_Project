class_name MyGameSave extends EssenceSaveData


# ==========================================
# NEW VARIABLES FOR MAIN GAME TEST
# ==========================================
var current_scene: String = "MainRoom"
var current_phase: int = 0 # We use int because enums (TestPhase.INTRO) are stored as numbers.
var character_clothing_state: Dictionary = {}
var current_room: int = 0
var story_flags: Dictionary = {}
var playtime_seconds: float = 0.0

# 1. Packaging: The Manager will call this to create the save structure.
func _get_child_data() -> Dictionary:
	return {
		GameSaveKeys.CURRENT_SCENE: current_scene,
		GameSaveKeys.CURRENT_PHASE: current_phase,
		GameSaveKeys.CURRENT_ROOM: current_room,
		GameSaveKeys.CHARACTER_CLOTHING_STATE: character_clothing_state,
		GameSaveKeys.STORY_FLAGS: story_flags,
		GameSaveKeys.PLAYTIME_SECONDS: playtime_seconds
	}

# 2. Unpacking: Called when loading an existing game.
func _load_child_data(data: Dictionary) -> void:
	current_scene = data.get(GameSaveKeys.CURRENT_SCENE, "MainRoom")
	current_phase = int(data.get(GameSaveKeys.CURRENT_PHASE, 0))
	character_clothing_state = data.get(GameSaveKeys.CHARACTER_CLOTHING_STATE, {})
	current_room = int(data.get(GameSaveKeys.CURRENT_ROOM, 0))
	story_flags = data.get(GameSaveKeys.STORY_FLAGS, {})
	playtime_seconds = float(data.get(GameSaveKeys.PLAYTIME_SECONDS, 0.0))
	
	# We print a full log to ensure the RAM contains the actual data.
	#print("[MyGameSave] ¡DATOS DE DISCO DESEMPAQUETADOS CON ÉXITO!")
	#print(" -> Habitación Recuperada: ", habitacion_actual)
	#print(" -> Fase: ", fase_actual)
	#print(" -> Banderas de Historia: ", story_flags)
