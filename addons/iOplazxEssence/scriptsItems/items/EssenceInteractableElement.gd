class_name EssenceInteractableElement
extends Area2D

## Adaptive scaling factor and color presets for polished interaction.
const HOVER_SCALE_MULTIPLIER: float = 1.05
const COLOR_CLICK_TARGET: Color = Color(0.7, 0.7, 0.7)
const COLOR_DEFAULT_TARGET: Color = Color(1.0, 1.0, 1.0)
const ANIMATION_DURATION: float = 0.12

## Cached references for optimal calculations.
var _visual_node: CanvasItem
var _original_scale: Vector2 = Vector2.ONE
var _is_scale_cached: bool = false

## Tweens memory handling to prevent visual overlapping.
var _scale_tween: Tween
var _color_tween: Tween

func _ready() -> void:
	_visual_node = _find_visual_target()
	
	# Connect automated hover and click signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

## Automatically scans children to isolate the rendering node.
func _find_visual_target() -> CanvasItem:
	for child in get_children():
		if child is CanvasItem and not child is CollisionShape2D:
			return child
	return null

func _on_mouse_entered() -> void:
	if not is_instance_valid(_visual_node): return
	
	# LAZY-CACHE: Safely store the layout preset baseline scale on first hover
	if not _is_scale_cached:
		_original_scale = _visual_node.scale
		_is_scale_cached = true
		
	if _scale_tween and _scale_tween.is_running():
		_scale_tween.kill()
		
	# Calculate target scale dynamically relative to its preset size (e.g., 0.256 * 1.05)
	var target_hover_scale: Vector2 = _original_scale * HOVER_SCALE_MULTIPLIER
	_scale_tween = EssenceUIAnimator.scale_to(_visual_node, target_hover_scale, ANIMATION_DURATION)

func _on_mouse_exited() -> void:
	if not is_instance_valid(_visual_node): return
	
	if _scale_tween and _scale_tween.is_running():
		_scale_tween.kill()
	if _color_tween and _color_tween.is_running():
		_color_tween.kill()
		
	# Return cleanly to the exact layout preset scale and default modulation
	_scale_tween = EssenceUIAnimator.scale_to(_visual_node, _original_scale, ANIMATION_DURATION)
	_color_tween = EssenceUIAnimator.modulate_to(_visual_node, COLOR_DEFAULT_TARGET, ANIMATION_DURATION)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_instance_valid(_visual_node): return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _color_tween and _color_tween.is_running():
			_color_tween.kill()
			
		if event.pressed:
			_color_tween = EssenceUIAnimator.modulate_to(_visual_node, COLOR_CLICK_TARGET, ANIMATION_DURATION)
		else:
			_color_tween = EssenceUIAnimator.modulate_to(_visual_node, COLOR_DEFAULT_TARGET, ANIMATION_DURATION)
			
