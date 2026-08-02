## [EssenceDimmerOverlay]
## Componente modular para oscurecer la pantalla y bloquear clics traseros.
## Puede usarse como nodo independiente o dentro de escenas modales.
class_name EssenceDimmerOverlay
extends ColorRect

# ==
# EssenceDimmerOverlay (ColorRect) [Script: EssenceDimmerOverlay]
# ├── Layout: Full Rect (Preset 15)
# ├── Color: Color(0, 0, 0, 0.65)
# └── Mouse Filter: Stop

## Emitido si el usuario hace clic sobre el área oscura (útil para cerrar modales al hacer clic afuera)
signal overlay_clicked

@export_category("Overlay Settings")
## Tiempo por defecto de las animaciones de entrada/salida.
@export var default_fade_duration: float = 0.25
## Color y opacidad objetivo cuando la cortina está totalmente desplegada.
@export var target_color: Color = Color(0.0, 0.0, 0.0, 0.65)
## Si es verdadero, el overlay absorberá los clics e impedirá que pasen al fondo.
@export var block_mouse_input: bool = true


func _ready() -> void:
	# Forzamos el ajuste a pantalla completa y el filtro de mouse
	anchors_preset = Control.PRESET_FULL_RECT
	color = target_color
	mouse_filter = Control.MOUSE_FILTER_STOP if block_mouse_input else Control.MOUSE_FILTER_IGNORE
	
	# Detectar clics en el fondo si se requiere la señal
	gui_input.connect(_on_gui_input)


## Muestra el overlay ejecutando un fundido de entrada (Fade In).
func fade_in(duration: float = -1.0) -> Tween:
	var anim_time: float = duration if duration >= 0.0 else default_fade_duration
	show()
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, anim_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	return tween


## Oculta el overlay ejecutando un fundido de salida (Fade Out).
func fade_out(duration: float = -1.0) -> Tween:
	var anim_time: float = duration if duration >= 0.0 else default_fade_duration
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, anim_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
		
	tween.finished.connect(hide)
	return tween


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		overlay_clicked.emit()
