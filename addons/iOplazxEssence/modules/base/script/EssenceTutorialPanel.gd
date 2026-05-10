extends EssenceLateralPanel 
class_name EssenceTutorialPanel
# =======
# ESTRUCTURA DE LA ESCENA: EssenceTutorialPanelUI (Heredada)
# =======
# EssenceTutorialPanelUI (Control) [Heredado]
# └── CajonDeslizante (Control) [Heredado]
#     ├── ContenedorFondo (Panel) [Heredado]
#     │   └── MargenInterno (MarginContainer) [Heredado]
#     │       └── ContenedorContenido (VBoxContainer) [Heredado]
#     │           ├── (+) TituloTutorial (Label)          <- Ej: "Annie dice:"
#     │           ├── (+) Separador (HSeparator)         <- Opcional: línea estética
#     │           ├── (+) TextoExplicativo (RichTextLabel) <- El texto del tutorial
#     │           └── (+) ContenedorBotones (HBoxContainer) <- Para ponerlos en fila
#     │               ├── (+) BtnAnterior (Button)        <- Volver atrás
#     │               └── (+) BtnSiguiente (Button)       <- Avanzar
#     └── BtnAlternar (Button) [Heredado]
# =====
# ==========================================
# SEÑALES
# ==========================================
signal tutorial_finished
signal page_changed(page: int)

# ==========================================
# VARIABLES
# ==========================================
@export var tutorial_pages: Array[String] = []
var _current_page: int = 0

# Referencias a la UI (Asegúrate de marcar estos nodos con % en la escena)
@onready var rich_text_tutorial: RichTextLabel = %TextoExplicativo
@onready var btn_prev: Button = %BtnAnterior
@onready var btn_next: Button = %BtnSiguiente

# ==========================================
# INICIALIZACIÓN
# ==========================================
func _ready() -> void:
	super._ready() 
	
	# Borrar texto de prueba del editor
	if rich_text_tutorial: 
		rich_text_tutorial.text = ""
	
	# Conectar botones propios del tutorial
	if btn_prev: 
		btn_prev.pressed.connect(prev_page)
		btn_prev.focus_mode = Control.FOCUS_NONE
		
	if btn_next: 
		btn_next.pressed.connect(next_page)
		btn_next.focus_mode = Control.FOCUS_NONE
	
	_update_ui()

# ==========================================
# MÉTODOS PÚBLICOS (API del Tutorial)
# ==========================================

# Opción 1: Carga los mensajes y abre el panel automáticamente
func load_and_show_tutorial(messages: Array[String]) -> void:
	_setup_new_tutorial(messages)
	show() # Asegura que el control principal sea visible
	if not is_open:
		toggle() # Llama a la función de la clase base para abrirlo con animación

# Opción 2: Carga los mensajes pero espera a que el jugador abra el panel
func load_tutorial_silently(messages: Array[String]) -> void:
	_setup_new_tutorial(messages)

func next_page() -> void:
	if _current_page < tutorial_pages.size() - 1:
		_current_page += 1
		_update_ui()
	else:
		tutorial_finished.emit()
		# Opcional: Cerrar el panel automáticamente al terminar
		if is_open:
			toggle()

func prev_page() -> void:
	if _current_page > 0:
		_current_page -= 1
		_update_ui()

# ==========================================
# MÉTODOS PRIVADOS
# ==========================================

# Método central que hace el trabajo de carga de datos
func _setup_new_tutorial(messages: Array[String]) -> void:
	tutorial_pages = messages
	_current_page = 0
	_update_ui()

func _update_ui() -> void:
	if tutorial_pages.is_empty(): 
		return
		
	# Actualizar texto
	if rich_text_tutorial: 
		rich_text_tutorial.text = tutorial_pages[_current_page]
		
	# Actualizar estado de los botones
	if btn_prev:
		btn_prev.disabled = (_current_page == 0)
	
	if btn_next:
		if _current_page == tutorial_pages.size() - 1:
			btn_next.text = "Understood!"
		else:
			btn_next.text = "Next >"

	page_changed.emit(_current_page)
