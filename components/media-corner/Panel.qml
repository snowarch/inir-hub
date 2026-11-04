pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.iris.style
import "corner"
import "pages"
import "state"

// The Media Corner, worn with iRiS: anime from AniList and films and series from Cinemeta, over the desktop or in a
// window of its own (the window key at the foot of its places). Nothing is built while it is closed.
Scope {
    id: root

    readonly property bool windowed: CornerState.options.windowed
    // Built when it opens; kept until its closing motion ends.
    property bool resident: CornerState.open
    Timer {
        id: grace
        interval: IrisStyle.settleDuration + 120
        onTriggered: root.resident = CornerState.open
    }
    Connections {
        target: CornerState
        function onOpenChanged(): void {
            if (CornerState.open) { grace.stop(); root.resident = true }
            else grace.restart()
        }
    }

    LazyLoader {
        active: root.resident && !root.windowed
        IrisCornerOverlay { namespace: "quickshell:media-corner"; open: CornerState.open; body: MediaCorner {} }
    }
    LazyLoader {
        active: CornerState.open && root.windowed
        IrisCornerWindow {
            title: "iNiR Media Corner"
            open: CornerState.open
            onCloseRequested: CornerState.open = false
            body: MediaCorner { windowed: true }
        }
    }

    /// The Media Corner: find any anime, film or series, and where it streams.
    ///
    /// ```kdl
    /// Mod+Shift+M { spawn "inir" "media-corner" "toggle"; }
    /// ```
    IpcHandler {
        target: "media-corner"
        /// Open or close it
        function toggle(): void { CornerState.open = !CornerState.open }
        /// Open it
        function open(): void { CornerState.open = true }
        /// Close it
        function close(): void { CornerState.open = false }
        /// Open it searching anime, films and series
        function search(text: string): void {
            CornerState.query = text
            CornerState.open = true
        }
        /// Open it on a place: home, anime:airing|trending|top|season|genres, movie:movies|series|top|years|genres, anime:<AniList id> or title:<movie|series>:<IMDb id>
        function go(place: string): void { CornerState.place = place; CornerState.open = true }
    }
}
