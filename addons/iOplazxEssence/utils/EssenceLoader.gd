class_name EssenceLoader extends RefCounted

## Carga imágenes propias del Framework
static func get_internImage(key: EssencePaths.KeyImage) -> Texture2D:
	if EssencePaths.INTERNAL_IMAGES.has(key):
		return load(EssencePaths.INTERNAL_IMAGES[key])
	
	push_error("iOplazxEssence Error: Clave de imagen interna no encontrada.")
	return load(EssencePaths.INTERNAL_IMAGES[EssencePaths.KeyImage.ERROR_FALLBACK])

## Carga imágenes del usuario (fuera del addon)
static func get_externImage(ruta: String, usar_imagen_error: bool = true) -> Texture2D:
	if ruta != "" and ResourceLoader.exists(ruta):
		return load(ruta)
	
	push_error("iOplazxEssence Error: No se encontró la imagen externa en -> " + ruta)
	
	if usar_imagen_error:
		return load(EssencePaths.INTERNAL_IMAGES[EssencePaths.KeyImage.ERROR_FALLBACK])
	
	return null
