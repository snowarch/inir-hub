pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style

// Week (his 11-06 references): now as the figure beside its sky, the coming days as columns under it, each its name,
// its sky and its high over its low. Today's column stands on the quiet fill. Small has room for three days, the
// others for five; large adds the place and the conditions in words.
Item {
    id: view
    required property var face

    readonly property var days: Array.from(view.face.days ?? []).slice(0, view.face.small ? 3 : 5)
    readonly property bool label: view.face.nothing ?? false

    function skyOf(glyph: string): color {
        return view.label ? view.face.ink : IrisStyle.skyLight(glyph)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: view.face.dp(view.face.large ? 14 : 8)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: view.face.dp(10)
            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: view.face.glyph
                fill: 1
                iconSize: view.face.px(view.face.small ? 34 : view.face.large ? 52 : 44)
                color: view.skyOf(view.face.glyph)
            }
            FaceFigure {
                face: view.face
                Layout.alignment: Qt.AlignVCenter
                text: view.face.widget.temperatureText
                size: view.face.small ? 38 : view.face.large ? 60 : 50
            }
            ColumnLayout {
                visible: !view.face.small
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: view.face.dp(1)
                FaceText {
                    face: view.face
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    visible: text.length > 0
                    text: view.label ? view.face.city.toUpperCase() : view.face.city
                    color: view.label ? view.face.inkSecondary : view.face.heading
                    size: view.label ? 11 : 13.5
                    weight: Font.DemiBold
                    font.family: view.label ? view.face.fontLabel : view.face.fontMain
                    font.letterSpacing: view.label ? view.face.px(11) * 0.12 : 0
                }
                FaceText {
                    face: view.face
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: view.face.readout.length > 0 ? view.face.readout : view.face.condition
                    color: view.face.inkSecondary
                    size: 12.5
                }
                FaceText {
                    face: view.face
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    visible: view.face.large && view.face.range.length > 0
                    text: view.face.range
                    color: view.face.inkTertiary
                    size: 12
                }
            }
        }
        Item { Layout.fillHeight: true }
        Row {
            id: strip
            Layout.fillWidth: true
            Layout.preferredHeight: view.face.dp(view.face.large ? 104 : view.face.small ? 74 : 82)
            readonly property real column: strip.width / Math.max(1, view.days.length)
            Repeater {
                model: view.days
                Item {
                    id: day
                    required property var modelData
                    required property int index
                    readonly property string glyph: Icons.getWeatherIcon(day.modelData.code, false) ?? "cloud"
                    width: strip.column
                    height: strip.height
                    Rectangle {
                        visible: day.index === 0
                        anchors.fill: parent
                        anchors.leftMargin: view.face.dp(2)
                        anchors.rightMargin: view.face.dp(2)
                        radius: Math.min(view.face.innerRadius, width / 2)
                        color: view.face.fill
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: view.face.dp(view.face.large ? 8 : 5)
                        FaceText {
                            face: view.face
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: day.index === 0 ? (view.label ? Translation.tr("Today").toUpperCase() : Translation.tr("Today"))
                                : view.label ? String(day.modelData.dayName ?? "").toUpperCase() : String(day.modelData.dayName ?? "")
                            color: day.index === 0 ? view.face.ink : view.face.inkSecondary
                            size: view.label ? 10.5 : 12
                            weight: Font.DemiBold
                            font.family: view.label ? view.face.fontLabel : view.face.fontMain
                            font.letterSpacing: view.label ? view.face.px(10.5) * 0.1 : 0
                        }
                        MaterialSymbol {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: day.glyph
                            fill: 1
                            iconSize: view.face.px(view.face.large ? 26 : 22)
                            color: view.skyOf(day.glyph)
                        }
                        FaceText {
                            face: view.face
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Math.round(Number(day.modelData.hiVal)) + "°"
                            size: view.face.large ? 16 : 14
                            weight: Font.DemiBold
                            font.family: view.face.fontNumbers
                        }
                        FaceText {
                            face: view.face
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Math.round(Number(day.modelData.loVal)) + "°"
                            color: view.face.inkTertiary
                            size: view.face.large ? 14 : 12.5
                            font.family: view.face.fontNumbers
                        }
                    }
                }
            }
        }
    }
}
