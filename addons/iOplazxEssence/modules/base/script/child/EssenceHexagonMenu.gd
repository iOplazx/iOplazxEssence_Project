## [EssenceHexagonMenu]
## Overrides the geometric structure to arrange buttons in a rigid hexagonal pattern.
class_name EssenceHexagonMenu
extends EssenceBaseInteractionMenu

# ==
# HexagonMenu.tscn
# ==
# EssenceHexagonMenu (Control) [Script: HexagonMenu]
# └── Anchor (Marker2D)
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
	# Using fixed trigonometric ratios of the hexagon (sin(60°) = 0.866025)
	var h_offset: float = cell_spacing * 0.866025 # Internal height of the hex triangle
	var v_offset: float = cell_spacing * 0.5      # Half of the radius
	
	# Define the exact 6 positions of a pointy-topped hexagon ring
	var pos_top_center: Vector2 = Vector2(0, -cell_spacing)
	var pos_top_right: Vector2 = Vector2(h_offset, -v_offset)
	var pos_bottom_right: Vector2 = Vector2(h_offset, v_offset)  # Dedicated to NEXT PAGE
	var pos_bottom_center: Vector2 = Vector2(0, cell_spacing)
	var pos_bottom_left: Vector2 = Vector2(-h_offset, v_offset)   # Dedicated to PREV PAGE
	var pos_top_left: Vector2 = Vector2(-h_offset, -v_offset)

	# 2. REGISTER THE 4 STANDARD ACTION SLOTS
	# We map these 4 layout positions for dynamic gameplay choices (e.g. Talk, Examine)
	var action_positions: Array[Vector2] = [
		pos_top_center,
		pos_top_right,
		pos_bottom_center,
		pos_top_left
	]

	for pos in action_positions:
		var btn = _instance_slot(pos, "vacio")
		if unknown_icon:
			btn.get_node("Icon").texture = unknown_icon
			
		# Rotate button to face outward from the center
		# Add 90 degrees in radians because the base triangle asset faces North.
		btn.rotation = pos.angle() + deg_to_rad(90)
		
		botones_accion.append(btn)

	# 3. REGISTER THE 2 PAGINATION SLOTS AT THE BOTTOM CORNERS
	# Bottom Left Slot (Previous Page)
	btn_prev = _instance_slot(pos_bottom_left, "pagina_anterior")
	btn_prev.rotation = pos_bottom_left.angle() + deg_to_rad(90)
	if icon_prev: 
		btn_prev.get_node("Icon").texture = icon_prev

	# Bottom Right Slot (Next Page)
	btn_next = _instance_slot(pos_bottom_right, "pagina_siguiente")
	btn_next.rotation = pos_bottom_right.angle() + deg_to_rad(90)
	if icon_next: 
		btn_next.get_node("Icon").texture = icon_next
