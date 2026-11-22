pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

// A group of settings as Windows 11 Settings draws one (CommunityToolkit SettingsCard / SettingsExpander, read 10-29).
// Open: a BodyStrong section header, then every setting its own card, 4 px apart. Collapsible: a SettingsExpander,
// one 68 px header card whose rows sit inside it, flat, a hairline apart, indented past its icon.
// Content that isn't a row (a preview, a button strip, a note) gets a card of its own with the card's padding.
// An expander may carry a toggle in its header (`toggle`, as Windows' SettingsExpander with a ToggleSwitch): the
// header turns the thing on, the rows inside tune it and rest disabled while it is off.
Item {
    id: root

    property string title: ""
    property string icon: ""
    property string description: ""
    property bool expanded: true
    property bool collapsible: false
    // the section header above an expander (an open group's header is its title)
    property string section: ""
    property bool toggle: false
    property bool checked: false
    signal toggled(bool checked)
    default property alias content: contentColumn.data

    readonly property bool expander: root.collapsible
    readonly property Item header: expanderHeader

    // a search that opened this expander lands on its row after the body has grown
    function landAfterOpen(row: Item): void {
        landTimer.row = row
        landTimer.restart()
    }
    Timer {
        id: landTimer
        property Item row: null
        interval: (Looks.transition.enabled ? Looks.transition.duration.medium : 0) + 60
        onTriggered: if (row) row.land()
    }
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
        let first = null
        for (let i = 0; i < kids.length && !first; ++i)
            if (kids[i].visible)
                first = kids[i]
        for (let i = 0; i < kids.length; ++i) {
            const c = kids[i]
            if (c.settingsCardRole === "row") {
                // Waffle Next: a group is one plate, its settings rows on it a hairline apart
                c.cardStyle = "item"
                c.hairline = root.expander || c !== first
                c.itemIndent = root.expander ? Looks.dp(58) : Looks.settings.cardPadding
                c.endInset = root.expander ? Looks.dp(44) : Looks.settings.cardPadding
                if (root.toggle)
                    c.enabled = Qt.binding(() => root.checked)
                continue
            }
            if (!c.visible || c.height <= 0 || c.Layout === undefined)
                continue
            // a note that brings its own plate (WSettingsInfoBar)
            if (c.radius !== undefined && c.color !== undefined && c.color.a > 0.02)
                continue
            // a plain line of text is a caption on the plate: it reads with the setting above it, so it keeps the
            // plate's side padding and closes the gap below (on top only when nothing stands above it)
            if (c.children.length === 0 && typeof c.text === "string") {
                c.Layout.leftMargin = root.expander ? Looks.dp(58) : Looks.settings.cardPadding
                c.Layout.rightMargin = root.expander ? Looks.dp(44) : Looks.settings.cardPadding
                c.Layout.topMargin = c === first ? Looks.dp(12) : 0
                c.Layout.bottomMargin = Looks.dp(12)
                continue
            }
            c.Layout.leftMargin = root.expander ? Looks.dp(58) : Looks.settings.cardPadding
            c.Layout.rightMargin = root.expander ? Looks.dp(44) : Looks.settings.cardPadding
            c.Layout.fillWidth = true
            c.Layout.topMargin = Looks.settings.cardPadding
            c.Layout.bottomMargin = Looks.settings.cardPadding
            blocks.push(c)
        }
        root._blocks = blocks
    }
    Component.onCompleted: Qt.callLater(root.relayout)
    // a group hidden while it loaded saw no visible children: it lays them out once it shows
    onVisibleChanged: if (visible) Qt.callLater(root.relayout)

    ColumnLayout {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // ── Open group: the section header ──
        ColumnLayout {
            visible: root.expander ? root.section !== "" : root.title !== ""
            Layout.fillWidth: true
            Layout.topMargin: Looks.dp(22)
            Layout.bottomMargin: Looks.dp(8)
            Layout.leftMargin: Looks.dp(4)
            spacing: Looks.dp(2)

            WText {
                Layout.fillWidth: true
                text: root.expander ? root.section : root.title
                font.pixelSize: Looks.settings.body + Looks.dp(1)
                font.weight: Looks.font.weight.stronger
                elide: Text.ElideRight
                Accessible.role: Accessible.Heading
            }
            WText {
                visible: !root.expander && root.description !== ""
                Layout.fillWidth: true
                text: root.description
                font.pixelSize: Looks.settings.caption
                font.weight: Looks.font.weight.thin
                color: Looks.colors.subfg
                wrapMode: Text.WordWrap
            }
        }

        // ── Expander: the header card, a row of its own (search lands on it, keyboard reaches it) ──
        WSettingsRow {
            id: expanderHeader
            visible: root.expander
            enableSettingsSearch: root.expander
            Layout.fillWidth: true
            label: root.title
            icon: root.icon
            description: root.description
            clickable: true
            flatBottom: root.expanded
            endInset: Looks.dp(8)
            onClicked: root.expanded = !root.expanded
            control: Component {
                RowLayout {
                    spacing: Looks.dp(12)
                    WText {
                        visible: root.toggle
                        text: root.checked ? Translation.tr("On") : Translation.tr("Off")
                        font.pixelSize: Looks.settings.body
                        font.weight: Looks.font.weight.thin
                    }
                    WSwitch {
                        visible: root.toggle
                        checked: root.checked
                        Accessible.name: root.title
                        onClicked: root.toggled(!root.checked)
                    }
                    // the chevron sits in a 32 px button like the expander's toggle
                    Item {
                        Layout.leftMargin: Looks.dp(-8)
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
                animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.slow : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
            }

            // an expander's body is one plate under its header; an open group is one plate whole
            Rectangle {
                visible: root.expander || contentColumn.visibleChildren.length > 0
                anchors.fill: parent
                anchors.topMargin: root.expander ? -1 : 0
                radius: root.expander ? 0 : Looks.settings.radiusLarge
                topLeftRadius: root.expander ? 0 : Looks.settings.radiusLarge
                topRightRadius: root.expander ? 0 : Looks.settings.radiusLarge
                bottomLeftRadius: Looks.settings.radiusLarge
                bottomRightRadius: Looks.settings.radiusLarge
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
                    color: "transparent"
                    Rectangle {
                        visible: plate.y > 1
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
                spacing: 0
                opacity: root.expanded ? 1 : 0
                onImplicitHeightChanged: Qt.callLater(root.relayout)

                Behavior on opacity {
                    animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0; easing.type: Easing.OutQuad }
                }
            }
        }
    }
}
