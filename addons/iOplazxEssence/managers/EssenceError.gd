extends Node

enum Severity { INFO, WARNING, CRITICAL }

signal on_error_reported(error_data: Dictionary)

# For Dev mode: if true, the screen does not appear, only the log
var silent_mode: bool = false 

func report(title: String, msg: String, severity: int = Severity.CRITICAL):
	var stack = get_stack()
	var error_data = {
		"title": title,
		"message": msg,
		"severity": severity,
		"stack": stack,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	# 1. Session Log Entry (session.log)
	# Convert the error into a single line of text for the general logal
	var type_label = "CRITICAL" if severity == Severity.CRITICAL else "WARNING"
	var log_line = "[%s] %s: %s" % [type_label, title, msg]
	
	# We use the actual Logger method
	EssenceLogger.system_info(log_line)
	
	# 2. React according to severity
	match severity:
		Severity.WARNING:
			_show_warning_icon(error_data)
		Severity.CRITICAL:
			if not silent_mode:
				_trigger_crash_screen(error_data)
			else:
				push_error("Essence Critical (Silent): " + msg)

	on_error_reported.emit(error_data)

# ==========================================
# DEVELOPER TOOLS
# ==========================================

# Use it in empty functions instead of 'pass'
func ExceptionNotImplement(method_name: String = "Unknown"):
	var stack = get_stack()
	var script = stack[1]["source"] if stack.size() > 1 else "Unknown script"
	var line = stack[1]["line"] if stack.size() > 1 else 0
	
	# We use %s to inject the variables into the translated text.
	var msg = tr("ERR_DESC_NOT_IMPLEMENTED") % [method_name, script, str(line)]
	report(tr("ERR_TITLE_NOT_IMPLEMENTED"), msg, Severity.CRITICAL)

func safe_execute(object: Object, method: String, args: Array = [], default_value = null):
	if not is_instance_valid(object):
		report(tr("ERR_TITLE_NULL_OBJECT"), tr("ERR_DESC_NULL_OBJECT") % method, Severity.CRITICAL)
		return default_value
		
	if not object.has_method(method):
		report(tr("ERR_TITLE_METHOD_NOT_FOUND"), tr("ERR_DESC_METHOD_NOT_FOUND") % method, Severity.CRITICAL)
		return default_value

	return object.callv(method, args)

# ==========================================
# VISUAL REACTIONS
# ==========================================

func _show_warning_icon(data: Dictionary):
	# For now, we use the engine's native warning. 
	# Here, you could instantiate a small floating panel in the corner.
	push_warning("Essence WARNING: [" + data["title"] + "] " + data["message"])

func _trigger_crash_screen(data: Dictionary):
	get_tree().paused = true
	
	# 1. Generate the physical log file and save the path.
	var log_path = EssenceLogger.create_crash_report(data)
	data["log_path"] = log_path # Metemos la ruta en el diccionario
	
	# 2. Instantiate screen
	var crash_path = EssencePaths.PATH_UI_SCREEN + "/EssenceCrashScreen.tscn"
	if ResourceLoader.exists(crash_path):
		var screen = load(crash_path).instantiate()
		get_tree().root.add_child(screen)
		if screen.has_method("setup"):
			screen.setup(data) # Now 'data' holds the log path

## Convenience shortcuts for quick reporting by severity
func report_warning(title: String, msg: String) -> void:
	report(title, msg, Severity.WARNING)

func report_critical(title: String, msg: String) -> void:
	report(title, msg, Severity.CRITICAL)

func report_info(title: String, msg: String) -> void:
	report(title, msg, Severity.INFO)
