## [PoseComponentGIC]
## Representa una postura física del personaje y sus prendas exclusivas.
extends WardrobeGroupGIC
class_name PoseComponentGIC

@export_category("Dependencias de Postura")
## La carpeta/control de ropa fija que comparte esta postura (ej: Group_Normal_Action).
@export var shared_clothing_group: WardrobeGroupGIC
