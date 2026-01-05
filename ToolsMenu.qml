import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: root
    implicitWidth: 500
    implicitHeight: 450
    visible: false
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property string tempFile: ""
    property int selectedIndex: 0
    property string currentMode: "main"
    property string pendingAction: ""
    property string clipboardUrl: ""

    readonly property string saveDir: "$HOME/Pictures/Screenshots"
    readonly property string downloadDir: "$HOME/Downloads"

    readonly property var mainOptions: [
        { icon: "\uf030", label: "Screenshot", desc: "Capture screen or region", action: "screenshot" },
        { icon: "\uf15c", label: "OCR Text", desc: "Extract text from screen", action: "ocr" },
        { icon: "\uf1fb", label: "Color Picker", desc: "Pick color from screen", action: "colorpicker" },
        { icon: "\uf019", label: "Downloader", desc: "Download video or audio", action: "downloader" }
    ]

    readonly property var screenshotOptions: [
        { icon: "\uf03e", label: "Capture Region", desc: "Select area to capture", action: "region" },
        { icon: "\uf108", label: "Full Screen", desc: "Capture entire screen", action: "fullscreen" },
        { icon: "\uf2d0", label: "Active Window", desc: "Capture current window", action: "window" }
    ]

    readonly property var postOptions: [
        { icon: "\uf0c5", label: "Copy to Clipboard", desc: "Copy image to clipboard", action: "clipboard" },
        { icon: "\uf0c7", label: "Save to Pictures", desc: "Save in Screenshots folder", action: "save" }
    ]

    readonly property var downloadOptions: [
        { icon: "\uf03d", label: "Video", desc: "Download best quality video", action: "video" },
        { icon: "\uf001", label: "Audio", desc: "Download as MP3", action: "audio" }
    ]

    function show() {
        currentMode = "main"
        selectedIndex = 0
        visible = true
    }

    function hide() {
        visible = false
        currentMode = "main"
    }

    function currentOptions() {
        if (currentMode === "main") return mainOptions
        if (currentMode === "screenshot") return screenshotOptions
        if (currentMode === "post") return postOptions
        if (currentMode === "downloader") return downloadOptions
        return mainOptions
    }

    function currentTitle() {
        if (currentMode === "main") return "Tools"
        if (currentMode === "screenshot") return "Screenshot"
        if (currentMode === "post") return "What to do?"
        if (currentMode === "downloader") return "Download"
        return "Tools"
    }

    function handleAction(action) {
        if (currentMode === "main") {
            if (action === "screenshot") {
                currentMode = "screenshot"
                selectedIndex = 0
            } else if (action === "ocr") {
                pendingAction = "ocr"
                hide()
            } else if (action === "colorpicker") {
                pendingAction = "colorpicker"
                hide()
            } else if (action === "downloader") {
                clipboardProc.running = true
            }
        } else if (currentMode === "screenshot") {
            pendingAction = "screenshot_" + action
            hide()
        } else if (currentMode === "post") {
            doPostAction(action)
        } else if (currentMode === "downloader") {
            doDownload(action)
        }
    }

    function showPostMenu() {
        currentMode = "post"
        selectedIndex = 0
        visible = true
    }

    function doPostAction(action) {
        if (action === "clipboard") {
            Hyprland.dispatch("exec wl-copy < '" + tempFile + "' && notify-send 'Screenshot' 'Copied to clipboard' && rm '" + tempFile + "'")
        } else if (action === "save") {
            Hyprland.dispatch("exec mkdir -p '" + saveDir + "' && mv '" + tempFile + "' '" + saveDir + "/' && notify-send 'Screenshot' 'Saved'")
        }
        hide()
    }

    function doDownload(type) {
        if (clipboardUrl === "") {
            Hyprland.dispatch("exec notify-send 'Downloader' 'No valid URL in clipboard'")
            hide()
            return
        }

        var cmd = type === "video"
            ? "yt-dlp -o '" + downloadDir + "/%(title)s.%(ext)s' '" + clipboardUrl + "'"
            : "yt-dlp -x --audio-format mp3 -o '" + downloadDir + "/%(title)s.%(ext)s' '" + clipboardUrl + "'"

        Hyprland.dispatch("exec notify-send 'Downloader' 'Starting download...' && " + cmd + " && notify-send 'Downloader' 'Download complete' || notify-send 'Downloader' 'Download failed'")
        hide()
    }

    onVisibleChanged: {
        if (!visible && pendingAction !== "") {
            actionTimer.start()
        }
    }

    Process {
        id: clipboardProc
        command: ["wl-paste", "-n"]
        stdout: SplitParser {
            onRead: data => {
                if (data.match(/^https?:\/\//)) {
                    root.clipboardUrl = data
                    root.currentMode = "downloader"
                    root.selectedIndex = 0
                } else {
                    root.clipboardUrl = ""
                    Hyprland.dispatch("exec notify-send 'Downloader' 'No valid URL in clipboard'")
                }
            }
        }
    }

    Timer {
        id: actionTimer
        interval: 150
        onTriggered: {
            var action = root.pendingAction
            root.pendingAction = ""

            if (action === "ocr") {
                Hyprland.dispatch("exec grim -g \"$(slurp)\" /tmp/ocr_tmp.png && tesseract /tmp/ocr_tmp.png - -l eng 2>/dev/null | wl-copy && notify-send 'OCR' 'Text copied to clipboard' && rm /tmp/ocr_tmp.png")
            } else if (action === "colorpicker") {
                Hyprland.dispatch("exec hyprpicker -a -f hex && notify-send 'Color Picker' 'Color copied to clipboard'")
            } else if (action.startsWith("screenshot_")) {
                var type = action.replace("screenshot_", "")
                var filename = "/tmp/screenshot_" + Date.now() + ".png"
                root.tempFile = filename

                if (type === "region") {
                    Hyprland.dispatch("exec grim -g \"$(slurp)\" '" + filename + "'")
                } else if (type === "fullscreen") {
                    Hyprland.dispatch("exec grim '" + filename + "'")
                } else if (type === "window") {
                    Hyprland.dispatch("exec grim -g \"$(hyprctl activewindow -j | jq -r '.at[0],.at[1],.size[0],.size[1]' | tr '\\n' ' ' | awk '{print $1\",\"$2\" \"$3\"x\"$4}')\" '" + filename + "'")
                }
                fileCheckTimer.start()
            }
        }
    }

    Timer {
        id: fileCheckTimer
        interval: 200
        repeat: true
        property int attempts: 0
        onTriggered: {
            attempts++
            fileCheckProc.command = ["test", "-f", root.tempFile]
            fileCheckProc.running = true
            if (attempts > 30) {
                stop()
                attempts = 0
            }
        }
    }

    Process {
        id: fileCheckProc
        onExited: (code, status) => {
            if (code === 0) {
                fileCheckTimer.stop()
                fileCheckTimer.attempts = 0
                root.showPostMenu()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 380
        height: currentMode === "main" ? 300 : 260
        radius: 16
        color: Theme.bgAlpha90
        border.width: 1
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: currentMode === "main" ? "\uf0ad" : (currentMode === "downloader" ? "\uf019" : "\uf030")
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    color: Theme.accent
                }

                Text {
                    text: root.currentTitle()
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: Theme.foreground
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "\uf053"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: backMouse.containsMouse ? Theme.accent : Theme.muted
                    visible: currentMode !== "main"

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentMode = "main"
                            root.selectedIndex = 0
                        }
                    }
                }

                Text {
                    text: "\uf00d"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: closeMouse.containsMouse ? Theme.error : Theme.muted

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.hide()
                    }
                }
            }

            ListView {
                id: optionsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.currentOptions()
                clip: true
                spacing: 4
                currentIndex: root.selectedIndex
                focus: true
                cacheBuffer: 200

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        if (root.currentMode !== "main") {
                            root.currentMode = "main"
                            root.selectedIndex = 0
                        } else {
                            root.hide()
                        }
                    } else if (event.key === Qt.Key_Down) {
                        root.selectedIndex = Math.min(root.selectedIndex + 1, optionsList.count - 1)
                    } else if (event.key === Qt.Key_Up) {
                        root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        var item = optionsList.model[root.selectedIndex]
                        root.handleAction(item.action)
                    }
                }

                delegate: Rectangle {
                    width: optionsList.width
                    height: 50
                    radius: 10
                    color: index === root.selectedIndex ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 8
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                color: Theme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: index === root.selectedIndex ? Theme.accent : Theme.foreground
                            }

                            Text {
                                text: modelData.desc
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.muted
                            }
                        }

                        Text {
                            text: "\uf054"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.muted
                            visible: index === root.selectedIndex
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.handleAction(modelData.action)
                        onEntered: root.selectedIndex = index
                    }
                }
            }
        }
    }
}
