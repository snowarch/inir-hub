pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.modules.common.widgets
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    showClickabilityButton: false
    resizable: false
    clickthrough: true

    property string imageSource: Config.options?.overlay?.floatingImage?.imageSource ?? ""
    property real scaleFactor: Config.options?.overlay?.floatingImage?.scale ?? 0.5
    property int imageWidth: 0
    property int imageHeight: 0
    property string pendingImageSource: ""
    readonly property bool hasConfiguredSource: imageSource.trim().length > 0
    readonly property bool isRemoteSource: /^https?:\/\//i.test(imageSource)

    Component.onCompleted: root.pendingImageSource = root.imageSource

    // Override to always save 0 size
    function savePosition(xPos = root.x, yPos = root.y, width = 0, height = 0) {
        root.persistentStateEntry.x = Math.round(xPos);
        root.persistentStateEntry.y = Math.round(yPos);
        root.persistentStateEntry.width = 0
        root.persistentStateEntry.height = 0
    }

    onImageSourceChanged: {
        root.pendingImageSource = root.imageSource;

        if (!root.hasConfiguredSource) {
            imageDownloader.running = false;
            root.imageWidth = 0;
            root.imageHeight = 0;
            animatedImage.source = "";
            root.setSize();
            return;
        }

        root.imageWidth = 0;
        root.imageHeight = 0;
        root.setSize();

        if (!root.isRemoteSource) {
            imageDownloader.running = false;
            animatedImage.source = root.imageSource;
            return;
        }

        imageDownloader.running = false;
        imageDownloader.sourceUrl = root.imageSource;
        imageDownloader.filePath = Qt.resolvedUrl(Directories.tempImages + "/" + Qt.md5(root.imageSource))
        imageDownloader.running = true;
    }
    onScaleFactorChanged: {
        setSize();
    }

    function setSize() {
        if (!root.hasConfiguredSource || root.imageWidth <= 0 || root.imageHeight <= 0) {
            bg.implicitWidth = 340;
            bg.implicitHeight = 164;
            return;
        }

        bg.implicitWidth = root.imageWidth * root.scaleFactor;
        bg.implicitHeight = root.imageHeight * root.scaleFactor;
    }

    function applyImageSource(rawSource: string): void {
        const source = rawSource.trim();
        if (!source.length)
            return;

        Config.setNestedValue("overlay.floatingImage.imageSource", source);
        root.pendingImageSource = source;
    }

    contentItem: OverlayBackground {
        id: bg
        color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, root.actuallyPinned ? 1 : 0)
        radius: root.contentRadius

        WheelHandler {
            onWheel: (event) => {
                const currentScale = Config.options?.overlay?.floatingImage?.scale ?? 0.5;
                if (event.angleDelta.y < 0) {
                    Config.setNestedValue("overlay.floatingImage.scale", Math.max(0.1, currentScale - 0.1));
                }
                else if (event.angleDelta.y > 0) {
                    Config.setNestedValue("overlay.floatingImage.scale", Math.min(5.0, currentScale + 0.1));
                }
            }
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: bg.width
                height: bg.height
                radius: bg.radius
            }
        }

        AnimatedImage {
            id: animatedImage
            anchors.centerIn: parent
            visible: root.hasConfiguredSource
            width: root.imageWidth * root.scaleFactor
            height: root.imageHeight * root.scaleFactor
            sourceSize.width: width
            sourceSize.height: height

            playing: visible
            asynchronous: true
            source: ""
            onStatusChanged: {
                if (status === Image.Ready) {
                    root.imageWidth = sourceSize.width > 0 ? sourceSize.width : Math.max(1, implicitWidth)
                    root.imageHeight = sourceSize.height > 0 ? sourceSize.height : Math.max(1, implicitHeight)
                    root.setSize();
                }
            }

            ImageDownloaderProcess {
                id: imageDownloader
                filePath: Qt.resolvedUrl(Directories.tempImages + "/" + Qt.md5(root.imageSource))
                sourceUrl: root.imageSource

                onDone: (path, width, height) => {
                    root.imageWidth = Number.isFinite(width) && width > 0 ? width : 0;
                    root.imageHeight = Number.isFinite(height) && height > 0 ? height : 0;
                    root.setSize();
                    animatedImage.source = path;
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: !root.hasConfiguredSource

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 16, 320)
                spacing: 8

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: Translation.tr("No image configured")
                    font.pixelSize: Appearance.font.pixelSize.normal
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Add a GIF or image URL, or pick a local file.")
                    font.pixelSize: Appearance.font.pixelSize.small
                }

                MaterialTextField {
                    id: sourceField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("https://... or file:///...")
                    text: root.pendingImageSource
                    onTextChanged: root.pendingImageSource = text
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RippleButton {
                        Layout.fillWidth: true
                        onClicked: root.applyImageSource(sourceField.text)
                        contentItem: StyledText {
                            anchors.centerIn: parent
                            text: Translation.tr("Apply source")
                        }
                    }

                    RippleButton {
                        Layout.fillWidth: true
                        onClicked: fileDialog.open()
                        contentItem: StyledText {
                            anchors.centerIn: parent
                            text: Translation.tr("Pick file")
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: Translation.tr("Select image or GIF")
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.gif *.bmp *.svg)", "All files (*)"]
        onAccepted: {
            root.applyImageSource(selectedFile.toString())
        }
    }
}
