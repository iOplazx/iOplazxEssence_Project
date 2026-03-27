extends MarginContainer

@export_category("Tab: Language")
@export var list_languages: VBoxContainer 
@export var btn_reimport: Button

@export_subgroup("Prefabs")
@export var card_prefab: PackedScene
@export var info_prefab: PackedScene

func _ready():
	_populate()
	if btn_reimport:
		btn_reimport.pressed.connect(_on_reimport)

func _populate():
	for c in list_languages.get_children(): c.queue_free()
	
	var data = LanguageManager.get_language_list()
	var current = TranslationServer.get_locale()
	
	for d in data:
		var card = card_prefab.instantiate()
		list_languages.add_child(card)
		card.setup_card(d, current)
		card.on_apply_requested.connect(_on_apply)
		card.on_info_requested.connect(_on_info)

func _on_apply(code):
	TranslationServer.set_locale(code)
	AudioManager.play_ui_sfx()
	LanguageManager.save_language_preference(code)
	
	var current = TranslationServer.get_locale()
	for card in list_languages.get_children():
		if card.has_method("refresh_state"): card.refresh_state(current)

func _on_info(data):
	var p = info_prefab.instantiate()
	get_tree().root.add_child(p) # Lo mandamos al root para que flote sobre todo
	if p.has_method("setup"): p.setup(data)

func _on_reimport():
	AudioManager.play_ui_sfx()
	LanguageManager.scan_all_languages()
	LanguageManager.inject_translations()
	_populate()
