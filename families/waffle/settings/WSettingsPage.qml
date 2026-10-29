pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.waffle.looks

// Base page component for Windows 11 style settings
Flickable {
    id: root
    
    property string pageTitle: ""
    property string pageIcon: ""
    property string pageDescription: ""
    default property alias content: contentColumn.data
    signal navigateRequested(int pageIndex)
    
    // Settings search context
    // the Settings frame draws the title as a breadcrumb and sets these
    property bool showHeader: true
    property int sidePadding: 28
    property int settingsPageIndex: -1
    property string settingsPageName: pageTitle
    
    clip: true
    contentHeight: contentColumn.implicitHeight + 56
    boundsBehavior: Flickable.StopAtBounds
    pressDelay: 50
    
    ScrollBar.vertical: WScrollBar {}
    
    ColumnLayout {
        id: contentColumn
        // Windows' Settings keeps a page to 1000 px, left-aligned under its title
        x: root.sidePadding
        y: root.showHeader ? 24 : 0
        width: Math.min(root.width - root.sidePadding * 2, Looks.dp(1000))
        spacing: Looks.settings.cardSpacing

        opacity: 0
        transform: Translate { id: contentTranslate; y: Looks.transition.enabled ? 14 : 0 }

        Component.onCompleted: {
            if (Looks.transition.enabled) {
                contentEntrance.start()
            } else {
                contentColumn.opacity = 1
                contentTranslate.y = 0
            }
        }

        ParallelAnimation {
            id: contentEntrance
            NumberAnimation {
                target: contentColumn
                property: "opacity"
                from: 0; to: 1
                duration: Looks.transition.duration.page
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate
            }
            NumberAnimation {
                target: contentTranslate
                property: "y"
                from: 14; to: 0
                duration: Looks.transition.duration.page
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate
            }
        }

        // Page header
        ColumnLayout {
            visible: root.showHeader
            Layout.fillWidth: true
            Layout.bottomMargin: 6
            spacing: 4

            WText {
                text: root.pageTitle
                font.pixelSize: Looks.font.pixelSize.xlarger * 1.5
                font.weight: Looks.font.weight.stronger
            }
            
            WText {
                visible: root.pageDescription !== ""
                Layout.fillWidth: true
                text: root.pageDescription
                font.pixelSize: Looks.font.pixelSize.small
                color: Looks.colors.subfg
                wrapMode: Text.WordWrap
                lineHeight: 1.3
            }
        }
    }
}
