pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"

// Home's hero card, as Settings' big card: one show's art, its cover, its name, what it is about, and Watch and
// Details. The same actions in both styles.
ClippingRectangle {
    id: root
    property var show: null
    property string status: ""
    readonly property real d: IrisStyle.density
    readonly property bool compact: width < Math.round(600 * root.d * Math.min(1.4, IrisStyle.typeScale))
    readonly property bool film: root.show?.type === "Movie" || Number(root.show?.episodes) === 1
    implicitHeight: Math.round(250 * root.d)
    radius: IrisStyle.radiusCard
    color: CornerSkin.card
    border.width: CornerSkin.edgeWidth
    border.color: CornerSkin.edge

    IrisImage {
        anchors.fill: parent
        source: String(root.show?.banner || root.show?.imageLarge || "")
        fillMode: Image.PreserveAspectCrop
    }
    // The words sit on the left over a veil that keeps them readable on any art.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: IrisStyle.veilHeavy }
            GradientStop { position: 0.6; color: IrisStyle.veilStrong }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Math.round(22 * root.d)
        spacing: Math.round(20 * root.d)

        ClippingRectangle {
            id: cover
            visible: root.show !== null && !root.compact
            Layout.fillHeight: true
            Layout.preferredWidth: Math.round(height / 1.5)
            radius: IrisStyle.radiusTile
            color: IrisStyle.veilStrong
            border.width: 1
            border.color: IrisStyle.hairlineOf(IrisStyle.inkOnDark)
            IrisImage { anchors.fill: parent; source: String(root.show?.imageLarge ?? "") }
            MouseArea {
                id: coverAction
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: String(root.show?.title ?? "")
                onClicked: CornerState.openShow(root.show)
                Keys.onReturnPressed: CornerState.openShow(root.show)
                Keys.onSpacePressed: CornerState.openShow(root.show)
            }
            CornerFocusRing { on: coverAction.activeFocus }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(6 * root.d)
            IrisText {
                text: root.show ? Translation.tr("Trending now") : Translation.tr("Media Corner")
                color: IrisStyle.inkOnDark
                opacity: 0.72 // literal: an eyebrow over art reads quieter than the title
                font.pixelSize: IrisStyle.typeMeta
                font.weight: IrisStyle.weight(Font.DemiBold)
            }
            IrisText {
                Layout.fillWidth: true
                text: String(root.show?.title ?? root.status)
                textFormat: Text.PlainText
                font.family: IrisStyle.fontTitle
                font.pixelSize: IrisStyle.typeTitleLarge
                font.letterSpacing: CornerSkin.titleTracking
                color: IrisStyle.inkOnDark
                font.weight: IrisStyle.weight(Font.Bold)
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
            }
            IrisText {
                Layout.fillWidth: true
                visible: root.show !== null
                text: [root.show?.year, Translation.tr(String(root.show?.type ?? "")), (root.show?.genres ?? []).slice(0, 3).map(g => Translation.tr(g)).join(" · "),
                       Number(root.show?.score ?? 0) > 0 ? "★ " + Number(root.show.score).toFixed(1) : ""].filter(x => String(x ?? "").length > 0).join("  ·  ")
                color: IrisStyle.inkOnDark
                opacity: 0.72 // literal: facts over art, quieter than the title
                font.pixelSize: IrisStyle.typeMeta
                elide: Text.ElideRight
            }
            IrisText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: String(root.show?.description ?? "")
                textFormat: Text.PlainText
                color: IrisStyle.inkOnDark
                opacity: 0.72 // literal: the synopsis over art, quieter than the title
                font.pixelSize: IrisStyle.typeLabel
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 3
            }
            Row {
                visible: root.show !== null
                spacing: Math.round(8 * root.d)
                CornerPill {
                    tone: "solid"
                    glyph: "play_arrow"
                    label: Translation.tr("Watch")
                    onClicked: {
                        CornerState.openShow(root.show)
                        CornerWatch.begin(Object.assign({}, root.show, { film: root.film }), { episode: 1 })
                    }
                }
                CornerPill {
                    tone: "art"
                    glyph: "info"
                    label: Translation.tr("Details")
                    onClicked: CornerState.openShow(root.show)
                }
            }
        }
    }
}
