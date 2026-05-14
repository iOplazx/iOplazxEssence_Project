## [EssenceActor]
## Universal base class for any character or entity on screen.
## It is extremely lightweight, ideal for background or filler characters
## that do not require interactivity or complex changes.
extends Node2D
class_name EssenceActor

# ==========================================
# PROPIEDADES BASE
# ==========================================
## Unique ID of the character (useful for save systems or dictionaries).
@export var character_id: String = "unknown_id"

## The name that will be displayed in dialog boxes or UI.
@export var display_name: String = "Unknown Character"

# ==========================================
# INICIALIZACIÓN
# ==========================================
func _ready() -> void:
	# Aquí a futuro se pueden registrar los actores en un "ActorManager" global
	pass

# ==========================================
# API DE ESCENARIO (STUBS PREPARADOS PARA EL FUTURO)
# ==========================================

## Slides or makes the character appear on the stage.
## [param entry_type]: The type of animation ("fade", "slide_left", etc.).
## [param duration]: How long the transition lasts.
func enter_stage(entry_type: String = "fade", duration: float = 0.5) -> void:
	# Lógica a implementar conectada con EssenceUIAnimator
	pass

## Removes the character from the stage.
## [param exit_type]: The type of animation ("fade", "slide_right", etc.).
## [param duration]: How long the transition lasts.
func exit_stage(exit_type: String = "fade", duration: float = 0.5) -> void:
	# Lógica a implementar conectada con EssenceUIAnimator
	pass
