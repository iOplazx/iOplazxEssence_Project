## [Essence Base Interaction Button]
## Abstract parent class for all buttons in the interaction menu.
## Controls input cycle, mass click blocking, and standard hover effects.

class_name EssenceBaseInteractionButton
extends Control


## Señal oficial para notificar al mánager qué acción fue seleccionada 
signal accion_elegida(nombre_accion: String)

@export_category("Configuración Base")
@export var nombre_accion: String = "vacio" 
@export var textura_icono: Texture2D 

var btn: TextureButton
var icon: TextureRect
var escala_base: Vector2 
var puede_pulsarse: bool = true 

func _ready() -> void:
	# 1. Configurar el centro geométrico para animaciones elásticas 
	pivot_offset = size / 2.0
	
	# 2. Búsqueda segura por tipado para desacoplar el árbol de nodos
	btn = get_node_or_null("Btn") as TextureButton
	icon = get_node_or_null("Icon") as TextureRect
	
	# 3. Inicialización pasiva de texturas 
	if textura_icono and icon:
		icon.texture = textura_icono
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	# 4. Conexión segura de señales internas de Godot 
	if btn:
		btn.pressed.connect(_on_btn_pressed)
		btn.mouse_entered.connect(_on_hover_enter)
		btn.mouse_exited.connect(_on_hover_exit)
		
	call_deferred("_guardar_escala_base") 

func _guardar_escala_base() -> void:
	escala_base = scale 

## ANTI-SPAM COOLDOWN: Previene la explotación de múltiples clicks accidentales 
func _on_btn_pressed() -> void:
	if not puede_pulsarse: 
		return 
		
	puede_pulsarse = false 
	accion_elegida.emit(nombre_accion) 
	
	# Desbloqueo automatizado mediante hilos de tiempo nativos
	get_tree().create_timer(0.3).timeout.connect(func(): puede_pulsarse = true) 

## EFECTOS VISUALES VIRTUALES: Abiertos para sobreescritura en clases hijas 
func _on_hover_enter() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", escala_base * 1.1, 0.1).set_trans(Tween.TRANS_SINE) 

func _on_hover_exit() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", escala_base, 0.1).set_trans(Tween.TRANS_SINE) 
