class_name StageItemManager
extends RefCounted

const KEY_POSITION: String = "position"
const KEY_SCALE: String = "scale"
const KEY_IS_VISIBLE: String = "is_visible"

# ==============================================================================
# 🎯 ENUM DE PRESETS VISUALES (Ubicaciones reutilizables)
# ==============================================================================
enum LayoutPreset {
	NONE,         # Útil para objetos únicos que pondrán sus coordenadas a mano
	DOOR_LEFT,
	DOOR_RIGHT,
	DOOR_CENTER,
	HOUSE_RIGHT,
	HUD_PHONE,
	HUD_BACKPACK,
	HUD_NOTEBOOK
}

# Geometría física mapeada directamente a los enums
const LAYOUT_GEOMETRY = {
	LayoutPreset.DOOR_LEFT:   {KEY_POSITION: Vector2(48, 593), KEY_SCALE: Vector2(0.2, 0.2)},
	LayoutPreset.DOOR_RIGHT:  {KEY_POSITION: Vector2(1223, 593), KEY_SCALE: Vector2(0.2, 0.2)},
	LayoutPreset.DOOR_CENTER: {KEY_POSITION: Vector2(640, 593), KEY_SCALE: Vector2(0.2, 0.2)},
	LayoutPreset.HOUSE_RIGHT: {KEY_POSITION: Vector2(1198, 614), KEY_SCALE: Vector2(0.294, 0.337)},
	LayoutPreset.HUD_PHONE:    {KEY_POSITION: Vector2(1150, 80), KEY_SCALE: Vector2(0.6, 0.6)},
	LayoutPreset.HUD_BACKPACK: {KEY_POSITION: Vector2(1150, 200), KEY_SCALE: Vector2(0.6, 0.6)},
	LayoutPreset.HUD_NOTEBOOK: {KEY_POSITION: Vector2(80, 80), KEY_SCALE: Vector2(0.5, 0.5)}
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
			# OBJETO ÚNICO: No usa preset, metemos sus coordenadas exclusivas aquí
			"layout_preset": LayoutPreset.NONE, 
			KEY_POSITION: Vector2(641, 400),
			KEY_SCALE: Vector2(0.54, 0.54),
			"destination": -1
		},
		{
			"instance_id": 101,
			"item_id": GameIDs.ItemID.DOOR_SPRITE,
			"operator": GameIDs.StageCondition.GREATER_EQUAL,
			"stage_value": 2,
			"layout_preset": LayoutPreset.DOOR_LEFT, # Uso limpio del Enum
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
			"layout_preset": LayoutPreset.HOUSE_RIGHT,
			"destination": GameIDs.RoomID.ROOM_3_DOORS
		}
	]
}

# ==============================================================================
# 📐 CALCULADOR DE POSICIÓN
# ==============================================================================
static func get_item_placement(item_data: Dictionary, current_room_mode: int) -> Dictionary:
	var config: Dictionary = {
		KEY_POSITION: Vector2.ZERO,
		KEY_SCALE: Vector2.ONE,
		KEY_IS_VISIBLE: false
	}
	
	# 1. ENVIAMOS LOS DOS PARAMETROS AL VALIDADOR INTERNO
	var op: int = item_data.get("operator", GameIDs.StageCondition.EQUAL)
	var target_val: int = item_data.get("stage_value", 1)
	
	if not _evaluate_operator_condition(current_room_mode, op, target_val):
		config[KEY_IS_VISIBLE] = false
		return config

	# 2. CARGA DE PRESET
	var preset = item_data.get("layout_preset", LayoutPreset.NONE)
	if preset != LayoutPreset.NONE and LAYOUT_GEOMETRY.has(preset):
		config[KEY_POSITION] = LAYOUT_GEOMETRY[preset][KEY_POSITION]
		config[KEY_SCALE] = LAYOUT_GEOMETRY[preset][KEY_SCALE]
		config[KEY_IS_VISIBLE] = true
			
	# 3. OVERRIDE MANUAL
	if item_data.has(KEY_POSITION):
		config[KEY_POSITION] = item_data[KEY_POSITION]
		config[KEY_SCALE] = item_data.get(KEY_SCALE, Vector2.ONE)
		config[KEY_IS_VISIBLE] = true
		
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
