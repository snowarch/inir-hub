pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.iris.style
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.field as Field
import qs.modules.iris.bar.island as IslandParts

// The resting Island, drawn by the field like the real one: its rim, glass edge, Afterglow and shadow come from the
// same pass instead of a bordered Rectangle that only resembled them.
Item {
    id: pill
    property bool vertical: false
    readonly property real radius: Math.min(width, height) / 2
    width: pill.vertical ? Math.round(IrisFrame.islandBand) : Math.round(150 * IrisStyle.density)
    height: pill.vertical ? Math.round(150 * IrisStyle.density) : Math.round(IrisFrame.islandBand)
    // Set on a scene (PreviewScene), the pill wears the scene's glass where it sits on it.
    property Item glass: pill.parent?.glass ?? null
    Field.IrisField {
        anchors.fill: parent
        backdropOverride: pill.glass
        sceneOrigin: Qt.point(pill.x, pill.y)
        sceneSize: Qt.size(pill.parent?.width ?? 0, pill.parent?.height ?? 0)
        framed: false
        shapes: [{ id: "island", x: 0, y: 0, width: pill.width, height: pill.height, radius: pill.radius }]
    }
    // A Design that draws the Island's face shows it here at rest, on a stand-in Island.
    readonly property string faceUrl: pill.vertical ? "" : IrisDesign.skin("islandFace")
    Loader {
        id: face
        anchors.fill: parent
        active: pill.faceUrl.length > 0
        source: pill.faceUrl
        onLoaded: item.island = ({ compactMode: "clock", compactHeight: pill.height, clockScale: 1, clockStyle: "time",
            notch: false, bottomEdge: false, clockText: () => "" })
    }
    IrisClock {
        visible: !pill.vertical && !face.item
        anchors.centerIn: parent
        pixelSize: IrisStyle.typeHeadline
        separatorColor: IrisStyle.secondaryAccent
    }
    IslandParts.IslandStackedClock {
        visible: pill.vertical
        anchors.centerIn: parent
        pixelSize: IrisStyle.typeHeadline
        accent: IrisStyle.secondaryAccent
    }
}
