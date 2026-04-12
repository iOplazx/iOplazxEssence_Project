extends CanvasLayer

const ES_NAME_CLASS = "GlobalLoading"

@export_category("UI Connections")
@export var label: Label
@export var background: ColorRect # (Opcional) Por si en el futuro quieres animar el fondo

func _ready():
	_check_security_nodes()
	
	# TRUCO SENIOR: Forzamos la capa al máximo (100+) para garantizar 
	# que NADA en todo el juego pueda dibujarse por encima de esta pantalla.
	layer = 120 
	
	hide() # Nos aseguramos de que empiece invisible

# ==========================================
# BLINDAJE DE SEGURIDAD
# ==========================================
func _check_security_nodes():
	if not label:
		# Al ser un Autoload, usamos push_error directamente
		push_error("[%s] CRITICAL: Missing exported Label node." % ES_NAME_CLASS)

# ==========================================
# MÉTODOS PÚBLICOS
# ==========================================
## Muestra la pantalla bloqueando la UI con una suave transición
func show_loading(text_key: String = "UI_LOADING_DEFAULT"):
	if label:
		label.text = tr(text_key) 
		
	show()
	
	# Parche: Aplicamos la micro-animación al 'background' (ColorRect), no al CanvasLayer
	if background:
		background.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(background, "modulate:a", 1.0, 0.15)

## Oculta la pantalla de forma elegante
func hide_loading():
	if background:
		var tween = create_tween()
		tween.tween_property(background, "modulate:a", 0.0, 0.15)
		# Ocultamos todo el CanvasLayer cuando el fondo termina de desaparecer
		tween.tween_callback(hide) 
	else:
		# Fallback de seguridad por si olvidaste asignar el background
		hide()
