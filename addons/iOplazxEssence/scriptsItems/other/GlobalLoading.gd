extends CanvasLayer

const ES_NAME_CLASS = "GlobalLoading"

@export_category("UI Connections")
@export var label: Label
@export var background: ColorRect # (Optional) Used for background fade animations

func _ready() -> void:
	_check_security_nodes()
	
	# Force layer to maximum (120) to guarantee 
	# that no other UI element in the game renders above this overlay.
	layer = 120 
	
	hide() # Ensure it starts invisible

# ==========================================
# SECURITY ARMORING
# ==========================================
func _check_security_nodes() -> void:
	if not label:
		EssenceReportUtils.critical(
			"UI Setup Error",
			"Missing exported Label node in %s." % ES_NAME_CLASS
		)

# ==========================================
# PUBLIC METHODS
# ==========================================
## Displays the loading overlay blocking background UI with a smooth fade-in.
func show_loading(text_key: String = "UI_LOADING_DEFAULT") -> void:
	if label:
		label.text = tr(text_key) 
		
	show()
	
	# Apply micro-animation to background ColorRect
	if background:
		background.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(background, "modulate:a", 1.0, 0.15)

## Smoothly hides the loading overlay.
func hide_loading() -> void:
	if background:
		var tween: Tween = create_tween()
		tween.tween_property(background, "modulate:a", 0.0, 0.15)
		# Hide CanvasLayer once fade-out completes
		tween.tween_callback(hide) 
	else:
		# Defensive fallback if background reference is missing
		hide()
