class_name EssenceSettingsController extends Control

@export_category("iOplazx Settings UI")
@export_group("Global Connections")
@export var btn_return: Button

func _ready():
	_connect_signals()

func _connect_signals():
	if btn_return:
		# Asumiendo que SceneManager maneja el cambio de escenas
		btn_return.pressed.connect(SceneManager.go_back)
		AudioManager.play_ui_sfx()
