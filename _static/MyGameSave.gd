class_name MyGameSave extends EssenceSaveData

# 1. Tus variables reales del juego
var box_color: String = "ffffff"
var player_hp: int = 100

# 2. El dev empaqueta sus datos (Para escribir en el disco)
func _get_child_data() -> Dictionary:
	return {
		"box_color": box_color,
		"player_hp": player_hp
	}

# 3. El dev desempaqueta sus datos (Al leer del disco)
func _load_child_data(data: Dictionary):
	box_color = data.get("box_color", "ffffff")
	player_hp = data.get("player_hp", 100)
	print("iOplazxEssence: MyGameSave cargó el color -> ", box_color)
