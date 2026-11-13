pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// Settings › Displays › Workspaces: the chosen screen's workspaces drawn as the screens they are, laid the way they
// run (stacked or side by side). A person presses the last one they want: with "As needed" that is how many always
// wait there, with "Fixed" how many there are. The loop mark joins the last to the first.
Column {
    id: root

    property var spec: ({})
    readonly property real d: IrisStyle.settingsDensity
    readonly property var out: CompositorConfig.output
    readonly property var kept: { CompositorConfig.revision; return CompositorConfig.displayValue("workspaces") }
    readonly property bool fixed: root.kept !== "dynamic"
    readonly property int floor_: { CompositorConfig.revision; return Number(CompositorConfig.displayValue("min-workspaces")) || 1 }
    // How many are surely there: every one of a fixed set, the floor of a set that grows.
    readonly property int sure: root.fixed ? Number(root.kept) : root.floor_
    readonly property bool loops: { CompositorConfig.revision; return CompositorConfig.displayValue("cyclic") === true }
    readonly property bool sideways: { CompositorConfig.revision; return String(CompositorConfig.displayValue("workspace-axis")) === "horizontal" }
    readonly property int shown: Math.max(6, Math.min(8, root.sure + 1))
    readonly property real aspect: {
        const rect = root.out ? CompositorConfig.logicalRect(root.out) : null
        return rect && rect.height > 0 ? Math.max(1.2, Math.min(2.4, rect.width / rect.height)) : 16 / 9
    }
    readonly property real gap: Math.round(7 * root.d)
    readonly property real pad: Math.round(18 * root.d)
    readonly property real miniHeight: root.sideways
        ? Math.round(Math.min(92 * root.d, (root.width - 2 * root.pad - root.gap * (root.shown - 1)) / root.shown / root.aspect))
        : Math.round(132 * root.d / root.aspect)
    // Stacked, each one shows a band under the one before it, a deck seen from the front.
    readonly property real band: Math.round(22 * root.d)
    readonly property real miniWidth: Math.round(root.miniHeight * root.aspect)
    readonly property url picture: {
        const own = WallpaperListener.multiMonitorEnabled ? WallpaperListener.effectivePerMonitor?.[root.out?.name ?? ""]?.path : ""
        return own ? Wallpapers.stillUrlFor(own) : Wallpapers.effectiveWallpaperUrl
    }
    function pick(count: int): void {
        CompositorConfig.applyDisplay(root.fixed ? "workspaces" : "min-workspaces", count)
    }

    spacing: Math.round(10 * root.d)

    Rectangle {
        id: desk
        width: root.width
        height: (root.sideways ? Math.max(Math.round(150 * root.d), root.miniHeight + Math.round(84 * root.d))
            : root.miniHeight + (root.shown - 1) * root.band + 2 * root.pad)
        radius: IrisStyle.radiusTile
        color: IrisStyle.fill
        clip: true
        Behavior on height { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }

        Item {
            id: strip
            anchors.centerIn: parent
            width: root.sideways ? root.shown * root.miniWidth + (root.shown - 1) * root.gap : root.miniWidth
            height: root.sideways ? root.miniHeight : root.miniHeight + (root.shown - 1) * root.band
            Repeater {
                model: root.shown
                Rectangle {
                    id: mini
                    required property int index
                    readonly property int number: mini.index + 1
                    readonly property bool there: mini.number <= root.sure
                    // The one a growing set opens next: it is what "as needed" means.
                    readonly property bool next: !root.fixed && mini.number === root.sure + 1
                    readonly property bool lit: press.containsMouse || mini.activeFocus
                    // A deck recedes: each card under the first stands a little narrower.
                    readonly property real tuck: root.sideways ? 0 : Math.round(mini.index * 4 * root.d)
                    x: root.sideways ? mini.index * (root.miniWidth + root.gap) : mini.tuck
                    y: root.sideways ? 0 : mini.index * root.band
                    z: root.shown - mini.index
                    Behavior on x { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }
                    width: root.miniWidth - 2 * mini.tuck
                    height: root.miniHeight
                    radius: Math.round(4 * root.d) // iris-literal: a drawn monitor's bezel, not a shell surface
                    // A place not there yet is the desk a step lighter, opaque so a deck never shows through itself.
                    color: mini.there ? "#0b0b0c" // iris-literal: the bezel's hardware black
                        : Qt.tint(IrisStyle.surfaceHighOpaque, Qt.rgba(IrisStyle.text.r, IrisStyle.text.g, IrisStyle.text.b, mini.lit ? 0.3 : mini.next ? 0.2 : 0.07 + 0.02 * (root.shown - mini.index)))
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }

                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: Translation.tr("Workspace %1").arg(mini.number)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                            root.pick(mini.number)
                            event.accepted = true
                        }
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: Math.max(1, Math.round(2 * root.d))
                        visible: mini.there
                        source: root.picture
                        sourceSize.width: Math.round(200 * root.d)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        opacity: mini.lit ? 1 : 0.78
                    }
                    MaterialSymbol {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.sideways ? Math.round((parent.height - height) / 2) : parent.height - root.band + Math.round((root.band - height) / 2)
                        visible: mini.next
                        text: "add"
                        iconSize: Math.round(15 * root.d)
                        color: IrisStyle.text
                    }
                    MouseArea {
                        id: press
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            mini.forceActiveFocus()
                            root.pick(mini.number)
                        }
                    }
                }
            }
        }

        // The loop: a tag in the screen's own dark, the accent while the last workspace leads back to the first.
        Rectangle {
            id: loopTag
            readonly property bool lit: loopPress.containsMouse || loopTag.activeFocus
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Math.round(10 * root.d)
            height: Math.round(24 * root.d)
            width: loopRow.implicitWidth + Math.round(18 * root.d)
            radius: height / 2
            color: root.loops ? IrisStyle.accent : "#0b0b0c" // iris-literal: an idle tag is the screen's own dark
            opacity: root.loops || loopTag.lit ? 1 : 0.72
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
            activeFocusOnTab: true
            Accessible.role: Accessible.CheckBox
            Accessible.name: Translation.tr("Loops around")
            Accessible.checkable: true
            Accessible.checked: root.loops
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    CompositorConfig.applyDisplay("cyclic", !root.loops)
                    event.accepted = true
                }
            }
            Row {
                id: loopRow
                anchors.centerIn: parent
                spacing: Math.round(6 * root.d)
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "laps"
                    iconSize: Math.round(14 * root.d)
                    color: root.loops ? IrisStyle.inkOnAccent : "#ffffff" // iris-literal: a mark on the screen's dark
                }
                IrisText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Loops around")
                    color: root.loops ? IrisStyle.inkOnAccent : "#ffffff" // iris-literal: a name on the screen's dark
                    font.pixelSize: IrisStyle.typeMeta
                    font.weight: IrisStyle.weight(root.loops ? Font.DemiBold : Font.Medium)
                }
            }
            MouseArea {
                id: loopPress
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: CompositorConfig.applyDisplay("cyclic", !root.loops)
            }
        }
    }

    Item {
        width: root.width
        height: Math.max(mode.height, axis.height)
        IrisSegmented {
            id: mode
            width: Math.round(Math.min(root.width * 0.46, 250 * root.d))
            height: implicitHeight
            accessibleName: Translation.tr("Workspaces")
            options: [{ label: Translation.tr("As needed"), value: "dynamic" }, { label: Translation.tr("Fixed"), value: "fixed" }]
            current: root.fixed ? "fixed" : "dynamic"
            onPicked: value => {
                if ((value === "fixed") === root.fixed) return
                CompositorConfig.applyDisplay("workspaces", value === "fixed" ? Math.max(root.sure, 4) : "dynamic")
            }
        }
        IrisSegmented {
            id: axis
            anchors.right: parent.right
            width: Math.round(Math.min(root.width * 0.46, 250 * root.d))
            height: implicitHeight
            accessibleName: Translation.tr("Workspaces run")
            options: [{ label: Translation.tr("Stacked"), value: "vertical" }, { label: Translation.tr("Side by side"), value: "horizontal" }]
            current: root.sideways ? "horizontal" : "vertical"
            onPicked: value => CompositorConfig.applyDisplay("workspace-axis", value)
        }
    }

    IrisText {
        width: root.width
        text: (root.fixed ? Translation.tr("This screen always has %1.").arg(root.sure)
                : root.sure > 1 ? Translation.tr("A new one opens when the last fills; %1 always wait here.").arg(root.sure)
                : Translation.tr("A new one opens when the last fills."))
            + (root.loops ? " " + Translation.tr("Past the last comes the first.") : "")
        color: IrisStyle.muted
        font.pixelSize: IrisStyle.typeFootnote
        wrapMode: Text.WordWrap
    }
}
