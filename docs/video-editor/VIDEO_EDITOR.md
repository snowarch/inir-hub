# Video Editor

Open **Video Editor** from the app launcher in Material, iRiS or Waffle, on Niri or Umbriel.
Drop a local video into the editor, or click **Browse Files**. This edits one clip at a time.
Use the header controls to switch between **Classic**, **Folio** and **Prism** styles, or to toggle
between a floating **Window** and a desktop **Overlay** without losing the active clip or edits.

Drag the timeline handles to trim, choose a crop preset and move/resize the outline, rotate or flip,
and adjust speed or mute. **Compress** shows MP4 quality/resolution, an approximate size estimate,
and GIF settings. The camera button saves an original frame in your Pictures folder.

**Save Copy** makes a numbered MP4 beside the input. **Save and Replace** replaces an MP4 only after
successful encoding; other inputs get an adjacent `*_edited.mp4`. GIF and MP3 exports create numbered
files. Cancellation or failure preserves the input, and existing copies are never overwritten.

Python 3, FFmpeg/ffprobe and Qt Multimedia are required. Optional programs are wl-clipboard (Copy Path),
xdg-utils (Open Video/Audio/GIF and Open Folder), libnotify (notifications) and LosslessCut (external editing).
Missing dependencies and processing failures are shown in the window.

Space plays or pauses. Left/Right steps a frame, Home/End seeks to trim boundaries, I/O sets in/out,
S cycles speed, and P saves a frame. Escape returns from export or closes the editor.

All 18 Hub languages are supported.

The editor works on Niri and Umbriel. It has been tested on Niri only so far; on Umbriel the
launcher entry and editing work the same way, but live verification there is still pending.

## Recording prompt

When iNiR's recorder finishes, its “Recording saved” notification supplies the exact path and the
prompt appears automatically on the screen focused at completion. With recorder notifications
disabled, the plugin captures wf-recorder's output argument once while recording and probes it after
the recording stops. Duplicate events show one prompt; completion while locked waits until unlock.
The prompt expires after eight seconds while not hovered or busy, and **Edit Video** opens the clip.

Other recorders can call `inir video-editor prompt /absolute/path/recording.mp4` directly.
Very short recordings may finish before their PID is exposed; keep recorder notifications enabled
for those clips.

Options are in `~/.config/inir/plugins/video-editor.json`. `showEditPrompt` defaults to `true`
(`false` disables automatic capture and the prompt); `openInLosslessCut` defaults to `false` and
sends the prompt's Edit button to LosslessCut when enabled; `windowed` toggles between a floating
window and a desktop overlay; `style` (`""`, `"classic"`, `"folio"`, `"prism"`) stores the chosen
skin (empty wears Folio).

## Permissions and saved state

This local component declares `process` and `files` and contacts no network hosts. Its explicitly
authorized filesystem scope includes selected input videos, adjacent exports/replacement, Pictures
snapshots, its own options and `$XDG_CACHE_HOME/inir/video-editor/` cache. This scope exceeds the Hub
helper guide's usual state/cache-only rule and requires acceptance of that exception for publication.

Edits are held in memory until the editor closes. Only the plugin options and cached thumbnails persist.
