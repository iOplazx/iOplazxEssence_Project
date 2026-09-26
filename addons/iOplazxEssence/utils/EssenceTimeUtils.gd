class_name EssenceTimeUtils
extends RefCounted

## Formats total seconds into a clean display string (e.g., 3661 -> "01:01:01").
static func format_seconds(total_seconds: float, include_seconds: bool = true) -> String:
	var total_int: int = int(total_seconds)
	var hours: int = total_int / 3600
	var minutes: int = (total_int % 3600) / 60
	var seconds: int = total_int % 60
	
	if include_seconds:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]
	else:
		return "%02d:%02d" % [hours, minutes]

## Safely gets total active playtime seconds from TimeManager Autoload.
static func get_playtime_seconds() -> float:
	var main_loop: SceneTree = Engine.get_main_loop() as SceneTree
	if is_instance_valid(main_loop) and main_loop.root.has_node("TimeManager"):
		var manager: Node = main_loop.root.get_node("TimeManager")
		if is_instance_valid(manager) and manager.has_method("get_total_playtime"):
			return manager.get_total_playtime()
	return 0.0
