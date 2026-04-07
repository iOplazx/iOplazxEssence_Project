class_name EssenceLoader extends RefCounted

## Carga imágenes propias del Framework
static func get_internImage(key: EssencePaths.KeyImage) -> Texture2D:
	if EssencePaths.INTERNAL_IMAGES.has(key):
		return load(EssencePaths.INTERNAL_IMAGES[key])
	
	push_error("iOplazxEssence Error: Clave de imagen interna no encontrada.")
	return load(EssencePaths.INTERNAL_IMAGES[EssencePaths.KeyImage.ERROR_FALLBACK])

## Carga imágenes del usuario (fuera del addon)
static func get_externImage(ruta: String, usar_imagen_error: bool = true) -> Texture2D:
	# FileAccess mira el disco duro real, no el registro interno de Godot
	if ruta != "" and FileAccess.file_exists(ruta):
		var img = Image.new()
		var err = img.load(ruta) # Cargamos los bytes puros de la imagen
		
		if err == OK:
			# Convertimos esos bytes en una Textura que la UI puede usar
			return ImageTexture.create_from_image(img)
	
	push_error("iOplazxEssence Error: No se encontró la imagen externa en -> " + ruta)
	
	if usar_imagen_error:
		return load(EssencePaths.INTERNAL_IMAGES[EssencePaths.KeyImage.ERROR_FALLBACK])
	
	return null
