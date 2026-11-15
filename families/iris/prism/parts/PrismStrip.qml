pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// The page's stage once it is scrolled past: a 72 px strip that stays over the page, its cover and title, every group
// numbered like an index divider (`.claude/ref/language`, dividers-delave) and Restore defaults. The open group is a
// key held down under its number: one key that glides from group to group as the page is read or a number pressed.
// A dot says a group changed. It eases in and out.
Item {
    id: root

    property var page: ({})
    property var groups: []
    property string currentGroup: ""
    property int restorable: 0
    property bool shown: false
    signal pickGroup(string title)
    signal restore()

    height: PrismTheme.dp(72)
    opacity: root.shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: IrisStyle.feedbackEasing } }
    transform: Translate {
        y: root.shown ? 0 : -PrismTheme.dp(8)
        Behavior on y { NumberAnimation { duration: PrismTheme.ms(240); easing.type: IrisStyle.feedbackEasing } }
    }

    // Keeps the open group's chip in view as the page is read.
    onCurrentGroupChanged: Qt.callLater(root.reveal)
    function reveal(): void {
        const chip = chips.children.find(item => item.title === root.currentGroup)
        if (!chip || flick.contentWidth <= flick.width) return
        flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width, chip.x - (flick.width - chip.width) / 2))
    }

    RectangularShadow {
        anchors.fill: plate
        radius: plate.radius
        blur: PrismTheme.dp(28)
        offset.y: PrismTheme.dp(8)
        color: Qt.rgba(0, 0, 0, PrismTheme.light ? 0.12 : 0.4) // iris-literal: Prism's own fills and scrims, scheme-aware above
    }
    Rectangle {
        id: plate
        anchors.fill: parent
        radius: PrismTheme.dp(22)
        color: PrismTheme.raised
        // Presses and the pointer stop here, never reaching a row hidden under it; the wheel goes on to the page.
        MouseArea { anchors.fill: parent; hoverEnabled: true; onWheel: wheel => wheel.accepted = false }
    }

    PrismThumb {
        id: cover
        x: PrismTheme.dp(14)
        anchors.verticalCenter: parent.verticalCenter
        size: PrismTheme.dp(36)
        glyph: String(root.page?.glyph ?? "circle")
        tint: String(root.page?.tint ?? "grey")
    }
    PrismText {
        id: title
        anchors.left: cover.right
        anchors.leftMargin: PrismTheme.dp(12)
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, PrismTheme.dp(180))
        elide: Text.ElideRight
        text: Translation.tr(String(root.page?.name ?? ""))
        color: PrismTheme.ink
        font.pixelSize: PrismTheme.row
        font.weight: Font.Bold
        font.letterSpacing: -PrismTheme.row * 0.02
    }
    Rectangle {
        id: rule
        anchors.left: title.right
        anchors.leftMargin: PrismTheme.dp(16)
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: PrismTheme.dp(28)
        color: PrismTheme.line
    }

    Flickable {
        id: flick
        anchors.left: rule.right
        anchors.leftMargin: PrismTheme.dp(8)
        anchors.right: restorePill.visible ? restorePill.left : parent.right
        anchors.rightMargin: PrismTheme.dp(restorePill.visible ? 10 : 14)
        height: parent.height
        contentWidth: chips.width
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        clip: true
        Behavior on contentX { NumberAnimation { duration: PrismTheme.ms(260); easing.type: IrisStyle.feedbackEasing } }

        // The open group's key, under the numbers: it glides to the chip that is open.
        PrismKey {
            id: held
            readonly property Item at: chips.children.find(item => item.title === root.currentGroup) ?? null
            visible: held.at !== null
            x: held.at?.x ?? 0
            y: chips.y + (chips.height - height) / 2
            width: held.at?.width ?? 0
            height: PrismTheme.dp(40)
            radius: PrismTheme.dp(13)
            face: PrismTheme.solid
            down: true
            Behavior on x { NumberAnimation { duration: PrismTheme.ms(260); easing.type: IrisStyle.feedbackEasing } }
            Behavior on width { NumberAnimation { duration: PrismTheme.ms(260); easing.type: IrisStyle.feedbackEasing } }
        }
        Row {
            id: chips
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(2)
            Repeater {
                model: root.groups
                delegate: Item {
                    id: chip
                    required property var modelData
                    required property int index
                    readonly property string title: String(chip.modelData.title)
                    readonly property bool here: root.currentGroup === chip.title
                    width: said.x + said.implicitWidth + PrismTheme.dp(14)
                    height: PrismTheme.dp(44)
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: PrismTheme.dp(2)
                        anchors.bottomMargin: PrismTheme.dp(2)
                        radius: PrismTheme.dp(13)
                        visible: !chip.here
                        color: tap.pressed ? PrismTheme.fillPress : hover.hovered ? PrismTheme.fillHover : "transparent"
                        Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: IrisStyle.feedbackEasing } }
                    }
                    PrismText {
                        id: number
                        x: PrismTheme.dp(14)
                        y: (parent.height - height) / 2 + (chip.here ? PrismTheme.keyLip / 2 : 0)
                        mono: true
                        text: String(chip.index + 1).padStart(2, "0")
                        color: chip.here ? PrismTheme.inkSolid : PrismTheme.ink3
                        opacity: chip.here ? 0.55 : 1
                        font.pixelSize: PrismTheme.caption
                        Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: IrisStyle.feedbackEasing } }
                    }
                    Rectangle {
                        id: dot
                        visible: Boolean(chip.modelData.changed)
                        x: number.x + number.implicitWidth + PrismTheme.dp(4)
                        y: (parent.height - height) / 2 + (chip.here ? PrismTheme.keyLip / 2 : 0)
                        width: PrismTheme.dp(5)
                        height: width
                        radius: width / 2
                        color: PrismTheme.accent
                    }
                    PrismText {
                        id: said
                        x: (dot.visible ? dot.x + dot.width : number.x + number.implicitWidth) + PrismTheme.dp(7)
                        y: (parent.height - height) / 2 + (chip.here ? PrismTheme.keyLip / 2 : 0)
                        text: Translation.tr(chip.title)
                        color: chip.here ? PrismTheme.inkSolid : PrismTheme.ink
                        font.pixelSize: PrismTheme.small
                        font.weight: Font.DemiBold
                        Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: IrisStyle.feedbackEasing } }
                    }
                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: tap; onTapped: root.pickGroup(chip.title) }
                }
            }
        }
    }

    // More groups past either edge fade into the plate instead of being cut.
    Rectangle {
        visible: flick.contentX > 1
        anchors.left: flick.left
        anchors.verticalCenter: parent.verticalCenter
        width: PrismTheme.dp(36)
        height: PrismTheme.dp(44)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: PrismTheme.raised }
            GradientStop { position: 1; color: Qt.alpha(PrismTheme.raised, 0) }
        }
    }
    Rectangle {
        visible: flick.interactive && flick.contentX < flick.contentWidth - flick.width - 1
        anchors.right: flick.right
        anchors.verticalCenter: parent.verticalCenter
        width: PrismTheme.dp(36)
        height: PrismTheme.dp(44)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(PrismTheme.raised, 0) }
            GradientStop { position: 1; color: PrismTheme.raised }
        }
    }

    PrismPill {
        id: restorePill
        visible: root.restorable > 0
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(14)
        anchors.verticalCenter: parent.verticalCenter
        tone: "quiet"
        glyph: "restart_alt"
        text: Translation.tr("Restore defaults")
        onClicked: root.restore()
    }
}
