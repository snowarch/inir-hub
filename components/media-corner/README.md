# Media Corner

Find any anime, film or series and see where it streams officially, in a Place worn with iRiS. Anime comes from
AniList, films and series from Cinemeta (Stremio's open catalogue); it plays nothing itself.

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

The key at the foot of the places opens it over the desktop or in a window of its own.

## Keys

Tab walks the places, the posters and the buttons; Return or Space opens what is focused. Ctrl+F goes to the search.
Escape clears the search, steps back (a title, a search, a genre) and then closes it. It opens where you left it.

## Estilo, fuentes y subtítulos

En Community Hub, abre los ajustes de Media Corner y elige **Normal** o **Prism**. Si todavía no hay una elección guardada, al abrir el componente aparecen ambas opciones. El estilo se guarda en la configuración propia del componente.

En **Sources**, añade la dirección HTTPS del manifiesto de un addon Stremio que administres, o una dirección de búsqueda web con `%s` donde se insertará el título. Las búsquedas web se abren en el navegador. Media Corner no incluye addons: revisa las condiciones y derechos de las fuentes que añadas. Una copia privada de la configuración anterior se guarda antes de migrar la lista de fuentes.

Para subtítulos, escribe en Sources el idioma como código ISO (por ejemplo `eng` o `spa`) y añade un addon que ofrezca el recurso `subtitles`. Al pulsar Watch aparecen los subtítulos disponibles; se preselecciona el idioma configurado cuando hay coincidencia. También puedes elegir «sin subtítulos». La selección se entrega a mpv antes de iniciar la reproducción; para cambiarla hay que volver a elegir el vídeo.

Como alternativa opcional, registra una aplicación y solicita una clave de API en [OpenSubtitles](https://www.opensubtitles.com/); consulta sus [instrucciones para desarrolladores](https://opensubtitles.stoplight.io/docs/opensubtitles-api/e3750fd63a100-getting-started) y sus condiciones vigentes. Introduce la clave en Sources; se guarda en la configuración local privada, no en el repositorio. Para descargar directamente, inicia sesión allí con tu usuario y contraseña: la contraseña no se guarda y el token se descarta al cerrar Media Corner. Primero se muestran los resultados de los addons configurados y luego los de OpenSubtitles si hay clave. La disponibilidad, los idiomas y las cuotas dependen de cada proveedor; si un proveedor falla puedes seleccionar otro o reproducir sin subtítulos.

La lógica de respuestas y errores se ha probado con fixtures, sin una clave real. Para una prueba real, añade una fuente autorizada, configura el idioma y, si corresponde, la clave; abre un título con identificador IMDb, pulsa Watch, elige un subtítulo y un vídeo, y comprueba en mpv que se muestra. Repite con un idioma distinto y sin conexión; revisa los límites y la respuesta de tu cuenta antes de sacar conclusiones.
