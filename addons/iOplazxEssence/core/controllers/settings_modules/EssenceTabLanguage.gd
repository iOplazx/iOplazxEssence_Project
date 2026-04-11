extends MarginContainer

const ES_NAME_CLASS = "TabLanguage"

@export_category("Tab: Language")
@export var language_browser: Control 
@export var btn_reimport: Button
@export var btn_restore: Button 

@export_subgroup("Prefabs")
@export var info_prefab: PackedScene

func _ready():
	_check_security_nodes()
	_connect_signals()

# ==========================================
# 0. BLINDAJE: VERIFICACIÓN DE NODOS
# ==========================================
func _check_security_nodes():
	var missing = []
	if not language_browser: missing.append("language_browser")
	if not btn_reimport: missing.append("btn_reimport")
	if not btn_restore: missing.append("btn_restore")
	if not info_prefab: missing.append("info_prefab")
	
	# Si falta algún nodo, lanzamos el Warning Overlay
	if missing.size() > 0:
		var msg = "Missing exported nodes in %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		EssenceError.report("UI Setup Warning", msg, EssenceError.Severity.WARNING)

# ==========================================
# 1. CONEXIONES ÚNICAS
# ==========================================
func _connect_signals():
	if language_browser:
		language_browser.on_info_requested.connect(_on_info)
		language_browser.on_apply_requested.connect(_on_apply)
	
	if btn_reimport and not btn_reimport.pressed.is_connected(_on_reimport):
		btn_reimport.pressed.connect(_on_reimport)
		
	if btn_restore and not btn_restore.pressed.is_connected(_on_restore):
		btn_restore.pressed.connect(_on_restore)

# ==========================================
# REACCIÓN A EVENTOS GLOBALES
# ==========================================
func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if language_browser and language_browser.has_method("refresh_list"):
			language_browser.refresh_list()

# ==========================================
# LÓGICA DE BOTONES Y TARJETAS
# ==========================================
func _on_apply(code):
	TranslationServer.set_locale(code)
	AudioManager.play_ui_sfx()
	LanguageManager.save_language_preference(code)

func _on_info(data):
	if not info_prefab: return
	var p = info_prefab.instantiate()
	get_tree().root.add_child(p) 
	if p.has_method("setup"): p.setup(data)

# === BOTÓN 1: REIMPORTAR (Solo actualiza RAM) ===
func _on_reimport():
	AudioManager.play_ui_sfx()
	if get_tree().root.has_node("EssenceConfirmBox"): return
		
	var box = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn").instantiate()
	box.name = "EssenceConfirmBox"
	get_tree().root.add_child(box)
	
	box.setup("LANG_REIMPORT_TITLE", "LANG_REIMPORT_MSG", "MENU_YES", "MENU_NO")
	
	box.on_choice.connect(func(accepted):
		if accepted:
			var log_msg = "[%s/_on_reimport] Hot-reloading languages into memory..." % ES_NAME_CLASS
			EssenceLogger.system_info(log_msg)
			
			LanguageManager.scan_all_languages()
			LanguageManager.inject_translations()
			
			if language_browser: language_browser.refresh_list()
	)

# === BOTÓN 2: RESTAURAR (Copia archivos físicos) ===
func _on_restore():
	AudioManager.play_ui_sfx()
	if get_tree().root.has_node("EssenceConfirmBox"): return
		
	var box = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn").instantiate()
	box.name = "EssenceConfirmBox"
	get_tree().root.add_child(box)
	
	# Usamos nuevas llaves de texto para esta ventana
	box.setup("LANG_RESTORE_TITLE", "LANG_RESTORE_MSG", "MENU_YES", "MENU_NO")
	
	box.on_choice.connect(func(accepted):
		if accepted:
			var log_msg = "[%s/_on_restore] Restoring official files to remote..." % ES_NAME_CLASS
			EssenceLogger.system_info(log_msg)
			
			# Llamamos al manager para que haga la magia en el disco duro
			LanguageManager.restore_official_languages()
			
			if language_browser: language_browser.refresh_list()
	)

# ==========================================
# INTEGRACIÓN CON EL CONTROLADOR GLOBAL
# ==========================================
func has_unsaved_changes() -> bool:
	return false
