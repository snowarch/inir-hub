pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets
import qs.modules.iris.style

IrisButton {
    id: root

    property string materialIcon: "circle"
    property string title: ""
    property string subtitle: ""
    property string trailingText: ""
    property bool compact: false
    property bool showChevron: true

    implicitHeight: (root.compact ? 44 : 56) * IrisStyle.density
    quiet: !root.selected

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8 * IrisStyle.density
        anchors.rightMargin: 10 * IrisStyle.density
        spacing: 10 * IrisStyle.density

        Rectangle {
            visible: !IrisStyle.island
            Layout.preferredWidth: 3 * IrisStyle.density
            Layout.preferredHeight: (root.compact ? 24 : 30) * IrisStyle.density
            radius: width / 2
            color: root.danger ? IrisStyle.danger
                : root.selected ? IrisStyle.accent : IrisStyle.hairline
        }

        MaterialSymbol {
            text: root.materialIcon
            iconSize: Math.round((root.compact ? 18 : 20) * IrisStyle.density)
            fill: root.selected ? 1 : 0
            animateFill: true
            font.weight: root.selected || root.hovered ? Font.DemiBold : Font.Normal
            color: root.danger ? IrisStyle.danger
                : root.selected ? IrisStyle.accent : IrisStyle.subtext
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            IrisText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: (root.compact ? 12 : 13) * IrisStyle.typeScale
                font.weight: root.selected ? Font.Bold : Font.DemiBold
                color: root.foreground
                elide: Text.ElideRight
            }
            IrisText {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                role: IrisText.Meta
                font.pixelSize: 10 * IrisStyle.typeScale
                color: root.selected ? root.foreground : IrisStyle.subtext
                elide: Text.ElideRight
            }
        }

        IrisText {
            visible: root.trailingText.length > 0
            text: root.trailingText
            role: IrisText.Meta
            font.family: IrisStyle.fontNumbers
            color: root.selected ? root.foreground : IrisStyle.subtext
        }

        MaterialSymbol {
            visible: root.showChevron && root.trailingText.length === 0
            text: "arrow_forward"
            iconSize: 14 * IrisStyle.density
            color: root.selected ? IrisStyle.accent : IrisStyle.muted
        }
    }
}
