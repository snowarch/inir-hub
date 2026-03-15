pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

Item {
    id: root

    signal closed
    signal activateWindow(int windowId)

    required property var itemSnapshot
    property int selectedIndex: 0
    readonly property int skewSliceWidth: 126
    readonly property int skewExpandedWidth: 460
    readonly property int skewSliceHeight: 270
    readonly property int skewOffset: 24
    readonly property int skewSliceSpacing: -22
    readonly property int skewVisibleCount: Math.min(7, Math.max(1, itemSnapshot?.length ?? 1))
    readonly property int skewPanelWidth: Math.min(
        1100,
        root.skewExpandedWidth + Math.max(0, root.skewVisibleCount - 1) * (root.skewSliceWidth + root.skewSliceSpacing) + 40
    )

    // Config getters for live updates
    function cfg() { return Config.options?.waffles?.altSwitcher ?? {} }
    function getPreset() { return cfg().preset ?? "thumbnails" }
    function getThumbnailWidth() { return cfg().thumbnailWidth ?? 280 }
    function getThumbnailHeight() { return cfg().thumbnailHeight ?? 180 }

    // Reactive properties that update when config changes
    property string preset: getPreset()
    property int thumbnailWidth: getThumbnailWidth()
    property int thumbnailHeight: getThumbnailHeight()

    property int columns: Math.min(5, Math.max(1, itemSnapshot?.length ?? 1))

    // Update properties when config changes
    Connections {
        target: Config
        function onOptionsChanged() {
            root.preset = root.getPreset()
            root.thumbnailWidth = root.getThumbnailWidth()
            root.thumbnailHeight = root.getThumbnailHeight()
        }
    }

    implicitWidth: contentLoader.item?.implicitWidth ?? 400
    implicitHeight: contentLoader.item?.implicitHeight ?? 300

    property real contentOpacity: 0
    property real contentScale: 0.95

    Component.onCompleted: openAnim.start()

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "contentOpacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "contentScale"; from: 0.95; to: 1; duration: 200; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "contentOpacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "contentScale"; to: 0.95; duration: 150; easing.type: Easing.InCubic }
        }
        ScriptAction { script: root.closed() }
    }

    function close() { closeAnim.start() }

    Loader {
        id: contentLoader
        anchors.centerIn: parent
        opacity: root.contentOpacity
        scale: root.contentScale
        sourceComponent: {
            switch (root.preset) {
                case "compact": return compactPreset
                case "list": return listPreset
                case "skew": return skewPreset
                case "cards": return cardsPreset
                case "none": return nonePreset
                default: return thumbnailsPreset
            }
        }
    }

    // === PRESET: Thumbnails ===
    Component {
        id: thumbnailsPreset
        Column {
            spacing: 16
            Grid {
                columns: root.columns
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: ScriptModel { values: root.itemSnapshot }
                    WaffleAltSwitcherThumbnail {
                        required property var modelData
                        required property int index
                        item: modelData
                        selected: root.selectedIndex === index
                        thumbnailWidth: root.thumbnailWidth
                        thumbnailHeight: root.thumbnailHeight
                        onClicked: { root.selectedIndex = index; root.activateWindow(modelData.id) }
                    }
                }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: appNameText.implicitWidth + 32
                height: 36
                radius: Looks.radius.large
                color: Looks.colors.bg1Base
                WText {
                    id: appNameText
                    anchors.centerIn: parent
                    text: root.itemSnapshot?.[root.selectedIndex]?.appName ?? ""
                    font.pixelSize: Looks.font.pixelSize.large
                    color: Looks.colors.fg
                }
            }
        }
    }

    // === PRESET: Compact ===
    Component {
        id: compactPreset
        WPane {
            radius: Looks.radius.xLarge
            contentItem: Row {
                spacing: 4
                leftPadding: 8; rightPadding: 8; topPadding: 8; bottomPadding: 8
                Repeater {
                    model: ScriptModel { values: root.itemSnapshot }
                    WaffleAltSwitcherTile {
                        required property var modelData
                        required property int index
                        item: modelData
                        selected: root.selectedIndex === index
                        compact: true
                        onClicked: { root.selectedIndex = index; root.activateWindow(modelData.id) }
                    }
                }
            }
        }
    }

    // === PRESET: List ===
    Component {
        id: listPreset
        WPane {
            radius: Looks.radius.large

            contentItem: Column {
                spacing: 0

                RowLayout {
                    width: 400
                    height: 44

                    Item { width: 16 }
                    WText {
                        text: Translation.tr("Switch windows")
                        font.pixelSize: Looks.font.pixelSize.larger
                        font.weight: Looks.font.weight.strong
                        color: Looks.colors.fg
                    }
                    Item { Layout.fillWidth: true }
                    WText {
                        text: (root.itemSnapshot?.length ?? 0) + " " + Translation.tr("windows")
                        font.pixelSize: Looks.font.pixelSize.small
                        color: Looks.colors.subfg
                    }
                    Item { width: 16 }
                }

                WPanelSeparator { width: 400 }

                Column {
                    width: 400
                    topPadding: 8; bottomPadding: 8; leftPadding: 8; rightPadding: 8
                    spacing: 4

                    Repeater {
                        model: ScriptModel { values: root.itemSnapshot }
                        WaffleAltSwitcherTile {
                            required property var modelData
                            required property int index
                            width: 384
                            item: modelData
                            selected: root.selectedIndex === index
                            compact: false
                            onClicked: { root.selectedIndex = index; root.activateWindow(modelData.id) }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: skewPreset
        Item {
            implicitWidth: root.skewPanelWidth
            implicitHeight: skewDeck.height + skewLabel.height + 26

            ListView {
                id: skewDeck
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.skewPanelWidth
                height: root.skewSliceHeight
                currentIndex: root.selectedIndex
                orientation: ListView.Horizontal
                model: ScriptModel { values: root.itemSnapshot }
                spacing: root.skewSliceSpacing
                clip: false
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: root.skewExpandedWidth * 3
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 180
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: (width - root.skewExpandedWidth) / 2
                preferredHighlightEnd: (width + root.skewExpandedWidth) / 2
                header: Item { width: Math.max(0, (skewDeck.width - root.skewExpandedWidth) / 2); height: 1 }
                footer: Item { width: Math.max(0, (skewDeck.width - root.skewExpandedWidth) / 2); height: 1 }

                delegate: Item {
                    id: skewSlice
                    required property var modelData
                    required property int index
                    width: ListView.isCurrentItem ? root.skewExpandedWidth : root.skewSliceWidth
                    height: skewDeck.height
                    z: ListView.isCurrentItem ? 100 : 50 - Math.min(Math.abs(index - root.selectedIndex), 50)
                    scale: ListView.isCurrentItem ? 1.0 : 0.93
                    opacity: ListView.isCurrentItem ? 1.0 : 0.82
                    y: ListView.isCurrentItem ? 0 : 10

                    transform: Rotation {
                        origin.x: skewSlice.index < root.selectedIndex ? skewSlice.width : 0
                        origin.y: skewSlice.height / 2
                        axis.x: 0
                        axis.y: 1
                        axis.z: 0
                        angle: ListView.isCurrentItem ? 0 : (skewSlice.index < root.selectedIndex ? 12 : -12)
                    }

                    property string previewUrl: ""

                    function refreshPreview(): void {
                        if (modelData?.id === undefined)
                            return
                        const url = WindowPreviewService.getPreviewUrl(modelData.id)
                        if (url && url.length > 0)
                            previewUrl = url
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Looks.transition.enabled ? Looks.transition.duration.panel : 0
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Looks.transition.enabled ? Looks.transition.duration.panel : 0
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Looks.transition.enabled ? Looks.transition.duration.panel : 0
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate
                        }
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: Looks.transition.enabled ? Looks.transition.duration.panel : 0
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate
                        }
                    }

                    Component.onCompleted: Qt.callLater(() => skewSlice.refreshPreview())

                    Connections {
                        target: WindowPreviewService
                        function onPreviewUpdated(updatedId: int): void {
                            if (updatedId === skewSlice.modelData?.id)
                                skewSlice.previewUrl = WindowPreviewService.getPreviewUrl(updatedId)
                        }
                        function onCaptureComplete(): void {
                            skewSlice.refreshPreview()
                        }
                    }

                    Item {
                        id: maskedBody
                        anchors.fill: parent
                        layer.enabled: true
                        layer.smooth: true
                        layer.samples: 4
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: ShaderEffectSource {
                                sourceItem: Item {
                                    width: maskedBody.width
                                    height: maskedBody.height
                                    layer.enabled: true
                                    layer.smooth: true
                                    layer.samples: 8

                                    Shape {
                                        anchors.fill: parent
                                        antialiasing: true
                                        preferredRendererType: Shape.CurveRenderer

                                        ShapePath {
                                            fillColor: "white"
                                            strokeColor: "transparent"
                                            startX: root.skewOffset
                                            startY: 0
                                            PathLine { x: skewSlice.width; y: 0 }
                                            PathLine { x: skewSlice.width - root.skewOffset; y: skewSlice.height }
                                            PathLine { x: 0; y: skewSlice.height }
                                            PathLine { x: root.skewOffset; y: 0 }
                                        }
                                    }
                                }
                            }
                            maskThresholdMin: 0.3
                            maskSpreadAtMin: 0.3
                        }

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Looks.colors.bg2 }
                                GradientStop { position: 1.0; color: Looks.colors.bg1Base }
                            }
                        }

                        Image {
                            id: previewImage
                            anchors.fill: parent
                            source: skewSlice.previewUrl
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                            cache: false
                            visible: status === Image.Ready && source.toString().length > 0
                            sourceSize.width: root.skewExpandedWidth
                            sourceSize.height: root.skewSliceHeight
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: previewImage.visible
                                ? Qt.rgba(0, 0, 0, ListView.isCurrentItem ? 0.10 : 0.42)
                                : Qt.rgba(0, 0, 0, ListView.isCurrentItem ? 0.12 : 0.24)
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: 14
                            anchors.leftMargin: root.skewOffset + 10
                            width: 42
                            height: 42
                            radius: Looks.radius.large
                            color: ColorUtils.transparentize(Looks.colors.bg0Opaque, 0.18)
                            border.width: 1
                            border.color: Looks.colors.bg2Border

                            Image {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                source: skewSlice.modelData?.icon ?? ""
                                sourceSize: Qt.size(24, 24)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: ListView.isCurrentItem ? 74 : 44
                            height: width
                            source: skewSlice.modelData?.icon ?? ""
                            sourceSize: Qt.size(width, height)
                            fillMode: Image.PreserveAspectFit
                            visible: !previewImage.visible
                            smooth: true
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: root.skewOffset + 10
                            anchors.bottomMargin: 10
                            visible: (skewSlice.modelData?.workspaceIdx ?? 0) > 0
                            width: wsBadgeText.implicitWidth + 12
                            height: 24
                            radius: Looks.radius.medium
                            color: ColorUtils.transparentize(Looks.colors.bg0Opaque, 0.18)
                            border.width: 1
                            border.color: Looks.colors.bg2Border

                            WText {
                                id: wsBadgeText
                                anchors.centerIn: parent
                                text: Translation.tr("WS") + " " + (skewSlice.modelData?.workspaceIdx ?? "")
                                font.pixelSize: Looks.font.pixelSize.small
                                color: Looks.colors.fg
                            }
                        }
                    }

                    Shape {
                        anchors.fill: parent
                        antialiasing: true
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: ListView.isCurrentItem ? Looks.colors.accent : Looks.colors.bg2Border
                            strokeWidth: ListView.isCurrentItem ? 3 : 1
                            startX: root.skewOffset
                            startY: 0
                            PathLine { x: skewSlice.width; y: 0 }
                            PathLine { x: skewSlice.width - root.skewOffset; y: skewSlice.height }
                            PathLine { x: 0; y: skewSlice.height }
                            PathLine { x: root.skewOffset; y: 0 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.selectedIndex = index
                            root.activateWindow(modelData.id)
                        }
                    }
                }
            }

            Rectangle {
                id: skewLabel
                anchors.top: skewDeck.bottom
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(260, skewLabelRow.implicitWidth + 30)
                height: 52
                radius: Looks.radius.large
                color: Looks.colors.bgPanelFooter
                border.width: 1
                border.color: Looks.colors.bg2Border

                WRectangularShadow {
                    target: parent
                }

                RowLayout {
                    id: skewLabelRow
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Image {
                        Layout.alignment: Qt.AlignVCenter
                        width: 22
                        height: 22
                        source: root.itemSnapshot?.[root.selectedIndex]?.icon ?? ""
                        sourceSize: Qt.size(22, 22)
                        fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        WText {
                            Layout.fillWidth: true
                            text: root.itemSnapshot?.[root.selectedIndex]?.appName ?? root.itemSnapshot?.[root.selectedIndex]?.title ?? "Window"
                            font.pixelSize: Looks.font.pixelSize.normal
                            font.weight: Looks.font.weight.strong
                            color: Looks.colors.fg
                            elide: Text.ElideRight
                        }

                        WText {
                            Layout.fillWidth: true
                            text: root.itemSnapshot?.[root.selectedIndex]?.title ?? ""
                            visible: text !== "" && text !== (root.itemSnapshot?.[root.selectedIndex]?.appName ?? "")
                            font.pixelSize: Looks.font.pixelSize.small
                            color: Looks.colors.subfg
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // === PRESET: None (no UI, just switch) ===
    Component {
        id: nonePreset
        Item {
            implicitWidth: 1
            implicitHeight: 1
            visible: false
        }
    }


    // === PRESET: Cards (Fluent-style with shadows and acrylic) ===
    Component {
        id: cardsPreset
        Item {
            implicitWidth: cardsRow.width
            implicitHeight: cardsRow.height + selectedLabel.height + 24

            Row {
                id: cardsRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Repeater {
                    model: ScriptModel { values: root.itemSnapshot }

                    Item {
                        required property var modelData
                        required property int index
                        width: 180
                        height: 200

                        // Shadow behind card
                        WRectangularShadow {
                            target: cardPane
                        }

                        // Main card using WPane
                        Rectangle {
                            id: cardPane
                            anchors.fill: parent
                            radius: Looks.radius.large
                            color: root.selectedIndex === index ? Looks.colors.accent : Looks.colors.bgPanelFooter
                            border.width: root.selectedIndex === index ? 0 : 1
                            border.color: Looks.colors.bg2Border
                            scale: cardMouse.pressed ? 0.95 : (cardMouse.containsMouse ? 1.02 : 1.0)
                            
                            Behavior on scale {
                                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }
                            Behavior on color {
                                animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                // Icon area with gradient background
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: Looks.radius.medium
                                    color: root.selectedIndex === index 
                                        ? ColorUtils.transparentize(Looks.colors.accentFg, 0.9)
                                        : Looks.colors.bg1Base

                                    Image {
                                        anchors.centerIn: parent
                                        width: 72
                                        height: 72
                                        source: modelData?.icon ?? ""
                                        sourceSize: Qt.size(72, 72)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }
                                }

                                // App name
                                WText {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData?.appName ?? "Window"
                                    font.pixelSize: Looks.font.pixelSize.normal
                                    font.weight: Looks.font.weight.strong
                                    color: root.selectedIndex === index ? Looks.colors.accentFg : Looks.colors.fg
                                    elide: Text.ElideMiddle
                                }

                                // Workspace indicator
                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    visible: (modelData?.workspaceIdx ?? 0) > 0
                                    width: wsCardText.implicitWidth + 12
                                    height: 20
                                    radius: Looks.radius.small
                                    color: root.selectedIndex === index 
                                        ? ColorUtils.transparentize(Looks.colors.accentFg, 0.8)
                                        : Looks.colors.bg2

                                    WText {
                                        id: wsCardText
                                        anchors.centerIn: parent
                                        text: Translation.tr("WS") + " " + (modelData?.workspaceIdx ?? "")
                                        font.pixelSize: Looks.font.pixelSize.small
                                        color: root.selectedIndex === index ? Looks.colors.accentFg : Looks.colors.subfg
                                    }
                                }
                            }

                            // Selection indicator at bottom
                            Rectangle {
                                visible: root.selectedIndex === index
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 8
                                width: 32
                                height: 4
                                radius: 2
                                color: Looks.colors.accentFg
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.selectedIndex = index
                                root.activateWindow(modelData.id)
                            }
                        }
                    }
                }
            }

            // Window title label
            Rectangle {
                id: selectedLabel
                anchors.top: cardsRow.bottom
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(titleLabelText.implicitWidth + 40, 200)
                height: 44
                radius: Looks.radius.large
                color: Looks.colors.bgPanelFooter
                border.width: 1
                border.color: Looks.colors.bg2Border

                WRectangularShadow {
                    target: parent
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Image {
                        width: 24
                        height: 24
                        source: root.itemSnapshot?.[root.selectedIndex]?.icon ?? ""
                        sourceSize: Qt.size(24, 24)
                        fillMode: Image.PreserveAspectFit
                    }

                    WText {
                        id: titleLabelText
                        text: root.itemSnapshot?.[root.selectedIndex]?.title ?? ""
                        font.pixelSize: Looks.font.pixelSize.normal
                        color: Looks.colors.fg
                        elide: Text.ElideMiddle
                        Layout.maximumWidth: 350
                    }
                }
            }
        }
    }
}
