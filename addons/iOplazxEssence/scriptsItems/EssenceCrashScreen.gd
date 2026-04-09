extends CanvasLayer

@export_category("Textos")
@export var lbl_header: Label
@export var lbl_title: Label
@export var lbl_description: Label

@export_category("Detalles Técnicos")
@export var btn_toggle_details: Button
@export var details_container: PanelContainer
@export var txt_details: TextEdit

@export_category("Botones de Acción")
@export var btn_back: Button
@export var btn_open_log: Button
@export var btn_open_folder: Button
@export var btn_ignore: Button
@export var btn_quit: Button

var _is_details_open: bool = false
var _current_log_path

func _ready():
	# Nos aseguramos de que este nodo corra aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Conectar botones a sus funciones
	if btn_toggle_details: btn_toggle_details.pressed.connect(_on_toggle_details_pressed)
	if btn_back: btn_back.pressed.connect(_on_back_pressed)
	if btn_open_log: btn_open_log.pressed.connect(_on_open_log_pressed)
	if btn_open_folder: btn_open_folder.pressed.connect(_on_open_folder_pressed)
	if btn_ignore: btn_ignore.pressed.connect(_on_ignore_pressed)
	if btn_quit: btn_quit.pressed.connect(_on_quit_pressed)
	
	# Ocultar detalles por defecto
	if details_container: details_container.visible = false

# ==========================================
# INYECCIÓN DE DATOS
# ==========================================
func setup(data: Dictionary):
	if lbl_title: 
		lbl_title.text = data.get("title", "Error Inesperado")
		
	if lbl_description: 
		lbl_description.text = data.get("message", "Se detectó una inconsistencia, pero no se proporcionaron detalles.")
		
	if txt_details:
		var stack = data.get("stack", [])
		var stack_text = "=== TRAZA DE ERROR ===\n"
		
		if stack.is_empty():
			stack_text += "No hay detalles de la pila (Stack Trace vacío).\n"
		else:
			# Formateamos el array de diccionarios en líneas legibles
			for i in range(stack.size()):
				var frame = stack[i]
				var file = frame.get("source", "N/A")
				var line = frame.get("line", 0)
				var func_name = frame.get("function", "N/A")
				stack_text += "[Nivel %d] %s -> %s() (Línea %d)\n" % [i, file, func_name, line]
				
		txt_details.text = stack_text
	_current_log_path = data.get("log_path", "")

# ==========================================
# EVENTOS DE BOTONES
# ==========================================
func _on_toggle_details_pressed():
	_is_details_open = not _is_details_open
	details_container.visible = _is_details_open
	
	if _is_details_open:
		btn_toggle_details.text = "▼ Ocultar detalles técnicos"
	else:
		btn_toggle_details.text = "► Ver detalles técnicos"

func _on_back_pressed():
	# El botón "Retroceder" por ahora simplemente recarga la escena actual
	# En un futuro, podría cargar el último "Slot_Temp" de autoguardado
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()

func _on_open_log_pressed():
	if _current_log_path != "":
		OS.shell_open(ProjectSettings.globalize_path(_current_log_path))
	else:
		_on_open_folder_pressed() # Si no hay log específico, abre la carpeta

func _on_open_folder_pressed():
	# Abre la carpeta 'user://' del juego en el explorador de Windows/Linux
	var path = ProjectSettings.globalize_path("user://")
	OS.shell_open(path)

func _on_ignore_pressed():
	# Continúa bajo propio riesgo del usuario/dev
	get_tree().paused = false
	queue_free()

func _on_quit_pressed():
	# Salida segura
	get_tree().quit()
