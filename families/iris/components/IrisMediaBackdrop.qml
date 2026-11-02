pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.modules.common.functions
import qs.modules.iris.style

Item {
    id: root
    property string source: ""
    property real radius: 0
    property real strength: 0.62
    // The side where the body it lies in is welded (the Island's page to its strip or the frame): the cover thins out
    // to nothing there, so the body's own material carries the join. A black scrim there read as a card stuck on the
    // frame (his 11-02). `fadeClear` stays bare, then the cover comes in over `fadeLength`.
    property string fadeEdge: ""
    property real fadeClear: 0
    property real fadeLength: 0
    readonly property bool fades: root.fadeEdge.length > 0 && root.fadeClear + root.fadeLength > 0
    readonly property bool masked: (root.radius > 0 || root.fades) && !skin.active

    readonly property real overscan: 48

    // A Design may lay the cover its own way (AIRISU: the record's lacquer); the cover and where it sits stay the owner's.
    IrisSkin { id: skin; part: "mediaBackdrop"; host: root }

    Image {
        id: cover
        anchors.fill: parent
        anchors.margins: -root.overscan
        source: skin.active ? "" : root.source
        sourceSize: Qt.size(160, 160)
        // Its own texture: a mipmapped cover of the same size elsewhere shared it and flipped its filtering.
        cache: false
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    Item {
        id: composed
        anchors.fill: parent
        visible: !skin.active
        layer.enabled: root.masked
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: roundMask
            // Centred and fully spread the mask is a smoothstep over its whole alpha: the fade ramps, the round edge
            // keeps its antialiasing (at 0 / 0 it is a hard cut at the first non-zero pixel).
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
        MultiEffect {
            anchors.fill: parent
            anchors.margins: -root.overscan
            source: cover
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            opacity: root.strength
            visible: cover.status === Image.Ready
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: IrisStyle.artVeil }
                GradientStop { position: 1; color: IrisStyle.artVeilHeavy }
            }
        }
    }
    // Hidden layered mask child: an inline ShaderEffectSource crashed Qt on window unload.
    Item {
        id: roundMask
        anchors.fill: parent
        visible: false
        layer.enabled: root.masked
        Rectangle {
            id: maskPlate
            readonly property bool across: root.fadeEdge === "left" || root.fadeEdge === "right"
            readonly property bool far: root.fadeEdge === "bottom" || root.fadeEdge === "right"
            readonly property real span: Math.max(1, maskPlate.across ? maskPlate.width : maskPlate.height)
            readonly property real clearAt: Math.min(1, root.fadeClear / maskPlate.span)
            readonly property real fullAt: Math.min(1, (root.fadeClear + root.fadeLength) / maskPlate.span)
            // Positions from the start of the gradient: bare from the welded side, full where the fade ends.
            function at(t: real): real { return maskPlate.far ? 1 - t : t }
            anchors.fill: parent
            radius: root.radius
            color: "white"
            gradient: root.fades ? fade : null
            Gradient {
                id: fade
                orientation: maskPlate.across ? Gradient.Horizontal : Gradient.Vertical
                GradientStop { position: maskPlate.at(maskPlate.far ? 1 : 0); color: maskPlate.far ? "white" : "transparent" }
                GradientStop { position: maskPlate.at(maskPlate.far ? maskPlate.fullAt : maskPlate.clearAt); color: maskPlate.far ? "white" : "transparent" }
                GradientStop { position: maskPlate.at(maskPlate.far ? maskPlate.clearAt : maskPlate.fullAt); color: maskPlate.far ? "transparent" : "white" }
                GradientStop { position: maskPlate.at(maskPlate.far ? 0 : 1); color: maskPlate.far ? "transparent" : "white" }
            }
        }
    }
}
