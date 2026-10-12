class_name EssenceNavigationRoom
extends EssenceInteractiveLocation

@warning_ignore("unused_signal")
signal navigation_requested(next_place: int, mode: int, is_only_mode: bool)

func _ready() -> void:
	super._ready() # Executes framework automatic click hook
	_setup_hover_effects()

## Scans hotspots and hooks mouse hover behavior automatically.
func _setup_hover_effects() -> void:
	if not fixed_hotspots: return
	
	for hotspot in fixed_hotspots.get_children():
		if hotspot is Area2D:
			# Disable hover/highlight visual visibility on startup
			_apply_hover_state(hotspot, false)
			
			var on_entered = func(target: Area2D):
				if environment_interactable:
					_apply_hover_state(target, true)

			var on_exited = func(target: Area2D):
				_apply_hover_state(target, false)
			
			if not hotspot.mouse_entered.is_connected(on_entered):
				hotspot.mouse_entered.connect(on_entered.bind(hotspot))
			if not hotspot.mouse_exited.is_connected(on_exited):
				hotspot.mouse_exited.connect(on_exited.bind(hotspot))

## Apply visual logic when hovering over a hotspot.
func _apply_hover_state(hotspot: Area2D, is_hovered: bool) -> void:
	for child in hotspot.get_children():
		if child is CanvasItem and not child is CollisionShape2D:
			child.visible = is_hovered

func _toggle_hotspots_interaction(enabled: bool) -> void:
	super._toggle_hotspots_interaction(enabled)
	# Turn off hover states when room interactions are locked
	if not enabled and fixed_hotspots:
		for hotspot in fixed_hotspots.get_children():
			if hotspot is Area2D:
				_apply_hover_state(hotspot, false)
