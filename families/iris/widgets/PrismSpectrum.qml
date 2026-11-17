import QtQuick

// Once Prism's spectrum painted the mark a face lit (a bar, a tick, a trace, the window in focus). His 11-16: the
// rainbow on bars and marks reads cheap; the refs (`.claude/ref/prism-widgets`) light a mark white inside the glass
// (today a white pill, a lit key holding its own colour). The type stays so an item that still names it loads: it
// draws its source as it is, the mark in its own ink. New faces never wear it.
ShaderEffect {
    property variant source
    property real angle: 0
    property real from: 0
    property real to: 1
    property real white: 0
    property bool mono: false
    property real bright: 1
}
