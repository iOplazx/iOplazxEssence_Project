extends MarginContainer

@export_category("Tab: Language")
@export var language_browser: Control 
@export var btn_reimport: Button

@export_subgroup("Prefabs")
@export var info_prefab: PackedScene

func _ready():
	_connect_signals()
	# Ya no llamamos a _populate() aquí, porque el Browser se auto-construye en su propio _ready()

# ==========================================
# 1. CONEXIONES ÚNICAS
# ==========================================
func _connect_signals():
	if language_browser:
		language_browser.on_info_requested.connect(_on_info)
		# Conectamos la nueva señal para aplicar el idioma
		language_browser.on_apply_requested.connect(_on_apply)
	
	if btn_reimport and not btn_reimport.pressed.is_connected(_on_reimport):
		btn_reimport.pressed.connect(_on_reimport)

# ==========================================
# REACCIÓN A EVENTOS GLOBALES
# ==========================================
func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		# En lugar de iterar tarjetas manualmente, le decimos al Browser que se refresque
		if language_browser and language_browser.has_method("refresh_list"):
			language_browser.refresh_list()

# ==========================================
# LÓGICA DE BOTONES Y TARJETAS
# ==========================================
func _on_apply(code):
	# Mantenemos esto aquí para poder reproducir el sonido de la UI de forma global
	TranslationServer.set_locale(code)
	AudioManager.play_ui_sfx()
	LanguageManager.save_language_preference(code)

func _on_info(data):
	var p = info_prefab.instantiate()
	get_tree().root.add_child(p) 
	if p.has_method("setup"): p.setup(data)

func _on_reimport():
	AudioManager.play_ui_sfx()
	
	if get_tree().root.has_node("EssenceConfirmBox"): 
		return
		
	var box = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn").instantiate()
	box.name = "EssenceConfirmBox"
	get_tree().root.add_child(box)
	
	box.setup("LANG_REIMPORT_TITLE", "LANG_REIMPORT_MSG", "MENU_YES", "MENU_NO")
	
	box.on_choice.connect(func(accepted):
		if accepted:
			print("iOplazxEssence: Reimportando idiomas...")
			LanguageManager.scan_all_languages()
			LanguageManager.inject_translations()
			# Le pedimos al browser que reconstruya la lista con los nuevos datos
			if language_browser:
				language_browser.refresh_list()
	)

# ==========================================
# INTEGRACIÓN CON EL CONTROLADOR GLOBAL
# ==========================================
func has_unsaved_changes() -> bool:
	return false
