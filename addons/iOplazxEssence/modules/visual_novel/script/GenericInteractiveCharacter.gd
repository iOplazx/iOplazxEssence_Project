extends EssenceInteractiveActor
class_name GenericInteractiveCharacter
# ==
# ESTRUCTURA DE LA ESCENA: GenericInteractiveCharacter (Base para Personajes)
# ==
# CharacterRoot (Node2D) [Script: EssenceInteractiveActor]
# ├── SubViewportContainer                     <-- Igual que Annie
# │   ├── SubViewport                          <-- Igual que Annie
# │   │   └── Visuals (Node2D)                 <-- Tu "Carpeta Raíz" interna
# │   │       └── Pose_Normal (Node2D)         <-- Carpeta de Pose (Aquí puedes crear Pose_B, Pose_C, etc.)
# │   │           ├── BaseBody (Sprite2D)      <-- El cuerpo de esta pose específica
# │   │           └── Wardrobe (Node2D)        <-- Contenedor de ropa de esta pose
# │   │               ├── FemDibujoCamisa (Sprite2D)
# │   │               └── FemDibujoPantalon (Sprite2D)
# │   └── Effects (Node2D)                     <-- Igual que Annie (Hermano de SubViewport)
# └── InteractArea (Area2D)                    <-- Igual que Annie (En la raíz, para los clics)
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
	
	# 2. Conectamos la señal de clic (que emite el padre) a nuestra propia función
	clicked_on_character.connect(_on_character_clicked)	
	

# ==========================================
# RESPUESTA A LA INTERACCIÓN
# ==========================================
func _on_character_clicked() -> void:
	# Aquí ocurre lo que sea que deba pasar cuando el jugador le hace clic.
	# Puede ser abrir un DialogBox, reproducir un sonido, etc.
	print("[%s] ¡Fui clicado! Ejecutando evento..." % display_name)
	
	# Ejemplo de uso de las funciones del addon (cambiar ropa al hacer clic):
	# toggle_garment("Camisa", false) 
