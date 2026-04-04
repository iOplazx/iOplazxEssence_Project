extends CanvasLayer

@onready var label: Label = $ColorRect/CenterContainer/Label

func _ready():
	hide() # Nos aseguramos de que empiece invisible

## Muestra la pantalla bloqueando la UI
func show_loading(text: String = "Processing..."):
	label.text = text
	show()

## Oculta la pantalla
func hide_loading():
	hide()
