## [EssenceModalPrompt]
## Implementación concreta del modal prompt para iOplazx Essence.
class_name EssenceModalPrompt
extends EssenceBaseModalPrompt

# ==
# ESTRUCTURA DE LA ESCENA PROCESADA:
# ==
# EssenceModalPrompt (Control) [Script: EssenceModalPrompt] ────> Full Rect (Anclaje a toda la pantalla)
# ├── DimmerOverlay (ColorRect) ────────────────────────────────> Color: Negro con Alpha (ej. Color(0,0,0,0.6))
# │                                                               Layout: Full Rect
# │                                                               Mouse Filter: STOP (¡Bloquea todos los clics!)
# └── PromptPanel (PanelContainer) ──────────────────────────────> Anclaje: Center / Ancho Mínimo: 400px
#     └── MarginContainer ───────────────────────────────────────> Margin: 20px
#         └── VBoxContainer
#             ├── TitleLabel (Label) ───────────────────────────> Estilo H1 (Ej. 26px)
#             ├── BodyLabel (RichTextLabel) ────────────────────> Estilo H2 (Ej. 20px) / Fit Content: True
#             └── ButtonContainer (HBoxContainer) ──────────────> Alineación: Center / Separation: 10px


@onready var title_label: Label = $PromptPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var body_label: RichTextLabel = $PromptPanel/MarginContainer/VBoxContainer/BodyLabel
@onready var button_container: HBoxContainer = $PromptPanel/MarginContainer/VBoxContainer/ButtonContainer


func _set_title_text(text: String) -> void:
	if is_instance_valid(title_label):
		title_label.text = text


func _set_body_text(text: String) -> void:
	if is_instance_valid(body_label):
		body_label.text = text


func _get_button_container() -> Container:
	return button_container
