class_name EssencePaths extends RefCounted

# ==========================================
# RUTAS BASE
# ==========================================
const BASE_RUTE = "res://addons/iOplazxEssence/"
const BASE_RESOURCES = BASE_RUTE + "resources/"
const PATH_IMAGES = BASE_RESOURCES + "images/"
const PATH_AUDIO = BASE_RESOURCES + "audio/"
const PATH_CORE = BASE_RUTE + "core/"
const PATH_UI = BASE_RUTE + "ui/"
const PATH_UI_CARDS = BASE_RUTE + "ui/cards/"
const PATH_UI_OVERLAYS = BASE_RUTE + "ui/overlays/"
const PATH_UI_SCREEN = BASE_RUTE + "ui/screens/"
const PATH_UI_WIDGETS = BASE_RUTE + "ui/widgets/"

# ==========================================
# CONSTANTES DIRECTAS (Para usar con preload en Audio/Escenas)
# ==========================================
const AUDIO_UI_SPACE = PATH_AUDIO + "spaceUiSound.wav"
const AUDIO_UI_BUBBLE = PATH_AUDIO + "bubbleUiSound.wav"
# Puedes agregar aquí escenas también: const SCENE_WARNING = ...

# ==========================================
# DICCIONARIOS DE CARGA DINÁMICA (Para usar con load)
# ==========================================
enum KeyImage {
	GODOT,
	IOPLAZX,
	WARNING,
	EYE,
	PLUS18,
	ERROR_FALLBACK,
	ICON_PLAY,  
	ICON_PAUSE,
	ICON_INFO
}

const INTERNAL_IMAGES = {
	KeyImage.GODOT: PATH_IMAGES + "icon_godot.png",
	KeyImage.IOPLAZX: PATH_IMAGES + "ioplazx_logo.png",
	KeyImage.WARNING: PATH_IMAGES + "iconWarning.png",
	KeyImage.EYE: PATH_IMAGES + "iconEye.png",
	KeyImage.PLUS18: PATH_IMAGES + "iconPlus18.png",
	KeyImage.ERROR_FALLBACK: PATH_IMAGES + "iconImageNoLoad.png",
	KeyImage.ICON_PLAY: PATH_IMAGES + "icon_play.png",
	KeyImage.ICON_PAUSE: PATH_IMAGES + "icon_pause.png",
	KeyImage.ICON_INFO: PATH_IMAGES + "icon_info.png"
}
