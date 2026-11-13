pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "reveal.js" as Reveal

// The Corner's places: the search plate, a glyph and a name for each, the open one an inverted capsule, and at the foot
// the key that moves it between the desktop and a window. In a narrow window the rows are taller, to push into.
Rectangle {
    id: root
    property bool narrow: false
    property bool windowed: false
    // [{ id, title, icon, caption? }]: titles untranslated, a caption opens a group.
    property var places: []
    property string section: ""
    property string hint: ""
    property real outerRadius: 0
    property int pad: Math.round(10 * root.d)
    readonly property alias search: searchPlate
    readonly property real d: IrisStyle.density
    signal picked(string id)
    signal submitted()
    signal switchHost()

    function isOn(id: string): bool {
        // "anime:genres" is on for each of its genres too ("anime:genre:Drama").
        return CornerState.query.length === 0 && (root.section === id
            || (id.endsWith(":genres") && root.section.startsWith(id.slice(0, -"genres".length) + "genre:")))
    }

    color: IrisStyle.readingSidebar
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: 0

        CornerSearch {
            id: searchPlate
            Layout.fillWidth: true
            Layout.bottomMargin: Math.round(6 * root.d)
            hint: root.hint
            outerRadius: root.outerRadius
            pad: root.pad
            onSubmitted: root.submitted()
        }
        Flickable {
            IrisScrollFeel {}
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: list.implicitHeight
            implicitHeight: list.implicitHeight
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: IrisScrollBar {}
            Column {
                id: list
                width: parent.width
                spacing: Math.round(2 * root.d)
                Repeater {
                    model: root.places
                    delegate: PlaceRow {}
                }
            }
        }
        Item { Layout.fillHeight: true }
        IrisIconButton {
            id: hostKey
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Math.round(8 * root.d)
            materialIcon: root.windowed ? "layers" : "web_asset"
            Accessible.name: root.windowed ? Translation.tr("Open over the desktop") : Translation.tr("Open in a window")
            onClicked: root.switchHost()
            StyledToolTip { text: hostKey.Accessible.name; extraVisibleCondition: hostKey.buttonHovered }
        }
    }

    component PlaceRow: MouseArea {
        id: row
        required property var modelData
        readonly property bool selected: root.isOn(row.modelData.id)
        readonly property real rowHeight: Math.round((root.narrow ? 40 : 34) * root.d * Math.max(1, IrisStyle.typeScale))
        readonly property string caption: Translation.tr(String(row.modelData.caption ?? ""))
        readonly property real washY: row.caption.length > 0 ? Math.round(9 * root.d) + captionText.implicitHeight + Math.round(2 * root.d) : 0
        width: parent ? parent.width : 0
        height: row.washY + row.rowHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: Translation.tr(row.modelData.title)
        onClicked: root.picked(row.modelData.id)
        Keys.onReturnPressed: root.picked(row.modelData.id)
        Keys.onSpacePressed: root.picked(row.modelData.id)
        onActiveFocusChanged: if (activeFocus) Reveal.reveal(row)
        IrisText {
            id: captionText
            visible: row.caption.length > 0
            x: Math.round(12 * root.d)
            y: Math.round(9 * root.d)
            width: row.width - x
            text: row.caption
            color: IrisStyle.textTertiary
            font.family: IrisStyle.fontMono
            font.pixelSize: IrisStyle.typeCaption
            font.weight: IrisStyle.weight(Font.Medium)
            font.capitalization: Font.AllUppercase
            elide: Text.ElideRight
        }
        Rectangle {
            y: row.washY
            width: parent.width
            height: row.rowHeight
            radius: IrisStyle.capsule(height)
            color: row.selected ? IrisStyle.text : row.containsMouse ? IrisStyle.fillHover : "transparent"
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
            CornerFocusRing { on: row.activeFocus }
            MaterialSymbol {
                id: ink
                x: Math.round(12 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.icon
                iconSize: Math.round(18 * root.d)
                fill: row.selected ? 1 : 0
                color: row.selected ? IrisStyle.surfaceOpaque : IrisStyle.text
            }
            IrisText {
                x: ink.x + Math.round(30 * root.d)
                width: parent.width - x - Math.round((root.narrow ? 36 : 12) * root.d)
                anchors.verticalCenter: parent.verticalCenter
                role: IrisText.Name
                text: Translation.tr(row.modelData.title)
                color: row.selected ? IrisStyle.surfaceOpaque : IrisStyle.text
                font.weight: IrisStyle.weight(row.selected ? Font.Bold : Font.DemiBold)
                elide: Text.ElideRight
            }
            MaterialSymbol {
                visible: root.narrow
                anchors.right: parent.right
                anchors.rightMargin: Math.round(6 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: "chevron_right"
                iconSize: Math.round(18 * root.d)
                color: row.selected ? IrisStyle.surfaceOpaque : IrisStyle.muted
            }
        }
    }
}
