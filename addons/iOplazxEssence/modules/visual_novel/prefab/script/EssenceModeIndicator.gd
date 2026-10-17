class_name EssenceModeIndicator
extends EssenceBaseModeIndicator

#==
# PROCESSED SCENE STRUCTURE:
#==
# EssenceModeIndicator.tscn
#  EssenceModeIndicator (Control) [Script: EssenceModeIndicator.gd]
#  └── PanelContainer (PanelContainer)
#      └── Margin (MarginContainer)
#          └── HBox (HBoxContainer)
#              ├── ModeIcon (TextureRect)
#              └── ModeLabel (Label)

@export_category("Optional Visual Styling")
## Text tint applied during exploration state.
@export var color_exploration: Color = Color(0.3, 0.9, 0.5, 1.0)
## Text tint applied during dialogue state.
@export var color_dialogue: Color = Color(0.9, 0.7, 0.2, 1.0)
## Text tint applied during cutscene / event state.
@export var color_cutscene: Color = Color(0.9, 0.3, 0.3, 1.0)


## Overrides concrete visual assignments for icons, localized text, and color tints.
func _apply_mode_graphics(game_state: EssenceGameplayDirector.GameState) -> void:
	match game_state:
		EssenceGameplayDirector.GameState.EXPLORATION:
			if is_instance_valid(mode_label):
				mode_label.text = tr("ESS_MODE_INDICATOR_EXPLORATION")
				mode_label.modulate = color_exploration
			if is_instance_valid(mode_icon) and icon_exploration:
				mode_icon.texture = icon_exploration

		EssenceGameplayDirector.GameState.DIALOGUE:
			if is_instance_valid(mode_label):
				mode_label.text = tr("ESS_MODE_INDICATOR_DIALOGUE")
				mode_label.modulate = color_dialogue
			if is_instance_valid(mode_icon) and icon_dialogue:
				mode_icon.texture = icon_dialogue

		EssenceGameplayDirector.GameState.CUTSCENE:
			if is_instance_valid(mode_label):
				mode_label.text = tr("ESS_MODE_INDICATOR_CUTSCENE")
				mode_label.modulate = color_cutscene
			if is_instance_valid(mode_icon) and icon_cutscene:
				mode_icon.texture = icon_cutscene
