class_name EssenceMenuController extends Control

const ES_NAME_CLASS = "EssenceMenuController"

# Enums for animation types (Inspector-friendly)
enum EntranceAnimation { NONE, FADE_IN, SLIDE_FROM_TOP }
enum IdleAnimation { NONE, BREATHING }

@export_category("UI Connections")
@export var btn_new_game: Button
@export var btn_continue: Button
@export var btn_load: Button
@export var btn_settings: Button
@export var btn_credits: Button
@export var btn_exit: Button

@export_subgroup("Navigation Settings")
## The button that will grab focus by default for keyboard/gamepad
@export var first_focus_button: Control

@export_category("Visual Effects (Juice)")
@export_subgroup("Button Animation") 
## Enables a coordinated entrance for buttons
@export var animate_buttons_entrance: bool = true
## (Optional) The panel containing buttons. Appears before the buttons.
@export var buttons_panel: Control 

@export_subgroup("Title Settings")
@export var title_container: Control 
@export var entrance_anim_type: EntranceAnimation = EntranceAnimation.FADE_IN
@export var entrance_duration: float = 0.5
@export var slide_distance: float = 100.0
@export var idle_anim_type: IdleAnimation = IdleAnimation.BREATHING
@export var idle_duration: float = 1.5

# Internal state
var _idle_tween: Tween

func _ready() -> void:
	if _validate_requirements():
		EssenceLogger.system_info("[%s] Initializing main menu..." % ES_NAME_CLASS)
		
		# Clean RAM from previous sessions
		SaveManager.clear_all_temp()
		
		_conectar_botones()
		_update_continue_button_state()
		
		# Setup initial visual state
		if animate_buttons_entrance:
			_prepare_button_entrance()
		
		if title_container:
			_iniciar_animaciones_titulo()

		if animate_buttons_entrance:
			_animar_entrada_ui_botones()
			
		_setup_ui_sounds()
		_iniciar_foco_teclado()

## Validates that all exported nodes are correctly assigned
func _validate_requirements() -> bool:
	var buttons = {
		"New Game": btn_new_game,
		"Load": btn_load,
		"Settings": btn_settings,
		"Credits": btn_credits,
		"Exit": btn_exit
	}
	
	var is_valid = true
	for btn_name in buttons:
		if buttons[btn_name] == null:
			EssenceError.report("Missing Button", "Button '%s' is not assigned in %s." % [btn_name, name], EssenceError.Severity.CRITICAL)
			is_valid = false
			
	return is_valid

func _conectar_botones() -> void:
	# Using 'is_instance_valid' and connection checks for maximum safety
	var connections = {
		btn_new_game: _on_new_game_pressed,
		btn_continue: _on_continue_pressed,
		btn_load: _on_load_pressed,
		btn_settings: _on_settings_pressed,
		btn_credits: _on_credits_pressed,
		btn_exit: _on_exit_pressed
	}
	
	for btn in connections:
		if is_instance_valid(btn) and not btn.pressed.is_connected(connections[btn]):
			btn.pressed.connect(connections[btn])

## Merged logic for the Continue button state
func _update_continue_button_state() -> void:
	if not is_instance_valid(btn_continue): return
	
	var latest_id = SaveManager.get_latest_save_id()
	var can_continue = latest_id != "" and SaveManager.save_exists(latest_id)
	
	btn_continue.disabled = not can_continue
	btn_continue.modulate.a = 1.0 if can_continue else 0.5
	btn_continue.focus_mode = Control.FOCUS_ALL if can_continue else Control.FOCUS_NONE
	
	EssenceLogger.system_info("[%s] Continue state: %s (ID: %s)" % [ES_NAME_CLASS, "Enabled" if can_continue else "Disabled", latest_id])

func _iniciar_foco_teclado() -> void:
	if is_instance_valid(first_focus_button):
		first_focus_button.grab_focus()

# ==========================================
# INTERFACE AUDIO
# ==========================================
func _setup_ui_sounds() -> void:
	var group_buttons = [btn_new_game, btn_continue, btn_load, btn_settings, btn_credits, btn_exit]
	
	for btn in group_buttons:
		if is_instance_valid(btn):
			if not btn.mouse_entered.is_connected(_play_hover_ui):
				btn.mouse_entered.connect(_play_hover_ui)
			if not btn.focus_entered.is_connected(_play_hover_ui):
				btn.focus_entered.connect(_play_hover_ui)
			# Note: pressed is already connected in _conectar_botones, 
			# we call play_ui_sfx directly inside action handlers or here.

func _play_hover_ui() -> void:
	var pitch = randf_range(0.95, 1.05)
	AudioManager.play_ui_sfx(null, pitch)

func _play_click_ui() -> void:
	AudioManager.play_ui_sfx()

# ==========================================
# ACTION HANDLERS
# ==========================================

func _on_new_game_pressed() -> void:
	_play_click_ui()
	SaveManager.clear_all_temp() 
	_on_new_game_hook()
	SceneManager.goto_new_game()

func _on_continue_pressed() -> void:
	_play_click_ui()
	var latest_save_id = SaveManager.get_latest_save_id()
	
	if latest_save_id == "":
		EssenceError.report("Invalid Continue State", "No valid save ID found.", EssenceError.Severity.WARNING)
		return 
		
	var data = SaveManager.load_game(latest_save_id)
	
	if data.is_empty() or not data.has("game_data"):
		EssenceError.report(
			"Corrupt Save File",
			"Save file '%s' is missing or corrupt. Please load from menu." % latest_save_id,
			EssenceError.Severity.WARNING
		)
		_update_continue_button_state() 
		return

	# Happy Path
	SaveManager.loaded_game_data = data["game_data"]
	
	var save_type = "Checkpoint" if latest_save_id.begins_with("checkpoint") else "Manual"
	EssenceLogger.system_info("[%s] Continuing from %s save (%s)" % [ES_NAME_CLASS, save_type, latest_save_id])
	
	SaveManager.mark_save_as_latest_played(latest_save_id)
	
	if has_method("_on_continue_hook"):
		_on_continue_hook(data)
		
	SceneManager.goto_continue_game()
	
func _on_load_pressed() -> void:
	_play_click_ui()
	SaveManager.clear_all_temp()
	SceneManager.goto_load_game()

func _on_settings_pressed() -> void:
	_play_click_ui()
	SceneManager.goto_settings()
	
func _on_credits_pressed() -> void:
	_play_click_ui()
	SceneManager.goto_credits()

func _on_exit_pressed() -> void:
	_play_click_ui()
	SceneManager.request_quit()

# ==========================================
# VISUAL EFFECTS
# ==========================================

func _prepare_button_entrance() -> void:
	if is_instance_valid(buttons_panel):
		buttons_panel.modulate.a = 0.0
	
	var buttons = [btn_new_game, btn_continue, btn_load, btn_settings, btn_credits, btn_exit]
	for btn in buttons:
		if is_instance_valid(btn):
			btn.modulate.a = 0.0

func _iniciar_animaciones_titulo() -> void:
	var tween_entrada: Tween
	
	match entrance_anim_type:
		EntranceAnimation.NONE:
			title_container.modulate.a = 1.0
			_iniciar_animacion_idle() 
		EntranceAnimation.FADE_IN:
			tween_entrada = EssenceUIAnimator.fade_in(title_container, entrance_duration)
		EntranceAnimation.SLIDE_FROM_TOP:
			tween_entrada = EssenceUIAnimator.slide_from_top(title_container, slide_distance, entrance_duration)
			
	if tween_entrada:
		tween_entrada.finished.connect(_iniciar_animacion_idle)

func _iniciar_animacion_idle() -> void:
	if idle_anim_type == IdleAnimation.BREATHING:
		_idle_tween = EssenceUIAnimator.breathing(title_container, idle_duration)

func _animar_entrada_ui_botones() -> void:
	var cascade_start = 0.0
	
	if is_instance_valid(buttons_panel):
		EssenceUIAnimator.fade_in(buttons_panel, 0.4)
		cascade_start = 0.5 
		
	var buttons = [btn_new_game, btn_continue, btn_load, btn_settings, btn_credits, btn_exit]
	EssenceUIAnimator.cascade_fade_in(buttons, 0.4, 0.15, cascade_start)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_continue_button_state()

# ==============================================================================
# INTEGRATION HOOKS
# ==============================================================================

func _on_new_game_hook() -> void:
	pass

func _on_continue_hook(_save_data: Dictionary) -> void:
	pass