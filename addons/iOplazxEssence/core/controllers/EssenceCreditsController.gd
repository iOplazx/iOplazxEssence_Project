class_name EssenceCreditsController extends Control

@export_category("UI Connections")
@export var btn_back: Button
@export var scroll_container: ScrollContainer 
@export var lbl_game: Label
@export var lbl_thanks: Label
@export var lbl_framework: Label

@export_category("Game Credits")
@export var game_title: String = "My Game Demo"
@export_multiline var game_credits: String = "Lead Developer:\nYour Name Here\n\nMusic:\nAudio Better Days"

@export_category("Special Thanks")
## Add donors, testers, or asset providers here
@export var special_thanks: Array[String] = []

@export_category("Scroll Settings")
## Speed of the automatic scrolling (pixels per second). Set to 0 to disable.
@export var auto_scroll_speed: float = 30.0

# Variable interna para el scroll fraccional exacto
var _exact_scroll: float = 0.0

func _ready():
	_connect_buttons()
	_load_game_section()
	_load_special_thanks()
	_load_framework_section()

func _process(delta: float):
	# Lógica ligera de Auto-Scroll
	if auto_scroll_speed > 0.0 and scroll_container:
		_exact_scroll += auto_scroll_speed * delta
		# Solo actualizamos la UI si hemos acumulado al menos 1 píxel de movimiento
		if _exact_scroll >= 1.0:
			var pixels_to_scroll = int(_exact_scroll)
			scroll_container.scroll_vertical += pixels_to_scroll
			_exact_scroll -= pixels_to_scroll

func _connect_buttons():
	if btn_back:
		# Using our Router / SceneManager
		btn_back.pressed.connect(SceneManager.go_back)

func _load_game_section():
	var game_version = "v???"
	# Dynamically load static constants in case the user moved the file
	var game_const_path = "res://_static/GameConstants.gd"
	if ResourceLoader.exists(game_const_path):
		var const_script = load(game_const_path)
		if "GAME_VERSION" in const_script:
			game_version = const_script.GAME_VERSION
			
	if lbl_game:
		lbl_game.text = "--- " + game_title + " (" + game_version + ") ---\n\n"
		lbl_game.text += game_credits + "\n\n"

func _load_special_thanks():
	if lbl_thanks:
		if special_thanks.is_empty():
			lbl_thanks.hide() # Hide section if no one is added
		else:
			var thanks_text = "--- Special Thanks ---\n\n"
			for person in special_thanks:
				thanks_text += "• " + person + "\n"
			lbl_thanks.text = thanks_text + "\n\n"

func _load_framework_section():
	if lbl_framework:
		var fw_text = "--- Framework ---\n\n"
		fw_text += "Developed with:\n"
		fw_text += EssenceConstants.ENGINE_NAME + "\n"
		fw_text += "Version: " + EssenceConstants.ENGINE_VERSION + "\n"
		fw_text += "Updated: " + EssenceConstants.UPDATE_DATE
		lbl_framework.text = fw_text
