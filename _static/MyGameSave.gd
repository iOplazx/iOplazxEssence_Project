class_name MyGameSave extends EssenceSaveData

func _get_child_data() -> Dictionary:
	return {}

func _load_child_data(data: Dictionary):
	print("Test STATIC myGameSave")
	
