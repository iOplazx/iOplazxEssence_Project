extends PanelContainer 

signal on_slot_clicked(action: String, slot_id: String)

@export var img_screenshot: TextureRect
@export var lbl_slot_number: Label 
@export var lbl_save_date: Label

@onready var btn_click = $BtnClick

var _my_slot_id: String
var _is_save_mode: bool
var _has_data: bool

func setup(slot_id: String, save_data: Dictionary, is_save_mode: bool):
	_my_slot_id = slot_id
	_is_save_mode = is_save_mode
	
	# Formatear el ID visual (Ej: "save_1_1" -> "1-1")
	var visual_id = slot_id.replace("save_", "").replace("_", "-")
	if slot_id.begins_with("auto_"): visual_id = slot_id.replace("auto_", "Auto ")
	
	# Asignamos el número a su etiqueta correspondiente
	if lbl_slot_number:
		lbl_slot_number.text = visual_id
	
	# ARREGLO 1: Preguntamos si está vacío, no si es null
	if save_data.is_empty():
		_has_data = false
		if lbl_save_date: lbl_save_date.text = tr("SLOT_EMPTY")
		# Limpiamos la imagen si el slot está vacío
		if img_screenshot: img_screenshot.texture = null 
	else:
		_has_data = true
		if lbl_save_date: 
			lbl_save_date.text = save_data.get("date_string", "Sin fecha") 
			
		# Llamamos a la función para cargar la foto
		_cargar_imagen_screenshot(slot_id)
		
	if btn_click:
		btn_click.pressed.connect(_on_ghost_button_pressed)

func _on_ghost_button_pressed():
	# Si estamos en modo Cargar y está vacío, no hacemos nada
	if not _is_save_mode and not _has_data:
		print("iOplazxEssence: Slot vacío. No se puede cargar.")
		return
		
	var action = "SAVE" if _is_save_mode else "LOAD"
	print("iOplazxEssence: Emitiendo señal -> ", action, " en ", _my_slot_id)
	on_slot_clicked.emit(action, _my_slot_id)

func _cargar_imagen_screenshot(slot_id: String):
	if not img_screenshot: 
		print("iOplazxEssence: ERROR - El nodo img_screenshot no está asignado en el Inspector.")
		return
	
	var image_path = SaveManager._save_dir + slot_id + ".webp"
	print("iOplazxEssence: Buscando foto en -> ", image_path)
	
	if FileAccess.file_exists(image_path):
		# --- PRUEBA VISUAL (Rayo X) ---
		# Forzamos el nodo a color ROJO para ver si físicamente existe en la pantalla
		img_screenshot.modulate = Color.RED 
		
		var img = Image.new()
		var err = img.load(image_path)
		
		if err == OK:
			print("iOplazxEssence: ¡Foto encontrada y decodificada! Aplicando textura...")
			img_screenshot.texture = ImageTexture.create_from_image(img)
			
			# Si cargó bien, le quitamos el rojo para que se vea normal
			img_screenshot.modulate = Color.WHITE 
		else:
			push_error("iOplazxEssence: La foto existe, pero está corrupta. Error código: " + str(err))
	else:
		print("iOplazxEssence: No se encontró la foto .webp en el disco duro.")
