pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.iris.prism.core
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// The layouts, one key each, in every layout's head: switching keeps the place and morphs the page. The last key wears
// Prism instead, on the page Prism has for this area (Home when it has none).
// A quiet word pill; `compact` leaves the glyphs alone.
Rectangle {
    id: root
    property Item host
    property string voice: "folio"
    property bool compact: false
    readonly property real d: IrisStyle.settingsDensity
    readonly property var keys: [
        { id: "classic", glyph: "view_sidebar", name: Translation.tr("Classic") },
        { id: "folio", glyph: "article", name: Translation.tr("Folio") },
        { id: "prism", glyph: "flare", name: Translation.tr("Prism") }
    ]
    implicitHeight: Math.round(36 * root.d)
    implicitWidth: keyRow.implicitWidth + 6
    radius: IrisStyle.capsule(height)
    color: "transparent"
    border.width: 1
    border.color: IrisStyle.hairline
    Accessible.role: Accessible.PageTabList
    Accessible.name: Translation.tr("Layout")

    Row {
        id: keyRow
        anchors.centerIn: parent
        spacing: 2
        Repeater {
            model: root.keys.filter(entry => entry.id === "classic" || entry.id === "prism" || root.host?.layouts?.[entry.id] !== undefined)
            MouseArea {
                id: key
                required property var modelData
                readonly property bool on: String(root.host?.chosenLayout ?? root.host?.layout ?? "") === key.modelData.id
                width: keyContent.implicitWidth + Math.round((root.compact ? 18 : 26) * root.d)
                height: root.height - 6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.PageTab
                Accessible.name: key.modelData.name
                Accessible.checked: key.on
                onClicked: {
                    if (key.modelData.id !== "prism") {
                        root.host.setLayout(key.modelData.id)
                        return
                    }
                    const area = String(root.host?.section ?? "general")
                    const page = ({ home: "general", island: "bar" })[area] ?? area
                    GlobalStates.settingsOverlayRequestedSection = PrismModel.ids.includes(page) ? page : "general"
                    PrismModel.wearSettings("prism")
                }
                Rectangle {
                    anchors.fill: parent
                    radius: IrisStyle.capsule(height)
                    color: key.on ? IrisStyle.fill : key.containsMouse ? IrisStyle.fillQuiet : "transparent"
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                }
                Row {
                    id: keyContent
                    anchors.centerIn: parent
                    spacing: Math.round(6 * root.d)
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: key.modelData.glyph
                        iconSize: Math.round(16 * root.d)
                        fill: key.on ? 1 : 0
                        color: key.on ? IrisStyle.text : IrisStyle.muted
                    }
                    IrisText {
                        visible: !root.compact
                        anchors.verticalCenter: parent.verticalCenter
                        text: key.modelData.name
                        color: key.on ? IrisStyle.text : IrisStyle.muted
                        font.pixelSize: IrisStyle.typeMeta
                        font.weight: IrisStyle.weight(Font.Medium)
                    }
                }
            }
        }
    }
}
