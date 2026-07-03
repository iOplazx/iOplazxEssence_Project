## [EssenceUIAnimator]
## A static utility class for high-quality UI animations using Tweens.
## Optimized for Godot 4 with safety checks for Containers and Node lifecycle.
extends RefCounted
class_name EssenceUIAnimator

const LOG_TAG = "EssenceUIAnimator"

# ==========================================
# APPEARANCE ANIMATIONS (IN)
# ==========================================

## Makes a Control node appear smoothly by animating its alpha modulate.
## [param node]: The Control node to animate.
## [param duration]: Animation time in seconds.
## [param delay]: Time to wait before starting the animation.
static func fade_in(node: Control, duration: float, delay: float = 0.0) -> Tween:
	if not is_instance_valid(node): return null
	
	node.modulate.a = 0.0
	var tween = node.create_tween()
	tween.bind_node(node)
	tween.tween_property(node, "modulate:a", 1.0, duration).set_delay(delay).set_trans(Tween.TRANS_SINE)
	return tween

## Makes a Control node disappear smoothly.
## [param node]: The Control node to animate.
## [param duration]: Animation time in seconds.
static func fade_out(node: Control, duration: float) -> Tween:
	if not is_instance_valid(node): return null
	
	var tween = node.create_tween()
	tween.bind_node(node)
	tween.tween_property(node, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	return tween

## Slides a node from the top with a slight bounce effect.
## [color=yellow]Warning:[/color] If the parent is a Container, it will fallback to fade_in.
static func slide_from_top(node: Control, distance: float, duration: float) -> Tween:
	if not is_instance_valid(node): return null
	
	# Container Shield
	if node.get_parent() is Container:
		return _container_fallback(node, "slide_from_top", duration)
		
	node.modulate.a = 1.0
	node.pivot_offset = node.size / 2.0
	
	# Position Memory (Prevent cumulative displacement)
	var target_y = _get_original_y(node)
	node.position.y = target_y - distance
	
	var tween = node.create_tween()
	tween.bind_node(node)
	tween.tween_property(node, "position:y", target_y, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween

## Slides a node from the bottom to its original position.
## [color=yellow]Warning:[/color] If the parent is a Container, it will fallback to fade_in.
static func slide_from_bottom(node: Control, distance: float, duration: float) -> Tween:
	if not is_instance_valid(node): return null
	
	# Container Shield
	if node.get_parent() is Container:
		return _container_fallback(node, "slide_from_bottom", duration)
		
	node.modulate.a = 1.0
	node.pivot_offset = node.size / 2.0
	
	# Position Memory
	var target_y = _get_original_y(node)
	node.position.y = target_y + distance
	
	var tween = node.create_tween()
	tween.bind_node(node)
	tween.tween_property(node, "position:y", target_y, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween

# ==========================================
# IDLE ANIMATIONS (LOOPS)
# ==========================================

## Creates an infinite breathing (scaling) effect.
## [param scale_max]: The maximum scale reached (e.g., 1.05 for 5% growth).
static func breathing(node: Control, duration: float, scale_max: float = 1.05) -> Tween:
	if not is_instance_valid(node): return null
	
	if node.size != Vector2.ZERO:
		node.pivot_offset = node.size / 2.0
		
	var tween = node.create_tween().set_loops()
	tween.bind_node(node)
	tween.tween_property(node, "scale", Vector2(scale_max, scale_max), duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), duration).set_trans(Tween.TRANS_SINE)
	return tween

# ==========================================
# GROUP ANIMATIONS
# ==========================================

## Makes a list of nodes appear one after another (staggered effect).
static func cascade_fade_in(nodes: Array, duration: float, stagger: float, start_delay: float = 0.0):
	var current_delay = start_delay
	for node in nodes:
		if is_instance_valid(node) and node is Control:
			fade_in(node, duration, current_delay)
			current_delay += stagger

# ==========================================
# SPECIAL NODE2D / VIEWPORT ANIMATIONS
# ==========================================

## Smoothly fades in a SubViewportContainer (ideal for 3D character previews).
## Ensures the internal Viewport doesn't look transparent or glitchy.
static func fade_in_subviewport(node: Node, duration: float) -> Tween:
	if not is_instance_valid(node): return null
	
	var container = node if node is SubViewportContainer else node.get_node_or_null("SubViewportContainer")
	
	if container and container is SubViewportContainer:
		container.modulate.a = 0.0
		var tween = container.create_tween()
		tween.bind_node(container)
		tween.tween_property(container, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE)
		return tween
	
	push_warning("[%s] fade_in_subviewport: No SubViewportContainer found." % LOG_TAG)
	return null

## Slides a Node2D (like a Character Sprite) from a side while fading in.
## [param offset_x]: Distance from its final position (Negative for Left, Positive for Right).
static func slide_in_node2d(node: Node2D, offset_x: float, duration: float) -> Tween:
	if not is_instance_valid(node): return null
	
	var target_x = node.position.x
	node.position.x += offset_x
	node.modulate.a = 0.0
	
	var tween = node.create_tween().set_parallel(true)
	tween.bind_node(node)
	tween.tween_property(node, "position:x", target_x, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 1.0, duration)
	return tween

# ==========================================
# INTERNAL HELPERS (PRIVATE)
# ==========================================

static func _get_original_y(node: Control) -> float:
	if node.has_meta("y_original"):
		return node.get_meta("y_original")
	
	var y = node.position.y
	node.set_meta("y_original", y)
	return y

static func _container_fallback(node: Control, anim_name: String, duration: float) -> Tween:
	# Use EssenceLogger if available, otherwise use print
	var msg = "[%s] '%s' converted to 'fade_in' for node: %s (Parent is Container)" % [LOG_TAG, anim_name, node.name]
	if ClassDB.class_exists("EssenceLogger"):
		EssenceLogger.system_info(msg)
	else:
		print(msg)
	return fade_in(node, duration)

# ==========================================
# INTERACTIVE CANVASITEM ANIMATIONS
# ==========================================

## Smoothly interpolates the scale of any CanvasItem (Node2D or Control).
static func scale_to(node: CanvasItem, target_scale: Vector2, duration: float) -> Tween:
	if not is_instance_valid(node): return null
	
	var tween = node.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", target_scale, duration)
	return tween

## Smoothly interpolates the color modulation of any CanvasItem.
static func modulate_to(node: CanvasItem, target_color: Color, duration: float) -> Tween:
	if not is_instance_valid(node): return null
	
	var tween = node.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate", target_color, duration)
	return tween
