extends EssenceLayeredLocation 

func _ready() -> void:
	super._ready()
	# Inicia apagado por defecto
	if is_instance_valid(atmosphere_fx):
		atmosphere_fx.visible = false

## Método público invocado desde el menú de interacción
func toggle_atmosphere() -> void:
	if is_instance_valid(atmosphere_fx):
		atmosphere_fx.visible = not atmosphere_fx.visible
