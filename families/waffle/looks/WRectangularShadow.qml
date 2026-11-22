import QtQuick
import QtQuick.Effects
import qs.modules.common
import qs.modules.common.widgets

// Waffle Next: a deep, soft shadow that lifts a floating plate off any wallpaper
StyledRectangularShadow {
    blur: 24
    spread: 0
    offset: Qt.vector2d(0.0, 8)
    color: Looks.colors.shadow
}
