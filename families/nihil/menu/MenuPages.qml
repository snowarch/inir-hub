pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// The settings behind each of the menu's tiles, one column of rows per page.
Column {
    id: root

    required property string page
    property real w: NihilStyle.s(290)
    spacing: NihilStyle.cellGap

    function close(): void { NihilState.menuOpen = false }

    // Widgets.
    Column {
        visible: root.page === "widgets"
        spacing: root.spacing
        MenuRow {
            width: root.w; label: Translation.tr("Faces"); key: "nihil.widgets.design"; fallback: "nihil"
            choices: [{ value: "nihil", label: "NiHiL" }, { value: "instrument", label: Translation.tr("Instrument") },
                { value: "readout", label: Translation.tr("Readout") }]
        }
        MenuRow {
            width: root.w; label: Translation.tr("Clock"); key: "nihil.clock.style"; fallback: "dots"
            choices: [{ value: "dots", label: Translation.tr("Dots") }, { value: "fused", label: Translation.tr("Fused") }]
        }
        MenuRow { width: root.w; label: Translation.tr("Two-tone clock"); key: "nihil.clock.twoTone"; fallback: true }
        MenuRow {
            width: root.w; label: Translation.tr("Add or arrange widgets")
            action: () => NihilState.openSettings("widgets")
        }
    }

    // Menus.
    Column {
        visible: root.page === "menus"
        spacing: root.spacing
        MenuRow {
            width: root.w; label: Translation.tr("Signal colour"); key: "nihil.theme.accent"; fallback: "signal"
            choices: [{ value: "signal", label: Translation.tr("Signal") }, { value: "dynamic", label: Translation.tr("Dynamic") }]
        }
        MenuRow {
            width: root.w; label: Translation.tr("Bar"); key: "nihil.bar.bottom"; fallback: true
            choices: [{ value: true, label: Translation.tr("Bottom") }, { value: false, label: Translation.tr("Top") }]
        }
        MenuRow { width: root.w; label: Translation.tr("Hide the bar"); key: "nihil.bar.autoHide"; fallback: false }
        MenuRow { width: root.w; label: Translation.tr("One-colour icons"); key: "nihil.bar.monochromeIcons"; fallback: true }
        MenuRow {
            width: root.w; label: Translation.tr("Size"); key: "nihil.theme.scale"; fallback: 1
            choices: [{ value: 1, label: "100%" }, { value: 1.1, label: "110%" }, { value: 1.25, label: "125%" }, { value: 0.9, label: "90%" }]
        }
    }

    // Wallpapers.
    Column {
        visible: root.page === "wallpapers"
        spacing: root.spacing
        MenuRow {
            width: root.w; label: Translation.tr("Choose a wallpaper")
            action: () => { root.close(); GlobalStates.wallpaperSelectorOpen = true }
        }
        MenuRow {
            width: root.w; label: Translation.tr("Light or dark")
            actionValue: Appearance.m3colors.darkmode ? Translation.tr("Dark") : Translation.tr("Light")
            action: () => MaterialThemeLoader.setDarkMode(!Appearance.m3colors.darkmode)
        }
        MenuRow { width: root.w; label: Translation.tr("Blur on the lock screen"); key: "nihil.lock.blur"; fallback: true }
    }

    // Extras.
    Column {
        visible: root.page === "extras"
        spacing: root.spacing
        MenuRow {
            width: root.w; label: Translation.tr("All settings")
            action: () => NihilState.openSettings("")
        }
        MenuRow {
            width: root.w; label: Translation.tr("Change family")
            action: () => NihilState.openSettings("system")
        }
    }

    // About.
    NTile {
        id: about
        visible: root.page === "about"
        width: root.w
        height: words.implicitHeight + about.pad * 2
        Column {
            id: words
            x: about.pad
            y: about.pad
            width: about.width - about.pad * 2
            spacing: NihilStyle.s(6)
            NFigure {
                size: NihilStyle.s(30)
                text: Plugins.manifests?.nihil?.version ?? ""
                color: about.ink
            }
            NText {
                width: parent.width
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                text: Translation.tr("Tiles packed in blocks, three inks and one signal colour. A family of iNiR.")
                color: about.inkSoft
            }
        }
    }
}
