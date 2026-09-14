pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components

IrisSurface {
    id: root
    property var targetScreen
    readonly property var options: Config.options?.iris?.bar ?? ({})

    implicitHeight: Math.max(32, Math.round(Number(root.options?.height ?? 42) * IrisStyle.density))
    radius: Math.min(IrisStyle.radiusSmall, implicitHeight / 2)
    outlined: true

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: Math.round(12 * IrisStyle.density)
        anchors.bottom: parent.bottom
        width: Math.round(34 * IrisStyle.density)
        height: Math.max(2, Math.round(2 * IrisStyle.density))
        radius: height / 2
        color: IrisStyle.secondaryAccent
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.round(10 * IrisStyle.density)
        anchors.rightMargin: Math.round(10 * IrisStyle.density)
        spacing: IrisStyle.gap

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            spacing: Math.round(2 * IrisStyle.density)
            Repeater {
                model: root.options?.leftModules ?? ["brand", "workspaces"]
                IrisBarModule {
                    required property string modelData
                    moduleId: modelData
                    targetScreen: root.targetScreen
                    slot: "bar.left"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(2 * IrisStyle.density)
            Repeater {
                model: root.options?.centerModules ?? ["activeWindow"]
                IrisBarModule {
                    required property string modelData
                    moduleId: modelData
                    targetScreen: root.targetScreen
                    slot: "bar.center"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignRight
            spacing: Math.round(2 * IrisStyle.density)
            Repeater {
                model: root.options?.rightModules ?? ["status", "clock", "controls"]
                IrisBarModule {
                    required property string modelData
                    moduleId: modelData
                    targetScreen: root.targetScreen
                    slot: "bar.right"
                }
            }
        }
    }
}
