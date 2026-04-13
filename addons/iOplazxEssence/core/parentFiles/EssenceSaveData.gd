class_name EssenceSaveData extends RefCounted
const ES_NAME_CLASS = "EssenceSaveData"

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
# GESTIÓN DE INTENCIONES (CRUD EN MEMORIA)
# ==========================================

# Se llama cuando es un slot vacío
func prepare_as_new(temp_meta: Dictionary, temp_game: Dictionary):
	title = temp_meta.get("title", "Auto-Save")
	description = temp_meta.get("description", "")
	play_time = temp_meta.get("play_time", "00:00:00")
	_load_child_data(temp_game)

# Se llama cuando se va a pisar una partida existente
func prepare_as_overwrite(old_data: Dictionary, temp_meta: Dictionary, temp_game: Dictionary):
	# 1. Cargamos la meta-información vieja para rescatar cosas importantes
	var old_meta = old_data.get("essence_meta", {})
	
	# RESCATE DE TÍTULO: Si el viejo ya tenía título, lo conservamos. Si no, usamos el nuevo.
	var old_title = old_meta.get("title", "")
	if old_title != "" and old_title != "Auto-Save":
		title = old_title
	else:
		title = temp_meta.get("title", "Auto-Save")
		
	description = temp_meta.get("description", "")
	play_time = temp_meta.get("play_time", "00:00:00")
	
	# Conservamos la ubicación exacta en el grid
	page = old_meta.get("page", 1)
	slot_number = old_meta.get("slot_number", 1)
	
	# 2. Le pasamos los datos al desarrollador por si quiere "fusionar" en vez de reemplazar
	_handle_overwrite_game_data(old_data.get("game_data", {}), temp_game)


# ==========================================
# LÓGICA DE SERIALIZACIÓN (Para el JSON)
# ==========================================
func to_dict() -> Dictionary:
	if timestamp == 0.0:
		timestamp = Time.get_unix_time_from_system()
		
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

func from_dict(data: Dictionary):
	if data.is_empty():
		EssenceLogger.system_info("[%s] Advertencia: Intentando cargar un diccionario vacío en from_dict." % [ES_NAME_CLASS])
		return

	# 1. Obtenemos la meta-información del framework
	var meta = data.get("essence_meta", {})
	
	# Mapeo completo de variables obligatorias
	version     = meta.get("version", 1)
	timestamp   = meta.get("timestamp", 0.0)
	date_string = meta.get("date_string", "")
	title       = meta.get("title", "Auto-Save")
	description = meta.get("description", "")
	play_time   = meta.get("play_time", "00:00:00")
	slot_number = meta.get("slot_number", 1)
	page        = meta.get("page", 1)
	is_auto     = meta.get("is_auto", false)

	# 2. Cargamos los datos específicos del juego (los que define el desarrollador)
	# Esto llama al método virtual que el usuario debe sobrescribir.
	_load_child_data(data.get("game_data", {}))
	
	EssenceLogger.system_info("[%s] Datos deserializados correctamente para el slot %d" % [ES_NAME_CLASS, slot_number])

# ==========================================
# MÉTODOS VIRTUALES (Para que el Dev los sobrescriba)
# ==========================================
func _get_child_data() -> Dictionary:
	return {}

func _load_child_data(_data: Dictionary):
	pass

# ¡NUEVO HOOK PARA EL DESARROLLADOR!
func _handle_overwrite_game_data(_old_game_data: Dictionary, new_game_data: Dictionary):
	# Por defecto, simplemente reemplaza los datos viejos con los nuevos.
	# Pero el desarrollador puede hacer un override para, por ejemplo, 
	# mantener estadísticas acumulativas (ej: muertes totales).
	_load_child_data(new_game_data)
