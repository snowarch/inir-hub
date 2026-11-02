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
    readonly property bool masked: root.radius > 0 && !skin.active

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
            // Centred and fully spread the round edge keeps its antialiasing (at 0 / 0 it is a hard cut at the first
            // non-zero pixel).
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
            anchors.fill: parent
            radius: root.radius
        }
    }
}
