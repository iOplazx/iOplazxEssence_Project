## [EssenceActor]
## Universal base class for any character or entity on screen.
## It is extremely lightweight, ideal for background or filler characters
## that do not require interactivity or complex changes.
extends Node2D
class_name EssenceActor

## Defines the available type-safe transition animations for the stage lifecycle.
enum TransitionType {
	INSTANT,
	FADE,
	SLIDE_LEFT,
	SLIDE_RIGHT
}

## Unique ID of the character (useful for save systems or dictionaries).
@export var character_id: String = "unknown_id"

## The name that will be displayed in dialog boxes or UI.
@export var display_name: String = "Unknown Character"

# ==========================================
# INICIALIZACIÓN
# ==========================================
func _ready() -> void:
	pass

## Makes the character appear smoothly on the stage using a type-safe transition style.
## [param entry_type]: The animation style chosen from the TransitionType enum.
## [param duration]: How long the transition lasts in seconds.
func enter_stage(entry_type: TransitionType = TransitionType.FADE, duration: float = 0.5) -> void:
	var container = get_node_or_null("SubViewportContainer")
	var target_node: CanvasItem = container if container else self
	
	match entry_type:
		TransitionType.INSTANT:
			target_node.modulate.a = 1.0
			
		TransitionType.FADE:
			target_node.modulate.a = 0.0
			if container:
				EssenceUIAnimator.fade_in_subviewport(container, duration)
			else:
				var tween = create_tween()
				tween.tween_property(self, "modulate:a", 1.0, duration)
				
		TransitionType.SLIDE_LEFT:
			# Target for future extension using your slide utilities
			pass

## Removes the character from the stage.
## [param exit_type]: The type of animation ("fade", "slide_right", etc.).
## [param duration]: How long the transition lasts.
func exit_stage(exit_type: String = "fade", duration: float = 0.5) -> void:
	# Lógica a implementar conectada con EssenceUIAnimator
	pass
