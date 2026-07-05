extends EssenceInteractiveActor
class_name GenericInteractiveCharacter

# ==
# ESTRUCTURA DE LA ESCENA: GenericInteractiveCharacter (Base para Personajes)
# ==
# CharacterRoot (Node2D) [Script: EssenceInteractiveActor]
# ├── SubViewportContainer                     
# │   ├── SubViewport                          
# │   │   └── Visuals (Node2D)                 
# │   │       └── Pose_Normal (Node2D)         
# │   │           ├── BaseBody (Sprite2D)     
# │   │           └── Wardrobe (Node2D)        
# │   │               ├── GenericChrBelt (Sprite2D)
# │   │               ├── GenericChrHat (Sprite2D)
# │   │               └── ...
# │   └── Effects (Node2D)                    
# └── InteractArea (Area2D)                    
#     └── CollisionShape2D
# ==

# ==========================================
# NODOS Y EFECTOS ESPECÍFICOS DEL PERSONAJE
# ==========================================
# (Nota: La ropa ya NO va aquí. La ropa la arrastras directo al array 
# "Wardrobe Nodes" en el Inspector gracias a la clase padre).

#@export_category("Unique Effects")
#@export var marca_estado: Sprite2D
#@export var fantasma_acechante: Sprite2D

# ==========================================
# INICIALIZACIÓN
# ==========================================
func _ready() -> void:
	# 1. IMPORTANTE: Llamamos al _ready del padre para que el Addon
	# construya automáticamente el diccionario de ropa (Wardrobe Map).
	super._ready() 	

# ==========================================
# DETECCIÓN DE CLIC EN EL ÁREA
# ==========================================
func _on_interact_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Solo nos interesa clic izquierdo y presionado
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		if is_interactable:
			# Emitimos la señal oficial del Framework
			clicked_on_character.emit()
			
			# Consumimos el clic para que no siga traspasando la pantalla
			get_viewport().set_input_as_handled()
