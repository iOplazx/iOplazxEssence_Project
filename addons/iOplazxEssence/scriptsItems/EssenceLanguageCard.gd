class_name EssenceLanguageCard extends PanelContainer

signal on_info_requested(data: Dictionary)
signal on_apply_requested(folder_name: String)

@export_category("Nodos Internos")
@export var tex_flag: TextureRect
@export var lbl_name: Label
@export var lbl_author: Label
@export var btn_info: Button
@export var btn_apply: Button

@export_category("Estado Híbrido (Iconos)")
@export var icon_game_status: TextureRect
@export var icon_addon_status: TextureRect

var _language_data: Dictionary = {}
var _my_folder_code: String = ""

func _ready():
	if btn_info:
		btn_info.icon = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_INFO)
		btn_info.text = "" 
	
	if btn_info: btn_info.pressed.connect(_on_info_pressed)
	if btn_apply: btn_apply.pressed.connect(_on_apply_pressed)

func setup_card(data: Dictionary, current_locale: String):
	_language_data = data
	_my_folder_code = data.get("folder", "en")
	
	if lbl_name: lbl_name.text = data.get("name", "Unknown")
	if lbl_author: lbl_author.text = "Por: " + data.get("author", "Comunidad")
	
	if tex_flag and data.has("flag_path"):
		var path = data["flag_path"]
		
		# Si es nativo y NO está ignorado por el debug
		if path.begins_with("res://") and not "_remote_debug" in path:
			tex_flag.texture = load(path)
		else:
			# TRADUCCIÓN A RUTA REAL (C:/...)
			# Esto convierte "res://_remote_debug/..." o "user://..." a la ruta de tu PC
			var real_path = ProjectSettings.globalize_path(path)
			
			# Ahora sí, tu loader externo puede buscar el archivo en el disco duro
			tex_flag.texture = EssenceLoader.get_externImage(real_path)
			
	# === LÓGICA DE ICONOS DE ESTADO ===
	# Si el diccionario dice que está soportado, pintamos el icono de verde. Si no, gris oscuro.
	if icon_game_status:
		var has_game = data.get("game_supported", false)
		icon_game_status.modulate = Color(0.2, 0.8, 0.2) if has_game else Color(0.3, 0.3, 0.3)
		
	if icon_addon_status:
		var has_addon = data.get("addon_supported", false)
		icon_addon_status.modulate = Color(0.2, 0.8, 0.2) if has_addon else Color(0.3, 0.3, 0.3)
			
	refresh_state(current_locale)

func refresh_state(current_locale: String):
	if not btn_apply: return
	
	if _my_folder_code == current_locale:
		btn_apply.disabled = true
		btn_apply.text = tr("MENU_SELECTED") 
	else:
		btn_apply.disabled = false
		btn_apply.text = tr("MENU_APPLY")

func _on_info_pressed():
	on_info_requested.emit(_language_data)
	AudioManager.play_ui_sfx()

func _on_apply_pressed():
	on_apply_requested.emit(_my_folder_code)
	AudioManager.play_ui_sfx()
