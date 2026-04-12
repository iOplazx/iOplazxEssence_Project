class_name EssenceLanguageCard extends PanelContainer

const ES_NAME_CLASS = "EssenceLanguageCard"

signal on_info_requested(data: Dictionary)
signal on_apply_requested(folder_name: String)

@export_category("Internal Nodes")
@export var tex_flag: TextureRect
@export var lbl_name: Label
@export var lbl_author: Label
@export var btn_info: Button
@export var btn_apply: Button

@export_category("Hybrid State (Icons)")
@export var icon_game_status: TextureRect
@export var icon_addon_status: TextureRect

var _language_data: Dictionary = {}
var _my_folder_code: String = ""

func _ready():
	_check_security_nodes()
	
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

# ==========================================
# SECURITY & BLINDING
# ==========================================
func _check_security_nodes():
	var missing = []
	if not tex_flag: missing.append("tex_flag")
	if not lbl_name: missing.append("lbl_name")
	if not lbl_author: missing.append("lbl_author")
	if not btn_info: missing.append("btn_info")
	if not btn_apply: missing.append("btn_apply")
	if not icon_game_status: missing.append("icon_game_status")
	if not icon_addon_status: missing.append("icon_addon_status")
	
	if missing.size() > 0:
		var msg = "Missing exported nodes in %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		if is_instance_valid(EssenceError) and EssenceError.has_method("report"):
			EssenceError.report("UI Setup Warning", msg, EssenceError.Severity.WARNING)
		else:
			push_error(msg)

# ==========================================
# DATA INJECTION & SETUP
# ==========================================
func setup_card(data: Dictionary, current_locale: String):
	_language_data = data
	_my_folder_code = data.get("folder", "en")
	
	if lbl_name: 
		lbl_name.text = data.get("name", "Unknown")
	
	# === 1. LÓGICA DE AUTORES (SIEMPRE DIVIDIDOS) ===
	if lbl_author:
		var t_game = tr("LANG_GAME")           # "Juego"
		var t_addon = tr("LANG_ADDON")         # "Sistema"
		
		var author_game = data.get("game_data", {}).get("author", "Community")
		var author_addon = data.get("addon_data", {}).get("author", "Community")
		
		lbl_author.text = t_game + ": " + author_game + " | " + t_addon + ": " + author_addon
	
	# === 2. LÓGICA DE LA BANDERA (Refactorizada con Smart Loader) ===
	if tex_flag and data.has("flag_path"):
		var path = data["flag_path"]
		
		# Resolvemos la ruta absoluta solo si es externa
		var final_path = path
		if not path.begins_with("res://"):
			final_path = ProjectSettings.globalize_path(path)
			
		# ¡MAGIA! Usamos el método blindado que creamos antes
		tex_flag.texture = EssenceLoader.smart_load_texture(final_path, true)
			
	# === 3. SEMÁFORO SIMPLIFICADO (VERDE / ROJO) ===
	if icon_game_status:
		var has_game = data.get("game_supported", false)
		icon_game_status.modulate = Color(0.2, 0.8, 0.2) if has_game else Color(0.8, 0.2, 0.2)
		icon_game_status.tooltip_text = tr("INFO_GAME_LANG_OK") if has_game else tr("INFO_GAME_LANG_MISSING")
		
	if icon_addon_status:
		var has_addon = data.get("addon_supported", false)
		var is_fallback = data.get("addon_is_fallback", false)
		
		# Si es fallback (entró el default), para nosotros es ROJO (No disponible)
		if has_addon and not is_fallback:
			icon_addon_status.modulate = Color(0.2, 0.8, 0.2) # Verde
			icon_addon_status.tooltip_text = tr("INFO_ADDON_LANG_OK")
		else:
			icon_addon_status.modulate = Color(0.8, 0.2, 0.2) # Rojo
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

# ==========================================
# UI EVENTS
# ==========================================
func _on_info_pressed():
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
	on_info_requested.emit(_language_data)

func _on_apply_pressed():
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
	on_apply_requested.emit(_my_folder_code)
