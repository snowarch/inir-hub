import QtQuick
import QtQuick.Effects

// Where a scrolled list meets what floats over it, its rows soften into a blur and fade into the air instead of
// ending on a cut (the scroll edge of Apple's Liquid Glass). Laid over the Flickable (anchors.fill: flick); the flick
// takes `mask` as its layer mask while `active`. The edge that has more rows past it fades over `reach`; at the head
// (`blurs`) a band shows the rows just under it blurred, sharp below and gone at the top. A row that scrolls sideways
// (`horizontal`) fades at its left and right ends the same way; its head band does not blur.
Item {
    id: root

    required property Flickable flick
    property bool horizontal: false
    property real reach: 28
    // The head's own fade, longer where keys float over the list's top: the rows are gone before they reach them.
    property real headReach: root.reach
    property bool blurs: true
    property real blurMax: 24
    // The corners of what holds the list: rows passing them are cut by the same curve, never by a square clip.
    property real radius: 0
    // The veil's own corners, where the list meets a rounded corner of its holder: the fill keeps that curve.
    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomLeftRadius: 0
    property real bottomRightRadius: 0
    // atTop and atBottom: more content past the start (top or left) and past the end (bottom or right).
    // Measured from the origin: a ListView whose rows differ in size moves it, and contentX 0 is then not its start.
    readonly property bool atTop: root.horizontal ? root.flick.contentX - root.flick.originX > 1
        : root.flick.contentY - root.flick.originY > 1
    readonly property bool atBottom: root.horizontal
        ? root.flick.contentX - root.flick.originX + root.flick.width < root.flick.contentWidth - 1
        : root.flick.contentY - root.flick.originY + root.flick.height < root.flick.contentHeight - 1
    readonly property real span: root.horizontal ? root.width : root.height
    readonly property bool active: (root.atTop || root.atBottom) && !root.veiled
    readonly property Item mask: fade
    // A list over an opaque fill fades into that colour drawn over its edges instead: the same look with nothing
    // rendered offscreen, where the mask re-rendered the whole list into a texture on every scrolled frame.
    property color veil: "transparent"
    readonly property bool veiled: root.veil.a > 0
    readonly property real share: Math.min(0.5, root.reach / Math.max(1, root.span))
    readonly property real headShare: Math.min(0.5, root.headReach / Math.max(1, root.span))

    // An eased ramp (0, a quarter, a half, all) so the fade has no visible start like a linear one.
    Item {
        id: fade
        anchors.fill: parent
        visible: false
        layer.enabled: root.active
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            gradient: Gradient {
                orientation: root.horizontal ? Gradient.Horizontal : Gradient.Vertical
                GradientStop { position: 0; color: root.atTop ? "transparent" : "white" }
                GradientStop { position: root.headShare * 0.35; color: root.atTop ? Qt.rgba(1, 1, 1, 0.2) : "white" } // iris-literal: mask alpha, not a colour
                GradientStop { position: root.headShare * 0.7; color: root.atTop ? Qt.rgba(1, 1, 1, 0.65) : "white" } // iris-literal: mask alpha, not a colour
                GradientStop { position: root.headShare; color: "white" }
                GradientStop { position: 1 - root.share; color: "white" }
                GradientStop { position: 1 - root.share * 0.7; color: root.atBottom ? Qt.rgba(1, 1, 1, 0.65) : "white" } // iris-literal: mask alpha, not a colour
                GradientStop { position: 1 - root.share * 0.35; color: root.atBottom ? Qt.rgba(1, 1, 1, 0.2) : "white" } // iris-literal: mask alpha, not a colour
                GradientStop { position: 1; color: root.atBottom ? "transparent" : "white" }
            }
        }
    }

    // The veil: the fill over each edge with rows past it, on the same eased ramp as the mask.
    Rectangle {
        visible: root.veiled && root.atTop
        width: root.horizontal ? root.headReach : root.width
        height: root.horizontal ? root.height : root.headReach
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.horizontal ? 0 : root.topRightRadius
        bottomLeftRadius: root.horizontal ? root.bottomLeftRadius : 0
        gradient: Gradient {
            orientation: root.horizontal ? Gradient.Horizontal : Gradient.Vertical
            GradientStop { position: 0; color: root.veil }
            GradientStop { position: 0.35; color: Qt.alpha(root.veil, 0.8) } // iris-literal: the mask's ramp, inverted
            GradientStop { position: 0.7; color: Qt.alpha(root.veil, 0.35) } // iris-literal: the mask's ramp, inverted
            GradientStop { position: 1; color: Qt.alpha(root.veil, 0) }
        }
    }
    Rectangle {
        visible: root.veiled && root.atBottom
        x: root.horizontal ? root.width - width : 0
        y: root.horizontal ? 0 : root.height - height
        width: root.horizontal ? root.reach : root.width
        height: root.horizontal ? root.height : root.reach
        topRightRadius: root.horizontal ? root.topRightRadius : 0
        bottomLeftRadius: root.horizontal ? 0 : root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        gradient: Gradient {
            orientation: root.horizontal ? Gradient.Horizontal : Gradient.Vertical
            GradientStop { position: 0; color: Qt.alpha(root.veil, 0) }
            GradientStop { position: 0.3; color: Qt.alpha(root.veil, 0.35) } // iris-literal: the mask's ramp, inverted
            GradientStop { position: 0.65; color: Qt.alpha(root.veil, 0.8) } // iris-literal: the mask's ramp, inverted
            GradientStop { position: 1; color: root.veil }
        }
    }

    ShaderEffectSource {
        id: band
        visible: root.blurs && !root.horizontal && root.atTop
        width: root.width
        height: Math.min(root.height, Math.round(root.headReach * 1.4))
        sourceItem: root.flick.contentItem
        sourceRect: Qt.rect(root.flick.contentX, root.flick.contentY, band.width, band.height)
        live: band.visible
        // Blurred at half size, as the field's glass is: the band is a soft shape, not text to read.
        textureSize: Qt.size(Math.max(1, Math.ceil(band.width / 2)), Math.max(1, Math.ceil(band.height / 2)))
        layer.enabled: band.visible
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: root.blurMax
            maskEnabled: true
            maskSource: bandMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }
    // Gone at the very top (the rows have faded there too), fullest a third down, back to the sharp rows below.
    Item {
        id: bandMask
        width: band.width
        height: band.height
        visible: false
        layer.enabled: band.visible
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0.85) } // iris-literal: mask alpha, not a colour
                GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.6) } // iris-literal: mask alpha, not a colour
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }
}
