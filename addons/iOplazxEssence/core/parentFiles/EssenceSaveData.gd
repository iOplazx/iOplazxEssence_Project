class_name EssenceSaveData extends RefCounted

# ==========================================
# DATOS OBLIGATORIOS DEL FRAMEWORK
# ==========================================
var version: int = 1
var timestamp: float = 0.0
var title: String = "Auto-Save"
var play_time: String = "00:00:00"
var slot_number: int = 1
var page: int = 1
var is_auto: bool = false

# ==========================================
# LÓGICA DE SERIALIZACIÓN (Para el JSON)
# ==========================================
func to_dict() -> Dictionary:
	var dict = {
		"essence_meta": {
			"version": version,
			"timestamp": Time.get_unix_time_from_system() if timestamp == 0.0 else timestamp,
			"title": title,
			"play_time": play_time,
			"slot_number": slot_number,
			"page": page,
			"is_auto": is_auto
		},
		# Aquí ocurre la magia: llamamos al método del hijo
		"game_data": _get_child_data() 
	}
	return dict

# ==========================================
# LÓGICA DE DESERIALIZACIÓN Y SANITIZACIÓN (Para el Factory)
# ==========================================
func from_dict(data: Dictionary):
	var meta = data.get("essence_meta", {})
	
	# Sanitización base con valores por defecto seguros
	version = meta.get("version", 1)
	timestamp = meta.get("timestamp", 0.0)
	title = meta.get("title", "Unknown Save")
	play_time = meta.get("play_time", "00:00:00")
	slot_number = meta.get("slot_number", 1)
	page = meta.get("page", 1)
	is_auto = meta.get("is_auto", false)
	
	# Le pasamos el resto de los datos al hijo para que se reconstruya
	_load_child_data(data.get("game_data", {}))

# ==========================================
# MÉTODOS VIRTUALES (Para que el Dev los sobrescriba)
# ==========================================
func _get_child_data() -> Dictionary:
	push_warning("iOplazxEssence: _get_child_data() no ha sido sobrescrito por el desarrollador.")
	return {}

func _load_child_data(_data: Dictionary):
	push_warning("iOplazxEssence: _load_child_data() no ha sido sobrescrito por el desarrollador.")
