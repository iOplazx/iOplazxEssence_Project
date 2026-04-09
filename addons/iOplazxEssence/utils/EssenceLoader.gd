class_name EssenceLoader extends RefCounted

## Carga imágenes propias del Framework
static func get_internImage(key: EssencePaths.KeyImage) -> Texture2D:
	if EssencePaths.INTERNAL_IMAGES.has(key):
		return load(EssencePaths.INTERNAL_IMAGES[key])
	
	push_error("iOplazxEssence Error: Clave de imagen interna no encontrada.")
	return load(EssencePaths.INTERNAL_IMAGES[EssencePaths.KeyImage.ERROR_FALLBACK])

## Carga imágenes del usuario (fuera del addon)
static func get_externImage(ruta: String, usar_imagen_error: bool = true) -> Texture2D:
	if ruta == "":
		pass # Salta directo al fallback
	
	# === EL PARCHE ===
	# Si la ruta es interna del motor, usamos el cargador nativo y evitamos el error al exportar
	elif ruta.begins_with("res://"):
		if ResourceLoader.exists(ruta):
			return load(ruta) as Texture2D
			
	# Si es una ruta externa real (user:// o C:/)
	elif FileAccess.file_exists(ruta):
		var img = Image.new()
		var err = img.load(ruta) # Cargamos los bytes puros
		
		if err == OK:
			return ImageTexture.create_from_image(img)
	
	push_error("iOplazxEssence Error: No se pudo cargar la imagen en -> " + ruta)
	
	# === FALLBACK ===
	if usar_imagen_error:
		return load(EssencePaths.INTERNAL_IMAGES[EssencePaths.KeyImage.ERROR_FALLBACK])
	
	return null
