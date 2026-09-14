pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style

Item {
    id: root

    property string icon: "visibility"
    property string title: ""
    property string subtitle: ""
    property string indexText: ""
    property real markSize: 18 * IrisStyle.density
    property string eyebrow: "IRIS"

    readonly property real metricGap: 14 * IrisStyle.density

    // Every consumer places the header in a width-owning layout. Do not feed
    // content width back into that parent or large typography can trigger a
    // Layout rearrange loop.
    implicitWidth: 1
    implicitHeight: Math.max(headerColumn.implicitHeight, metric.implicitHeight)

    Column {
        id: headerColumn
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: metric.visible
            ? Math.max(0, root.width - metric.width - root.metricGap)
            : root.width
        spacing: 2 * IrisStyle.density

        Row {
            visible: !IrisStyle.island
            spacing: 7 * IrisStyle.density

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: IrisStyle.accentRuleWidth
                height: IrisStyle.accentRuleHeight
                radius: height / 2
                color: IrisStyle.secondaryAccent
            }

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.icon.length > 0
                text: root.icon
                iconSize: Math.round(root.markSize)
                color: IrisStyle.accent
            }

            IrisText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.eyebrow
                role: IrisText.Eyebrow
            }
        }

        IrisText {
            width: headerColumn.width
            text: root.title
            role: IrisText.Title
            elide: Text.ElideRight
        }

        IrisText {
            width: headerColumn.width
            visible: root.subtitle.length > 0
            text: root.subtitle
            role: IrisText.Meta
            elide: Text.ElideRight
        }
    }

    IrisText {
        id: metric
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.indexText.length > 0 && !IrisStyle.island
        // Fixed presentation lane. Binding width back to Text.implicitWidth while
        // eliding makes the metric participate in its own sizing calculation at
        // large font scales and causes QtQuick.Layouts rearrange loops upstream.
        width: 128 * IrisStyle.density
        text: root.indexText
        role: IrisText.Metric
        font.pixelSize: 24 * IrisStyle.typeScale
        color: ColorUtils.applyAlpha(IrisStyle.accent, 0.18)
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
    }
}
