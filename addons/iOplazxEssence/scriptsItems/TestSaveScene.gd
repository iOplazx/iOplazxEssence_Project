extends Control

@export var btn_save: Button
@export var btn_load: Button
@export var btn_return: Button
@export var lbl_output: Label
@export var test_element: ColorRect

# Usaremos un slot fijo para esta prueba
var _test_slot_id: String = "save_1_1"

func _ready():
	btn_save.pressed.connect(_on_save_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_return.pressed.connect(_on_return_pressed)
	
	lbl_output.text = "Escena de prueba lista.\nEsperando acción..."
	
	# Cambiamos el color del cuadro al iniciar para la prueba visual
	if test_element:
		test_element.color = Color(randf(), randf(), randf())

func _on_save_pressed():
	lbl_output.text = "Guardando y tomando captura..."
	
	# 1. Tomamos la captura PRIMERO (usamos await porque la función espera el frame)
	await SaveManager.take_and_save_screenshot(_test_slot_id)
	
	# 2. Generamos "Game Data" (lo que el juego guardaría: HP, posición, etc.)
	var mock_game_data = {
		"player_hp": randi_range(20, 100),
		"player_gold": randi_range(500, 9999),
		"current_map": "Test Sandbox",
		"box_color": test_element.color.to_html() # Guardamos el color actual
	}
	
	# 3. Generamos "Meta Data" (lo que la UI necesita para mostrar en la lista)
	var mock_meta_data = {
		"slot_page": 1,
		"slot_number": 1,
		"title": "Prueba de Framework",
		"description": "Zona de Pruebas",
		"duration_game": "00:05:23",
		"datetime": Time.get_datetime_string_from_system()
	}
	
	# 4. Enviamos al Manager
	var success = SaveManager.save_game(_test_slot_id, mock_game_data, mock_meta_data)
	
	if success:
		lbl_output.text = "¡Guardado exitoso en " + _test_slot_id + "!\n"
		lbl_output.text += "Revisa la carpeta para ver el .ess y el .webp."
		
		# Cambiamos el color DESPUÉS de guardar para probar que al cargar, vuelva al anterior
		test_element.color = Color(randf(), randf(), randf())

func _on_load_pressed():
	lbl_output.text = "Cargando..."
	
	# Pedimos los datos al Manager (ya vienen descifrados y migrados)
	var data = SaveManager.load_game(_test_slot_id)
	
	if data.is_empty():
		lbl_output.text = "Error: No se encontró partida en " + _test_slot_id
		return
		
	# JSON.stringify con "\t" nos formatea el diccionario con sangrías bonitas para leerlo
	lbl_output.text = "DATOS CARGADOS:\n\n" + JSON.stringify(data, "\t")
	
	# Aplicamos el dato cargado al mundo real (restauramos el color del cuadro)
	var loaded_color_html = data.get("game_data", {}).get("box_color", "ffffff")
	test_element.color = Color(loaded_color_html)

func _on_return_pressed():
	# lbl_output.text = "Volviendo al menú principal..."
	SceneManager.go_back()
	print("Saliendo de la escena de prueba.")
