class_name EssenceSettingsController extends Control

@export_category("iOplazx Settings UI")
@export_group("Global Connections")
@export var btn_return: Button
@export var btn_restore: Button 

func _ready():
	_connect_signals()

func _connect_signals():
	if btn_return:
		btn_return.pressed.connect(_on_return_pressed)
		
	# 2. Conectamos el botón de restaurar
	if btn_restore: 
		btn_restore.pressed.connect(_on_restore_pressed)

func _on_restore_pressed():
	AudioManager.play_ui_sfx()
	
	# Evitamos múltiples cajas si hace doble clic
	if get_tree().root.has_node("EssenceConfirmBox"): 
		return
		
	var box = load(EssencePaths.PATH_UI + "EssenceConfirmBox.tscn").instantiate()
	box.name = "EssenceConfirmBox"
	get_tree().root.add_child(box)
	
	# Usamos nuevas claves para el CSV
	box.setup("SETTINGS_RESTORE_TITLE", "SETTINGS_RESTORE_MSG", "MENU_YES", "MENU_NO")
	
	box.on_choice.connect(func(accepted):
		if accepted:
			print("iOplazxEssence: Aplicando valores de fábrica...")
			Preferences.restore_defaults()
			
			# ¡EL HACK MAESTRO!
			# Enviamos esta notificación global. Como tus pestañas (Video, Game, etc.) 
			# ya tienen un _notification() que reacciona a esto reconstruyendo la UI,
			# se actualizarán visualmente al instante leyendo los nuevos valores de fábrica.
			get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)
			
			# Opcional: También bajamos las banderas de "cambios sin guardar"
			for tab in get_tree().get_nodes_in_group("settings_tabs"):
				if "pending_changes" in tab: tab._pending_changes = false
				if "_unsaved_mode" in tab: tab._unsaved_mode = DisplayManager.current_window_mode
	)

func _on_return_pressed():
	AudioManager.play_ui_sfx()
	
	# 1. Preguntamos a TODAS las pestañas si tienen algo sin guardar
	var tabs = get_tree().get_nodes_in_group("settings_tabs")
	
	var changes_detected = false
	for tab in tabs:
		if tab.has_method("has_unsaved_changes"):
			if tab.has_unsaved_changes():
				changes_detected = true
				break
	
	# 2. Reaccionamos según el resultado
	if changes_detected:
		var box = load(EssencePaths.PATH_UI + "EssenceConfirmBox.tscn").instantiate()
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
