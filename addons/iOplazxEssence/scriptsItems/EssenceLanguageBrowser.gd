extends VBoxContainer

@onready var search_input = $Header/MarginContainer/HBoxContainer/SearchInput
@onready var list_languages = $ScrollLanguages/ListLanguages

# Tu escena de la tarjeta que ya tenemos
@export var card_prefab: PackedScene 

# Diccionario interno de filtros activos
var _current_filters = {
	"exclude_game_ai": false,
	"exclude_addon_ai": false,
	"min_game_version": 0
}

func _ready():
	# Conectamos señales
	search_input.text_changed.connect(_on_search_changed)
	refresh_list()

## Función maestra para reconstruir la lista
func refresh_list():
	# 1. Limpiar lista actual
	for c in list_languages.get_children():
		c.queue_free()
	
	# 2. Pedir data filtrada al Manager
	# Pasamos los filtros que definimos antes
	var data = LanguageManager.get_languages(_current_filters)
	var search_text = search_input.text.to_lower()
	var current_locale = TranslationServer.get_locale()
	
	# 3. Instanciar tarjetas
	for d in data:
		# Filtro de texto simple (Nombre o Carpeta)
		if search_text != "" and not search_text in d["name"].to_lower() and not search_text in d["folder"].to_lower():
			continue
			
		var card = card_prefab.instantiate()
		list_languages.add_child(card)
		card.setup_card(d, current_locale)
		
		# Conectar botones de la tarjeta (Apply/Info)
		card.on_apply_requested.connect(_on_apply_language)

## Evento al escribir en la barra de búsqueda
func _on_search_changed(_new_text):
	# Podríamos poner un timer para no refrescar cada milisegundo (ahorra CPU)
	refresh_list()

func _on_apply_language(lang_code):
	LanguageManager.save_language_preference(lang_code)
	# Opcional: Refrescar UI completa si es necesario
