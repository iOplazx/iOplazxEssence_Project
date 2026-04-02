class_name MyGameSave extends EssenceSaveData

# 1. Variables con tipado fuerte (Mejora el autocompletado y rendimiento)
var box_color: String = "ffffff"
var player_hp: int = 100

# 2. Empaquetado: El Manager llamará a esto para crear el JSON
func _get_child_data() -> Dictionary:
	return {
		"box_color": box_color,
		"player_hp": player_hp
	}

# 3. Desempaquetado: Se llama al cargar una partida existente
func _load_child_data(data: Dictionary):
	# Usamos el segundo parámetro de .get() para asegurar el tipo de dato correcto
	box_color = data.get("box_color", "ffffff")
	player_hp = int(data.get("player_hp", 100))
	
	print("iOplazxEssence: [MyGameSave] Datos cargados -> Color: ", box_color, " | HP: ", player_hp)
