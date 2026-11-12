import QtQuick

// Loaded by the shell while the radio is installed (widget.json "service"), so the radio's IPC answers a keybind or a
// media key with no face on screen. Nothing plays until asked.
QtObject {
    readonly property var radio: Radio
}
