class_name EssenceLanguageCard extends PanelContainer

# Estas señales le avisarán al menú principal cuando el usuario haga clic
signal on_info_requested(data: Dictionary)
signal on_apply_requested(folder_name: String)

@export_category("Nodos Internos")
@export var tex_flag: TextureRect
@export var lbl_name: Label
@export var lbl_author: Label
@export var btn_info: Button
@export var btn_apply: Button

var _language_data: Dictionary = {}
var _my_folder_code: String = ""

func _ready():
	# 1. Cargamos el icono que acabas de agregar al EssencePaths
	if btn_info:
		btn_info.icon = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_INFO)
		btn_info.text = "" # Borramos la "i" de texto para que solo quede tu imagen
	
	# 2. Conectamos los clics
	if btn_info:
		btn_info.pressed.connect(_on_info_pressed)
	if btn_apply:
		btn_apply.pressed.connect(_on_apply_pressed)

# Esta es la función mágica que usaremos más adelante para llenar los datos
func setup_card(data: Dictionary, current_locale: String):
	_language_data = data
	_my_folder_code = data.get("folder", "en")
	
	if lbl_name: lbl_name.text = data.get("name", "Unknown")
	if lbl_author: lbl_author.text = "Por: " + data.get("author", "Comunidad")
	
	if tex_flag and data.has("flag_path"):
		var path = data["flag_path"]
		if path.begins_with("res://"):
			tex_flag.texture = load(path)
		else:
			tex_flag.texture = EssenceLoader.get_externImage(path)
			
	# Evaluamos el estado inicial del botón
	refresh_state(current_locale)

func refresh_state(current_locale: String):
	if not btn_apply: return
	
	if _my_folder_code == current_locale:
		btn_apply.disabled = true
		btn_apply.text = tr("MENU_SELECTED") # Godot traducirá esto automáticamente
	else:
		btn_apply.disabled = false
		btn_apply.text = tr("MENU_APPLY")

func _on_info_pressed():
	on_info_requested.emit(_language_data)
	# ¡Y usamos tu AudioManager global para el feedback!
	AudioManager.play_ui_sfx()

func _on_apply_pressed():
	on_apply_requested.emit(_language_data.get("folder", "en"))
	AudioManager.play_ui_sfx()
