import QtQuick
import Quickshell

// One sheet of glass on every screen.
Variants {
    model: Quickshell.screens
    StageScreen {}
}
