pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.iris.prism.core

// Every face this computer has, opened under a row's typeface cards by the pill at its end (his 11-20: the pill pressed
// and nothing opened): a search, then the faces that match, each named in itself; the chosen one solid. Enter takes the
// first match.
Column {
    id: root
    property var current
    signal picked(var value)

    property string query: ""
    readonly property var families: FontSyncService.pickableFamilies()
    readonly property var matches: {
        const words = root.query.trim().toLowerCase()
        const found = words.length > 0 ? root.families.filter(family => family.toLowerCase().includes(words)) : root.families
        return found.slice(0, 48)
    }
    spacing: PrismTheme.dp(10)

    PrismField {
        id: search
        width: Math.min(root.width, PrismTheme.dp(320))
        glyph: "search"
        placeholder: Translation.tr("Search installed fonts")
        onEdited: text => root.query = text
        onEntered: if (root.matches.length > 0) root.picked(root.matches[0])
        Component.onCompleted: search.input.forceActiveFocus()
    }
    Flow {
        visible: root.matches.length > 0
        width: root.width
        spacing: PrismTheme.dp(6)
        Repeater {
            model: root.matches
            delegate: Item {
                id: fam
                required property string modelData
                readonly property bool chosen: fam.modelData === String(root.current ?? "")
                implicitWidth: label.width + PrismTheme.dp(28)
                implicitHeight: PrismTheme.dp(32)
                PrismKey {
                    anchors.fill: parent
                    face: fam.chosen ? PrismTheme.solid : PrismTheme.keyQuiet
                    hovered: area.containsMouse
                    down: area.pressed
                    PrismText {
                        id: label
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, PrismTheme.dp(220))
                        text: fam.modelData
                        font.family: fam.modelData
                        font.pixelSize: PrismTheme.body
                        color: fam.chosen ? PrismTheme.inkSolid : PrismTheme.ink
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(fam.modelData)
                }
                Accessible.role: Accessible.RadioButton
                Accessible.checked: fam.chosen
                Accessible.name: fam.modelData
            }
        }
    }
    PrismText {
        visible: root.matches.length === 0
        text: Translation.tr("No installed font matches")
        color: PrismTheme.ink2
        font.pixelSize: PrismTheme.small
    }
}
