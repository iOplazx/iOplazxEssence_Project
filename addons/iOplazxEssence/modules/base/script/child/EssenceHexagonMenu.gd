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
	
	var hex_positions: Array[Vector2] = [
		Vector2(0, -cell_spacing),      # 1. Top Center
		Vector2(h_offset, -v_offset),    # 2. Top Right
		Vector2(h_offset, v_offset),     # 3. Bottom Right
		Vector2(0, cell_spacing),       # 4. Bottom Center
		Vector2(-h_offset, v_offset),    # 5. Bottom Left
		Vector2(-h_offset, -v_offset)    # 6. Top Left
	]
	
	# Manual correction for mathematical precision and hardware compression alignment
	hex_positions[5] = Vector2(-h_offset, -v_offset)

	# 2. ASSIGNMENT OF THE 6 CENTRAL ACTION SLOTS
	for pos in hex_positions:
		var btn = _instance_slot(pos, "vacio")
		if unknown_icon:
			btn.get_node("Icon").texture = unknown_icon
			
		# Rotates the button to face outward from the center
		# Add 90 degrees in radians because the base triangle asset faces North.
		btn.rotation = pos.angle() + deg_to_rad(90)
		
		botones_accion.append(btn)

	# 3. PAGINATION ARROWS POSITIONING (Horizontal outer wings)
	# Placed symmetrically on the sides of the hexagon for a sci-fi console layout look
	var pos_prev: Vector2 = Vector2(-h_offset * 1.8, 0.0)
	var pos_next: Vector2 = Vector2(h_offset * 1.8, 0.0)

	btn_prev = _instance_slot(pos_prev, "pagina_anterior")
	if icon_prev: 
		btn_prev.get_node("Icon").texture = icon_prev

	btn_next = _instance_slot(pos_next, "pagina_siguiente")
	if icon_next: 
		btn_next.get_node("Icon").texture = icon_next
