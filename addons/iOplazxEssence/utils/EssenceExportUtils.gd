class_name EssenceExportUtils extends RefCounted

const ES_NAME_CLASS = "EssenceExportUtils"

# ==========================================
# EXPORTACIÓN DE PARTIDAS
# ==========================================

static func export_slot(slot_id: String, internal_dir: String, external_dest_dir: String) -> bool:
	EssenceLogger.system_info("[%s] Iniciando exportación del slot: %s" % [ES_NAME_CLASS, slot_id])
	
	if slot_id.is_empty() or internal_dir.is_empty() or external_dest_dir.is_empty():
		# Usamos WARNING para que salte la campana amarilla sin crashear el juego
		EssenceError.report("Export Aborted", "Faltan parámetros para la exportación.", EssenceError.Severity.WARNING)
		return false
	
	var source_ess = internal_dir.path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)
	var source_webp = internal_dir.path_join(slot_id + GameConstants.EXTENSION_IMAGE)
	
	var name_game = ProjectSettings.get_setting("application/config/name", "iOplazxEssence")
	if name_game.is_empty(): name_game = "iOplazxEssence"
	
	var export_folder_name = name_game + "_Backup_" + slot_id
	var final_export_path = external_dest_dir.path_join(export_folder_name)
	
	if not DirAccess.dir_exists_absolute(final_export_path):
		var err_dir = DirAccess.make_dir_recursive_absolute(final_export_path)
		if err_dir != OK:
			# Solo llamamos al Error. Él se encarga del log internamente.
			EssenceError.report("Folder Error", "No se pudo crear la carpeta. Código: %s" % err_dir, EssenceError.Severity.WARNING)
			return false
	
	var target_ess = final_export_path.path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)
	var target_webp = final_export_path.path_join(slot_id + GameConstants.EXTENSION_IMAGE)
	
	if not FileAccess.file_exists(source_ess):
		EssenceError.report("File Missing", "El archivo original no existe: %s" % source_ess, EssenceError.Severity.WARNING)
		return false
		
	var err_ess = DirAccess.copy_absolute(source_ess, target_ess)
	
	if err_ess == OK:
		if FileAccess.file_exists(source_webp):
			DirAccess.copy_absolute(source_webp, target_webp)
			
		_crear_archivo_readme(final_export_path)
		EssenceLogger.system_info("[%s] ¡Exportación exitosa a: %s!" % [ES_NAME_CLASS, final_export_path])
		return true
	else:
		EssenceError.report("I/O Error", "Falló la copia del archivo. Código: %s" % err_ess, EssenceError.Severity.WARNING)
		return false

static func export_all_slots(slot_ids: Array, internal_dir: String, external_dest_dir: String) -> bool:
	EssenceLogger.system_info("[%s] Iniciando respaldo masivo de %d slots." % [ES_NAME_CLASS, slot_ids.size()])
	
	var name_game = ProjectSettings.get_setting("application/config/name", "iOplazxEssence")
	if name_game.is_empty(): name_game = "iOplazxEssence"
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var export_folder_name = name_game + "_Full_Backup_" + timestamp
	var final_export_path = external_dest_dir.path_join(export_folder_name)
	
	if not DirAccess.dir_exists_absolute(final_export_path):
		var err_dir = DirAccess.make_dir_recursive_absolute(final_export_path)
		if err_dir != OK:
			EssenceError.report("Folder Error", "Fallo al crear carpeta maestra. Código: %s" % err_dir, EssenceError.Severity.WARNING)
			return false
	
	var success_count = 0
	
	for slot_id in slot_ids:
		var source_ess = internal_dir.path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)
		var source_webp = internal_dir.path_join(slot_id + GameConstants.EXTENSION_IMAGE)
		var target_ess = final_export_path.path_join(slot_id + GameConstants.EXTENSION_SAVE_FILE)
		var target_webp = final_export_path.path_join(slot_id + GameConstants.EXTENSION_IMAGE)
		
		if FileAccess.file_exists(source_ess):
			var copy_err = DirAccess.copy_absolute(source_ess, target_ess)
			if copy_err == OK:
				success_count += 1
				if FileAccess.file_exists(source_webp):
					DirAccess.copy_absolute(source_webp, target_webp)
			else:
				# Aquí usamos el Logger normal porque es un fallo menor (se saltó 1 archivo, pero seguirá con los demás)
				EssenceLogger.system_info("[%s] Advertencia: No se pudo copiar %s" % [ES_NAME_CLASS, slot_id])

	if success_count > 0:
		_crear_archivo_readme(final_export_path)
		EssenceLogger.system_info("[%s] Respaldo masivo completado. %d partidas exportadas." % [ES_NAME_CLASS, success_count])
		return true
		
	EssenceError.report("Export Failed", "El respaldo masivo falló. No se exportó ninguna partida.", EssenceError.Severity.WARNING)
	return false

# ==========================================
# UTILIDADES INTERNAS
# ==========================================
static func _crear_archivo_readme(folder_path: String):
	var txt_path = folder_path.path_join("README.txt")
	var file = FileAccess.open(txt_path, FileAccess.WRITE)
	
	if file:
		var title = TranslationServer.translate("README_TITLE")
		var desc = TranslationServer.translate("README_DESC")
		var contenido_final = "=== " + title + " ===\n\n" + desc
		
		file.store_string(contenido_final)
		file.close()
	else:
		EssenceLogger.system_info("[%s] Advertencia: No se pudo generar el README.txt" % ES_NAME_CLASS)