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
    property int osdBrightness: 0
    property bool osdVisible: false
    property int lastVolume: -1

    Timer {
        id: volumeCheckTimer
        interval: 200
        running: true
        repeat: true

        onTriggered: {
            checkVolumeProc.running = true
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
                    shell.osdVisible = true
                    hideTimer.restart()
                }
                shell.lastVolume = newVolume
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
                    scale: osdWindow.shouldShow ? 1 : 0.8

                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 14

                        Text {
                            text: shell.osdVolume === 0 ? "\uf6a9" : (shell.osdVolume < 50 ? "\uf027" : "\uf028")
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            width: 160
                            height: 6
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: barBg
                                anchors.fill: parent
                                radius: 3
                                color: Theme.surface
                            }

                            Rectangle {
                                id: barFill
                                width: parent.width * shell.osdVolume / 100
                                height: parent.height
                                radius: 3

                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Theme.secondary }
                                    GradientStop { position: 0.5; color: Theme.accent }
                                    GradientStop { position: 1.0; color: Qt.lighter(Theme.accent, 1.2) }
                                }

                                Behavior on width {
                                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                }
                            }

                            Rectangle {
                                id: barGlow
                                width: barFill.width
                                height: parent.height + 8
                                y: -4
                                radius: 6
                                visible: shell.osdVolume > 0
                                opacity: 0.3

                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.7; color: Theme.accent }
                                    GradientStop { position: 1.0; color: Theme.accent }
                                }

                                Behavior on width {
                                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        Text {
                            text: shell.osdVolume + "%"
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
