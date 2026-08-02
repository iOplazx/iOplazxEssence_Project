## [EssenceModalPrompt]
## Concrete implementation of the modal prompt UI for iOplazx Essence.
class_name EssenceModalPrompt
extends EssenceBaseModalPrompt

# ==
# ESTRUCTURA DE LA ESCENA PROCESADA:
# ==
# EssenceModalPrompt (Control) [Script: EssenceModalPrompt] 
# ├── DimmerOverlay (EssenceDimmerOverlay) 
# └── PromptPanel (PanelContainer) 
#     └── MarginContainer
#         └── VBoxContainer
#             ├── TitleLabel (Label) 
#             ├── BodyLabel (RichTextLabel) 
#             └── ButtonContainer (HBoxContainer) 

@export_category("UI References")
@onready var title_label: Label = $PromptPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var body_label: RichTextLabel = $PromptPanel/MarginContainer/VBoxContainer/BodyLabel
@onready var button_container: HBoxContainer = $PromptPanel/MarginContainer/VBoxContainer/ButtonContainer
@onready var dimmer_overlay: EssenceDimmerOverlay = $DimmerOverlay


func _set_title_text(text: String) -> void:
	if is_instance_valid(title_label):
		title_label.text = text


func _set_body_text(text: String) -> void:
	if is_instance_valid(body_label):
		body_label.text = text


func _get_button_container() -> Container:
	return button_container


## Animate the entrance of the dark background and the pop-up window
func _animate_in() -> void:
	modulate.a = 0.0
	if is_instance_valid(dimmer_overlay):
		dimmer_overlay.fade_in(fade_duration)
		
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	await tween.finished


## Encourages the departure of the entire group
func _animate_out() -> void:
	if is_instance_valid(dimmer_overlay):
		dimmer_overlay.fade_out(fade_duration)
		
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
