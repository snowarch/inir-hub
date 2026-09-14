pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.components
import qs.modules.iris.style

// One row inside a grouped settings card: label (and optional description) on
// the left, the control inline on the right; sliders and wide choices take a
// second line. Writes go straight to Config.
Item {
    id: root
    required property var spec
    property bool last: false
    readonly property real d: IrisStyle.density
    readonly property var value: {
        Config.revision
        return Config.getNestedValue(root.spec.path, root.spec.fallback)
    }
    readonly property var choices: root.spec.choices ?? []
    // Two or three short choices fit beside the label; others wrap below.
    readonly property bool inlineChoice: root.spec.kind === "choice" && root.choices.length <= 3
        && root.choices.every(choice => String(choice.label).length <= 11)

    implicitHeight: layout.implicitHeight + Math.round(22 * root.d)

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16 * root.d
        anchors.rightMargin: 16 * root.d
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10 * root.d

        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * root.d

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2 * root.d
                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr(root.spec.label)
                    font.pixelSize: 13.5 * IrisStyle.typeScale
                    font.weight: Font.Normal
                    wrapMode: Text.WordWrap
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.spec.description ? Translation.tr(root.spec.description) : ""
                    color: IrisStyle.muted
                    font.pixelSize: 11.5 * IrisStyle.typeScale
                    wrapMode: Text.WordWrap
                }
            }

            IrisText {
                visible: root.spec.kind === "range"
                text: Math.round(Number(root.value)) + (root.spec.unit ?? "")
                color: IrisStyle.subtext
                font.features: ({ "tnum": 1 })
                font.pixelSize: 12.5 * IrisStyle.typeScale
            }

            // Switch: accent track when on, white knob in both states.
            Rectangle {
                id: toggle
                visible: root.spec.kind === "switch"
                readonly property bool on: Boolean(root.value)
                implicitWidth: Math.round(40 * root.d)
                implicitHeight: Math.round(24 * root.d)
                radius: height / 2
                color: toggle.on ? IrisStyle.accent : ColorUtils.applyAlpha(IrisStyle.text, 0.16)
                Behavior on color { ColorAnimation { duration: IrisStyle.duration(140) } }
                Accessible.role: Accessible.CheckBox
                Accessible.name: Translation.tr(root.spec.label)
                Accessible.checked: toggle.on
                Rectangle {
                    y: 2 * root.d
                    x: toggle.on ? toggle.width - width - 2 * root.d : 2 * root.d
                    width: toggle.height - 4 * root.d
                    height: width
                    radius: width / 2
                    color: "#ffffff"
                    scale: toggleArea.pressed ? 0.9 : 1
                    Behavior on x { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
                    Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration } }
                }
                MouseArea {
                    id: toggleArea
                    anchors.fill: parent
                    anchors.margins: -6 * root.d
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Config.setNestedValue(root.spec.path, !toggle.on)
                }
            }

            Loader {
                active: root.inlineChoice
                visible: active
                Layout.preferredWidth: Math.round(Math.min(90 * root.choices.length, 270) * root.d)
                sourceComponent: segmentedComponent
            }
        }

        IrisScrubber {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(22 * root.d)
            visible: root.spec.kind === "range"
            knob: true
            fillColor: IrisStyle.accent
            trackColor: ColorUtils.applyAlpha(IrisStyle.text, 0.14)
            value: root.spec.kind === "range" ? (Number(root.value) - root.spec.min) / (root.spec.max - root.spec.min) : 0
            onMoved: next => {
                const step = root.spec.step ?? 1
                const value = Math.round((root.spec.min + next * (root.spec.max - root.spec.min)) / step) * step
                if (value !== Number(root.value)) Config.setNestedValue(root.spec.path, value)
            }
        }

        Loader {
            Layout.fillWidth: true
            active: root.spec.kind === "choice" && !root.inlineChoice
            visible: active
            sourceComponent: segmentedComponent
        }
    }

    // Hairline between rows, inset to the text column like grouped lists.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16 * root.d
        height: 1
        visible: !root.last
        color: IrisStyle.hairline
    }

    Component {
        id: segmentedComponent

        // One track, one selection that slides between choices.
        Rectangle {
            id: segmented
            readonly property int selectedIndex: root.choices.findIndex(choice => choice.value === root.value)
            implicitHeight: Math.round(28 * root.d)
            radius: height / 2
            color: ColorUtils.applyAlpha(IrisStyle.text, 0.08)
            Rectangle {
                visible: segmented.selectedIndex >= 0
                y: 2
                height: parent.height - 4
                width: (parent.width - 4) / Math.max(1, root.choices.length)
                x: 2 + width * Math.max(0, segmented.selectedIndex)
                radius: height / 2
                color: ColorUtils.applyAlpha(IrisStyle.text, 0.22)
                Behavior on x { NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
            }
            Row {
                anchors.fill: parent
                anchors.margins: 2
                Repeater {
                    model: root.choices
                    MouseArea {
                        id: segment
                        required property var modelData
                        required property int index
                        width: (segmented.width - 4) / Math.max(1, root.choices.length)
                        height: segmented.height - 4
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: Translation.tr(root.spec.label) + ": " + Translation.tr(segment.modelData.label)
                        Accessible.checked: segmented.selectedIndex === segment.index
                        onClicked: Config.setNestedValue(root.spec.path, segment.modelData.value)
                        IrisText {
                            anchors.centerIn: parent
                            text: Translation.tr(segment.modelData.label)
                            font.pixelSize: 12 * IrisStyle.typeScale
                            font.weight: segmented.selectedIndex === segment.index ? Font.DemiBold : Font.Normal
                            color: segmented.selectedIndex === segment.index ? IrisStyle.text : IrisStyle.subtext
                        }
                    }
                }
            }
        }
    }
}
