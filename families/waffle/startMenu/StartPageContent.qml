pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

// Waffle Next Start: one sheet under the search. Pinned apps on soft tiles, what is open now as cards under them, and
// the places people go from Start (their account, files, settings, power) along the footer.
WPanelPageColumn {
    id: root

    signal allAppsClicked()

    property list<string> pinnedApps: Config.options?.apps?.pinned ?? []
    // what is open now, one card per app, from the taskbar's own list: it knows every compositor's windows
    readonly property var openApps: TaskbarApps.apps.filter(app => (app?.toplevels?.length ?? 0) > 0).slice(0, 4)

    function close(): void {
        GlobalStates.searchOpen = false
    }

    function focusApp(app: var): void {
        const toplevel = app?.toplevels?.[0] ?? null
        const niriId = Number(toplevel?.niriWindowId ?? -1)
        if (CompositorService.isNiri && niriId > 0)
            NiriService.focusWindow(niriId)
        else
            toplevel?.activate()
        root.close()
    }

    BodyRectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: Looks.dp(24)
            anchors.rightMargin: Looks.dp(24)
            anchors.topMargin: Looks.dp(4)
            anchors.bottomMargin: Looks.dp(18)
            spacing: Looks.dp(10)

            RowLayout {
                Layout.fillWidth: true
                SectionTitle { text: Translation.tr("Pinned") }
                Item { Layout.fillWidth: true }
                WBorderlessButton {
                    implicitHeight: Looks.dp(28)
                    implicitWidth: allAppsRow.implicitWidth + Looks.dp(24)
                    radius: height / 2
                    colBackground: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.06 : 0.05)
                    contentItem: Item {
                        RowLayout {
                            id: allAppsRow
                            anchors.centerIn: parent
                            spacing: Looks.dp(6)
                            WText { text: Translation.tr("All apps"); font.pixelSize: Looks.font.pixelSize.normal }
                            FluentIcon { icon: "chevron-right"; implicitSize: Looks.dp(12) }
                        }
                    }
                    onClicked: root.allAppsClicked()
                }
            }

            // Flow reflows when Start resizes; the wrapper centres a row the columns don't fill
            Item {
                Layout.fillWidth: true
                implicitHeight: pinnedFlow.implicitHeight

                Flow {
                    id: pinnedFlow
                    readonly property int cellWidth: Looks.dp(90) + spacing
                    // six across, as Windows has them; fewer when Start is narrow
                    readonly property int maxCols: Math.max(1, Math.min(6, Math.floor((parent.width + spacing) / cellWidth)))
                    width: Math.min(parent.width, maxCols * cellWidth - spacing)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Looks.dp(2)

                    Repeater {
                        model: root.pinnedApps.slice(0, 18)
                        delegate: AppTile {
                            required property string modelData
                            required property int index
                            appId: modelData
                            animIndex: index
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            SectionTitle { text: Translation.tr("Recommended") }

            GridLayout {
                visible: root.openApps.length > 0
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Looks.dp(6)
                columnSpacing: Looks.dp(8)

                Repeater {
                    model: root.openApps
                    delegate: OpenCard {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        app: modelData
                        animIndex: index
                    }
                }
            }

            // nothing open yet: the place says what will come to it
            Rectangle {
                visible: root.openApps.length === 0
                Layout.fillWidth: true
                implicitHeight: Looks.dp(52)
                radius: Looks.radius.large
                color: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.04 : 0.03)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Looks.dp(8)
                    FluentIcon { icon: "apps"; implicitSize: Looks.dp(16); color: Looks.colors.subfg }
                    WText {
                        text: Translation.tr("Apps you open show up here")
                        color: Looks.colors.subfg
                    }
                }
            }
        }
    }

    WPanelSeparator {}

    StartFooter { Layout.fillWidth: true }

    component SectionTitle: WText {
        font.pixelSize: Looks.font.pixelSize.large
        font.weight: Font.DemiBold
    }

    component AppTile: WBorderlessButton {
        id: tile
        required property string appId
        property int animIndex: 0
        readonly property var de: DesktopEntries.heuristicLookup(appId)
        implicitWidth: Looks.dp(90)
        implicitHeight: Looks.dp(84)
        radius: Looks.radius.large
        onClicked: { if (tile.de) AppSearch.launchEntry(tile.de); root.close() }

        // the tiles arrive one after another
        opacity: 0
        scale: 0.85
        Component.onCompleted: {
            if (Looks.transition.enabled) {
                tileEntry.start()
            } else {
                opacity = 1
                scale = 1
            }
        }
        SequentialAnimation {
            id: tileEntry
            PauseAnimation { duration: Looks.transition.staggerDelay(tile.animIndex, 22) }
            ParallelAnimation {
                NumberAnimation { target: tile; property: "opacity"; to: 1; duration: Looks.transition.duration.normal; easing.type: Easing.OutQuad }
                NumberAnimation { target: tile; property: "scale"; to: 1; duration: Looks.transition.duration.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
            }
        }

        contentItem: ColumnLayout {
            anchors.centerIn: parent
            spacing: Looks.dp(6)
            // a theme that ships an icon only at 16 px would draw it at 16: the box is fixed
            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Looks.dp(36)
                Layout.preferredHeight: Looks.dp(36)
                fillMode: Image.PreserveAspectFit
                source: AppSearch.getIconSource(tile.appId, "application-x-executable")
                sourceSize: Qt.size(Looks.dp(36), Looks.dp(36))
                smooth: true
                mipmap: true
                scale: tile.down ? 0.92 : tile.hovered ? 1.06 : 1
                Behavior on scale {
                    animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                }
            }
            // one line, as Windows 11 does: a second line ran into the row below
            WText {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Looks.dp(82)
                text: tile.de?.name ?? tile.appId
                font.pixelSize: Looks.font.pixelSize.small
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
        WToolTip { text: tile.de?.name ?? tile.appId }
    }

    component OpenCard: WBorderlessButton {
        id: card
        required property var app
        property int animIndex: 0
        readonly property string appId: card.app?.appId ?? ""
        readonly property var de: DesktopEntries.heuristicLookup(card.appId)
        implicitHeight: Looks.dp(56)
        radius: Looks.radius.large
        leftPadding: Looks.dp(10)
        rightPadding: Looks.dp(14)
        colBackground: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.04 : 0.03)
        onClicked: root.focusApp(card.app)

        // the cards slide in after the tiles
        opacity: 0
        transform: Translate { id: cardShift; y: Looks.dp(8) }
        Component.onCompleted: {
            if (Looks.transition.enabled) {
                cardEntry.start()
            } else {
                opacity = 1
                cardShift.y = 0
            }
        }
        SequentialAnimation {
            id: cardEntry
            PauseAnimation { duration: 160 + Looks.transition.staggerDelay(card.animIndex, 40) }
            ParallelAnimation {
                NumberAnimation { target: card; property: "opacity"; to: 1; duration: Looks.transition.duration.normal; easing.type: Easing.OutQuad }
                NumberAnimation { target: cardShift; property: "y"; to: 0; duration: Looks.transition.duration.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
            }
        }

        contentItem: RowLayout {
            spacing: Looks.dp(12)
            Rectangle {
                Layout.preferredWidth: Looks.dp(36)
                Layout.preferredHeight: Looks.dp(36)
                radius: Looks.radius.medium
                color: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.06 : 0.05)
                Image {
                    anchors.centerIn: parent
                    width: Looks.dp(24)
                    height: Looks.dp(24)
                    fillMode: Image.PreserveAspectFit
                    source: AppSearch.getIconSource(card.appId, "application-x-executable")
                    sourceSize: Qt.size(Looks.dp(24), Looks.dp(24))
                    smooth: true
                    mipmap: true
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                WText {
                    Layout.fillWidth: true
                    text: card.de?.name ?? card.appId
                    font.pixelSize: Looks.font.pixelSize.normal
                    elide: Text.ElideRight
                }
                WText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    // the first line that says more than the name: pavucontrol's generic name is its name
                    text: [card.de?.genericName, card.de?.comment].find(s => !!s && s !== card.de?.name) ?? ""
                    color: Looks.colors.subfg
                    font.pixelSize: Looks.font.pixelSize.small
                    elide: Text.ElideRight
                }
            }
            // it runs: the dot the taskbar draws under it
            Rectangle {
                Layout.preferredWidth: Looks.dp(6)
                Layout.preferredHeight: Looks.dp(6)
                radius: width / 2
                color: Looks.colors.accent
            }
        }
        WToolTip { text: card.de?.name ?? card.appId }
    }

    component StartFooter: FooterRectangle {
        implicitHeight: Looks.dp(60)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Looks.dp(28)
            anchors.rightMargin: Looks.dp(28)
            spacing: Looks.dp(4)

            UserButton {}
            Item { Layout.fillWidth: true }
            FooterButton {
                iconName: "folder"
                tip: Translation.tr("Files")
                onClicked: { Qt.openUrlExternally(Directories.home); root.close() }
            }
            FooterButton {
                iconName: "settings"
                tip: Translation.tr("Settings")
                onClicked: { Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"]); root.close() }
            }
            PowerButton {}
        }
    }

    component FooterButton: WBorderlessButton {
        id: footerButton
        property string iconName
        property string tip
        implicitWidth: Looks.dp(40)
        implicitHeight: Looks.dp(40)
        contentItem: Item {
            FluentIcon {
                anchors.centerIn: parent
                icon: footerButton.iconName
                implicitSize: Looks.dp(18)
            }
        }
        WToolTip { text: footerButton.tip }
    }

    component UserButton: WBorderlessButton {
        id: userButton
        implicitWidth: userButtonRow.implicitWidth + Looks.dp(20)
        implicitHeight: Looks.dp(42)
        radius: height / 2

        contentItem: Item {
            RowLayout {
                id: userButtonRow
                anchors.centerIn: parent
                spacing: Looks.dp(10)
                WUserAvatar { sourceSize: Qt.size(Looks.dp(30), Looks.dp(30)) }
                WText {
                    Layout.alignment: Qt.AlignVCenter
                    text: SystemInfo.displayName || SystemInfo.username
                }
            }
        }

        onPressed: { if (userMenu.visible) userMenu.close(); else if (Date.now() - userMenu.closedAt > 250) userMenu.open() }
        WToolTip { text: SystemInfo.displayName || SystemInfo.username }

        Popup {
            id: userMenu
            property double closedAt: 0
            onClosed: userMenu.closedAt = Date.now()
            x: -Looks.dp(4)
            y: -userMenu.implicitHeight - Looks.dp(6)
            background: null

            WToolTipContent {
                id: popupContent
                horizontalPadding: 10
                verticalPadding: 7
                radius: Looks.radius.large
                realContentItem: Item {
                    implicitWidth: userMenuContentLayout.implicitWidth
                    implicitHeight: userMenuContentLayout.implicitHeight

                    ColumnLayout {
                        id: userMenuContentLayout
                        anchors {
                            fill: parent
                            leftMargin: popupContent.horizontalPadding
                            rightMargin: popupContent.horizontalPadding
                            topMargin: popupContent.verticalPadding
                            bottomMargin: popupContent.verticalPadding
                        }
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 6
                            FluentIcon {
                                Layout.alignment: Qt.AlignVCenter
                                implicitSize: 22
                                icon: "corporation"
                                monochrome: false
                            }
                            WText {
                                Layout.alignment: Qt.AlignVCenter
                                // `hostname` is "" until /etc/hostname resolves, and `??` does not catch "":
                                // the label would render blank on the first frame
                                text: SystemInfo.hostname || "Computer"
                                font.pixelSize: Looks.font.pixelSize.large
                                font.weight: Looks.font.weight.strong
                            }
                            Item { Layout.fillWidth: true }
                            WBorderlessButton {
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: 36
                                implicitWidth: signOutText.implicitWidth + 20
                                contentItem: WText {
                                    id: signOutText
                                    text: Translation.tr("Sign out")
                                    font.pixelSize: Looks.font.pixelSize.large
                                }
                                onClicked: Session.logout()
                            }
                        }

                        Item { implicitWidth: 334 }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 7
                            Layout.leftMargin: 6
                            spacing: 12
                            WUserAvatar { sourceSize: Qt.size(58, 58) }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                WText {
                                    text: SystemInfo.displayName || SystemInfo.username
                                    font.pixelSize: Looks.font.pixelSize.larger
                                    font.weight: Looks.font.weight.strong
                                }
                                WText {
                                    color: Looks.colors.fg1
                                    text: Translation.tr("Local account")
                                }
                                WText {
                                    color: Looks.colors.accent
                                    text: Translation.tr("Manage my account")
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            AppLauncher.launch("manageUser")
                                            root.close()
                                            userMenu.close()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component PowerButton: WBorderlessButton {
        id: powerButton
        implicitWidth: Looks.dp(40)
        implicitHeight: Looks.dp(40)

        contentItem: Item {
            FluentIcon {
                anchors.centerIn: parent
                icon: "power"
                implicitSize: Looks.dp(18)
            }
        }

        WToolTip { text: Translation.tr("Power") }
        onPressed: { if (powerMenu.visible) powerMenu.close(); else if (Date.now() - powerMenu.closedAt > 250) powerMenu.open() }

        WMenu {
            id: powerMenu
            property double closedAt: 0
            onClosed: powerMenu.closedAt = Date.now()
            x: -powerMenu.implicitWidth / 2 + powerButton.implicitWidth / 2
            y: -powerMenu.implicitHeight - 4
            Action { icon.name: "lock-closed"; text: Translation.tr("Lock"); onTriggered: Session.lock() }
            Action { icon.name: "weather-moon"; text: Translation.tr("Sleep"); onTriggered: Session.suspend() }
            Action { icon.name: "power"; text: Translation.tr("Shut down"); onTriggered: Session.poweroff() }
            Action { icon.name: "arrow-counterclockwise"; text: Translation.tr("Restart"); onTriggered: Session.reboot() }
        }
    }
}
