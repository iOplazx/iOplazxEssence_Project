## [GenericModularCharacter]
## Actor pasivo de relleno. Utiliza su propio archivo de IDs
## y aprovecha la constante de agrupación para cambiar de color al azar.
class_name GenericModularCharacter
extends EssenceModularActor

# ==
# ESTRUCTURA DE LA ESCENA PROCESADA:
# ==
#GenericModularCharacter (Node2D) [Script: GenericModularCharacter]
#└── SubViewportContainer
#    └── SubViewport
#        └── Visuals (Node2D)
#            └── Pose_Normal (Node2D) [NPCWardrobeGroup] ───> Control de Pose 1
#                ├── BaseBody (Sprite2D)
#                └── Wardrobe (Node2D)
#                    ├── Jacket1 (Sprite2D)
#                    ├── Jacket2 (Sprite2D)
#                    ...
#                    └── Mustache (Sprite2D)

func _ready() -> void:
	super._ready()
	_randomize_appearance()


func _randomize_appearance() -> void:
	var jacket_pool = IDsNPCModular.JACKET_COLOR_GROUP
	
	# 1. LIMPIEZA VISUAL Y LÓGICA ANTES DEL DADO:
	# Apagamos todas las chaquetas del inventario para que no se pisen ni se acumulen en pantalla
	for jacket_id in jacket_pool:
		modify_clothing(jacket_id, false)
		
	# 2. SELECCIÓN ALEATORIA DE LA CHAQUETA:
	if not jacket_pool.is_empty():
		var random_index: int = randi() % jacket_pool.size()
		var chosen_jacket_id: int = jacket_pool[random_index]
		
		# Encendemos únicamente la ganadora
		modify_clothing(chosen_jacket_id, true)
		
	# 3. RESOLUCIÓN DIRECTA DEL BIGOTE:
	# Pasamos explícitamente el resultado (true o false) para purgar lo que venía del editor
	var has_mustache: bool = (randi() % 2 == 0)
	modify_clothing(IDsNPCModular.Items.MUSTACHE, has_mustache)
