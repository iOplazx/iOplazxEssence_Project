class_name EssenceSettingsConfig extends Resource

@export_category("Custom Override")
## Si marcas esto, el motor ignorará todo y cargará tu propia escena de ajustes
@export var use_custom_settings_scene: bool = false
@export_file("*.tscn") var custom_settings_scene_path: String = ""

@export_category("Tabs Visibility")
@export var show_gameplay_tab: bool = true
@export var show_video_tab: bool = true
@export var show_audio_tab: bool = true

@export_category("Audio Elements")
@export var show_master_volume: bool = true
@export var show_music_volume: bool = true
@export var show_sfx_volume: bool = true
@export var show_voices_volume: bool = false # Apagado por defecto

@export_category("Video Elements")
@export var show_fullscreen_toggle: bool = true
@export var show_resolution_select: bool = true
@export var show_vsync_toggle: bool = false

@export_category("Gameplay Elements")
@export var show_text_speed: bool = true
@export var show_subtitles: bool = true
