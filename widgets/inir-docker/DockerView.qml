import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import "docker.js" as Docker

// The drawing shared by the desktop card and any future family sidebar host.
// All state and actions live in DockerBackend; this file only lays out.

ColumnLayout {
    id: view

    property var backend
    property real scaleFactor: 1
    property color ink: "white"
    property color accent: "white"
    property string numbersFamily: ""

    spacing: Math.round(6 * view.scaleFactor)

    function statusColor(status): color {
        if (status === "running") return Appearance.colors.colPrimary
        if (status === "exited") return Appearance.colors.colError
        return ColorUtils.applyAlpha(view.ink, 0.55)
    }

    function barColor(percent): color {
        if (percent >= 85) return Appearance.colors.colError
        return view.accent
    }

    // ── Header ───────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(6 * view.scaleFactor)

        MaterialSymbol {
            text: "deployed_code"
            fill: 1
            iconSize: Math.round(18 * view.scaleFactor)
            color: view.backend.available ? view.accent : ColorUtils.applyAlpha(view.ink, 0.55)
        }
        StyledText {
            text: "Docker"
            font.pixelSize: Math.round(Appearance.font.pixelSize.small * view.scaleFactor)
            font.weight: Font.DemiBold
            color: view.ink
        }
        StyledText {
            visible: view.backend.available && view.backend.snapshot?.dockerVersion?.length > 0
            text: "v" + String(view.backend.snapshot?.dockerVersion ?? "")
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * view.scaleFactor)
            color: ColorUtils.applyAlpha(view.ink, 0.55)
        }
        Item { Layout.fillWidth: true }
        RippleButton {
            implicitWidth: Math.round(26 * view.scaleFactor)
            implicitHeight: implicitWidth
            buttonRadius: implicitWidth / 2
            enabled: !view.backend.busy
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.applyAlpha(view.ink, 0.12)
            colRipple: ColorUtils.applyAlpha(view.ink, 0.2)
            onClicked: view.backend.refresh()
            Accessible.name: Translation.tr("Refresh Docker containers")
            contentItem: MaterialSymbol {
                text: "refresh"
                iconSize: Math.round(16 * view.scaleFactor)
                color: view.ink
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: view.backend.targetLabel.length > 0 && view.backend.layout !== "compact"
        text: view.backend.targetLabel
        elide: Text.ElideRight
        font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * view.scaleFactor)
        color: ColorUtils.applyAlpha(view.ink, 0.55)
    }

    // ── Compact summary ──────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        visible: view.backend.layout === "compact" && view.backend.error.length === 0 && view.backend.hasData
        spacing: Math.round(8 * view.scaleFactor)

        Rectangle {
            width: Math.round(6 * view.scaleFactor)
            height: width
            radius: width / 2
            color: view.accent
        }
        StyledText {
            text: view.backend.runningCount + "/" + view.backend.totalCount
            font.family: view.numbersFamily
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * view.scaleFactor)
            font.weight: Font.DemiBold
            color: view.ink
        }
        Rectangle {
            width: 1
            height: Math.round(11 * view.scaleFactor)
            color: ColorUtils.applyAlpha(view.ink, 0.15)
        }
        StyledText {
            text: "CPU " + view.backend.totalCpu.toFixed(1) + "%"
            font.family: view.numbersFamily
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * view.scaleFactor)
            color: ColorUtils.applyAlpha(view.ink, 0.65)
        }
        StyledText {
            text: "MEM " + Docker.formatBytes(view.backend.totalMemBytes)
            font.family: view.numbersFamily
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * view.scaleFactor)
            color: ColorUtils.applyAlpha(view.ink, 0.65)
        }
        Item { Layout.fillWidth: true }
    }

    // ── Monitoring strip ─────────────────────────────────────
    DockerSummary {
        Layout.fillWidth: true
        visible: view.backend.layout !== "compact" && view.backend.showSummary && view.backend.error.length === 0 && view.backend.hasData
        scaleFactor: view.scaleFactor
        ink: view.ink
        accent: view.accent
        numbersFamily: view.numbersFamily
        runningCount: view.backend.runningCount
        totalCount: view.backend.totalCount
        runningShare: view.backend.runningShare
        cpuText: view.backend.totalCpu.toFixed(1) + "%"
        memText: Docker.formatBytes(view.backend.totalMemBytes)
        memPercent: view.backend.memPercent
        cpuHistory: view.backend.cpuHistory
        cpuChartMax: view.backend.cpuChartMax
        showSparkline: view.backend.showSparkline
    }

    // ── Body ─────────────────────────────────────────────────
    StyledText {
        Layout.fillWidth: true
        visible: view.backend.error.length > 0
        text: view.backend.error
        wrapMode: Text.WordWrap
        font.pixelSize: Math.round(Appearance.font.pixelSize.small * view.scaleFactor)
        color: Appearance.colors.colError
    }

    StyledText {
        Layout.fillWidth: true
        visible: view.backend.error.length === 0 && view.backend.loading && !view.backend.hasData
        text: Translation.tr("Reading Docker…")
        font.pixelSize: Math.round(Appearance.font.pixelSize.small * view.scaleFactor)
        color: ColorUtils.applyAlpha(view.ink, 0.62)
    }

    StyledText {
        Layout.fillWidth: true
        visible: view.backend.error.length === 0 && view.backend.hasData && view.backend.shown.length === 0
        text: view.backend.filterText.length > 0
            ? Translation.tr("No containers match the filter")
            : Translation.tr("No containers")
        font.pixelSize: Math.round(Appearance.font.pixelSize.small * view.scaleFactor)
        color: ColorUtils.applyAlpha(view.ink, 0.62)
    }

    Column {
        id: rows
        Layout.fillWidth: true
        visible: view.backend.layout !== "tiles"
        spacing: Math.round(2 * view.scaleFactor)

        Repeater {
            model: view.backend.shown
            delegate: DockerRow {
                required property var modelData

                width: rows.width
                name: modelData.name
                statusText: view.backend.statusLabel(modelData.status)
                statusIcon: view.backend.statusIcon(modelData.status)
                statusColor: view.statusColor(modelData.status)
                cpuText: modelData.cpuPercent.length > 0 ? modelData.cpuPercent : "—"
                cpuPercent: view.backend.percentOf(modelData.cpuPercent)
                cpuColor: view.barColor(view.backend.percentOf(modelData.cpuPercent))
                memText: modelData.memUsageBytes > 0 ? Docker.formatBytes(modelData.memUsageBytes) : "—"
                memPercent: view.backend.percentOf(modelData.memPercent)
                memColor: view.barColor(view.backend.percentOf(modelData.memPercent))
                selected: view.backend.selectedId === modelData.fullId
                scaleFactor: view.scaleFactor
                ink: view.ink
                numbersFamily: view.numbersFamily
                onClicked: view.backend.selectContainer(modelData)
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: view.backend.hiddenCount > 0
        text: Translation.tr("+%1 more").arg(view.backend.hiddenCount)
        font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * view.scaleFactor)
        color: ColorUtils.applyAlpha(view.ink, 0.55)
    }

    DockerTiles {
        Layout.fillWidth: true
        visible: view.backend.layout === "tiles" && view.backend.shown.length > 0
        backend: view.backend
        scaleFactor: view.scaleFactor
        ink: view.ink
        accent: view.accent
        numbersFamily: view.numbersFamily
    }

    // ── Selected container ───────────────────────────────────
    StyledText {
        Layout.fillWidth: true
        visible: view.backend.selected !== null
        text: view.backend.selected ? view.backend.selected.image : ""
        elide: Text.ElideRight
        font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * view.scaleFactor)
        color: ColorUtils.applyAlpha(view.ink, 0.55)
    }

    RowLayout {
        Layout.fillWidth: true
        visible: view.backend.selected !== null && view.backend.pendingAction.length === 0
        spacing: Math.round(4 * view.scaleFactor)

        RippleButton {
            visible: Docker.canContainerAction("start", view.backend.selected)
            implicitWidth: Math.round(28 * view.scaleFactor)
            implicitHeight: implicitWidth
            buttonRadius: Math.round(7 * view.scaleFactor)
            enabled: !view.backend.busy
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.applyAlpha(view.accent, 0.14)
            colRipple: ColorUtils.applyAlpha(view.accent, 0.22)
            onClicked: view.backend.requestAction("start")
            Accessible.name: Translation.tr("Start container")
            contentItem: MaterialSymbol {
                text: "play_arrow"
                iconSize: Math.round(16 * view.scaleFactor)
                color: view.accent
            }
        }
        RippleButton {
            visible: Docker.canContainerAction("stop", view.backend.selected)
            implicitWidth: Math.round(28 * view.scaleFactor)
            implicitHeight: implicitWidth
            buttonRadius: Math.round(7 * view.scaleFactor)
            enabled: !view.backend.busy
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.applyAlpha(view.ink, 0.12)
            colRipple: ColorUtils.applyAlpha(view.ink, 0.2)
            onClicked: view.backend.requestAction("stop")
            Accessible.name: Translation.tr("Stop container")
            contentItem: MaterialSymbol {
                text: "stop"
                iconSize: Math.round(16 * view.scaleFactor)
                color: view.ink
            }
        }
        RippleButton {
            visible: Docker.canContainerAction("restart", view.backend.selected)
            implicitWidth: Math.round(28 * view.scaleFactor)
            implicitHeight: implicitWidth
            buttonRadius: Math.round(7 * view.scaleFactor)
            enabled: !view.backend.busy
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.applyAlpha(view.ink, 0.12)
            colRipple: ColorUtils.applyAlpha(view.ink, 0.2)
            onClicked: view.backend.requestAction("restart")
            Accessible.name: Translation.tr("Restart container")
            contentItem: MaterialSymbol {
                text: "restart_alt"
                iconSize: Math.round(16 * view.scaleFactor)
                color: view.ink
            }
        }
        RippleButton {
            implicitWidth: Math.round(28 * view.scaleFactor)
            implicitHeight: implicitWidth
            buttonRadius: Math.round(7 * view.scaleFactor)
            enabled: !view.backend.busy
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.applyAlpha(view.ink, 0.12)
            colRipple: ColorUtils.applyAlpha(view.ink, 0.2)
            onClicked: view.backend.openLogs(false)
            Accessible.name: Translation.tr("Open recent logs")
            contentItem: MaterialSymbol {
                text: "article"
                iconSize: Math.round(16 * view.scaleFactor)
                color: view.ink
            }
        }
        RippleButton {
            implicitWidth: Math.round(28 * view.scaleFactor)
            implicitHeight: implicitWidth
            buttonRadius: Math.round(7 * view.scaleFactor)
            enabled: !view.backend.busy
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.applyAlpha(view.ink, 0.12)
            colRipple: ColorUtils.applyAlpha(view.ink, 0.2)
            onClicked: view.backend.openLogs(true)
            Accessible.name: Translation.tr("Follow logs")
            contentItem: MaterialSymbol {
                text: "subject"
                iconSize: Math.round(16 * view.scaleFactor)
                color: view.ink
            }
        }
        Item { Layout.fillWidth: true }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: view.backend.pendingAction.length > 0
        spacing: Math.round(6 * view.scaleFactor)
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("%1 %2?")
                .arg(view.backend.actionLabel(view.backend.pendingAction))
                .arg(view.backend.selected?.name ?? Translation.tr("container"))
            elide: Text.ElideRight
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * view.scaleFactor)
            color: view.ink
        }
        RippleButton {
            buttonText: Translation.tr("Cancel")
            implicitWidth: Math.round(70 * view.scaleFactor)
            implicitHeight: Math.round(26 * view.scaleFactor)
            buttonRadius: Math.round(7 * view.scaleFactor)
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.applyAlpha(view.ink, 0.12)
            colRipple: ColorUtils.applyAlpha(view.ink, 0.2)
            onClicked: view.backend.cancelAction()
        }
        RippleButton {
            buttonText: Translation.tr("Confirm")
            implicitWidth: Math.round(74 * view.scaleFactor)
            implicitHeight: Math.round(26 * view.scaleFactor)
            buttonRadius: Math.round(7 * view.scaleFactor)
            colBackground: ColorUtils.applyAlpha(view.accent, 0.18)
            colBackgroundHover: ColorUtils.applyAlpha(view.accent, 0.28)
            colRipple: ColorUtils.applyAlpha(view.accent, 0.34)
            onClicked: view.backend.confirmAction()
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: view.backend.actionNotice.length > 0
        text: view.backend.actionNotice
        elide: Text.ElideRight
        font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * view.scaleFactor)
        color: view.accent
    }
    StyledText {
        Layout.fillWidth: true
        visible: view.backend.actionError.length > 0
        text: view.backend.actionError
        wrapMode: Text.WordWrap
        font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * view.scaleFactor)
        color: Appearance.colors.colError
    }
}
