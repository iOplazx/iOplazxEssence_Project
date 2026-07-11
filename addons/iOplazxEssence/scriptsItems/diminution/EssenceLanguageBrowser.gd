class_name EssenceLanguageBrowser extends VBoxContainer

const ES_NAME_CLASS = "EssenceLanguageBrowser"

# Señales que el TabLanguage está escuchando
signal on_info_requested(data: Dictionary)
signal on_apply_requested(lang_code: String)

@export_category("UI Connections")
@export var search_input: LineEdit
@export var btn_search: Button
@export var btn_filters: MenuButton
@export var list_languages: Control
@export var search_timer: Timer # Si el usuario no lo pone, lo creamos dinámicamente
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
	_check_security_nodes()
	_init_search_timer() # Truco Senior: Inyección dinámica del temporizador
	
	# 1. Cargar iconos desde nuestro sistema centralizado
	_icon_filter_normal = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_FILTER)
	_icon_filter_active = EssenceLoader.get_internImage(EssencePaths.KeyImage.ICON_FILTER_X)
	
	# 2. Conexiones Seguras
	if btn_search:
		btn_search.pressed.connect(_on_btn_search_pressed)
		
	if btn_filters:
		btn_filters.icon = _icon_filter_normal
		_setup_filter_menu()
		
	if search_input:
		search_input.text_changed.connect(_on_search_changed)
		
	# 3. Textos y Lista Inicial
	_update_ui_texts()
	refresh_list()

# ==========================================
# BLINDAJE Y AUTO-MANTENIMIENTO
# ==========================================
func _check_security_nodes():
	var missing = []
	if not search_input: missing.append("search_input")
	if not btn_search: missing.append("btn_search")
	if not btn_filters: missing.append("btn_filters")
	if not list_languages: missing.append("list_languages")
	if not card_prefab: missing.append("card_prefab")
	
	if missing.size() > 0:
		var msg = "Missing exported nodes in %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		if is_instance_valid(EssenceError) and EssenceError.has_method("report"):
			EssenceError.report("UI Setup Warning", msg, EssenceError.Severity.WARNING)
		else:
			push_error(msg)

func _init_search_timer():
	# Si no hay un Timer en el inspector, el código fabrica el suyo propio.
	# Esto hace que el script sea 100% a prueba de errores humanos.
	if not is_instance_valid(search_timer):
		search_timer = Timer.new()
		search_timer.name = "AutoSearchTimer"
		search_timer.wait_time = 0.3
		search_timer.one_shot = true
		add_child(search_timer)
		
	if not search_timer.timeout.is_connected(_on_search_timer_timeout):
		search_timer.timeout.connect(_on_search_timer_timeout)

# ==========================================
# TRADUCCIÓN DINÁMICA
# ==========================================
func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_ui_texts()

func _update_ui_texts():
	if search_input:
		search_input.placeholder_text = tr("UI_SEARCH_PLACEHOLDER")
		
	if btn_filters:
		var popup = btn_filters.get_popup()
		if popup:
			# 1. Actualizamos los ítems base (solo si ya existen)
			if popup.item_count > 0: popup.set_item_text(0, tr("FILTER_IA_GAME"))
			if popup.item_count > 1: popup.set_item_text(1, tr("FILTER_IA_ADDON"))
			if popup.item_count > 2: popup.set_item_text(2, tr("FILTER_COMPATIBLE"))
			
			# 2. Buscamos el botón de limpiar por su ID único (99)
			# Si aún no se ha creado, get_item_index devuelve -1 y lo ignoramos de forma segura.
			var clear_idx = popup.get_item_index(99)
			if clear_idx != -1:
				popup.set_item_text(clear_idx, tr("FILTER_CLEAR"))

# ==========================================
# CONFIGURACIÓN DE FILTROS
# ==========================================
func _setup_filter_menu():
	var popup = btn_filters.get_popup()
	if not popup: return
	
	# Evita que el menú se cierre cada vez que haces clic en un checkbox
	popup.hide_on_checkable_item_selection = false 
	popup.id_pressed.connect(_on_filter_selected)
	
	popup.add_separator()
	# Reparado: Ahora usa una llave de traducción en lugar de texto estático
	popup.add_item(tr("FILTER_CLEAR"), 99) 

func _on_filter_selected(id: int):
	var popup = btn_filters.get_popup()
	if not popup: return
	
	if id == 99:
		_clear_all_filters(popup)
		return

	var is_checked = not popup.is_item_checked(id)
	popup.set_item_checked(id, is_checked)
	
	match id:
		0: _current_filters["exclude_game_ai"] = is_checked
		1: _current_filters["exclude_addon_ai"] = is_checked
		2: _current_filters["min_game_version"] = 1 if is_checked else 0
		
	_update_filter_visuals()
	refresh_list()

func _clear_all_filters(popup: PopupMenu):
	for i in range(popup.item_count):
		if popup.is_item_checkable(i):
			popup.set_item_checked(i, false)
			
	_current_filters["exclude_game_ai"] = false
	_current_filters["exclude_addon_ai"] = false
	_current_filters["min_game_version"] = 0
	
	_update_filter_visuals()
	refresh_list()

func _update_filter_visuals():
	if not btn_filters: return
	
	var is_filtering = _current_filters["exclude_game_ai"] or _current_filters["exclude_addon_ai"] or _current_filters["min_game_version"] > 0
	
	if is_filtering:
		btn_filters.icon = _icon_filter_active
		btn_filters.modulate = Color(1.0, 0.4, 0.4) 
	else:
		btn_filters.icon = _icon_filter_normal
		btn_filters.modulate = Color.WHITE

# ==========================================
# CONSTRUCCIÓN DE LA LISTA
# ==========================================
func refresh_list():
	if not list_languages or not card_prefab: return
	
	for c in list_languages.get_children():
		c.queue_free()
	
	# Validación del Autoload
	if not is_instance_valid(LanguageManager): return
	
	var data = LanguageManager.get_languages(_current_filters)
	var search_text = ""
	if search_input: search_text = search_input.text.to_lower()
	
	var current_locale = TranslationServer.get_locale()
	
	for d in data:
		if search_text != "" and not search_text in d["name"].to_lower() and not search_text in d.get("folder", "").to_lower():
			continue
			
		var card = card_prefab.instantiate()
		list_languages.add_child(card)
		
		if card.has_method("setup_card"):
			card.setup_card(d, current_locale)
		
		# Validamos señales antes de conectar
		if card.has_signal("on_info_requested"):
			card.on_info_requested.connect(func(lang_data): on_info_requested.emit(lang_data))
		if card.has_signal("on_apply_requested"):
			card.on_apply_requested.connect(func(lang_code): on_apply_requested.emit(lang_code))

# ==========================================
# EVENTOS DEL BUSCADOR (DEBOUNCE)
# ==========================================
func _on_search_changed(_new_text):
	if is_instance_valid(search_timer):
		search_timer.start()
	
func _on_search_timer_timeout():
	refresh_list()

func _on_btn_search_pressed():
	if is_instance_valid(search_timer) and search_timer.time_left > 0:
		search_timer.stop()
	refresh_list()
