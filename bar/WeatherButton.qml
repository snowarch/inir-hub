import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

BarButton {
    id: root

    leftInset: 8
    rightInset: 8
    implicitWidth: contentRow.implicitWidth + leftInset + rightInset + 8
    readonly property bool hideLocation: Config.options?.waffles?.widgetsPanel?.weatherHideLocation ?? false
    readonly property string locationText: {
        if (root.hideLocation)
            return ""
        const city = String(Weather.data?.city ?? "")
        if (city.length > 0 && city.toLowerCase() !== "unknown")
            return city
        return ""
    }
    readonly property string secondaryText: locationText || root.weatherDescription

    onClicked: {
        Weather.getData()
        GlobalStates.waffleWidgetsOpen = !GlobalStates.waffleWidgetsOpen
    }

    contentItem: RowLayout {
        id: contentRow
        spacing: 8
        anchors.centerIn: parent

        MaterialSymbol {
            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
            iconSize: 20
            color: Looks.colors.fg
            Layout.alignment: Qt.AlignVCenter
        }

        Column {
            width: 92
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            WText {
                width: parent.width
                text: Weather.data?.temp ?? "--°"
                font.pixelSize: Looks.font.pixelSize.normal
                font.weight: Font.Medium
                color: Looks.colors.fg
                elide: Text.ElideRight
            }

            WText {
                width: parent.width
                text: root.secondaryText
                font.pixelSize: Looks.font.pixelSize.tiny
                color: Looks.colors.subfg
                elide: Text.ElideRight
            }
        }
    }

    // Weather description based on code
    readonly property string weatherDescription: Weather.describeWeather(Weather.data?.wCode ?? "113")

    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip
        text: root.hideLocation ? root.weatherDescription : (Weather.data?.city ?? Translation.tr("Unknown location"))
    }
}
