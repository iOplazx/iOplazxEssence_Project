# res://addons/ioplazx_essence/templates/SaveTemplate.gd
extends EssenceSaveData

# ==================================================================
# USAGE INSTRUCTIONS (Plug & Play):
# 1. Copy this file to a folder in your project (e.g., res://_static/)
# 2. Uncomment the line below and give your class any name you like
# 3. Drag your new file into EssenceMasterConfig
# ==================================================================
# class_name MyGameSave 

func _get_child_data() -> Dictionary:
	return {}

func _load_child_data(data: Dictionary):
	pass
