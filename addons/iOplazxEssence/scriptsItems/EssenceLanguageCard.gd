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
		btn_info.icon = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_INFO_MED)
		btn_info.text = "" 
		btn_info.pressed.connect(_on_info_pressed)
		
	if btn_apply: 
		btn_apply.pressed.connect(_on_apply_pressed)
		
	# Cargar iconos por defecto para los estados
	if icon_game_status:
		icon_game_status.texture = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_CONTROL_W)
	if icon_addon_status:
		icon_addon_status.texture = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_LAYOUT_W)

func setup_card(data: Dictionary, current_locale: String):
	_language_data = data
	_my_folder_code = data.get("folder", "en")
	
	if lbl_name: 
		lbl_name.text = data.get("name", "Unknown")
	
	# === 1. LÓGICA DE AUTORES (SIEMPRE DIVIDIDOS) ===
	if lbl_author:
		# Textos base traducidos
		var t_game = tr("LANG_GAME")           # "Juego"
		var t_addon = tr("LANG_ADDON")         # "Sistema"
		
		var author_game = data.get("game_data", {}).get("author", "Comunidad")
		var author_addon = data.get("addon_data", {}).get("author", "Comunidad")
		
		# Mostramos siempre la división para dejar claro quién hizo cada parte
		lbl_author.text = t_game + ": " + author_game + " | " + t_addon + ": " + author_addon
	
	# === 2. LÓGICA DE LA BANDERA ===
	if tex_flag and data.has("flag_path"):
		var path = data["flag_path"]
		if path.begins_with("res://") and not "_remote_debug" in path:
			tex_flag.texture = load(path)
		else:
			var real_path = ProjectSettings.globalize_path(path)
			tex_flag.texture = EssenceLoader.get_externImage(real_path)
			
	# === 3. SEMÁFORO SIMPLIFICADO (VERDE / ROJO) ===
	
	if icon_game_status:
		var has_game = data.get("game_supported", false)
		icon_game_status.modulate = Color(0.2, 0.8, 0.2) if has_game else Color(0.8, 0.2, 0.2)
		icon_game_status.tooltip_text = tr("INFO_GAME_LANG_OK") if has_game else tr("INFO_GAME_LANG_MISSING")
		
	if icon_addon_status:
		var has_addon = data.get("addon_supported", false)
		var is_fallback = data.get("addon_is_fallback", false)
		
		# Si es fallback (entró el inglés por defecto), para nosotros es ROJO (No disponible)
		if has_addon and not is_fallback:
			icon_addon_status.modulate = Color(0.2, 0.8, 0.2) # Verde (Soportado)
			icon_addon_status.tooltip_text = tr("INFO_ADDON_LANG_OK")
		else:
			icon_addon_status.modulate = Color(0.8, 0.2, 0.2) # Rojo (No disponible)
			icon_addon_status.tooltip_text = tr("INFO_ADDON_LANG_MISSING")
			
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
