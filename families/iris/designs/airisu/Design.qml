import QtQuick

// AIRISU (designs/airisu/DESIGN.md): the shell's own components in another colour, type and motion. Its values are the
// curated Theme `airisu` and the solver's `airisu` palette; its one part of its own is the blade that parts the Island.
QtObject {
    readonly property string id: "airisu"
    readonly property string name: "AIRISU"
    readonly property string theme: "airisu"
    // The solver's language for this Design (inir-accel's washi, language airisu): urushi, its pigments, the vermilion seal.
    readonly property string palette: "airisu"
    readonly property var parts: ({
        insignia: "parts/Insignia.qml",
        islandFace: "island/Face.qml"
    })
    readonly property string preset: "night"
    // Titles and figures in the wide voice.
    readonly property var fonts: ({ numbers: "Archivo SemiExpanded", title: "Archivo SemiExpanded" })
    // Its figures lean forward, the way a number is painted on a livery.
    readonly property real figureLean: 0.2
    readonly property var motion: ({ morph: "tuned", duration: 220 })
}
