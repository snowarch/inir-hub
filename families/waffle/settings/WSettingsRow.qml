pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

// Single settings row with label and control - Windows 11 style
Item {
    id: root
    
    property string icon: ""
    property string label: ""
    property string description: ""
    property alias control: controlLoader.sourceComponent
    property bool clickable: false
    property bool showChevron: false
    
    // Settings search integration
    property bool enableSettingsSearch: true
    property int settingsSearchOptionId: -1

    readonly property color rowHover: Looks.settings.tileHover
    readonly property color rowPressed: Looks.settings.tilePressed
    readonly property color rowTile: Looks.settings.tile

    signal clicked()

    // A clickable row (a link card to a page) is a Tab stop that Enter or Space opens, as a SettingsCard is; it was
    // mouse-only, so a category's pages could not be reached by keyboard.
    activeFocusOnTab: root.clickable
    Keys.onReturnPressed: if (root.clickable) root.clicked()
    Keys.onEnterPressed: if (root.clickable) root.clicked()
    Keys.onSpacePressed: if (root.clickable) root.clicked()
    // A search landing wears the system focus visual too, as Windows' Settings marks the setting it found.
    property bool landed: false
    WFocusVisual { shown: (root.activeFocus && root.clickable) || root.landed; radius: root._item ? 0 : Looks.settings.radiusSmall }
    
    Layout.fillWidth: true
    Layout.leftMargin: 0
    Layout.rightMargin: 0
    
    // Highlight animation for search focus
    Behavior on opacity {
        enabled: Looks.transition?.opacity !== undefined
        animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
    }
    Behavior on scale {
        enabled: Looks.transition?.resize !== undefined
        animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
    }
    
    function _findSettingsContext(): var {
        var page = null;
        var sectionTitle = "";
        var p = root.parent;
        while (p) {
            if (!page && p.hasOwnProperty("settingsPageIndex")) {
                page = p;
            }
            if (!sectionTitle && p.hasOwnProperty("title") && typeof p.title === "string") {
                sectionTitle = p.title;
            }
            p = p.parent;
        }
        return { page: page, sectionTitle: sectionTitle };
    }
    
    function focusFromSettingsSearch(): void {
        // A row inside a closed expander opens it first; an expander's own header is the setting and stays closed
        let opened = null;
        for (let e = root.parent; e; e = e.parent)
            if (e.expander === true && !e.expanded && e.header !== root) {
                e.expanded = true;
                opened = e;
            }
        // the page grows as the expander opens: centre the row once it has its place
        if (opened) {
            opened.landAfterOpen(root);
            return;
        }
        root.land();
    }

    function land(): void {
        // Find parent Flickable
        var flick = null;
        var p = root.parent;
        while (p) {
            if (p.hasOwnProperty("contentY") && p.hasOwnProperty("contentHeight")) {
                flick = p;
                break;
            }
            p = p.parent;
        }
        
        // Scroll to center this element in view
        if (flick) {
            var y = 0;
            var n = root;
            while (n && n !== flick) {
                y += n.y || 0;
                n = n.parent;
            }
            // Center the element in the viewport
            var centerOffset = (flick.height - root.height) / 2;
            var maxY = Math.max(0, flick.contentHeight - flick.height);
            var target = Math.max(0, Math.min(y - centerOffset, maxY));
            
            // Smooth scroll
            flick.contentY = target;
        }
        
        // Run highlight animation
        highlightAnim.stop();
        root.scale = 1.0;
        highlightOverlay.opacity = 0;
        highlightAnim.start();
    }
    
    // A Repeater's delegate completes before it is placed in the page, so the page is read a turn later
    // (an expander per mascot event registered with no page and its search never landed)
    Component.onCompleted: Qt.callLater(root._registerForSearch)

    function _registerForSearch(): void {
        if (!enableSettingsSearch) return;
        if (typeof SettingsSearchRegistry === "undefined") return;
        if (!root.label) return;
        
        var ctx = _findSettingsContext();
        var page = ctx.page;
        var sectionTitle = ctx.sectionTitle;
        
        settingsSearchOptionId = SettingsSearchRegistry.registerOption({
            control: root,
            pageIndex: page?.settingsPageIndex ?? -1,
            pageName: page?.settingsPageName ?? "",
            section: sectionTitle,
            label: root.label,
            description: root.description,
            keywords: []
        });
    }
    
    Component.onDestruction: {
        if (typeof SettingsSearchRegistry !== "undefined") {
            SettingsSearchRegistry.unregisterControl(root);
        }
    }
    
    // "card": a Windows 11 SettingsCard on its own; "item": a row inside an expander (WSettingsCard sets it),
    // flat with a hairline above, indented past the expander's icon
    property string cardStyle: "card"
    property bool flatBottom: false
    // an expander's header keeps its control left of the chevron, over its items' controls (44)
    property real endInset: root._item ? Looks.dp(44) : Looks.settings.cardPadding
    readonly property string settingsCardRole: "row"
    readonly property bool _item: root.cardStyle === "item"

    implicitHeight: Math.max(root._item ? Looks.settings.cardItemMinHeight : Looks.settings.cardMinHeight,
        contentRow.implicitHeight + (root._item ? Looks.dp(16) : Looks.dp(26)))

    Rectangle {
        id: background
        anchors.fill: parent
        radius: root._item ? 0 : Looks.settings.radiusSmall
        // an open expander's header meets its rows with a straight edge
        bottomLeftRadius: root.flatBottom ? 0 : radius
        bottomRightRadius: root.flatBottom ? 0 : radius
        color: {
            if (root.clickable && mouseArea.pressed)
                return Looks.settings.cardPressed
            if (root.clickable && mouseArea.containsMouse)
                return Looks.settings.cardHover
            return root._item ? "transparent" : Looks.settings.card
        }
        border.width: root._item ? 0 : 1
        border.color: Looks.settings.cardStroke
        Behavior on color {
            animation: ColorAnimation { duration: Looks.transition.enabled ? 83 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
        }
        Rectangle {
            visible: root._item
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Looks.settings.cardStroke
        }
    }

    // Highlight overlay for search focus
    Rectangle {
        id: highlightOverlay
        anchors.fill: parent
        radius: background.radius
        color: Looks.colors.accent
        opacity: 0
    }

    SequentialAnimation {
        id: highlightAnim
        // Long enough to be found after the page turns (0.8 s was gone before the eye arrived).
        ScriptAction { script: root.landed = true }
        NumberAnimation { target: highlightOverlay; property: "opacity"; to: 0.18; duration: 200; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 1400 }
        ScriptAction { script: root.landed = false }
        NumberAnimation { target: highlightOverlay; property: "opacity"; to: 0; duration: 400; easing.type: Easing.InCubic }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.clickable) root.clicked()
    }

    RowLayout {
        id: contentRow
        // WinUI's disabled ink (TextFillColorDisabled, ~36-40 %): a row under an expander that is off rests here
        opacity: root.enabled ? 1 : 0.4
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: root._item ? Looks.dp(root.icon !== "" ? 16 : 58) : Looks.settings.cardPadding
            rightMargin: root.endInset
        }
        spacing: Looks.dp(16)

        // SettingsCard header icon: 20 px glyph, 20 px before the text (HeaderIconMargin 2,0,20,0)
        FluentIcon {
            visible: root.icon !== ""
            Layout.leftMargin: Looks.dp(2)
            Layout.rightMargin: Looks.dp(4)
            Layout.alignment: Qt.AlignVCenter
            icon: root.icon
            implicitSize: Looks.settings.cardIconSize
            color: Looks.colors.fg
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            WText {
                Layout.fillWidth: true
                text: root.label
                font.pixelSize: Looks.settings.body
                font.weight: Looks.font.weight.thin
                elide: Text.ElideRight
            }

            WText {
                visible: root.description !== ""
                Layout.fillWidth: true
                text: root.description
                font.pixelSize: Looks.settings.caption
                font.weight: Looks.font.weight.thin
                color: Looks.colors.subfg
                wrapMode: Text.WordWrap
                lineHeight: 1.15
            }
        }

        Loader {
            id: controlLoader
            Layout.alignment: Qt.AlignVCenter
        }

        FluentIcon {
            visible: root.showChevron
            icon: "chevron-right"
            implicitSize: Looks.dp(13)
            color: Looks.colors.fg
        }
    }
}
