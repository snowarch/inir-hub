import QtQuick
import qs.modules.iris.style

// The mask of the Island's wallpaper header (IrisHeaderScrim holds the geometry). Solid bodies keep the image
// under the scrim; glass fades it out at the join and at the bottom so the body's glass shows there.
Item {
    id: root
    required property IrisHeaderScrim scrim
    visible: false
    layer.enabled: true
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: IrisStyle.glassy ? "transparent" : "white" }
            GradientStop { position: root.scrim.maskSolidEnd; color: IrisStyle.glassy ? "transparent" : "white" }
            GradientStop { position: Math.min(0.99, root.scrim.maskRampEnd + 0.08 * root.scrim.meltTop); color: "white" }
            GradientStop { position: Math.max(0.6, root.scrim.midAt); color: "white" }
            GradientStop { position: 1; color: IrisStyle.glassy ? "transparent" : "white" }
        }
    }
}
