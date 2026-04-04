class_name EssenceExportUtils extends RefCounted

# ==========================================
# EXPORTACIÓN DE PARTIDAS
# ==========================================

## Exporta un slot de guardado y su captura a una carpeta seleccionada por el usuario.
static func export_slot(slot_id: String, internal_dir: String, external_dest_dir: String) -> bool:
	var source_ess = internal_dir.path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)
	var source_webp = internal_dir.path_join(slot_id + GameConstants.EXTENSION_IMAGE)
	
	var name_game = ProjectSettings.get_setting("application/config/name", "iOplazxEssence")
	if name_game.is_empty():
		name_game = "iOplazxEssence"
	
	# Creamos una subcarpeta bonita en el destino para no desordenar los archivos del usuario
	var export_folder_name = name_game + "_Backup_" + slot_id
	var final_export_path = external_dest_dir.path_join(export_folder_name)
	
	if not DirAccess.dir_exists_absolute(final_export_path):
		var err_dir = DirAccess.make_dir_recursive_absolute(final_export_path)
		if err_dir != OK:
			printerr("iOplazxEssence: No se pudo crear la carpeta de exportación. Error: ", err_dir)
			return false
	
	var target_ess = final_export_path.path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)
	var target_webp = final_export_path.path_join(slot_id + GameConstants.EXTENSION_IMAGE)
	
	# Copiamos el archivo de datos (Obligatorio)
	var err_ess = OK
	if FileAccess.file_exists(source_ess):
		err_ess = DirAccess.copy_absolute(source_ess, target_ess)
	else:
		printerr("iOplazxEssence: El archivo original no existe -> ", source_ess)
		return false
		
	# Copiamos la foto (Opcional, si no existe no detenemos la exportación)
	if FileAccess.file_exists(source_webp):
		DirAccess.copy_absolute(source_webp, target_webp)
		
	if err_ess == OK:
		# Archivo de advertencia para el usuario (Opcional, pero muy profesional)
		_crear_archivo_readme(final_export_path)
		print("iOplazxEssence: ¡Exportación exitosa a -> ", final_export_path, "!")
		return true
	else:
		printerr("iOplazxEssence: Falló la exportación del archivo .ess. Código: ", err_ess)
		return false

# ==========================================
# UTILIDADES INTERNAS
# ==========================================
static func _crear_archivo_readme(folder_path: String):
	var txt_path = folder_path.path_join("README.txt")
	var file = FileAccess.open(txt_path, FileAccess.WRITE)
	
	if file:
		# En funciones estáticas, usamos TranslationServer para evitar errores de contexto
		var title = TranslationServer.translate("README_TITLE")
		var desc = TranslationServer.translate("README_DESC")
		
		# Formateamos el string final
		var contenido_final = "=== " + title + " ===\n\n" + desc
		
		file.store_string(contenido_final)
		file.close()
