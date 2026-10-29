pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

// A group of settings as Windows 11 Settings draws one (CommunityToolkit SettingsCard / SettingsExpander, read 10-29).
// Open: a BodyStrong section header, then every setting its own card, 4 px apart. Collapsible: a SettingsExpander,
// one 68 px header card whose rows sit inside it, flat, a hairline apart, indented past its icon.
// Content that isn't a row (a preview, a button strip, a note) gets a card of its own with the card's padding.
Item {
    id: root

    property string title: ""
    property string icon: ""
    property string description: ""
    property bool expanded: true
    property bool collapsible: false
    default property alias content: contentColumn.data

    readonly property bool expander: root.collapsible
    // kept for pages that read them
    readonly property int cardRadius: Looks.settings.radiusSmall
    readonly property int cardPadding: Looks.settings.cardPadding

    Layout.fillWidth: true
    implicitHeight: mainColumn.implicitHeight

    // the plates painted behind loose content; rows draw their own
    property var _blocks: []
    function relayout(): void {
        const blocks = []
        const kids = contentColumn.children
        for (let i = 0; i < kids.length; ++i) {
            const c = kids[i]
            if (c.settingsCardRole === "row") {
                c.cardStyle = root.expander ? "item" : "card"
                continue
            }
            if (!c.visible || c.height <= 0 || c.Layout === undefined)
                continue
            // a note that brings its own plate (WSettingsInfoBar)
            if (c.radius !== undefined && c.color !== undefined && c.color.a > 0.02)
                continue
            // a plain line of text is a caption under the header, not a setting
            if (c.children.length === 0 && typeof c.text === "string") {
                c.Layout.leftMargin = root.expander ? Looks.dp(58) : Looks.dp(2)
                c.Layout.rightMargin = c.Layout.leftMargin
                continue
            }
            c.Layout.leftMargin = root.expander ? Looks.dp(58) : Looks.settings.cardPadding
            c.Layout.rightMargin = root.expander ? Looks.dp(44) : Looks.settings.cardPadding
            c.Layout.topMargin = Looks.settings.cardPadding
            c.Layout.bottomMargin = Looks.settings.cardPadding
            blocks.push(c)
        }
        root._blocks = blocks
    }
    Component.onCompleted: Qt.callLater(root.relayout)

    ColumnLayout {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // ── Open group: the section header ──
        ColumnLayout {
            visible: !root.expander && root.title !== ""
            Layout.fillWidth: true
            Layout.topMargin: Looks.dp(18)
            Layout.bottomMargin: Looks.dp(6)
            Layout.leftMargin: Looks.dp(1)
            spacing: Looks.dp(2)

            WText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Looks.settings.body
                font.weight: Looks.font.weight.strong
                elide: Text.ElideRight
                Accessible.role: Accessible.Heading
            }
            WText {
                visible: root.description !== ""
                Layout.fillWidth: true
                text: root.description
                font.pixelSize: Looks.settings.caption
                font.weight: Looks.font.weight.thin
                color: Looks.colors.subfg
                wrapMode: Text.WordWrap
            }
        }

        // ── Expander: the header card ──
        Item {
            id: expanderHeader
            visible: root.expander
            Layout.fillWidth: true
            implicitHeight: Math.max(Looks.settings.cardMinHeight, headerRow.implicitHeight + Looks.dp(26))

            Rectangle {
                anchors.fill: parent
                bottomLeftRadius: root.expanded ? 0 : Looks.settings.radiusSmall
                bottomRightRadius: bottomLeftRadius
                topLeftRadius: Looks.settings.radiusSmall
                topRightRadius: Looks.settings.radiusSmall
                color: headerMouse.pressed ? Looks.settings.cardPressed
                    : headerMouse.containsMouse ? Looks.settings.cardHover : Looks.settings.card
                border.width: 1
                border.color: Looks.settings.cardStroke
                Behavior on color {
                    animation: ColorAnimation { duration: Looks.transition.enabled ? 83 : 0 }
                }
            }
            MouseArea {
                id: headerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
            RowLayout {
                id: headerRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Looks.settings.cardPadding
                anchors.rightMargin: Looks.dp(8)
                spacing: Looks.dp(16)

                FluentIcon {
                    visible: root.icon !== ""
                    Layout.leftMargin: Looks.dp(2)
                    Layout.rightMargin: Looks.dp(4)
                    icon: root.icon
                    implicitSize: Looks.settings.cardIconSize
                    color: Looks.colors.fg
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    WText {
                        Layout.fillWidth: true
                        text: root.title
                        font.pixelSize: Looks.settings.body
                        font.weight: Looks.font.weight.thin
                        elide: Text.ElideRight
                    }
                    WText {
                        visible: root.description !== ""
                        Layout.fillWidth: true
                        text: root.description
                        font.pixelSize: Looks.settings.caption
                        font.weight: Looks.font.weight.thin
                        color: Looks.colors.subfg
                        wrapMode: Text.WordWrap
                    }
                }
                // the chevron sits in a 32 px button like the expander's toggle
                Item {
                    implicitWidth: Looks.dp(32)
                    implicitHeight: Looks.dp(32)
                    FluentIcon {
                        anchors.centerIn: parent
                        icon: "chevron-down"
                        implicitSize: Looks.dp(13)
                        color: Looks.colors.fg
                        rotation: root.expanded ? 180 : 0
                        Behavior on rotation {
                            animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
                        }
                    }
                }
            }
        }

        // ── The settings ──
        Item {
            id: body
            Layout.fillWidth: true
            implicitHeight: root.expanded ? contentColumn.implicitHeight : 0
            clip: root.expander
            visible: implicitHeight > 0 || !root.expander

            Behavior on implicitHeight {
                enabled: root.expander
                animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
            }

            // an expander's body is one plate under its header
            Rectangle {
                visible: root.expander
                anchors.fill: parent
                anchors.topMargin: -1
                bottomLeftRadius: Looks.settings.radiusSmall
                bottomRightRadius: Looks.settings.radiusSmall
                color: Looks.settings.card
                border.width: 1
                border.color: Looks.settings.cardStroke
            }

            Repeater {
                model: root._blocks
                delegate: Rectangle {
                    id: plate
                    required property var modelData
                    readonly property Item block: plate.modelData
                    visible: plate.block && plate.block.visible
                    x: 0
                    y: plate.block ? plate.block.y - Looks.settings.cardPadding : 0
                    width: body.width
                    height: plate.block ? plate.block.height + Looks.settings.cardPadding * 2 : 0
                    radius: root.expander ? 0 : Looks.settings.radiusSmall
                    color: root.expander ? "transparent" : Looks.settings.card
                    border.width: root.expander ? 0 : 1
                    border.color: Looks.settings.cardStroke
                    Rectangle {
                        visible: root.expander
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: Looks.settings.cardStroke
                    }
                }
            }

            ColumnLayout {
                id: contentColumn
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: root.expander ? 0 : Looks.settings.cardSpacing
                opacity: root.expanded ? 1 : 0
                onImplicitHeightChanged: Qt.callLater(root.relayout)

                Behavior on opacity {
                    animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0; easing.type: Easing.OutQuad }
                }
            }
        }
    }
}
