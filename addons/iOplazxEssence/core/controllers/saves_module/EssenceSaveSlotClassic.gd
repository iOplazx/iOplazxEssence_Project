extends PanelContainer 
const ES_NAME_CLASS = "EssenceSaveSlotClassic"

signal on_slot_clicked(action: String, slot_id: String)

@export var img_screenshot: TextureRect
@export var lbl_slot_number: Label 
@export var lbl_save_date: Label

@onready var btn_click = $BtnClick

@export var fallback_image: Texture2D

var _my_slot_id: String
var _is_save_mode: bool
var _has_data: bool

func _ready():
	if btn_click and not btn_click.pressed.is_connected(_on_ghost_button_pressed):
		btn_click.pressed.connect(_on_ghost_button_pressed)

func setup(slot_id: String, save_data: Dictionary, is_save_mode: bool):
	_my_slot_id = slot_id
	_is_save_mode = is_save_mode
	
	# Formatear el ID visual usando tu lógica
	var visual_id = ""
	if slot_id.begins_with("auto_"): 
		visual_id = slot_id.replace("auto_", "Auto ")
	else:
		# "save_1_1" se convierte en "Slot 1-1"
		visual_id = "Slot " + slot_id.replace("save_", "").replace("_", "-")
	
	# Asignamos el número a su etiqueta correspondiente
	if lbl_slot_number:
		lbl_slot_number.text = visual_id
	
	if save_data.is_empty():
		_has_data = false
		if lbl_save_date: lbl_save_date.text = tr("SLOT_EMPTY")
		if img_screenshot: img_screenshot.texture = null 
	else:
		_has_data = true
		if lbl_save_date: 
			lbl_save_date.text = save_data.get("date_string", "Sin fecha") 
			
		# Llamamos a la función para cargar la foto
		_cargar_imagen_screenshot(slot_id)

func _on_ghost_button_pressed():
	var log_msg = ""
	# Si estamos en modo Cargar y está vacío, no hacemos nada
	if not _is_save_mode and not _has_data:
		#print("iOplazxEssence: Slot vacío. No se puede cargar.")
		log_msg = "You tried to load from an empty slot (%s). Make sure the player can only interact with full slots in Load mode." % _my_slot_id
		EssenceLogger.system_info(log_msg)
		return
		
	var action = "SAVE" if _is_save_mode else "LOAD"
	#print("iOplazxEssence: Emitiendo señal -> ", action, " en ", _my_slot_id)
	log_msg = "Player clicked on slot %s with action %s." % [_my_slot_id, action]
	EssenceLogger.system_info(log_msg)
	on_slot_clicked.emit(action, _my_slot_id)

func _cargar_imagen_screenshot(slot_id: String):
	if not img_screenshot: return
	
	var image_path = SaveManager._save_dir + slot_id + ".webp"
	var loaded_successfully = false
	
	# Intentamos cargar la imagen real
	if FileAccess.file_exists(image_path):
		var img = Image.new()
		var err = img.load(image_path)
		
		if err == OK:
			img_screenshot.texture = ImageTexture.create_from_image(img)
			img_screenshot.modulate = Color.WHITE
			loaded_successfully = true
		else:
			#push_warning("iOplazxEssence: La foto de " + slot_id + " está corrupta. Usando fallback.")
			EssenceError.report(
				"Corrupt Image",
				"The screenshot for slot %s is corrupt." % slot_id,
				EssenceError.Severity.WARNING
			)
			
	# Si no existe o hubo un error al cargarla, usamos la imagen por defecto
	if not loaded_successfully:
		if fallback_image:
			img_screenshot.texture = fallback_image
			img_screenshot.modulate = Color.WHITE
		else:
			# Si el dev tampoco asignó un fallback en el inspector, lo dejamos limpio
			img_screenshot.texture = null
