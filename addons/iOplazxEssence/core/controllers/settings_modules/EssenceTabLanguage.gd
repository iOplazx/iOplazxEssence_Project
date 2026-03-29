extends MarginContainer

@export_category("Tab: Language")
@export var list_languages: VBoxContainer 
@export var btn_reimport: Button

@export_subgroup("Prefabs")
@export var card_prefab: PackedScene
@export var info_prefab: PackedScene

func _ready():
	_connect_signals()
	_setup_texts()
	_populate()

# ==========================================
# 1. CONEXIONES ÚNICAS
# ==========================================
func _connect_signals():
	if btn_reimport and not btn_reimport.pressed.is_connected(_on_reimport):
		btn_reimport.pressed.connect(_on_reimport)

# ==========================================
# 2. ACTUALIZACIÓN DE TEXTOS
# ==========================================
func _setup_texts():
	# Si tienes llave para este botón en tu CSV, ponla aquí (ej. LANG_BTN_REIMPORT)
	if btn_reimport:
		btn_reimport.text = tr("LANG_REIMPORT_TITLE") 

# ==========================================
# 3. POBLAR Y SINCRONIZAR
# ==========================================
func _populate():
	for c in list_languages.get_children(): 
		c.queue_free()
	
	var data = LanguageManager.get_language_list()
	var current = TranslationServer.get_locale()
	
	for d in data:
		var card = card_prefab.instantiate()
		list_languages.add_child(card)
		card.setup_card(d, current)
		
		# Como estas tarjetas nacen de cero, sus conexiones son seguras
		card.on_apply_requested.connect(_on_apply)
		card.on_info_requested.connect(_on_info)

func _sync_active_card():
	# Refresca visualmente cuál tarjeta dice "Activo" o "Aplicar"
	var current = TranslationServer.get_locale()
	for card in list_languages.get_children():
		if card.has_method("refresh_state"): 
			card.refresh_state(current)

# ==========================================
# REACCIÓN A EVENTOS GLOBALES
# ==========================================
func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_setup_texts()
		_sync_active_card() 

# ==========================================
# LÓGICA DE BOTONES Y TARJETAS
# ==========================================
func _on_apply(code):
	# Al hacer set_locale, Godot dispara NOTIFICATION_TRANSLATION_CHANGED a todo el juego.
	# Por lo tanto, ¡nuestro propio _notification() escuchará el cambio y 
	# llamará a _sync_active_card() automáticamente!
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
			_populate()
	)

# ==========================================
# INTEGRACIÓN CON EL CONTROLADOR GLOBAL
# ==========================================
# Esta pestaña no tiene botón de "Aplicar", los cambios son instantáneos.
# Así que siempre le decimos al Controlador que estamos "limpios".
func has_unsaved_changes() -> bool:
	return false
