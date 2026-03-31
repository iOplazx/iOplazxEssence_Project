class_name MyGameSave extends EssenceSaveData

var player_hp: int = 100
var current_level: String = "Town"
var inventory: Array = []

func _get_child_data() -> Dictionary:
	return {}

func _load_child_data(data: Dictionary):
	player_hp = data.get("hp", 100)
	current_level = data.get("lvl", "Town")
	inventory = data.get("inv", [])
	
	# Ejemplo de sanitización por versión
	if version == "0.9.0":
		print("Migrando inventario antiguo...")
		# ... lógica de actualización de datos ...
