class_name EssenceConfig extends Resource

@export_category("Boot and Logos")
## 0 = Godot, 1 = Creator (iOplazx), 2 = Custom
@export_enum("Godot", "Creator (iOplazx)", "Custom") var logo_type: int = 1
@export_file("*.png", "*.jpg", "*.webp") var custom_logo_path: String = ""
@export var custom_logo_text: String = "My Custom Engine"

@export_category("General Settings")
@export var skip_splash_screen: bool = false

@export_category("Warning Screen")
@export var show_warning_screen: bool = true

@export_group("Warning Text")
@export var use_custom_text: bool = false
## Si use_custom_text es true, el motor leerá este cuadro de texto. Si es false, usará uno predefinido.
@export_multiline var custom_warning_text: String = "WARNING: This game contains flashing lights and mature themes.\nPlayer discretion is advised."

@export_group("Warning Icon")
@export var show_warning_icon: bool = false
@export_enum("Warning Triangle", "Eye (Epilepsy)", "+18 (Mature)", "Custom") var warning_icon_type: int = 0
@export_file("*.png", "*.jpg", "*.webp") var custom_warning_icon_path: String = ""

@export_group("Warning Buttons")
## 0 = Sin botones (desaparece solo por tiempo), 1 = OK, 2 = Yes/No, 3 = Confirm/Reject(Exit)
@export_enum("None (Auto-fade)", "OK", "Yes / No", "Confirm / Reject (Exit)") var button_type: int = 0

@export_category("Loading Screen")
@export var show_loading_screen: bool = true

@export_group("Loading Visuals")
@export_enum("Godot", "Creator (iOplazx)", "Custom", "None") var loading_logo_type: int = 1
@export_file("*.png", "*.jpg", "*.webp") var custom_loading_logo_path: String = ""
@export var show_progress_bar: bool = true
@export var show_progress_text: bool = true # Para mostrar "Cargando... 45%"
