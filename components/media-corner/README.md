# Media Corner

Find any anime, film or series and see where it streams officially, in a Place worn with iRiS. Anime comes from
AniList, films and series from Cinemeta (Stremio's open catalogue); user-added sources can be played with mpv.

- Open it: `inir media-corner toggle`, `open` or `close`, or bind it in niri:
  `Mod+Shift+M { spawn "inir" "media-corner" "toggle"; }`.
- Search: `inir media-corner search "<text>"` (anime, films and series at once).
- Go to a place: `inir media-corner go <place>`: `home`, `anime:popular|airing|trending|top|season|genres`,
  `movie:movies|series|top|years|genres`, `anime:<AniList id>` or `title:<movie|series>:<IMDb id>`.
- Worn with: iRiS.
- Its one option (over the desktop or in a window) lives in `~/.config/inir/plugins/media-corner.json`.

## Pages

- **Home**: what is trending, then shelves of anime airing now, trending and in season, and popular films and series.
- **Anime**: popular, airing now, trending, top rated, this season (‹ › walk the seasons), genres.
- **Films and series**: films, series, top rated, by year, genres.
- **A title**: synopsis, facts, genres, the official streaming services AniList lists, AniList or IMDb, the trailer,
  and related or similar titles.

## Options

The window button switches between the desktop overlay and a window. In Prism it is at the top of the sidebar.

## Keys

Tab walks the places, the posters and the buttons; Return or Space opens what is focused. Ctrl+F goes to the search.
Escape clears the search, steps back (a title, a search, a genre) and then closes it. It opens where you left it.

## Estilo, fuentes y subtítulos

En Community Hub, abre los ajustes de Media Corner y elige **Normal** o **Prism**. Si todavía no hay una elección guardada, al abrir el componente aparecen ambas opciones. El estilo se guarda en la configuración propia del componente.

En Prism, las secciones de anime y películas despliegan su navegación al abrirse. El filtro de guardados busca localmente por título o tipo en **Want to watch** y **Watching**, sin consultar la red. El botón de orden alterna entre título, fecha de añadido y actividad reciente; las entradas guardadas antes de esta opción no tienen fecha de añadido y quedan al final de ese orden. **Watching** muestra hasta cinco entradas recientes cuando el filtro está vacío; al buscar puede mostrar más. La página **Watch history** muestra todas las entradas agrupadas por título. Abrir una entrada lleva al selector de fuentes para el título y episodio correspondientes. La X pide confirmación antes de quitar esa entrada y su progreso; esto no elimina el título de **Want to watch** ni sus marcas de visto. La entrada que se está reproduciendo no se puede quitar hasta detenerla.

En la ficha puedes añadir o quitar un título de **Want to watch** y marcarlo como visto o no visto. Para los episodios, activa **Mark episodes watched or unwatched**, pulsa los episodios que quieras cambiar y termina el modo de marcado. Las marcas manuales se guardan por separado de la posición del reproductor: desmarcar no borra el progreso. Si no se pueden leer las marcas, la ficha muestra un error y permite reintentar sin reemplazar el archivo.

**Upcoming episodes** consulta AniList al abrir la página o al pulsar **Refresh schedule**. Muestra por fecha y hora local las próximas emisiones conocidas de anime guardado en **Want to watch**; excluye películas y fechas ya pasadas. La fecha de consulta indica cuándo se obtuvo la agenda. No se hacen sondeos ni avisos en segundo plano; al salir de la página se cancela la consulta en curso.

Las carátulas usan una memoria de hasta 24 imágenes decodificadas mientras Media Corner está abierto. Se reutilizan por dirección y tamaño, el componente deja de retenerlas al cerrar y no las guarda en una caché propia en disco (Qt puede mantener su propia caché); los fondos no forman parte de esa memoria.

En **Sources**, añade la dirección HTTPS del manifiesto de un addon Stremio que administres, o una dirección de búsqueda web con `%s` donde se insertará el título. Las búsquedas web se abren en el navegador. Media Corner no incluye addons: revisa las condiciones y derechos de las fuentes que añadas. Una copia privada de la configuración anterior se guarda antes de migrar la lista de fuentes.

Antes de guardar un addon, la vista previa muestra su nombre declarado, capacidades y tipos y prefijos de identificador admitidos; debes confirmarla. Al actualizar un manifiesto se muestran los valores anteriores y nuevos antes de aplicarlos. Consultar un manifiesto no verifica que la fuente sea segura o legítima. Las capacidades que aparecen por primera vez al actualizar permanecen desactivadas hasta que las habilites. La fecha mostrada corresponde a la lectura del manifiesto confirmada, no a una búsqueda de un título.

Puedes cambiar el orden de las fuentes, asignarles un alias local y activar o desactivar por separado streams y subtítulos cuando el addon los anuncia. El alias no cambia el nombre declarado ni la dirección. Los resultados de streams siguen la prioridad elegida, salvo que selecciones el orden alfabético en Watch.

Para subtítulos, elige en Sources un idioma o introduce un código ISO personalizado y añade un addon que ofrezca el recurso `subtitles`. Puedes configurar un segundo idioma y elegir entre selección automática o preguntar cada vez. Al pulsar Watch aparecen los subtítulos disponibles y siempre puedes elegir «sin subtítulos». La selección se entrega a mpv antes de iniciar la reproducción; para cambiar el archivo hay que volver a elegir el vídeo. Durante la reproducción puedes ajustar la sincronía y alternar pantalla completa desde los controles de Media Corner.

Antes de abrir un stream, Media Corner muestra su fuente y host y pide confirmación. Si hay progreso guardado, puedes continuar o empezar desde el principio. Un error al descargar subtítulos permite reintentar o elegir otro archivo antes de reproducir.

Como alternativa opcional, registra una aplicación y solicita una clave de API en [OpenSubtitles](https://www.opensubtitles.com/); consulta sus [instrucciones para desarrolladores](https://opensubtitles.stoplight.io/docs/opensubtitles-api/e3750fd63a100-getting-started) y sus condiciones vigentes. Introduce la clave en Sources; se guarda en la configuración local privada, no en el repositorio. Para descargar directamente, inicia sesión allí con tu usuario y contraseña: la contraseña no se guarda y puedes cerrar sesión en Sources; el token también se descarta al cerrar Media Corner. Primero se muestran los resultados de los addons configurados y luego los de OpenSubtitles si hay clave. La disponibilidad, los idiomas y las cuotas dependen de cada proveedor; si un proveedor falla puedes seleccionar otro o reproducir sin subtítulos.

La lógica de respuestas y errores se ha probado con fixtures, sin una clave real. Para una prueba real, añade una fuente autorizada, configura el idioma y, si corresponde, la clave; abre un título con identificador IMDb, pulsa Watch, elige un subtítulo y un vídeo, y comprueba en mpv que se muestra. Repite con un idioma distinto y sin conexión; revisa los límites y la respuesta de tu cuenta antes de sacar conclusiones.
