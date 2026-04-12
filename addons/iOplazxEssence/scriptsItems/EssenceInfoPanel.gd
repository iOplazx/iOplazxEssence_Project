class_name EssenceInfoPanel extends Control

const ES_NAME_CLASS = "EssenceInfoPanel"

@export_category("Main Nodes")
@export var lbl_title: Label
@export var btn_close: Button
@export var window_panel: PanelContainer

@export_category("Game Section")
@export var game_data_node: Control # VBox que contiene la info
@export var game_missing_node: Control # VBox/Label de "No encontrado"

@export_group("Dynamic Game Texts")
@export var lbl_game_author: Label
@export var lbl_game_version: Label
@export var lbl_game_desc: Label
@export var lbl_game_ai_warning: Label
@export var lbl_game_missing_msg: Label # Para el texto de error

@export_category("Addon Section")
@export var addon_data_node: Control # VBox que contiene la info
@export var addon_missing_node: Control # VBox/Label de "No encontrado"

@export_group("Dynamic Addon Texts")
@export var lbl_addon_author: Label
@export var lbl_addon_version: Label
@export var lbl_addon_desc: Label
@export var lbl_addon_ai_warning: Label
@export var lbl_addon_missing_msg: Label # Para el texto de error

func _ready():
	_check_security_nodes()
	
	if btn_close: 
		btn_close.pressed.connect(_on_close_pressed)
	
	# Ocultamos los warnings por defecto de forma segura
	if lbl_game_ai_warning: lbl_game_ai_warning.hide()
	if lbl_addon_ai_warning: lbl_addon_ai_warning.hide()
	
	# Animación de entrada segura (protegida contra nodos nulos)
	modulate.a = 0.0 
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	
	if window_panel:
		window_panel.scale = Vector2(0.8, 0.8)
		tween.tween_property(window_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ==========================================
# SECURITY & BLINDING
# ==========================================
func _check_security_nodes():
	var missing = []
	if not lbl_title: missing.append("lbl_title")
	if not btn_close: missing.append("btn_close")
	if not window_panel: missing.append("window_panel")
	if not game_data_node: missing.append("game_data_node")
	if not game_missing_node: missing.append("game_missing_node")
	if not addon_data_node: missing.append("addon_data_node")
	if not addon_missing_node: missing.append("addon_missing_node")
	
	# Solo verificamos los nodos estructurales principales. 
	# Los textos dinámicos no son críticos para que la ventana no crashee.
	if missing.size() > 0:
		var msg = "Missing exported core nodes in %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		if EssenceError and EssenceError.has_method("report"):
			EssenceError.report("UI Setup Warning", msg, EssenceError.Severity.WARNING)
		else:
			push_error(msg)

# ==========================================
# DATA INJECTION
# ==========================================
func setup(data: Dictionary):
	# 1. TÍTULO PRINCIPAL
	if lbl_title: lbl_title.text = data.get("name", "Unknown Language")

	# 2. SECCIÓN DEL JUEGO
	var game_info = data.get("game_data", {}) 
	_setup_game_section(game_info)

	# 3. SECCIÓN DEL ADDON
	var addon_info = data.get("addon_data", {})
	_setup_addon_section(addon_info)
	
func _setup_game_section(game_info: Dictionary):
	if not game_info.is_empty():
		if game_data_node: game_data_node.show()
		if game_missing_node: game_missing_node.hide()
		
		if lbl_game_author: 
			lbl_game_author.text = game_info.get("author", "Unknown")
			
		if lbl_game_version: 
			var v = str(game_info.get("version", "0.0.1"))
			var t = str(game_info.get("target_version", "0.0.1"))
			lbl_game_version.text = "v" + v + " (Target: v" + t + ")"
			
		if lbl_game_desc:
			var desc = game_info.get("description", "")
			lbl_game_desc.text = desc
			lbl_game_desc.visible = desc != ""
			
		if lbl_game_ai_warning:
			lbl_game_ai_warning.visible = game_info.get("is_ai", false)
	else:
		if game_data_node: game_data_node.hide()
		if game_missing_node: game_missing_node.show()
		if lbl_game_missing_msg: lbl_game_missing_msg.text = tr("INFO_GAME_LANG_MISSING")
		
func _setup_addon_section(addon_info: Dictionary):
	if not addon_info.is_empty():
		if addon_data_node: addon_data_node.show()
		if addon_missing_node: addon_missing_node.hide()
		
		if lbl_addon_author: 
			lbl_addon_author.text = addon_info.get("author", "Unknown")
		
		if lbl_addon_version: 
			var v = str(addon_info.get("version", "0.0.1"))
			var t = str(addon_info.get("target_version", "0.0.1"))
			lbl_addon_version.text = "v" + v + " (Target: v" + t + ")"
		
		if lbl_addon_desc:
			var desc = addon_info.get("description", "")
			lbl_addon_desc.text = desc
			lbl_addon_desc.visible = desc != ""
			
		if lbl_addon_ai_warning:
			lbl_addon_ai_warning.visible = addon_info.get("is_ai", false)
	else:
		if addon_data_node: addon_data_node.hide()
		if addon_missing_node: addon_missing_node.show()
		if lbl_addon_missing_msg: lbl_addon_missing_msg.text = tr("INFO_ADDON_LANG_MISSING")

# ==========================================
# UI EVENTS
# ==========================================
func _on_close_pressed():
	# Blindaje del AudioManager
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	
	if window_panel: 
		tween.tween_property(window_panel, "scale", Vector2(0.9, 0.9), 0.1)
		
	tween.chain().tween_callback(queue_free)
