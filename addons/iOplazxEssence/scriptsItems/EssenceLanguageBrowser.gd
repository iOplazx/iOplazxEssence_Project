extends VBoxContainer

@onready var search_input = $Header/MarginContainer/HBoxContainer/SearchInput
@onready var btn_search = $Header/MarginContainer/HBoxContainer/BtnSearch
@onready var btn_filters = $Header/MarginContainer/HBoxContainer/BtnFilters
@onready var list_languages = $ScrollLanguages/ListLanguages

# Señales que el TabLanguage está escuchando
signal on_info_requested(data: Dictionary)
signal on_apply_requested(lang_code: String)

@export var card_prefab: PackedScene 

var _icon_filter_normal: Texture2D
var _icon_filter_active: Texture2D

# Diccionario interno de filtros activos
var _current_filters = {
	"exclude_game_ai": false,
	"exclude_addon_ai": false,
	"min_game_version": 0
}

func _ready():
	# 1. Cargar iconos desde nuestro sistema centralizado
	_icon_filter_normal = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_FILTER)
	_icon_filter_active = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_FILTER_X)
	
	if btn_search:
		# Conectamos al nuevo método para detener el timer
		btn_search.pressed.connect(_on_btn_search_pressed)
		
	if btn_filters:
		btn_filters.icon = _icon_filter_normal
		_setup_filter_menu()
		
	if search_input:
		search_input.text_changed.connect(_on_search_changed)
		
	# 2. Traducir textos por primera vez
	_update_ui_texts()
	
	# 3. Construir lista inicial
	refresh_list()

# ==========================================
# TRADUCCIÓN DINÁMICA (Para que no se quede en español)
# ==========================================
func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_ui_texts()

func _update_ui_texts():
	if search_input:
		search_input.placeholder_text = tr("UI_SEARCH_PLACEHOLDER")
		
	if btn_filters:
		var popup = btn_filters.get_popup()
		popup.set_item_text(0, tr("FILTER_IA_GAME"))
		popup.set_item_text(1, tr("FILTER_IA_ADDON"))
		popup.set_item_text(2, tr("FILTER_COMPATIBLE"))
		# El ID 3 es el separador. El ID 4 es el botón de limpiar:
		popup.set_item_text(4, tr("FILTER_CLEAR")) 

# ==========================================
# CONFIGURACIÓN DE FILTROS
# ==========================================
func _setup_filter_menu():
	var popup = btn_filters.get_popup()
	# ¡Truco de UX! Evita que el menú se cierre cada vez que haces clic en un checkbox
	popup.hide_on_checkable_item_selection = false 
	popup.id_pressed.connect(_on_filter_selected)
	
	# Añadimos una opción extra al final para limpiar todo rápidamente
	popup.add_separator()
	popup.add_item("Limpiar todos los filtros", 99)

func _on_filter_selected(id: int):
	var popup = btn_filters.get_popup()
	
	# Si presionó el botón de limpiar (ID 99)
	if id == 99:
		_clear_all_filters(popup)
		return

	# Comportamiento normal de Checkbox
	var is_checked = not popup.is_item_checked(id)
	popup.set_item_checked(id, is_checked)
	
	match id:
		0: _current_filters["exclude_game_ai"] = is_checked
		1: _current_filters["exclude_addon_ai"] = is_checked
		2: _current_filters["min_game_version"] = 1 if is_checked else 0
		
	_update_filter_visuals()
	refresh_list()

func _clear_all_filters(popup: PopupMenu):
	# Desmarcamos visualmente
	for i in range(popup.item_count):
		if popup.is_item_checkable(i):
			popup.set_item_checked(i, false)
			
	# Reseteamos datos
	_current_filters["exclude_game_ai"] = false
	_current_filters["exclude_addon_ai"] = false
	_current_filters["min_game_version"] = 0
	
	_update_filter_visuals()
	refresh_list()

func _update_filter_visuals():
	var is_filtering = _current_filters["exclude_game_ai"] or _current_filters["exclude_addon_ai"] or _current_filters["min_game_version"] > 0
	
	if is_filtering:
		btn_filters.icon = _icon_filter_active
		btn_filters.modulate = Color(1.0, 0.4, 0.4) # Tono rojizo
	else:
		btn_filters.icon = _icon_filter_normal
		btn_filters.modulate = Color.WHITE

# ==========================================
# CONSTRUCCIÓN DE LA LISTA
# ==========================================
func refresh_list():
	for c in list_languages.get_children():
		c.queue_free()
	
	var data = LanguageManager.get_languages(_current_filters)
	var search_text = search_input.text.to_lower()
	var current_locale = TranslationServer.get_locale()
	
	for d in data:
		if search_text != "" and not search_text in d["name"].to_lower() and not search_text in d["folder"].to_lower():
			continue
			
		var card = card_prefab.instantiate()
		list_languages.add_child(card)
		card.setup_card(d, current_locale)
		
		# Avisamos al TabLanguage si el usuario interactúa
		card.on_info_requested.connect(func(lang_data): on_info_requested.emit(lang_data))
		card.on_apply_requested.connect(func(lang_code): on_apply_requested.emit(lang_code))

# ==========================================
# EVENTOS DEL BUSCADOR (DEBOUNCE)
# ==========================================
func _on_search_changed(_new_text):
	# Iniciamos el reloj cada vez que el usuario escribe
	if has_node("SearchTimer"):
		$SearchTimer.start()
	
func _on_search_timer_timeout():
	# El usuario dejó de escribir por 300ms, actualizamos la lista
	refresh_list()

func _on_btn_search_pressed():
	# Si el usuario hace clic en la lupa, forzamos la actualización instantánea
	if has_node("SearchTimer") and $SearchTimer.time_left > 0:
		$SearchTimer.stop()
	refresh_list()
