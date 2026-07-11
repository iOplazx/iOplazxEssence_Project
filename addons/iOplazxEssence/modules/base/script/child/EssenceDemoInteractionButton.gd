## [EssenceDemoInteractionButton]
## Especialización del botón para el entorno de pruebas de la demo.
class_name EssenceDemoInteractionButton
extends EssenceBaseInteractionButton

#==
#DemoInteractionButton.tscn
#==
#DemoInteractionButton (Control) [Script: DemoInteractionButton]
#├── Btn (TextureButton)
#├── Icon (TextureRect)
#└── HoverArrow (Sprite2D)
#==

@onready var hover_arrow: Sprite2D = $HoverArrow

func _ready() -> void:
	super._ready() # Inicializa texturas y eventos base[cite: 3]
	
	# La flecha inicia completamente invisible y transparente
	if hover_arrow:
		hover_arrow.visible = false
		hover_arrow.modulate.a = 0.0


## Sobreescritura del comportamiento cuando el mouse ENTRA al triángulo naranja[cite: 3]
func _on_hover_enter() -> void:
	# 1. Mantenemos el escalado elástico del padre[cite: 3]
	super._on_hover_enter()
	
	# 2. Activamos y hacemos un Fade In suave a la flecha blanca
	if hover_arrow:
		hover_arrow.visible = true
		var tween = create_tween()
		tween.tween_property(hover_arrow, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_SINE)


## Sobreescritura del comportamiento cuando el mouse SALE del triángulo naranja[cite: 3]
func _on_hover_exit() -> void:
	# 1. Regresamos el tamaño al estado original del padre[cite: 3]
	super._on_hover_exit()
	
	# 2. Desvanecemos la flecha blanca
	if hover_arrow:
		var tween = create_tween()
		tween.tween_property(hover_arrow, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func(): hover_arrow.visible = false)
		
