## [EssenceHexagonMenu]
## Overrides the geometric structure to arrange buttons in a rigid hexagonal pattern.
class_name EssenceHexagonMenu
extends EssenceBaseInteractionMenu

# ==
# HexagonMenu.tscn
# ==
# EssenceHexagonMenu (Control) [Script: HexagonMenu]
# └── Anchor (Control)
#     ├── HexagonFrame (TextureRect)   
#     └── ButtonsContainer (Control)  

@export_category("Hexagonal Geometry")
## Distance from the center of the menu to the center of each hexagonal cell.
@export var cell_spacing: float = 110.0

## Implementation of the geometric layout using direct vectors of a hexagonal ring.
func _generate_geometric_structure() -> void:
	if not button_scene:
		push_error("[%s] Error: Assign the button scene in the Inspector." % name)
		return

	# 1. HEXAGONAL RING DIRECTIONS (Pointy-Topped Hexagon)
	# Calculate the 6 corners of the honeycomb layout around the origin (0,0)
	var h_offset: float = cell_spacing * 0.866025 
	var v_offset: float = cell_spacing * 0.5      
	
	# Define the exact 6 positions of a pointy-topped hexagon ring
	var pos_top_center: Vector2 = Vector2(0, -cell_spacing)
	var pos_top_right: Vector2 = Vector2(h_offset, -v_offset)
	var pos_bottom_right: Vector2 = Vector2(h_offset, v_offset)  # Dedicated to NEXT PAGE
	var pos_bottom_center: Vector2 = Vector2(0, cell_spacing)
	var pos_bottom_left: Vector2 = Vector2(-h_offset, v_offset)   # Dedicated to PREV PAGE
	var pos_top_left: Vector2 = Vector2(-h_offset, -v_offset)

	# 2. REGISTER THE 4 STANDARD ACTION SLOTS
	var action_positions: Array[Vector2] = [
		pos_top_center,
		pos_top_right,
		pos_bottom_center,
		pos_top_left
	]

	for pos in action_positions:
		var btn = _instance_slot(pos, "vacio")
		
		# Rotate the main button container to face outward from the center
		btn.rotation = pos.angle() + deg_to_rad(90)
		
		# COUNTER-ROTATION LAYER: Keeps the internal icon perfectly upright
		var icon_node = btn.get_node_or_null("Icon") as Control
		if is_instance_valid(icon_node):
			icon_node.pivot_offset = icon_node.size / 2.0
			icon_node.rotation = -btn.rotation
			
		if unknown_icon and is_instance_valid(icon_node):
			icon_node.texture = unknown_icon
		
		botones_accion.append(btn)

	# 3. REGISTER THE 2 PAGINATION SLOTS AT THE BOTTOM CORNERS
	# Bottom Left Slot (Previous Page)
	btn_prev = _instance_slot(pos_bottom_left, "pagina_anterior")
	btn_prev.rotation = pos_bottom_left.angle() + deg_to_rad(90)
	
	var prev_icon_node = btn_prev.get_node_or_null("Icon") as Control
	if is_instance_valid(prev_icon_node):
		prev_icon_node.pivot_offset = prev_icon_node.size / 2.0
		prev_icon_node.rotation = -btn_prev.rotation
		if icon_prev: 
			prev_icon_node.texture = icon_prev

	# Bottom Right Slot (Next Page)
	btn_next = _instance_slot(pos_bottom_right, "pagina_siguiente")
	btn_next.rotation = pos_bottom_right.angle() + deg_to_rad(90)
	
	var next_icon_node = btn_next.get_node_or_null("Icon") as Control
	if is_instance_valid(next_icon_node):
		next_icon_node.pivot_offset = next_icon_node.size / 2.0
		next_icon_node.rotation = -btn_next.rotation
		if icon_next: 
			next_icon_node.texture = icon_next
