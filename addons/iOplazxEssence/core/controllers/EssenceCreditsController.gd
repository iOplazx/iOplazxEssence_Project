class_name EssenceCreditsController extends Control

const ES_NAME_CLASS = "EssenceCreditsController"

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
## Speed of the automatic scrolling (pixels per second).
@export var auto_scroll_speed: float = 30.0
## Speed multiplier when the player holds click/space/enter
@export var speed_multiplier: float = 4.0 

var _exact_scroll: float = 0.0
var _is_scrolling: bool = true

func _ready() -> void:
	if _validate_requirements():
		_connect_buttons()
		_build_all_sections()
		EssenceLogger.system_info("[%s] Credits screen initialized." % ES_NAME_CLASS)

## Check for missing nodes in the Inspector
func _validate_requirements() -> bool:
	var essential_nodes = {
		"Back Button": btn_back,
		"Scroll Container": scroll_container,
		"Game Label": lbl_game,
		"Framework Label": lbl_framework
	}
	
	for node_name in essential_nodes:
		if essential_nodes[node_name] == null:
			EssenceError.report(
				"Missing UI Reference",
				"Node '%s' is missing in %s. Credits might not display correctly." % [node_name, name],
				EssenceError.Severity.WARNING
			)
			# We return true anyway because credits aren't "game-breaking", 
			# but we warn the developer.
	
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_build_all_sections()

func _process(delta: float) -> void:
	if not _is_scrolling or auto_scroll_speed <= 0.0 or not is_instance_valid(scroll_container):
		return
		
	var current_speed = auto_scroll_speed
	
	# Fast-forward logic
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("ui_accept"):
		current_speed *= speed_multiplier
		
	_exact_scroll += current_speed * delta
	
	if _exact_scroll >= 1.0:
		var pixels_to_scroll = int(_exact_scroll)
		var v_scrollbar = scroll_container.get_v_scroll_bar()
		
		# Check if we reached the bottom
		var max_scroll = v_scrollbar.max_value - scroll_container.size.y
		if scroll_container.scroll_vertical >= max_scroll:
			_is_scrolling = false
			EssenceLogger.system_info("[%s] Credits scroll finished." % ES_NAME_CLASS)
			set_process(false) # Disable process to save CPU resources (Athlon Friendly)
		else:
			scroll_container.scroll_vertical += pixels_to_scroll
			_exact_scroll -= pixels_to_scroll

func _connect_buttons() -> void:
	if is_instance_valid(btn_back):
		if not btn_back.pressed.is_connected(SceneManager.go_back):
			btn_back.pressed.connect(SceneManager.go_back)

func _build_all_sections() -> void:
	_load_game_section()
	_load_special_thanks()
	_load_framework_section()

func _load_game_section() -> void:
	var game_version = "v???"
	var game_const_path = "res://_static/GameConstants.gd"
	
	# Safe dynamic load of GameConstants
	if ResourceLoader.exists(game_const_path):
		var const_script = load(game_const_path)
		if "GAME_VERSION" in const_script:
			game_version = const_script.GAME_VERSION
			
	if lbl_game:
		lbl_game.text = "--- " + game_title + " (" + game_version + ") ---\n\n"
		lbl_game.text += game_credits + "\n\n"

func _load_special_thanks() -> void:
	if not lbl_thanks: return
	
	if special_thanks.is_empty():
		lbl_thanks.hide() 
	else:
		lbl_thanks.show()
		var thanks_text = "--- " + tr("CREDITS_THANKS_TITLE") + " ---\n\n"
		for person in special_thanks:
			thanks_text += "• " + person + "\n"
		lbl_thanks.text = thanks_text + "\n\n"

func _load_framework_section() -> void:
	if lbl_framework:
		var fw_text = "--- " + tr("CREDITS_FRAMEWORK_TITLE") + " ---\n\n"
		fw_text += tr("CREDITS_DEVELOPED_WITH") + ":\n"
		fw_text += EssenceConstants.ENGINE_NAME + "\n"
		fw_text += tr("CREDITS_VERSION") + ": " + EssenceConstants.ENGINE_VERSION + "\n"
		fw_text += tr("CREDITS_UPDATED") + ": " + EssenceConstants.UPDATE_DATE
		lbl_framework.text = fw_text