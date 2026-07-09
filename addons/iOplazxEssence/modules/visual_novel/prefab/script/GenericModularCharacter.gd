class_name GenericModularCharacter
extends EssenceModularActor

## CONSTANTS: Nombres exactos de las capas de sprites según tu nomenclatura 'GenericChr'.
const JACKET_POOL: Array[String] = [
	"GenericChrJacket1",
	"GenericChrJacket2",
	"GenericChrJacket3",
	"GenericChrJacket4"
]

const MUSTACHE_ID: String = "GenericChrMoustache"

func _ready() -> void:
	# 1. CRITICAL: Llamamos al _ready del padre para construir el '_wardrobe_map' en RAM
	super._ready()
	
	# 2. Ejecutamos la aleatoriedad estética al instanciarse en el parque
	_randomize_appearance()


## Apaga las chaquetas del pool y activa una al azar, decidiendo también si lleva bigote.
func _randomize_appearance() -> void:
	# Cláusula de guarda: Si el diccionario del padre falló o está vacío, abortamos
	if _wardrobe_map.is_empty():
		return
		
	# 1. LIMPIEZA DE CATEGORÍA
	# Apagamos todas las chaquetas a través del método del padre para evitar superposiciones
	for jacket_id in JACKET_POOL:
		toggle_garment(jacket_id, false)
		
	# 2. SELECCIÓN ALEATORIA DE CHAQUETA
	if not JACKET_POOL.is_empty():
		var random_jacket_index: int = randi() % JACKET_POOL.size()
		var chosen_jacket: String = JACKET_POOL[random_jacket_index]
		toggle_garment(chosen_jacket, true) # Lo encendemos usando el mapa indexado
		
	# 3. RESOLUCIÓN DEL BIGOTE (50% de probabilidad de aparecer)
	var has_mustache: bool = (randi() % 2 == 0)
	toggle_garment(MUSTACHE_ID, has_mustache) # Mandamos la llave exacta al padre
	
