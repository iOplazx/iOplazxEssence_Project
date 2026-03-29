class_name EssenceSettingsController extends Control

@export_category("iOplazx Settings UI")
@export_group("Global Connections")
@export var btn_return: Button
@export var btn_restore: Button 
@export var tab_container: TabContainer 

const PATH = EssencePaths.PATH_UI_SCREEN + "settings/"

# 2. Diccionario con el "molde" de tus escenas separadas
var tab_scenes: Dictionary = {
	0: preload(PATH + "EssenceTabGame.tscn"),
	1: preload(PATH + "EssenceTabVideo.tscn"),
	2: preload(PATH + "EssenceTabAudio.tscn"),
	3: preload(PATH + "EssenceTabLanguage.tscn"),
}

func _ready():
	if not tab_container:
		push_error("Essence: ¡Olvidaste asignar el TabContainer en el Inspector de Settings!")
		return
	_connect_signals()
	
	# 3. Iniciamos el sistema de Carga Perezosa
	if tab_container:
		tab_container.tab_changed.connect(_on_tab_changed)
		_load_tab(tab_container.current_tab) # Cargamos la que esté visible al abrir el menú

func _connect_signals():
	if btn_return:
		btn_return.pressed.connect(_on_return_pressed)
		
	if btn_restore: 
		btn_restore.pressed.connect(_on_restore_pressed)

# ==========================================
# SISTEMA DE CARGA PEREZOSA (LAZY LOADING)
# ==========================================
func _on_tab_changed(tab_index: int):
	_load_tab(tab_index)
	AudioManager.play_ui_sfx()

func _load_tab(index: int):
	# Si no hay TabContainer o no tenemos una escena asignada a ese índice, ignoramos
	if not tab_container or not tab_scenes.has(index):
		return
		
	var placeholder = tab_container.get_child(index)
	
	# Si el placeholder (Control vacío) ya tiene hijos, significa que ya lo instanciamos antes
	if placeholder.get_child_count() > 0:
		return
		
	# Si está vacío, instanciamos la escena pesada al vuelo
	var tab_content = tab_scenes[index].instantiate()
	
	# Hacemos que se estire para llenar el placeholder perfectamente
	tab_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	placeholder.add_child(tab_content)
	print("iOplazxEssence: Sección cargada en memoria -> Pestaña ", index)

# ==========================================
# BOTONES GLOBALES
# ==========================================
func _on_restore_pressed():
	AudioManager.play_ui_sfx()
	
	if get_tree().root.has_node("EssenceConfirmBox"): 
		return
		
	var box = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn").instantiate()
	box.name = "EssenceConfirmBox"
	get_tree().root.add_child(box)
	
	box.setup("SETTINGS_RESTORE_TITLE", "SETTINGS_RESTORE_MSG", "MENU_YES", "MENU_NO")
	
	box.on_choice.connect(func(accepted):
		if accepted:
			print("iOplazxEssence: Aplicando valores de fábrica...")
			Preferences.restore_defaults()
			
			get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)
			
			for tab in get_tree().get_nodes_in_group("settings_tabs"):
				if "pending_changes" in tab: tab._pending_changes = false
				if "_unsaved_mode" in tab: tab._unsaved_mode = DisplayManager.current_window_mode
	)

func _on_return_pressed():
	AudioManager.play_ui_sfx()
	
	# Al usar "Lazy Loading", este grupo es súper inteligente: 
	# Solo preguntará a las pestañas que el usuario REALMENTE abrió.
	var tabs = get_tree().get_nodes_in_group("settings_tabs")
	
	var changes_detected = false
	for tab in tabs:
		if tab.has_method("has_unsaved_changes"):
			if tab.has_unsaved_changes():
				changes_detected = true
				break
	
	if changes_detected:
		var box = load(EssencePaths.PATH_UI_OVERLAYS + "EssenceConfirmBox.tscn").instantiate()
		get_tree().root.add_child(box)
		box.setup("SETTINGS_DISCARD_TITLE", "SETTINGS_DISCARD_MSG", "MENU_YES", "MENU_NO")
		
		box.on_choice.connect(func(accepted):
			if accepted:
				if Preferences.has_method("load_from_disk"):
					Preferences.load_from_disk()
				SceneManager.go_back()
		)
	else:
		SceneManager.go_back()
