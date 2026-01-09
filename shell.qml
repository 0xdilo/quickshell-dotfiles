import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "components"

ShellRoot {
    id: shell

    property bool hasScreens: Quickshell.screens.length > 0
    property string activeMonitor: hasScreens ? (Hyprland.focusedMonitor?.name ?? "") : ""

    IpcHandler {
        target: "shell"

        function toggleLauncherIpc() { shell.toggleLauncher() }
        function toggleClipboardIpc() { shell.toggleClipboard() }
        function toggleToolsIpc() { shell.toggleTools() }
    }

    property bool launcherOpen: false
    property bool clipboardOpen: false
    property bool toolsOpen: false

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Launcher {
                id: launcherInstance
                required property var modelData
                screen: modelData

                property bool shouldShow: shell.launcherOpen && modelData.name === shell.activeMonitor

                onShouldShowChanged: {
                    if (shouldShow) show()
                }

                onClosed: shell.launcherOpen = false
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            ClipboardManager {
                id: clipboardInstance
                required property var modelData
                screen: modelData

                property bool shouldShow: shell.clipboardOpen && modelData.name === shell.activeMonitor

                onShouldShowChanged: {
                    if (shouldShow) show()
                }

                onClosed: shell.clipboardOpen = false
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            ToolsMenu {
                id: toolsInstance
                required property var modelData
                screen: modelData

                property bool shouldShow: shell.toolsOpen && modelData.name === shell.activeMonitor

                onShouldShowChanged: {
                    if (shouldShow) show()
                }

                onClosed: shell.toolsOpen = false
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                required property var modelData
                targetScreen: modelData
                onLauncherRequested: shell.toggleLauncher()
            }
        }
    }

    property int osdVolume: 50
    property int osdBrightness: 50
    property string osdType: "volume"
    property bool osdVisible: false
    property int lastVolume: -1
    property int lastBrightness: -1

    Timer {
        id: pollTimer
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            checkVolumeProc.running = true
            checkBrightnessProc.running = true
        }
    }

    Process {
        id: checkVolumeProc
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+%' | head -1 | tr -d '%'"]
        stdout: SplitParser {
            onRead: data => {
                var newVolume = parseInt(data) || 0
                if (newVolume !== shell.lastVolume && shell.lastVolume !== -1) {
                    shell.osdVolume = newVolume
                    shell.osdType = "volume"
                    shell.osdVisible = true
                    hideTimer.restart()
                }
                shell.lastVolume = newVolume
            }
        }
    }

    Process {
        id: checkBrightnessProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | cut -d',' -f4 | tr -d '%'"]
        stdout: SplitParser {
            onRead: data => {
                var newBrightness = parseInt(data) || 0
                if (newBrightness !== shell.lastBrightness && shell.lastBrightness !== -1) {
                    shell.osdBrightness = newBrightness
                    shell.osdType = "brightness"
                    shell.osdVisible = true
                    hideTimer.restart()
                }
                shell.lastBrightness = newBrightness
            }
        }
    }

    IpcHandler {
        target: "osd"

        function show() {
            shell.osdVisible = true
            hideTimer.restart()
        }

        function hide() {
            shell.osdVisible = false
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: osdVisible = false
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: osdWindow
                required property var modelData
                screen: modelData

                property bool shouldShow: modelData.name === shell.activeMonitor && shell.osdVisible

                visible: shouldShow

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay

                Rectangle {
                    id: osdCard
                    width: 280
                    height: 56
                    radius: 28
                    color: Theme.background
                    border.width: 1
                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 80

                    opacity: osdWindow.shouldShow ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    property bool isVolume: shell.osdType === "volume"
                    property int value: isVolume ? shell.osdVolume : shell.osdBrightness

                    Row {
                        anchors.centerIn: parent
                        spacing: 14

                        Text {
                            text: {
                                if (osdCard.isVolume) {
                                    return shell.osdVolume === 0 ? "\uf026" : (shell.osdVolume < 50 ? "\uf027" : "\uf028")
                                } else {
                                    return shell.osdBrightness < 30 ? "\uf185" : (shell.osdBrightness < 70 ? "\uf185" : "\uf185")
                                }
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            color: Theme.accent
                            opacity: osdCard.isVolume ? 1 : (shell.osdBrightness < 30 ? 0.5 : 1)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            width: 160
                            height: 6
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                anchors.fill: parent
                                radius: 3
                                color: Theme.surface
                            }

                            Rectangle {
                                id: barFill
                                width: parent.width * osdCard.value / 100
                                height: parent.height
                                radius: 3

                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Theme.secondary }
                                    GradientStop { position: 0.5; color: Theme.accent }
                                    GradientStop { position: 1.0; color: Qt.lighter(Theme.accent, 1.2) }
                                }

                                                            }

                            Rectangle {
                                width: barFill.width
                                height: parent.height + 8
                                y: -4
                                radius: 6
                                visible: osdCard.value > 0
                                opacity: 0.3

                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.7; color: Theme.accent }
                                    GradientStop { position: 1.0; color: Theme.accent }
                                }

                                                            }
                        }

                        Text {
                            text: osdCard.value + "%"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Theme.foreground
                            width: 36
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    function toggleLauncher() {
        shell.launcherOpen = !shell.launcherOpen
    }

    function toggleClipboard() {
        shell.clipboardOpen = !shell.clipboardOpen
    }

    function toggleTools() {
        shell.toolsOpen = !shell.toolsOpen
    }
}
