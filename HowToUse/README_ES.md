# Guía de Inicio Rápido: iOplazx Essence Framework
Bienvenido al manual de configuración profesional. Sigue estos pasos para integrar el framework en tu proyecto de Godot 4.x de forma correcta.

## Instalación y Configuración Inicial
**Importar el Addon**: Copia la carpeta addons/iOplazxEssence dentro del directorio res:// de tu proyecto.

**Activar el Plugin**: Ve a Proyecto > Configuración del Proyecto > Plugins y activa iOplazxEssence.

**Activar Autoloads (Singletons)**: Ve a Proyecto > Configuración del Proyecto > Autoload. Es fundamental añadir los siguientes sistemas. Se recomienda encarecidamente respetar este orden exacto para asegurar que las dependencias carguen correctamente:

1. `EssenceLogger`
2. `EssenceError`
3. `FileManager`
4. `Preferences`
5. `LanguageManager`
6. `SaveManager`
7. `AudioManager`
8. `DisplayManager`
9. `SceneManager`
10. `GlobalLoading`
11. `EssenceWarningUI`

**Estructura de Datos**: Crea en la raíz res:// la carpeta game_data. Dentro de ella, crea tres subcarpetas: persistent/, remote/ y global/.

**Configuración Estática**: Copia los archivos de la carpeta addons/iOplazxEssence/templates a una nueva carpeta en la raíz llamada res://_static/.

**Ajuste de Clases**: Abre el archivo res://_static/GameConstants.gd. En la línea de class_name, elimina el sufijo _IESS para que quede así: class_name GameConstants.

## Configuración de Rutas y Menús
**Configuración de Rutas (RouteConfig)**: Abre el archivo res://_static/RouteConfig.tres con doble clic. Aquí podrás definir qué escenas usará el framework para el arranque y el menú principal.

**TIP DE SEGURIDAD**: *Para personalizar tu menú, copia la escena iOplazxEssence/ui/screens/MainMenu.tscn (y su script) a una carpeta fuera de addons/ (ej: res://scenes/). Esto evita que pierdas tus cambios visuales al actualizar el addon. Luego, asigna esta nueva ruta en el inspector del RouteConfig.tres.*

**Controlador de Menú**: En tu escena de menú personalizada, selecciona el nodo raíz. En el inspector verás el EssenceMenuController. Vincula tus botones (Play, Settings, Exit, etc.) arrastrándolos a los slots del controlador.

**Música Inicial**: En tu script de arranque (Boot.gd), define la música de tu menú usando: AudioManager.cache_audio("menu_theme", "res://tu_ruta/musica.ogg").

**Configuración Maestra**: Abre res://_static/EssenceMasterConfig.tres. En la sección Save System Customization, arrastra tu script de guardado (como MyGameSave.gd) al campo Custom Save Script.

**Escena Principal y Splash**: Establece Boot.tscn como escena principal. Luego, en la configuración del proyecto, desactiva el "Splash Screen" de Godot (el addon ya gestiona su propia pantalla de carga y advertencia).

## Configuración para Exportar (¡Obligatorio!)
Para que las traducciones y las banderas funcionen en el ejecutable final:

**Filtros de Exportación**: En Exportar > Recursos, añade en "Filters to export non-resource files": game_data/*, addons/iOplazxEssence/static_loc/*

**Importación de Imágenes Crudas**: Para archivos (como banderas) .png en game_data, cámbialos en la pestaña Importar a Keep File (No Import) y dale a Reimport.