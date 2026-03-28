class_name EssenceSettingsController extends Control

@export_category("iOplazx Settings UI")
@export_group("Global Connections")
@export var btn_return: Button

func _ready():
	_connect_signals()

func _connect_signals():
	if btn_return:
		# Conectamos a una función local, NO directamente a SceneManager.go_back
		btn_return.pressed.connect(_on_return_pressed)

func _on_return_pressed():
	AudioManager.play_ui_sfx()
	
	# 1. Preguntamos a TODAS las pestañas si tienen algo sin guardar
	var tabs = get_tree().get_nodes_in_group("settings_tabs")
	print("Pestañas encontradas en el grupo: ", tabs.size())
	
	var changes_detected = false
	for tab in tabs:
		if tab.has_method("has_unsaved_changes"):
			if tab.has_unsaved_changes():
				print("¡Pestaña con cambios detectada!: ", tab.name)
				changes_detected = true
				break
		else:
			print("Advertencia: La pestaña ", tab.name, " no tiene la función has_unsaved_changes")
	
	# 2. Reaccionamos según el resultado
	if changes_detected:
		var box = load(EssencePaths.PATH_UI + "EssenceConfirmBox.tscn").instantiate()
		get_tree().root.add_child(box)
		box.setup("SETTINGS_DISCARD_TITLE", "SETTINGS_DISCARD_MSG", "MENU_YES", "MENU_NO")
		
		box.on_choice.connect(func(accepted):
			if accepted:
				# PRO-TIP: Si cancela, recargamos las preferencias desde el disco duro
				# para "limpiar" la RAM de los cambios que no quiso guardar.
				if Preferences.has_method("load_from_disk"):
					Preferences.load_from_disk()
				SceneManager.go_back()
		)
	else:
		SceneManager.go_back()
