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
	# 1. ALEATORIZAR CHAQUETA USANDO LA SUB-CONSTANTE DE AGRUPACIÓN
	var jacket_pool = IDsNPCModular.JACKET_COLOR_GROUP
	if not jacket_pool.is_empty():
		var random_index: int = randi() % jacket_pool.size()
		var chosen_jacket_id: int = jacket_pool[random_index]
		
		# Equipa el ID numérico del color seleccionado
		modify_clothing(chosen_jacket_id, true)
		
	# 2. SELECCIÓN DEL BIGOTE (50% de probabilidad)
	if randi() % 2 == 0:
		modify_clothing(IDsNPCModular.Items.MUSTACHE, true)
