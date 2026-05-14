extends EssenceInteractiveActor
class_name GenericInteractiveCharacter
# ===
# ESTRUCTURA DE LA ESCENA: GenericInteractiveCharacter (Base para Personajes)
# ===
# CharacterRoot (Node2D) [Script: EssenceInteractiveActor]
# ├── Visuals (Node2D)                       <-- Contenedor de capas visuales
# │   ├── BaseBody (Sprite2D)                <-- El cuerpo/piel del personaje
# │   └── Wardrobe (Node2D)                  <-- Contenedor de ropa (opcional)
# │       ├── ... 
# ├── Effects (Node2D)                       <-- Capas de efectos (fantasmas, etc)
# │   └── ...
# └── InteractArea (Area2D)                  <-- Zona de detección de clics
#     └── CollisionShape2D                   <-- Forma de la zona (Silueta)
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
