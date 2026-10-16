class_name EssenceBaseModeIndicator
extends Control

enum ScreenCorner { TOP_LEFT, BOTTOM_LEFT, TOP_RIGHT, BOTTOM_RIGHT }

@export_category("Positioning Settings")
## Target corner of the screen where the indicator anchors.
@export var target_corner: ScreenCorner = ScreenCorner.TOP_LEFT
## Interpolation percentage from screen center (0%) to corner (100%).
## Set to 100.0 to lock it directly against the corner margins.
@export_range(0.0, 100.0) var corner_offset_percent: float = 100.0
## Safety margin in pixels from screen edges (X: horizontal, Y: vertical from top).
@export var margin_pixels: Vector2 = Vector2(16.0, 8.0)

@export_category("UI References")
@export var mode_label: Label
@export var mode_icon: TextureRect

@export_category("Mode Textures")
@export var icon_exploration: Texture2D
@export var icon_dialogue: Texture2D
@export var icon_cutscene: Texture2D

## Internal flag tracking explicit toggle visibility state.
var _is_indicator_enabled: bool = true


func _ready() -> void:
	_disable_mouse_filter_recursive(self)
	_validate_references()
	call_deferred("reposition_indicator")


## Validates required node references and reports warnings if missing.
func _validate_references() -> void:
	if not is_instance_valid(mode_label):
		EssenceReportUtils.warning(
			"UI Setup Warning",
			"['%s'] 'mode_label' reference is missing or unassigned in the Inspector." % name
		)
	if not is_instance_valid(mode_icon):
		EssenceReportUtils.warning(
			"UI Setup Warning",
			"['%s'] 'mode_icon' reference is missing or unassigned in the Inspector." % name
		)


## Calculates dynamic position between screen center (0%) and corner (100%).
func reposition_indicator() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size == Vector2.ZERO: 
		return
	
	var badge_size: Vector2 = custom_minimum_size if custom_minimum_size != Vector2.ZERO else size
	var center_pos: Vector2 = (viewport_size - badge_size) / 2.0
	var corner_pos: Vector2 = Vector2.ZERO
	
	match target_corner:
		ScreenCorner.TOP_LEFT:
			corner_pos = margin_pixels
		ScreenCorner.BOTTOM_LEFT:
			corner_pos = Vector2(margin_pixels.x, viewport_size.y - badge_size.y - margin_pixels.y)
		ScreenCorner.TOP_RIGHT:
			corner_pos = Vector2(viewport_size.x - badge_size.x - margin_pixels.x, margin_pixels.y)
		ScreenCorner.BOTTOM_RIGHT:
			corner_pos = viewport_size - badge_size - margin_pixels
			
	var final_position: Vector2 = center_pos.lerp(corner_pos, corner_offset_percent / 100.0)
	position = final_position
	set_meta("y_original", final_position.y)


## Changes the current game state display with animation sequence.
func set_mode(game_state: EssenceGameplayDirector.GameState) -> void:
	if not _is_indicator_enabled:
		return

	var update_content: Callable = func():
		_apply_mode_graphics(game_state)
		
	if not visible or modulate.a == 0.0:
		update_content.call()
		visible = true
		EssenceUIAnimator.slide_from_top(self, 40.0, 0.3)
	else:
		EssenceUIAnimator.transition_mode_switch(self, 40.0, 0.2, update_content)


## Toggles indicator visibility during scene changes or transitions.
func set_indicator_visible(p_visible: bool, animate: bool = true) -> void:
	_is_indicator_enabled = p_visible
	
	if not p_visible:
		if animate and visible:
			var tween = EssenceUIAnimator.fade_out(self, 0.2)
			if tween:
				tween.finished.connect(func(): visible = false)
		else:
			visible = false
			modulate.a = 0.0
	else:
		if animate:
			visible = true
			EssenceUIAnimator.fade_in(self, 0.2)
		else:
			visible = true
			modulate.a = 1.0


## Virtual method: Override in subclasses to update specific visual themes/textures.
func _apply_mode_graphics(_game_state: EssenceGameplayDirector.GameState) -> void:
	pass


## Recursively sets mouse filter to IGNORE so UI elements never block gameplay input.
func _disable_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_mouse_filter_recursive(child)
		
## Wrapper alias to reveal the indicator badge with optional animation.
func show_indicator(animate: bool = true) -> void:
	set_indicator_visible(true, animate)

## Wrapper alias to hide the indicator badge with optional animation.
func hide_indicator(animate: bool = true) -> void:
	set_indicator_visible(false, animate)

## Silently updates mode graphics while disabled and reveals the indicator with an entrance animation.
func initialize_and_show_mode(game_state: EssenceGameplayDirector.GameState) -> void:
	_is_indicator_enabled = true
	_apply_mode_graphics(game_state)
	visible = true
	modulate.a = 0.0
	EssenceUIAnimator.slide_from_top(self, 40.0, 0.3)
