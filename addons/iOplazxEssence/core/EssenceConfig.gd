class_name EssenceConfig extends Resource

@export_category("Boot and Logos")
## 0 = Godot, 1 = Creator (iOplazx), 2 = Custom
@export_enum("Godot", "Creator (iOplazx)", "Custom") var logo_type: int = 1
@export_file("*.png", "*.jpg", "*.webp") var custom_logo_path: String = ""

@export_category("General Settings")
@export var skip_splash_screen: bool = false
