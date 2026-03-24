class_name EssenceLoader extends RefCounted

enum KeyImage {
	GODOT,
	IOPLAZX,
	WARNING,
	EYE,
	PLUS18,
	ERROR_FALLBACK
}

const PATH_RESOURCE = "res://addons/iOplazxEssence/resources/images/"

# Diccionario de rutas internas (Cosas que siempre existirán dentro del addon)
const INTERNAL_IMAGES = {
	KeyImage.GODOT: PATH_RESOURCE + "icon_godot.png",
	KeyImage.IOPLAZX: PATH_RESOURCE + "ioplazx_logo.png",
	KeyImage.WARNING: PATH_RESOURCE + "iconWarning.png",
	KeyImage.EYE: PATH_RESOURCE + "iconEye.png",
	KeyImage.PLUS18: PATH_RESOURCE + "iconPlus18.png",
	KeyImage.ERROR_FALLBACK: PATH_RESOURCE + "iconImageNoLoad.png"
}

## Carga imágenes propias del Framework
static func get_internImage(key: KeyImage) -> Texture2D:
	if INTERNAL_IMAGES.has(key):
		return load(INTERNAL_IMAGES[key])
	
	push_error("iOplazxEssence Error: Clave de imagen interna no encontrada.")
	return load(INTERNAL_IMAGES[KeyImage.ERROR_FALLBACK])

## Carga imágenes del usuario (fuera del addon)
static func get_externImage(ruta: String, usar_imagen_error: bool = true) -> Texture2D:
	if ruta != "" and ResourceLoader.exists(ruta):
		return load(ruta)
	
	push_error("iOplazxEssence Error: No se encontró la imagen externa en -> " + ruta)
	
	if usar_imagen_error:
		return load(INTERNAL_IMAGES[KeyImage.ERROR_FALLBACK])
	
	return null
