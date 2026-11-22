pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

// Every app, A to Z. A letter opens the alphabet to jump through the list; what is pinned wears a dot, and a right
// click pins or unpins it. Typing goes to the search above, so this page holds no search of its own.
WPanelPageColumn {
    id: root
    signal back()

    // true while the alphabet covers the list
    property bool jumping: false
    property var menuEntry: null

    readonly property var pinnedIds: (Config.options?.apps?.pinned ?? []).map(p => String(p).toLowerCase())
    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => (a.name || "").localeCompare(b.name || ""))

    // [{letter: "A", apps: [...]}, ...]; names that start with a digit or a sign go under #
    // one group per letter even where the collation interleaves É with E
    readonly property var groupedApps: {
        const groups = []
        const byLetter = {}
        for (const app of root.apps) {
            const letter = root.letterOf(app.name)
            if (!byLetter[letter]) {
                byLetter[letter] = { letter: letter, apps: [] }
                groups.push(byLetter[letter])
            }
            byLetter[letter].apps.push(app)
        }
        return groups
    }
    readonly property var usedLetters: root.groupedApps.map(g => g.letter)
    // the whole alphabet, so a letter with no app sits there dimmed, plus any letter of another script that is in use
    readonly property var alphabet: {
        const base = "#ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("")
        return base.concat(root.usedLetters.filter(l => !base.includes(l)))
    }

    // É files under E and ß under S: the accent goes, and an upper case of two letters keeps its first
    function letterOf(name: string): string {
        const c = (name || "#").charAt(0).normalize("NFD").charAt(0).toUpperCase().charAt(0)
        return c.toLowerCase() === c ? "#" : c
    }

    function isPinned(entry: var): bool {
        return root.pinnedIds.includes(String(entry?.id ?? "").toLowerCase())
    }

    function launch(entry: var): void {
        AppSearch.launchEntry(entry)
        GlobalStates.searchOpen = false
    }

    function jumpTo(letter: string): void {
        root.jumping = false
        const children = appsColumn.children
        for (let i = 0; i < children.length; i++) {
            if (children[i].objectName !== "section_" + letter)
                continue
            scrollAnim.stop()
            scrollAnim.from = appsFlickable.contentY
            scrollAnim.to = Math.min(children[i].y, Math.max(0, appsFlickable.contentHeight - appsFlickable.height))
            scrollAnim.start()
            return
        }
    }

    // Esc closes the alphabet first, then leaves the page
    function leave(): void {
        if (root.jumping)
            root.jumping = false
        else
            root.back()
    }

    BodyRectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: Looks.dp(16)
            anchors.rightMargin: Looks.dp(10)
            anchors.topMargin: Looks.dp(2)
            anchors.bottomMargin: Looks.dp(10)
            spacing: Looks.dp(6)

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Looks.dp(4)
                Layout.rightMargin: Looks.dp(10)
                spacing: Looks.dp(10)

                WBorderlessButton {
                    implicitWidth: Looks.dp(32)
                    implicitHeight: Looks.dp(32)
                    radius: height / 2
                    colBackground: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.06 : 0.05)
                    contentItem: Item {
                        FluentIcon { anchors.centerIn: parent; icon: "chevron-left"; implicitSize: Looks.dp(14) }
                    }
                    onClicked: root.back()
                    WToolTip { text: Translation.tr("Back") }
                }
                WText {
                    text: Translation.tr("All apps")
                    font.pixelSize: Looks.font.pixelSize.larger
                    font.weight: Looks.font.weight.strong
                }
                Item { Layout.fillWidth: true }
                WText {
                    text: Translation.tr("%1 apps").arg(root.apps.length)
                    color: Looks.colors.subfg
                    font.pixelSize: Looks.font.pixelSize.small
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: appsFlickable
                    anchors.fill: parent
                    contentHeight: appsColumn.implicitHeight
                    clip: true
                    interactive: !root.jumping
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: WScrollBar {}
                    // the list steps back while the alphabet is over it
                    opacity: root.jumping ? 0.08 : 1
                    scale: root.jumping ? 0.98 : 1
                    Behavior on opacity { NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.OutQuad } }
                    Behavior on scale { NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate } }

                    NumberAnimation {
                        id: scrollAnim
                        target: appsFlickable
                        property: "contentY"
                        duration: Looks.transition.enabled ? 260 : 0
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate
                    }

                    Column {
                        id: appsColumn
                        width: appsFlickable.width - Looks.dp(6)
                        spacing: Looks.dp(4)

                        Repeater {
                            model: root.groupedApps

                            delegate: Column {
                                id: section
                                required property var modelData
                                required property int index
                                objectName: "section_" + modelData.letter
                                width: appsColumn.width
                                spacing: Looks.dp(2)

                                // the sections arrive top to bottom, as one sheet
                                opacity: 0
                                transform: Translate { id: sectionShift; y: Looks.dp(10) }
                                Component.onCompleted: {
                                    if (Looks.transition.enabled && section.index < 6) {
                                        sectionEntry.start()
                                    } else {
                                        opacity = 1
                                        sectionShift.y = 0
                                    }
                                }
                                SequentialAnimation {
                                    id: sectionEntry
                                    PauseAnimation { duration: Looks.transition.staggerDelay(section.index, 40) }
                                    ParallelAnimation {
                                        NumberAnimation { target: section; property: "opacity"; to: 1; duration: Looks.transition.duration.normal; easing.type: Easing.OutQuad }
                                        NumberAnimation { target: sectionShift; property: "y"; to: 0; duration: Looks.transition.duration.medium; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    height: Looks.dp(40)
                                    spacing: Looks.dp(10)

                                    WBorderlessButton {
                                        Layout.leftMargin: Looks.dp(4)
                                        implicitWidth: Looks.dp(30)
                                        implicitHeight: Looks.dp(30)
                                        radius: Looks.radius.medium
                                        colBackground: Qt.alpha(Looks.colors.accent, Looks.dark ? 0.18 : 0.12)
                                        colBackgroundHover: Qt.alpha(Looks.colors.accent, Looks.dark ? 0.3 : 0.22)
                                        contentItem: Item {
                                            WText {
                                                anchors.centerIn: parent
                                                text: section.modelData.letter
                                                color: Looks.colors.accent
                                                font.pixelSize: Looks.font.pixelSize.large
                                                font.weight: Looks.font.weight.strong
                                            }
                                        }
                                        onClicked: root.jumping = true
                                        WToolTip { text: Translation.tr("Jump to a letter") }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.rightMargin: Looks.dp(4)
                                        implicitHeight: 1
                                        color: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.08 : 0.07)
                                    }
                                }

                                // whole columns edge to edge, so the grid lines up under its letter
                                Flow {
                                    id: appFlow
                                    readonly property int cols: Math.max(1, Math.floor(width / Looks.dp(96)))
                                    readonly property real cellWidth: Math.floor(width / cols)
                                    width: parent.width

                                    Repeater {
                                        model: section.modelData.apps

                                        delegate: WBorderlessButton {
                                            id: appBtn
                                            required property var modelData
                                            readonly property bool pinned: root.isPinned(appBtn.modelData)
                                            implicitWidth: appFlow.cellWidth
                                            implicitHeight: Looks.dp(88)
                                            radius: Looks.radius.large
                                            onClicked: root.launch(appBtn.modelData)

                                            MouseArea {
                                                anchors.fill: parent
                                                acceptedButtons: Qt.RightButton
                                                onClicked: mouse => {
                                                    root.menuEntry = appBtn.modelData
                                                    appMenu.popup(appBtn, mouse.x, mouse.y)
                                                }
                                            }

                                            contentItem: Item {
                                                // icons on one line across the row, whether the name takes one line or two
                                                ColumnLayout {
                                                    anchors.top: parent.top
                                                    anchors.topMargin: Looks.dp(12)
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: parent.width - Looks.dp(8)
                                                    spacing: Looks.dp(6)
                                                    Item {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        implicitWidth: Looks.dp(36)
                                                        implicitHeight: Looks.dp(36)
                                                        Image {
                                                            anchors.fill: parent
                                                            fillMode: Image.PreserveAspectFit
                                                            source: Quickshell.iconPath(appBtn.modelData.icon || appBtn.modelData.name, "application-x-executable")
                                                            sourceSize: Qt.size(Looks.dp(36), Looks.dp(36))
                                                            smooth: true
                                                            mipmap: true
                                                            scale: appBtn.down ? 0.92 : appBtn.hovered ? 1.06 : 1
                                                            Behavior on scale {
                                                                animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                                                            }
                                                        }
                                                        // pinned: a dot in the accent at the icon's corner
                                                        Rectangle {
                                                            visible: appBtn.pinned
                                                            anchors.right: parent.right
                                                            anchors.top: parent.top
                                                            anchors.margins: -Looks.dp(2)
                                                            width: Looks.dp(8)
                                                            height: width
                                                            radius: width / 2
                                                            color: Looks.colors.accent
                                                            border.width: Looks.dp(1.5)
                                                            border.color: Looks.colors.bg0Opaque
                                                        }
                                                    }
                                                    WText {
                                                        Layout.fillWidth: true
                                                        text: appBtn.modelData.name || ""
                                                        font.pixelSize: Looks.font.pixelSize.small
                                                        horizontalAlignment: Text.AlignHCenter
                                                        elide: Text.ElideRight
                                                        maximumLineCount: 2
                                                        wrapMode: Text.Wrap
                                                    }
                                                }
                                            }
                                            WToolTip { text: appBtn.modelData.name || "" }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.groupedApps.length === 0
                    spacing: Looks.dp(8)

                    MascotImage {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Looks.dp(96)
                        Layout.preferredHeight: Looks.dp(96)
                        surface: "startMenu"
                        fallbackSurface: "emptyStates"
                        pose: "fisheye-inspect"
                    }
                    WText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("No apps found")
                        color: Looks.colors.subfg
                    }
                }

                // The alphabet over the list: a letter with apps jumps there, one without sits dimmed
                Item {
                    id: jumpLayer
                    anchors.fill: parent
                    visible: opacity > 0
                    opacity: root.jumping ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.OutQuad } }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.jumping = false
                    }

                    Grid {
                        id: letterGrid
                        anchors.centerIn: parent
                        columns: 7
                        spacing: Looks.dp(6)
                        scale: root.jumping ? 1 : 0.92
                        Behavior on scale { NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive } }

                        Repeater {
                            model: root.alphabet
                            delegate: WBorderlessButton {
                                id: letterBtn
                                required property string modelData
                                readonly property bool used: root.usedLetters.includes(letterBtn.modelData)
                                implicitWidth: Looks.dp(48)
                                implicitHeight: Looks.dp(48)
                                radius: Looks.radius.large
                                enabled: letterBtn.used
                                colBackground: letterBtn.used ? Qt.alpha(Looks.colors.fg, Looks.dark ? 0.06 : 0.05) : "transparent"
                                contentItem: Item {
                                    WText {
                                        anchors.centerIn: parent
                                        text: letterBtn.modelData
                                        color: letterBtn.used ? Looks.colors.fg : Looks.colors.subfg
                                        opacity: letterBtn.used ? 1 : 0.35
                                        font.pixelSize: Looks.font.pixelSize.xlarger
                                        font.weight: letterBtn.used ? Looks.font.weight.strong : Looks.font.weight.regular
                                    }
                                }
                                onClicked: root.jumpTo(letterBtn.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    WMenu {
        id: appMenu
        Action {
            icon.name: "open"
            text: Translation.tr("Open")
            onTriggered: root.launch(root.menuEntry)
        }
        Action {
            icon.name: root.isPinned(root.menuEntry) ? "pin-off" : "pin"
            text: root.isPinned(root.menuEntry) ? Translation.tr("Unpin from taskbar") : Translation.tr("Pin to taskbar")
            onTriggered: TaskbarApps.togglePin(root.menuEntry?.id ?? "")
        }
    }
}
