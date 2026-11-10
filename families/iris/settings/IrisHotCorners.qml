pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// Settings › Keyboard › Hot corners, where the compositor has them: the screen drawn with its wallpaper, each corner
// a lit quarter that says what resting the pointer there does. A press opens that corner's choices under the screen;
// the pick lands at once and the corner wears it.
Column {
    id: root

    property var spec: ({})
    readonly property real d: IrisStyle.settingsDensity
    readonly property var corners: [
        { key: "top-left", name: Translation.tr("Top left"), east: false, south: false },
        { key: "top-right", name: Translation.tr("Top right"), east: true, south: false },
        { key: "bottom-left", name: Translation.tr("Bottom left"), east: false, south: true },
        { key: "bottom-right", name: Translation.tr("Bottom right"), east: true, south: true }
    ]
    // The corner whose choices are open; "" is none.
    property string open: ""
    readonly property var openCorner: root.corners.find(corner => corner.key === root.open) ?? null
    // The choices open under the screen; on a short window that is under the fold, so the page follows them down.
    onOpenChanged: if (root.open.length > 0) followSoon.restart()
    Timer {
        id: followSoon
        interval: 60
        onTriggered: {
            let view = root.parent
            while (view && !(view instanceof Flickable)) view = view.parent
            if (!view) return
            const foot = root.mapToItem(view.contentItem, 0, root.height).y + Math.round(24 * root.d)
            const to = Math.min(foot - view.height, Math.max(0, view.contentHeight - view.height))
            if (to <= view.contentY) return
            follow.target = view
            follow.to = to
            follow.restart()
        }
    }
    NumberAnimation { id: follow; property: "contentY"; duration: 260; easing.type: Easing.OutCubic }
    readonly property var known: CompositorConfig.cornerActions
    function actionOf(key: string): string { return String(CompositorConfig.value({ comp: "corners", key: key, fallback: "" })) }
    // An action written by hand in the compositor's file keeps its place in the list as the person's own.
    function choicesOf(key: string): var {
        const now = root.actionOf(key)
        return root.known.some(action => action.value === now) ? root.known
            : root.known.concat([{ label: "Your own", value: now, glyph: "terminal" }])
    }
    function entryOf(key: string): var {
        const now = root.actionOf(key)
        return root.choicesOf(key).find(action => action.value === now) ?? root.known[0]
    }
    readonly property real aspect: {
        const rect = CompositorConfig.output ? CompositorConfig.logicalRect(CompositorConfig.output) : null
        return rect && rect.width > 0 && rect.height > 0 ? Math.max(1.2, Math.min(2.4, rect.width / rect.height)) : 16 / 9
    }

    spacing: Math.round(10 * root.d)

    Rectangle {
        id: desk
        width: root.width
        height: Math.round(Math.max(176, Math.min(236, root.width * 0.36)) * root.d)
        radius: IrisStyle.radiusTile
        color: IrisStyle.fill

        Rectangle {
            id: bezel
            anchors.centerIn: parent
            height: desk.height - Math.round(36 * root.d)
            width: Math.min(desk.width - Math.round(36 * root.d), Math.round(bezel.height * root.aspect))
            radius: Math.round(7 * root.d) // iris-literal: a drawn monitor's bezel, not a shell surface
            color: "#0b0b0c" // iris-literal: the bezel is the hardware's black, whatever the theme

            Item {
                id: glass
                anchors.fill: parent
                anchors.margins: Math.max(2, Math.round(3 * root.d))
                clip: true

                Image {
                    anchors.fill: parent
                    source: Wallpapers.effectiveWallpaperUrl
                    sourceSize.width: Math.round(480 * root.d)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                }
                // The wallpaper steps back so the four corners are what is read.
                Rectangle {
                    anchors.fill: parent
                    color: "#0b0b0c" // iris-literal: a screen turned down, the bezel's own black
                    opacity: 0.46
                }

                Repeater {
                    model: root.corners.length
                    Item {
                        id: spot
                        required property int index
                        readonly property var corner: root.corners[spot.index]
                        readonly property var entry: root.entryOf(spot.corner.key)
                        readonly property bool used: String(spot.entry.value).length > 0
                        readonly property bool opened: root.open === spot.corner.key
                        readonly property bool lit: spot.opened || press.containsMouse || spot.activeFocus
                        // The quarter's reach from the corner: it grows to meet the pointer and stays grown while open.
                        property real reach: Math.round((spot.opened ? 50 : spot.lit ? 44 : spot.used ? 38 : 30) * root.d)
                        Behavior on reach { NumberAnimation { duration: IrisStyle.duration(180); easing.type: IrisStyle.feedbackEasing } }

                        x: spot.corner.east ? glass.width - spot.width : 0
                        y: spot.corner.south ? glass.height - spot.height : 0
                        width: Math.round(glass.width * 0.46)
                        height: Math.round(glass.height * 0.46)

                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: spot.corner.name + ", " + Translation.tr(String(spot.entry.label))
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                root.open = spot.opened ? "" : spot.corner.key
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape && spot.opened) {
                                root.open = ""
                                event.accepted = true
                            }
                        }

                        // A disc centred on the screen's corner; the screen's edge cuts it to a quarter.
                        Rectangle {
                            id: quarter
                            x: (spot.corner.east ? spot.width : 0) - quarter.width / 2
                            y: (spot.corner.south ? spot.height : 0) - quarter.height / 2
                            width: spot.reach * 2
                            height: spot.reach * 2
                            radius: spot.reach
                            color: spot.used ? IrisStyle.accent : "#ffffff" // iris-literal: an idle corner is plain light over any wallpaper
                            opacity: spot.used ? 1 : spot.lit ? 0.3 : 0.16
                            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                            Behavior on color { ColorAnimation { duration: IrisStyle.duration(160) } }
                        }
                        MaterialSymbol {
                            id: glyph
                            readonly property real inset: Math.round(spot.reach * 0.2)
                            x: spot.corner.east ? spot.width - glyph.width - glyph.inset : glyph.inset
                            y: spot.corner.south ? spot.height - glyph.height - glyph.inset : glyph.inset
                            text: spot.used ? String(spot.entry.glyph ?? "bolt") : "add"
                            iconSize: Math.round(spot.reach * 0.42)
                            color: spot.used ? IrisStyle.inkOnAccent : "#ffffff" // iris-literal: an idle corner's mark, plain light
                            opacity: spot.used || spot.lit ? 1 : 0.7
                        }
                        IrisText {
                            id: said
                            readonly property real lead: spot.reach + Math.round(8 * root.d)
                            x: spot.corner.east ? spot.width - said.lead - said.width : said.lead
                            y: spot.corner.south ? spot.height - said.height - Math.round(7 * root.d) : Math.round(7 * root.d)
                            width: Math.min(said.implicitWidth, spot.width - said.lead)
                            horizontalAlignment: spot.corner.east ? Text.AlignRight : Text.AlignLeft
                            text: spot.used ? Translation.tr(String(spot.entry.label)) : spot.corner.name
                            color: "#ffffff" // iris-literal: a name over a wallpaper turned down, never the theme's text
                            opacity: spot.used ? 1 : spot.lit ? 0.8 : 0
                            font.pixelSize: IrisStyle.typeMeta
                            font.weight: IrisStyle.weight(spot.used ? Font.DemiBold : Font.Medium)
                            style: Text.Raised
                            styleColor: "#99000000" // iris-literal: the name's own shade over any wallpaper
                            elide: Text.ElideRight
                            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                        }

                        MouseArea {
                            id: press
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                spot.forceActiveFocus()
                                root.open = spot.opened ? "" : spot.corner.key
                            }
                        }
                    }
                }
            }
        }
    }

    IrisText {
        width: root.width
        visible: root.openCorner === null
        text: Translation.tr("Press a corner to choose what happens when the pointer rests there.")
        color: IrisStyle.muted
        font.pixelSize: IrisStyle.typeFootnote
        wrapMode: Text.WordWrap
    }

    Column {
        width: root.width
        visible: root.openCorner !== null
        spacing: Math.round(6 * root.d)
        IrisText {
            width: parent.width
            text: root.openCorner?.name ?? ""
            font.pixelSize: IrisStyle.typeBody
            font.weight: IrisStyle.weight(Font.DemiBold)
            elide: Text.ElideRight
        }
        Loader {
            width: parent.width
            active: root.openCorner !== null
            sourceComponent: IrisChoiceGrid {
                options: root.choicesOf(root.open)
                current: root.actionOf(root.open)
                accessibleName: root.openCorner?.name ?? ""
                onPicked: value => CompositorConfig.set({ comp: "corners", key: root.open }, value)
                onDismissed: root.open = ""
            }
        }
    }
}
