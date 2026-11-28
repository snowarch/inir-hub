pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Saved desktops in the edit panel: each one a picture of the desktop it brings back (this wallpaper, its widgets where
// they stood, each as it looks), worn with a click, Undo takes it back. The person's own are renamed and removed in place.
Flickable {
    id: root

    property string outputName: ""
    property real screenWidth: 1920
    property real screenHeight: 1080
    // url(key): a widget's picture (WidgetPortraits).
    property var pictureOf: null
    readonly property real d: IrisStyle.density
    readonly property real gap: Math.round(10 * root.d)
    readonly property real cellWidth: Math.floor((root.width - root.gap) / 2)
    readonly property real pictureHeight: Math.round(root.cellWidth * Math.max(0.4, Math.min(1, root.screenHeight / Math.max(1, root.screenWidth))))
    readonly property string worn: { Config.revision; return DesktopPresets.wornId() }
    property string naming: ""

    clip: true
    contentWidth: width
    contentHeight: column.implicitHeight + Math.round(12 * root.d)
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column
        width: root.width
        spacing: Math.round(14 * root.d)

        Grid {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: root.gap
            rowSpacing: Math.round(12 * root.d)

            // Save this desktop: an empty frame to fill.
            Item {
                width: root.cellWidth
                height: root.pictureHeight + nameRow.height
                Rectangle {
                    width: parent.width
                    height: root.pictureHeight
                    radius: IrisStyle.radiusTile
                    color: saveArea.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet
                    border.width: 1
                    border.color: saveArea.containsMouse ? IrisStyle.accent : IrisStyle.hairlineStrong
                    scale: saveArea.pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: IrisStyle.duration(saveArea.pressed ? 80 : 200); easing.type: IrisStyle.feedbackEasing } }
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(120); easing.type: IrisStyle.feedbackEasing } }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "add"
                        iconSize: Math.round(26 * root.d)
                        color: IrisStyle.accent
                    }
                    MouseArea {
                        id: saveArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.Button
                        Accessible.name: Translation.tr("Save this desktop")
                        onClicked: root.naming = DesktopPresets.save("")
                    }
                }
                Item {
                    id: nameRow
                    y: root.pictureHeight
                    width: parent.width
                    height: Math.round(26 * root.d)
                    IrisText {
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(2 * root.d)
                        anchors.bottom: parent.bottom
                        width: Math.min(implicitWidth, parent.width)
                        text: Translation.tr("Save this desktop")
                        color: IrisStyle.accent
                        font.pixelSize: IrisStyle.typeMeta
                        font.weight: IrisStyle.weight(Font.DemiBold)
                        elide: Text.ElideRight
                    }
                }
            }

            Repeater {
                // Factory desktops first (never renamed or removed), then the person's own.
                model: ScriptModel { values: DesktopPresets.factory.concat(DesktopPresets.presets); objectProp: "id" }
                delegate: Item {
                    id: preset
                    required property var modelData
                    readonly property bool worn: root.worn === preset.modelData.id
                    readonly property bool own: !DesktopPresets.isFactory(preset.modelData.id)
                    readonly property bool hovered: wearArea.containsMouse || renameKey.hovered || removeKey.hovered
                    width: root.cellWidth
                    height: root.pictureHeight + Math.round(26 * root.d)

                    ClippingRectangle {
                        id: picture
                        width: parent.width
                        height: root.pictureHeight
                        radius: IrisStyle.radiusTile
                        color: IrisStyle.fillQuiet
                        scale: wearArea.pressed ? 0.97 : 1
                        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(wearArea.pressed ? 80 : 200); easing.type: IrisStyle.feedbackEasing } }

                        // The desktop it brings back: this wallpaper under its widgets, where they stood.
                        IrisImage {
                            anchors.fill: parent
                            source: Wallpapers.effectiveWallpaperUrl
                            opacity: preset.hovered || preset.worn ? 1 : 0.78
                            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
                        }
                        Repeater {
                            model: DesktopPresets.placesOn(preset.modelData.id, root.outputName)
                            delegate: Item {
                                id: place
                                required property var modelData
                                readonly property string url: root.pictureOf ? root.pictureOf(place.modelData.key) : ""
                                readonly property real k: picture.width / Math.max(1, root.screenWidth)
                                readonly property real share: place.modelData.size === "small" ? 0.75 : place.modelData.size === "large" ? 1.4 : 1
                                x: Math.round(place.modelData.x * picture.width)
                                y: Math.round(place.modelData.y * picture.height)
                                width: shot.painted ? Math.max(4, Math.round(shot.implicitWidth * place.k)) : Math.round(picture.width * 0.12 * place.share)
                                height: shot.painted ? Math.max(4, Math.round(shot.implicitHeight * place.k)) : Math.round(picture.height * 0.16 * place.share)
                                // Its own picture at the scale of the desktop; a plate while it has none.
                                Image {
                                    id: shot
                                    anchors.fill: parent
                                    source: place.url
                                    asynchronous: true
                                    retainWhileLoading: true
                                    smooth: true
                                    mipmap: true
                                    fillMode: Image.PreserveAspectFit
                                    visible: shot.painted
                                    property bool painted: false
                                    Component.onCompleted: shot.painted = shot.status === Image.Ready
                                    onStatusChanged: {
                                        if (shot.status === Image.Ready) shot.painted = true
                                        else if (shot.status === Image.Null || shot.status === Image.Error) shot.painted = false
                                    }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    visible: !shot.painted
                                    radius: Math.round(3 * root.d) // iris-literal: a widget in miniature, at the preview's scale
                                    color: IrisStyle.fill
                                    border.width: 1
                                    border.color: IrisStyle.hairline
                                }
                            }
                        }
                        MouseArea {
                            id: wearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            Accessible.role: Accessible.Button
                            Accessible.name: Translation.tr("Wear %1").arg(preset.modelData.name)
                            onClicked: DesktopPresets.wear(preset.modelData.id)
                        }
                        // Worn: the accent rim and its check.
                        Rectangle {
                            anchors.fill: parent
                            radius: picture.radius
                            color: "transparent"
                            border.width: preset.worn ? Math.max(2, Math.round(2 * root.d)) : 1
                            border.color: preset.worn ? IrisStyle.accent : preset.hovered ? IrisStyle.hairlineStrong : IrisStyle.hairline
                            Behavior on border.color { ColorAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Math.round(6 * root.d)
                            width: Math.round(20 * root.d)
                            height: width
                            radius: width / 2
                            color: IrisStyle.accent
                            scale: preset.worn && !keys.shown ? 1 : 0
                            visible: scale > 0
                            Behavior on scale { NumberAnimation { duration: IrisStyle.duration(200); easing.type: IrisStyle.feedbackEasing } }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "check"
                                iconSize: Math.round(14 * root.d)
                                color: IrisStyle.inkOnAccent
                            }
                        }
                        // Rename and remove, at the corner while the pointer is over one of the person's own.
                        Row {
                            id: keys
                            readonly property bool shown: preset.own && preset.hovered
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Math.round(6 * root.d)
                            spacing: Math.round(4 * root.d)
                            opacity: keys.shown ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                            CornerKey {
                                id: renameKey
                                glyph: "edit"
                                name: Translation.tr("Rename")
                                onActivated: root.naming = preset.modelData.id
                            }
                            CornerKey {
                                id: removeKey
                                glyph: "delete"
                                danger: true
                                name: Translation.tr("Remove %1").arg(preset.modelData.name)
                                onActivated: DesktopPresets.remove(preset.modelData.id)
                            }
                        }
                    }

                    IrisText {
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(2 * root.d)
                        anchors.bottom: parent.bottom
                        width: Math.min(implicitWidth, parent.width - Math.round(4 * root.d))
                        visible: root.naming !== preset.modelData.id
                        text: preset.modelData.name
                        color: preset.worn ? IrisStyle.accent : IrisStyle.text
                        font.pixelSize: IrisStyle.typeMeta
                        font.weight: IrisStyle.weight(preset.worn ? Font.DemiBold : Font.Medium)
                        elide: Text.ElideRight
                    }
                    TextInput {
                        id: nameInput
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Math.round(2 * root.d)
                        anchors.bottom: parent.bottom
                        visible: root.naming === preset.modelData.id
                        color: IrisStyle.text
                        selectionColor: IrisStyle.accent
                        selectedTextColor: IrisStyle.inkOnAccent
                        font.family: IrisStyle.fontMain
                        font.pixelSize: IrisStyle.typeMeta
                        font.weight: IrisStyle.weight(Font.DemiBold)
                        clip: true
                        Accessible.name: Translation.tr("Rename")
                        onVisibleChanged: if (visible) { text = preset.modelData.name; forceActiveFocus(); selectAll() }
                        onAccepted: { DesktopPresets.rename(preset.modelData.id, text); root.naming = "" }
                        onActiveFocusChanged: if (!activeFocus && visible) { DesktopPresets.rename(preset.modelData.id, text); root.naming = "" }
                        Keys.onEscapePressed: event => { root.naming = ""; event.accepted = true }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.bottom
                            anchors.topMargin: Math.round(2 * root.d)
                            height: 1
                            color: IrisStyle.accent
                        }
                    }
                }
            }
        }

        // Nothing of the person's own yet: what this page is for, once.
        IrisText {
            Layout.fillWidth: true
            visible: DesktopPresets.presets.length === 0
            wrapMode: Text.WordWrap
            text: Translation.tr("Save how this desktop looks and wear it again whenever you like.")
            color: IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeMeta
        }
    }

    component CornerKey: Rectangle {
        id: key
        property string glyph: ""
        property string name: ""
        property bool danger: false
        readonly property bool hovered: keyArea.containsMouse
        signal activated()
        width: Math.round(24 * root.d)
        height: width
        radius: width / 2
        color: key.hovered ? (key.danger ? IrisStyle.danger : IrisStyle.accent) : IrisStyle.surface
        border.width: 1
        border.color: IrisStyle.hairline
        Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
        MaterialSymbol {
            anchors.centerIn: parent
            text: key.glyph
            iconSize: Math.round(14 * root.d)
            color: key.hovered ? (key.danger ? IrisStyle.inkOnDanger : IrisStyle.inkOnAccent) : IrisStyle.text
        }
        MouseArea {
            id: keyArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: key.name
            onClicked: key.activated()
        }
    }
}
