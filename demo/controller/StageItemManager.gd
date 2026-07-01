class_name StageItemManager
extends RefCounted

# ==============================================================================
# 🎯 ENUM DE PRESETS VISUALES (Ubicaciones reutilizables)
# ==============================================================================
enum LayoutPreset {
	NONE,         # 🚨 Útil para objetos únicos que pondrán sus coordenadas a mano
	DOOR_LEFT,
	DOOR_RIGHT,
	DOOR_CENTER,
	HUD_PHONE,
	HUD_BACKPACK,
	HUD_NOTEBOOK
}

# Geometría física mapeada directamente a los enums
const LAYOUT_GEOMETRY = {
	LayoutPreset.DOOR_LEFT:   {"position": Vector2(48, 593), "scale": Vector2(0.2, 0.2)},
	LayoutPreset.DOOR_RIGHT:  {"position": Vector2(1223, 593), "scale": Vector2(0.2, 0.2)},
	LayoutPreset.DOOR_CENTER: {"position": Vector2(640, 593), "scale": Vector2(0.2, 0.2)},
	LayoutPreset.HUD_PHONE:    {"position": Vector2(1150, 80), "scale": Vector2(0.6, 0.6)},
	LayoutPreset.HUD_BACKPACK: {"position": Vector2(1150, 200), "scale": Vector2(0.6, 0.6)},
	LayoutPreset.HUD_NOTEBOOK: {"position": Vector2(80, 80), "scale": Vector2(0.5, 0.5)}
}

# ==============================================================================
# 📋 MANIFIESTO ÚNICO (Con expresiones de modo, Enums e IDs Únicos)
# ==============================================================================
const ROOM_ITEM_MANIFESTO = {
	GameIDs.RoomID.INITIAL_ROOM: [
		{
			"instance_id": 100,
			"item_id": GameIDs.ItemID.TOUCH_INDICATOR,
			"operator": GameIDs.StageCondition.EQUAL,
			"stage_value": 1,
			# 🚨 OBJETO ÚNICO: No usa preset, metemos sus coordenadas exclusivas aquí
			"layout_preset": LayoutPreset.NONE, 
			"position": Vector2(672, 398),
			"scale": Vector2(0.54, 0.54),
			"destination": -1
		},
		{
			"instance_id": 101,
			"item_id": GameIDs.ItemID.DOOR_SPRITE,
			"operator": GameIDs.StageCondition.GREATER_EQUAL,
			"stage_value": 2,
			"layout_preset": LayoutPreset.DOOR_LEFT, # 🚨 Uso limpio del Enum
			"destination": GameIDs.RoomID.ROOM_3_DOORS
		}
	],
	
	GameIDs.RoomID.ROOM_3_DOORS: [
		{"instance_id": 200, "item_id": GameIDs.ItemID.DOOR_SPRITE, "operator": GameIDs.StageCondition.GREATER_EQUAL, "stage_value": 1, "layout_preset": LayoutPreset.DOOR_LEFT, "destination": GameIDs.RoomID.ROOM_1_DOOR},
		{"instance_id": 201, "item_id": GameIDs.ItemID.DOOR_SPRITE, "operator": GameIDs.StageCondition.GREATER_EQUAL, "stage_value": 1, "layout_preset": LayoutPreset.DOOR_RIGHT, "destination": GameIDs.RoomID.INITIAL_ROOM}
	],
	
	GameIDs.RoomID.ROOM_1_DOOR: [
		{"instance_id": 300, "item_id": GameIDs.ItemID.DOOR_SPRITE, "operator": GameIDs.StageCondition.GREATER_EQUAL, "stage_value": 1, "layout_preset": LayoutPreset.DOOR_RIGHT, "destination": GameIDs.RoomID.ROOM_3_DOORS}
	],
	
	GameIDs.RoomID.PARK: [
		{
			"instance_id": 400,
			"item_id": GameIDs.ItemID.HOUSE_SPRITE,
			"operator": GameIDs.StageCondition.EQUAL,
			"stage_value": 1,
			# 🚨 OTRO OBJETO ÚNICO: Al parque no le creamos preset, lo posicionamos directo
			"layout_preset": LayoutPreset.NONE,
			"position": Vector2(250, 480),
			"scale": Vector2(1.0, 1.0),
			"destination": GameIDs.RoomID.ROOM_3_DOORS
		}
	]
}

# ==============================================================================
# 📐 CALCULADOR DE POSICIÓN
# ==============================================================================
static func get_item_placement(item_data: Dictionary, current_room_mode: int) -> Dictionary:
	var config: Dictionary = {
		"position": Vector2.ZERO,
		"scale": Vector2.ONE,
		"is_visible": false
	}
	
	# 1. ENVIAMOS LOS DOS PARAMETROS AL VALIDADOR INTERNO
	var op: int = item_data.get("operator", GameIDs.StageCondition.EQUAL)
	var target_val: int = item_data.get("stage_value", 1)
	
	if not _evaluate_operator_condition(current_room_mode, op, target_val):
		config["is_visible"] = false
		return config

	# 2. CARGA DE PRESET
	var preset = item_data.get("layout_preset", LayoutPreset.NONE)
	if preset != LayoutPreset.NONE and LAYOUT_GEOMETRY.has(preset):
		config["position"] = LAYOUT_GEOMETRY[preset]["position"]
		config["scale"] = LAYOUT_GEOMETRY[preset]["scale"]
		config["is_visible"] = true
			
	# 3. OVERRIDE MANUAL
	if item_data.has("position"):
		config["position"] = item_data["position"]
		config["scale"] = item_data.get("scale", Vector2.ONE)
		config["is_visible"] = true
		
	return config
	
# ===================================================================================
# ⚙️ THE NEW TWO-PARAMETER METHOD (Zero Strings, Pure Enum Logic)
# ==================================================================================
## Compares the current mode of the room against the target value using the enum operator.
static func _evaluate_operator_condition(current_mode: int, operator: int, target_value: int) -> bool:
	match operator:
		GameIDs.StageCondition.EQUAL:
			return current_mode == target_value
		GameIDs.StageCondition.GREATER:
			return current_mode > target_value
		GameIDs.StageCondition.GREATER_EQUAL:
			return current_mode >= target_value
		GameIDs.StageCondition.LESS:
			return current_mode < target_value
		GameIDs.StageCondition.LESS_EQUAL:
			return current_mode <= target_value
			
	return false # Por seguridad si mandan un enum roto
