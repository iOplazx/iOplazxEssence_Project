class_name EssenceNavigationRoom
extends EssenceInteractiveLocation

@warning_ignore("unused_signal")
signal navigation_requested(next_place: int, mode: int, is_only_mode: bool)

func _ready() -> void:
	super._ready() # Ejecuta los clics automáticos del framework Essence
	_setup_hover_effects()

## Scans hotspots and hooks mouse hover behavior automatically.
func _setup_hover_effects() -> void:
	if not fixed_hotspots: return
	
	for hotspot in fixed_hotspots.get_children():
		if hotspot is Area2D:
			_set_hotspot_visual_visibility(hotspot, false)
			
			var on_entered = func(target: Area2D):
				if environment_interactable:
					_set_hotspot_visual_visibility(target, true)

			var on_exited = func(target: Area2D):
				_set_hotspot_visual_visibility(target, false)
			
			hotspot.mouse_entered.connect(on_entered.bind(hotspot))
			hotspot.mouse_exited.connect(on_exited.bind(hotspot))

## Helper to toggle hover visibility.
func _set_hotspot_visual_visibility(hotspot: Area2D, p_visible: bool) -> void:
	for child in hotspot.get_children():
		if child is CanvasItem and not child is CollisionShape2D:
			child.visible = p_visible
