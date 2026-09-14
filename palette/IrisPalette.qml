pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

PanelWindow {
    id: root

    readonly property var options: Config.options?.iris?.palette ?? ({})
    readonly property int configuredResultLimit: Math.max(3, Math.min(14, Number(root.options?.maxResults ?? 8)))
    readonly property int heightResultLimit: Math.max(3, Math.floor(
        Math.max(180, ((root.screen?.height ?? 1080) * 0.72) - (120 * IrisStyle.density))
        / Math.max(42, 50 * IrisStyle.density)))
    readonly property int resultLimit: Math.min(root.configuredResultLimit, root.heightResultLimit)
    readonly property var visibleResults: (LauncherSearch.results ?? []).slice(0, root.resultLimit)
    property int selectedIndex: 0

    visible: GlobalStates.searchOpen
    screen: GlobalStates.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-palette"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }

    onVisibleChanged: {
        if (visible) {
            root.selectedIndex = 0
            Qt.callLater(() => searchInput.forceActiveFocus())
        } else {
            LauncherSearch.query = ""
        }
    }

    Connections {
        target: LauncherSearch
        function onQueryChanged(): void { root.selectedIndex = 0 }
    }

    function executeSelected(): void {
        const entry = root.visibleResults[root.selectedIndex]
        if (!entry || typeof entry.execute !== "function") return
        entry.execute()
        GlobalStates.searchOpen = false
    }

    Rectangle {
        anchors.fill: parent
        color: IrisStyle.scrim
        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.searchOpen = false
        }
    }

    IrisSurface {
        id: paletteSurface
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(72, Math.round(parent.height * 0.16))
        width: Math.max(280, Math.min(parent.width - 32,
            Math.max(440, Number(root.options?.width ?? 640) * IrisStyle.density)))
        height: content.implicitHeight + IrisStyle.panelPadding * 2
        raised: true
        radius: IrisStyle.radius

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: IrisStyle.panelPadding
            spacing: 12 * IrisStyle.density

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: IrisStyle.headerHeight

                IrisSectionHeader {
                    id: paletteHeader
                    anchors.fill: parent
                    icon: "search"
                    eyebrow: "IRIS / PALETTE"
                    title: Translation.tr("Find anything")
                    subtitle: LauncherSearch.query.length > 0
                        ? Translation.tr("Search results")
                        : Translation.tr("Apps, actions, clipboard and math")
                    indexText: String(root.visibleResults.length).padStart(2, "0")
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: 52 * IrisStyle.density

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 2 * IrisStyle.density
                    anchors.rightMargin: 2 * IrisStyle.density
                    spacing: 8 * IrisStyle.density

                    Rectangle {
                        visible: !IrisStyle.island
                        Layout.preferredWidth: 3 * IrisStyle.density
                        Layout.preferredHeight: 30 * IrisStyle.density
                        radius: width / 2
                        color: IrisStyle.accent
                    }

                    IrisField {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: LauncherSearch.query
                        placeholderText: Translation.tr("Search or type a command…")
                        font.pixelSize: 17 * IrisStyle.typeScale
                        focus: true
                        onTextChanged: {
                            if (LauncherSearch.query !== text) LauncherSearch.query = text
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                GlobalStates.searchOpen = false
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                root.selectedIndex = Math.min(root.visibleResults.length - 1, root.selectedIndex + 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.executeSelected()
                                event.accepted = true
                            }
                        }
                    }

                    IrisKey {
                        visible: root.options?.showHints ?? true
                        key: "ESC"
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: root.visibleResults
                    IrisButton {
                        id: resultButton
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 54 * IrisStyle.density
                        selected: index === root.selectedIndex
                        quiet: !selected
                        onClicked: {
                            root.selectedIndex = index
                            root.executeSelected()
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            width: resultButton.width - 16 * IrisStyle.density
                            spacing: 10 * IrisStyle.density

                            Rectangle {
                                Layout.preferredWidth: 3 * IrisStyle.density
                                Layout.preferredHeight: 28 * IrisStyle.density
                                radius: width / 2
                                color: resultButton.selected ? IrisStyle.accent : "transparent"
                            }

                            Item {
                                Layout.preferredWidth: 28 * IrisStyle.density
                                Layout.preferredHeight: 28 * IrisStyle.density

                                Loader {
                                    anchors.centerIn: parent
                                    width: 24 * IrisStyle.density
                                    height: width
                                    active: resultButton.modelData?.iconType === LauncherSearchResult.IconType.System
                                    sourceComponent: SmartAppIcon {
                                        icon: resultButton.modelData?.iconName ?? "application-x-executable"
                                        fallback: "application-x-executable"
                                        iconSize: Math.round(24 * IrisStyle.density)
                                    }
                                }
                                Loader {
                                    anchors.centerIn: parent
                                    width: 22 * IrisStyle.density
                                    height: width
                                    active: resultButton.modelData?.iconType === LauncherSearchResult.IconType.Text
                                    sourceComponent: IrisText {
                                        text: resultButton.modelData?.iconName ?? ""
                                        font.pixelSize: 20 * IrisStyle.typeScale
                                        horizontalAlignment: Text.AlignHCenter
                                        color: resultButton.selected ? IrisStyle.accent : IrisStyle.subtext
                                    }
                                }
                                Loader {
                                    anchors.centerIn: parent
                                    width: 22 * IrisStyle.density
                                    height: width
                                    active: resultButton.modelData?.iconType !== LauncherSearchResult.IconType.System
                                        && resultButton.modelData?.iconType !== LauncherSearchResult.IconType.Text
                                    sourceComponent: MaterialSymbol {
                                        text: resultButton.modelData?.iconName || "search"
                                        iconSize: Math.round(21 * IrisStyle.density)
                                        color: resultButton.selected ? IrisStyle.accent : IrisStyle.subtext
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                IrisText {
                                    Layout.fillWidth: true
                                    text: resultButton.modelData?.name ?? ""
                                    font.family: IrisStyle.fontTitle
                                    font.pixelSize: 14 * IrisStyle.typeScale
                                    font.weight: resultButton.selected ? Font.Bold : Font.DemiBold
                                    color: resultButton.selected ? IrisStyle.text : IrisStyle.text
                                    elide: Text.ElideRight
                                }
                                IrisText {
                                    Layout.fillWidth: true
                                    visible: text.length > 0
                                    text: resultButton.modelData?.comment || resultButton.modelData?.type || ""
                                    font.pixelSize: 11 * IrisStyle.typeScale
                                    color: IrisStyle.subtext
                                    elide: Text.ElideRight
                                }
                            }

                            IrisKey { key: resultButton.modelData?.verb ?? ""; visible: key.length > 0 }
                        }
                    }
                }

                Item {
                    visible: LauncherSearch.query.length > 0 && root.visibleResults.length === 0
                    Layout.fillWidth: true
                    implicitHeight: 56 * IrisStyle.density
                    IrisText {
                        anchors.centerIn: parent
                        text: Translation.tr("No results")
                        color: IrisStyle.subtext
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2 * IrisStyle.density
                visible: root.options?.showHints ?? true
                spacing: 12 * IrisStyle.density
                IrisKey { key: "/" }
                IrisText { text: Translation.tr("actions"); role: IrisText.Meta }
                IrisKey { key: ";" }
                IrisText { text: Translation.tr("clipboard"); role: IrisText.Meta }
                IrisKey { key: "=" }
                IrisText { text: Translation.tr("math"); role: IrisText.Meta }
                Item { Layout.fillWidth: true }
                IrisKey { key: "↑↓" }
                IrisKey { key: "ENTER" }
            }
        }
    }
}
