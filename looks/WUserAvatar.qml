pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

Item {
    id: root
    property size sourceSize: Qt.size(32, 32)
    readonly property list<string> avatarCandidates: [
        Directories.userAvatarPathRicersAndWeirdSystems,
        Directories.userAvatarPathAccountsService,
        Directories.userAvatarPathRicersAndWeirdSystems2
    ]

    width: sourceSize.width
    height: sourceSize.height
    implicitWidth: sourceSize.width
    implicitHeight: sourceSize.height
    Layout.preferredWidth: sourceSize.width
    Layout.preferredHeight: sourceSize.height

    function reloadAvatarSource(): void {
        avatarSourceProbe.running = false
        avatarSourceProbe.running = true
    }

    Component.onCompleted: reloadAvatarSource()

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: Looks.colors.bg2Base
        visible: avatarImage.status !== Image.Ready
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: "person"
        iconSize: Math.round(root.sourceSize.width * 0.55)
        color: Looks.colors.subfg
        visible: avatarImage.status !== Image.Ready
    }

    Rectangle {
        id: avatarMask
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        visible: false
    }

    Process {
        id: avatarSourceProbe
        running: false
        command: [
            "/usr/bin/bash",
            "-lc",
            "for p in \"$@\"; do if [ -f \"$p\" ]; then printf '%s' \"$p\"; exit 0; fi; done; exit 1",
            "avatar-source-probe",
            ...root.avatarCandidates
        ]
        stdout: StdioCollector {
            id: avatarSourceProbeOutput
            onStreamFinished: {
                const resolved = avatarSourceProbeOutput.text.trim()
                avatarImage.source = resolved.length > 0
                    ? (resolved.startsWith("file://") ? resolved : `file://${resolved}`)
                    : ""
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                avatarImage.source = ""
        }
    }

    Image {
        id: avatarImage
        anchors.fill: parent
        sourceSize: Qt.size(root.sourceSize.width * 2, root.sourceSize.height * 2)
        fillMode: Image.PreserveAspectCrop
        source: ""
        cache: true
        smooth: true
        mipmap: true
        asynchronous: true
        visible: false
        onStatusChanged: {
            if (status === Image.Error)
                root.reloadAvatarSource()
        }
    }

    OpacityMask {
        anchors.fill: parent
        source: avatarImage
        maskSource: avatarMask
        visible: avatarImage.status === Image.Ready
    }
}
