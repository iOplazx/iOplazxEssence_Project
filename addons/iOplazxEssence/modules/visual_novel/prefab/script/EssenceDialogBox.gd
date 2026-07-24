## [EssenceDialogBox]
## Implementación concreta adaptada para la estructura del .tscn de Vessel Voyager / iOplazx Essence.
class_name EssenceDialogBox
extends EssenceBaseDialogBox

# ==
# ESTRUCTURA DE LA ESCENA PROCESADA:
# ==
# EssenceDialogBox (PanelContainer) [Script: EssenceDialogBox]
# ├── Margin (MarginContainer)
# │   └── VBox (VBoxContainer)
# │       ├── NombreLabel (Label)
# │       └── TextoDialogo (RichTextLabel)
# └── ClickArea (Button) [Flat/Transparente]

@onready var nombre_label: Label = $Margin/VBox/NombreLabel
@onready var texto_dialogo: RichTextLabel = $Margin/VBox/TextoDialogo
@onready var click_area: Button = $ClickArea


func _ready() -> void:
	super._ready()
	if is_instance_valid(click_area):
		click_area.pressed.connect(advance_dialogue)


# ==========================================
# VINCULACIÓN CON LA CLASE BASE
# ==========================================

func _set_speaker_name(name_text: String, line_data: Dictionary) -> void:
	if is_instance_valid(nombre_label):
		nombre_label.text = name_text
		
		# BONUS: Si la línea especifica un color para el hablante, lo aplicamos
		if line_data.has("color"):
			nombre_label.add_theme_color_override("font_color", line_data["color"])


func _get_text_label_node() -> Control:
	return texto_dialogo
