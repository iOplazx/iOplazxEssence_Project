## [EssenceReportUtils.gd]
## Static reporting utility for the Essence framework.
## Safely resolves dynamic enum values from EssenceError at runtime 
## and provides native Godot console fallbacks if the autoload is missing.
class_name EssenceReportUtils
extends RefCounted

# Default fallback severity values
const DEFAULT_INFO: int = 0
const DEFAULT_WARNING: int = 1
const DEFAULT_CRITICAL: int = 2

## Safely resolves severity value from EssenceError's Severity enum at runtime.
## Returns fallback_value if EssenceError is not registered or key is missing.
static func resolve_severity(severity_key: String, fallback_value: int) -> int:
	if Engine.has_singleton("EssenceError"):
		var singleton = Engine.get_singleton("EssenceError")
		if is_instance_valid(singleton):
			var script = singleton.get_script() as Script
			if is_instance_valid(script):
				var constants: Dictionary = script.get_script_constant_map()
				if constants.has("Severity") and constants["Severity"] is Dictionary:
					var severity_map: Dictionary = constants["Severity"]
					if severity_map.has(severity_key):
						return severity_map[severity_key]
	return fallback_value

## Main reporting method. Accepts String keys ("CRITICAL", "WARNING", "INFO") or raw ints.
static func report(title: String, msg: String, severity: Variant = "WARNING") -> void:
	var resolved_level: int = DEFAULT_WARNING
	
	if severity is String:
		var key_upper = severity.upper()
		match key_upper:
			"INFO":
				resolved_level = resolve_severity("INFO", DEFAULT_INFO)
			"CRITICAL", "ERROR":
				resolved_level = resolve_severity("CRITICAL", DEFAULT_CRITICAL)
			_:
				resolved_level = resolve_severity(key_upper, DEFAULT_WARNING)
	elif severity is int:
		resolved_level = severity

	# 1. Forward to EssenceError Autoload if loaded
	if Engine.has_singleton("EssenceError"):
		var singleton = Engine.get_singleton("EssenceError")
		if is_instance_valid(singleton) and singleton.has_method("report"):
			singleton.report(title, msg, resolved_level)
			return

	# 2. Native Godot console fallback
	match resolved_level:
		DEFAULT_INFO:
			print("[%s / INFO] %s" % [title, msg])
		DEFAULT_CRITICAL:
			push_error("[%s / CRITICAL] %s" % [title, msg])
		_:
			push_warning("[%s / WARNING] %s" % [title, msg])

# ==========================================
# CONVENIENCE SHORTCUTS
# ==========================================

static func warning(title: String, msg: String) -> void:
	report(title, msg, "WARNING")

static func critical(title: String, msg: String) -> void:
	report(title, msg, "CRITICAL")

static func info(title: String, msg: String) -> void:
	report(title, msg, "INFO")
