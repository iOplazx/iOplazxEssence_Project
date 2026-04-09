extends Node

enum Severity { INFO, WARNING, CRITICAL }

signal on_error_reported(error_data: Dictionary)

# Para el modo Dev: si es true, no sale la pantalla, solo el log
var silent_mode: bool = false 

func report(title: String, msg: String, severity: int = Severity.CRITICAL):
	var stack = get_stack() # Captura dónde falló exactamente
	var error_data = {
		"title": title,
		"message": msg,
		"severity": severity,
		"stack": stack,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	# 1. Siempre registrar en el Log (para el archivo .log)
	# Descomentar cuando tengamos el Logger listo:
	# EssenceLogger.write_log(error_data)
	
	# 2. Reaccionar según la gravedad
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
# HERRAMIENTAS PARA EL DESARROLLADOR
# ==========================================

# Úsalo en funciones vacías en lugar de 'pass'
func ExceptionNotImplement(method_name: String = "Desconocido"):
	var stack = get_stack()
	var script = stack[1]["source"] if stack.size() > 1 else "Script desconocido"
	var line = stack[1]["line"] if stack.size() > 1 else 0
	
	var msg = "El método '" + method_name + "' aún no ha sido programado en " + script + " (Línea " + str(line) + ")."
	report("MÉTODO NO IMPLEMENTADO", msg, Severity.CRITICAL)

# Envuelve funciones peligrosas para que no rompan el juego
func safe_execute(object: Object, method: String, args: Array = [], default_value = null):
	if not is_instance_valid(object):
		report("Objeto Nulo", "Se intentó llamar a " + method + " en un objeto que no existe.", Severity.CRITICAL)
		return default_value
		
	if not object.has_method(method):
		report("Método no encontrado", "El script no tiene la función: " + method, Severity.CRITICAL)
		return default_value

	# Llamamos al método de forma segura y devolvemos su resultado
	return object.callv(method, args)

# ==========================================
# REACCIONES VISUALES
# ==========================================

func _show_warning_icon(data: Dictionary):
	# Por ahora, usamos el warning nativo del motor.
	# Aquí podrías instanciar un pequeño panel flotante en la esquina.
	push_warning("Essence WARNING: [" + data["title"] + "] " + data["message"])

func _trigger_crash_screen(data: Dictionary):
	get_tree().paused = true
	
	# 1. Generar el archivo físico del log y guardar la ruta
	var log_path = EssenceLogger.create_crash_report(data)
	data["log_path"] = log_path # Metemos la ruta en el diccionario
	
	# 2. Instanciar pantalla
	var crash_path = EssencePaths.PATH_UI_SCREEN + "/EssenceCrashScreen.tscn"
	if ResourceLoader.exists(crash_path):
		var screen = load(crash_path).instantiate()
		get_tree().root.add_child(screen)
		if screen.has_method("setup"):
			screen.setup(data) # Ahora 'data' lleva la ruta del log
