class_name EssenceSaveData extends RefCounted

# ==========================================
# DATOS OBLIGATORIOS DEL FRAMEWORK
# ==========================================
var version: int = 1
var timestamp: float = 0.0
var date_string: String = ""
var title: String = "Auto-Save"
var description: String = "" 
var play_time: String = "00:00:00"
var slot_number: int = 1
var page: int = 1
var is_auto: bool = false
# ==========================================
# LÓGICA DE SERIALIZACIÓN (Para el JSON)
# ==========================================
func to_dict() -> Dictionary:
	# 1. El tiempo para la máquina (Ordenamiento)
	if timestamp == 0.0:
		timestamp = Time.get_unix_time_from_system()
		
	# 2. El tiempo para el humano (Interfaz limpia sin gastar CPU)
	if date_string == "":
		date_string = Time.get_datetime_string_from_system(false, true).replace("T", " ")
	
	return {
		"essence_meta": {
			"version": version,
			"timestamp": timestamp,
			"date_string": date_string,
			"title": title,
			"description": description,
			"play_time": play_time,
			"slot_number": slot_number,
			"page": page,
			"is_auto": is_auto
		},
		"game_data": _get_child_data() 
	}


# ==========================================
# LÓGICA DE DESERIALIZACIÓN Y SANITIZACIÓN (Para el Factory)
# ==========================================
func from_dict(data: Dictionary):
	var meta = data.get("essence_meta", {})
	
	version = meta.get("version", 1)
	timestamp = meta.get("timestamp", 0.0)
	date_string = meta.get("date_string", "")
	title = meta.get("title", "Unknown Save")
	description = meta.get("description", "")
	play_time = meta.get("play_time", "00:00:00")
	slot_number = meta.get("slot_number", 1)
	page = meta.get("page", 1)
	is_auto = meta.get("is_auto", false)
	
	_load_child_data(data.get("game_data", {}))

# ==========================================
# MÉTODOS VIRTUALES (Para que el Dev los sobrescriba)
# ==========================================
func _get_child_data() -> Dictionary:
	push_warning("iOplazxEssence: _get_child_data() no ha sido sobrescrito por el desarrollador.")
	return {}

func _load_child_data(_data: Dictionary):
	push_warning("iOplazxEssence: _load_child_data() no ha sido sobrescrito por el desarrollador.")
