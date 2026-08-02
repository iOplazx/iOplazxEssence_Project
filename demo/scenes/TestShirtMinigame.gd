## [TestShirtMinigame]
## A simple test minigame requiring the player to click 3 shirt buttons.
class_name TestShirtMinigame
extends EssenceBaseMiniGame

# TestShirtMinigame (Control) [Script: TestShirtMinigame] (Anchors: Full Rect / Layout: Center)
# └── PanelContainer (Ancho mínimo: 400px)
#     └── MarginContainer (Padding: 20px)
#         └── VBoxContainer (Separation: 16px)
#             ├── TitleLabel (Label) ───────────────────> Text: "Select all 3 shirts!"
#             └── ShirtContainer (HBoxContainer) ───────> Alignment: Center / Separation: 12px
#                 ├── ShirtButton1 (Button) ────────────> Text: "👕 Shirt 1" (% Unique Name)
#                 ├── ShirtButton2 (Button) ────────────> Text: "👕 Shirt 2" (% Unique Name)
#                 └── ShirtButton3 (Button) ────────────> Text: "👕 Shirt 3" (% Unique Name)

@onready var shirt_1: Button = %ShirtButton1
@onready var shirt_2: Button = %ShirtButton2
@onready var shirt_3: Button = %ShirtButton3

var _clicked_count: int = 0


func _ready() -> void:
	# Connect button clicks dynamically
	shirt_1.pressed.connect(_on_shirt_pressed.bind(shirt_1))
	shirt_2.pressed.connect(_on_shirt_pressed.bind(shirt_2))
	shirt_3.pressed.connect(_on_shirt_pressed.bind(shirt_3))


func _on_shirt_pressed(button: Button) -> void:
	button.disabled = true
	button.modulate = Color(0.5, 0.5, 0.5, 0.5) # Visually dim the clicked shirt
	_clicked_count += 1
	
	# When all 3 shirts have been clicked, conclude minigame with victory
	if _clicked_count >= 3:
		finish_minigame(true, {"shirts_clicked": 3})
