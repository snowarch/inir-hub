pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.preview
import qs.modules.iris.settings

// An area's live stage as every layout shows it: a plate that rounds with the form plates beside it, the scene one
// even mat inside (its corners concentric with the plate's), the caption under the scene on the same plate. A layout
// gives only its room (`ratio`, `least`, `most`); the shape, the mat and the caption are the same in Classic, Folio,
// Pocket and Drawer. A plain Rectangle: the scene clips itself, a ClippingRectangle here cost a second clip.
Item {
    id: root
    property Item host
    property string area: ""
    property string group: ""
    property bool playing: false
    // The stage's height as a share of its width, held between `least` and `most`.
    property real ratio: 0.3
    property real most: root.u(260)
    property real least: root.u(110)
    readonly property alias stage: stage
    readonly property bool staged: stage.available
    readonly property real d: Number(root.host?.d ?? IrisStyle.settingsDensity)
    function u(n: real): int { return Math.round(n * root.d) }
    readonly property int radius: Number(root.host?.plateRadius ?? IrisStyle.radiusTile)
    readonly property int mat: root.u(6)
    readonly property bool captioned: stage.caption.length > 0
    readonly property real captionRoom: root.captioned ? stageCaption.implicitHeight + 2 * root.u(7) : root.mat

    visible: root.staged
    implicitHeight: root.staged ? Math.round(Math.max(root.least, Math.min(root.most, root.width * root.ratio))) : 0

    Rectangle {
        anchors.fill: parent
        visible: !IrisStyle.fieldChamfer
        radius: root.radius
        color: IrisStyle.readingCard
        border.width: 1
        border.color: IrisStyle.hairline
    }
    IrisCutPlate {
        anchors.fill: parent
        visible: IrisStyle.fieldChamfer
        cutLength: Number(root.host?.plateCut ?? IrisStyle.chamferCut)
        color: IrisStyle.readingCard
        stroke: IrisStyle.hairline
        strokeWidth: 1
    }
    IrisGroupPreview {
        id: stage
        x: root.mat
        y: root.mat
        width: parent.width - 2 * root.mat
        height: Math.max(0, parent.height - root.mat - root.captionRoom)
        // Concentric with the plate: the mat is as wide round the curve as along the sides.
        radius: IrisStyle.concentric(root.radius, root.mat, IrisStyle.radiusChip)
        standIn: true
        captionOutside: true
        playing: root.playing && root.staged
        section: root.area
        niriValue: (section, key) => IrisNiri.value(IrisOptions.settings.find(spec => spec.niri === section && spec.key === key) ?? { niri: section, key: key })
        niriRevision: IrisNiri.revision
        group: root.group
    }
    // The caption under the stage, never a chip on it: on the stage it sat on the login's password and the motion's boxes.
    IrisText {
        id: stageCaption
        visible: root.captioned
        x: root.mat + root.u(8)
        width: parent.width - 2 * x
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.u(7)
        elide: Text.ElideRight
        text: stage.caption
        color: IrisStyle.muted
        font.pixelSize: IrisStyle.typeMeta
    }
}
