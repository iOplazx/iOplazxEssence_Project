class_name EssenceTabLanguage extends MarginContainer

const ES_NAME_CLASS = "EssenceTabLanguage"

@export_category("Tab: Language")
@export var language_browser: Control 
@export var btn_reimport: Button
@export var btn_restore: Button 

@export_subgroup("Prefabs")
@export var info_prefab: PackedScene

func _ready() -> void:
	if _validate_requirements():
		_connect_signals()
		EssenceLogger.system_info("[%s] Language Tab ready." % ES_NAME_CLASS)

# ==========================================
# 0. BLINDAJE: VERIFICACIÓN DE NODOS
# ==========================================
func _validate_requirements() -> bool:
	var missing = []
	if not language_browser: missing.append("language_browser")
	if not btn_reimport: missing.append("btn_reimport")
	if not btn_restore: missing.append("btn_restore")
	if not info_prefab: missing.append("info_prefab")
	
	if missing.size() > 0:
		EssenceError.report(
			"UI Setup Warning", 
			"Missing exported nodes in %s: %s" % [name, ", ".join(missing)], 
			EssenceError.Severity.WARNING
		)
		return false
	
	if not is_instance_valid(LanguageManager):
		EssenceError.report("Missing Autoload", "LanguageManager not found.", EssenceError.Severity.CRITICAL)
		return false
		
	return true

# ==========================================
# 1. CONEXIONES ÚNICAS
# ==========================================
func _connect_signals() -> void:
	if is_instance_valid(language_browser):
		if not language_browser.on_info_requested.is_connected(_on_info):
			language_browser.on_info_requested.connect(_on_info)
		if not language_browser.on_apply_requested.is_connected(_on_apply):
			language_browser.on_apply_requested.connect(_on_apply)
	
	if btn_reimport and not btn_reimport.pressed.is_connected(_on_reimport):
		btn_reimport.pressed.connect(_on_reimport)
		
	if btn_restore and not btn_restore.pressed.is_connected(_on_restore):
		btn_restore.pressed.connect(_on_restore)

# ==========================================
# REACCIÓN A EVENTOS GLOBALES
# ==========================================
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(language_browser) and language_browser.has_method("refresh_list"):
			language_browser.refresh_list()

# ==========================================
# LÓGICA DE BOTONES Y TARJETAS
# ==========================================
func _on_apply(code: String) -> void:
	TranslationServer.set_locale(code)
	AudioManager.play_ui_sfx()
	LanguageManager.save_language_preference(code)
	EssenceLogger.system_info("[%s] Language changed to: %s" % [ES_NAME_CLASS, code])

func _on_info(data: Dictionary) -> void:
	if not info_prefab: return
	var p = info_prefab.instantiate()
	get_tree().root.add_child(p) 
	if p.has_method("setup"): p.setup(data)

# === BOTÓN 1: REIMPORTAR (Hot-Reload) ===
func _on_reimport() -> void:
	AudioManager.play_ui_sfx()
	_show_confirm_box(
		"LANG_REIMPORT_TITLE", 
		"LANG_REIMPORT_MSG", 
		func():
			EssenceLogger.system_info("[%s] Hot-reloading languages into memory..." % ES_NAME_CLASS)
			LanguageManager.scan_all_languages()
			LanguageManager.inject_translations()
			if language_browser: language_browser.refresh_list()
	)

# === BOTÓN 2: RESTAURAR (Copia física) ===
func _on_restore() -> void:
	AudioManager.play_ui_sfx()
	_show_confirm_box(
		"LANG_RESTORE_TITLE", 
		"LANG_RESTORE_MSG", 
		func():
			EssenceLogger.system_info("[%s] Restoring official files to disk..." % ES_NAME_CLASS)
			LanguageManager.restore_official_languages()
			if language_browser: language_browser.refresh_list()
	)

# ==========================================
# UTILIDADES PRIVADAS
# ==========================================

## Helper para instanciar el ConfirmBox de forma segura y centralizada
func _show_confirm_box(title_key: String, msg_key: String, on_accept: Callable) -> void:
	if get_tree().root.has_node("EssenceConfirmBox"): return
	
	var box_path = EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn"
	if not ResourceLoader.exists(box_path):
		EssenceError.report("Resource Error", "ConfirmBox prefab not found at: %s" % box_path, EssenceError.Severity.CRITICAL)
		return
		
	var box = load(box_path).instantiate()
	box.name = "EssenceConfirmBox"
	get_tree().root.add_child(box)
	
	box.setup(title_key, msg_key, "MENU_YES", "MENU_NO")
	box.on_choice.connect(func(accepted): if accepted: on_accept.call())

func has_unsaved_changes() -> bool:
	return false