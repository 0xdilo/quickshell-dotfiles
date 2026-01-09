import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: launcher
    implicitWidth: 500
    implicitHeight: 450
    visible: false
    color: "transparent"

    signal closed()

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property var apps: []
    property var filteredApps: []
    property int selectedIndex: 0
    property string searchText: ""
    property bool appsLoaded: false

    property var commands: []

    Component.onCompleted: loadApps()

    function show() {
        if (!appsLoaded) loadApps()
        searchInput.text = ""
        searchText = ""
        selectedIndex = 0
        filteredApps = apps.slice(0, 12)
        visible = true
        searchInput.forceActiveFocus()
    }

    function hide() {
        visible = false
        closed()
    }

    function loadApps() {
        appsProc.running = true
    }

    function filterApps() {
        if (searchText === "") {
            filteredApps = apps.slice(0, 12)
            commands = []
        } else {
            var query = searchText.toLowerCase()
            var result = []

            for (var j = 0; j < apps.length && result.length < 8; j++) {
                if (apps[j].name.toLowerCase().indexOf(query) !== -1) {
                    result.push(apps[j])
                }
            }

            if (result.length < 8 && searchText.length >= 2) {
                cmdProc.command = ["sh", "-c", "compgen -c " + searchText + " 2>/dev/null | head -5"]
                cmdProc.running = true
            }

            filteredApps = result
        }
        selectedIndex = 0
    }

    Process {
        id: cmdProc
        stdout: SplitParser {
            onRead: data => {
                if (data && data.length > 0) {
                    var newCmds = launcher.commands.slice()
                    newCmds.push({ name: data, exec: data, icon: "", isCmd: true })
                    launcher.commands = newCmds
                    var newFiltered = launcher.filteredApps.slice()
                    if (newFiltered.length < 12) {
                        newFiltered.push({ name: data, exec: data, icon: "", isCmd: true })
                        launcher.filteredApps = newFiltered
                    }
                }
            }
        }
        onStarted: launcher.commands = []
    }

    function launchApp(exec) {
        var cmd = exec.replace(/%[fFuUdDnNickvm]/g, "").trim()
        Hyprland.dispatch("exec " + cmd)
        hide()
    }

    function runCommand(cmd) {
        Hyprland.dispatch("exec " + cmd)
        hide()
    }

    Process {
        id: appsProc
        command: ["sh", "-c", "find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null | while read f; do name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2); exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2); icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2); nodisplay=$(grep -m1 '^NoDisplay=' \"$f\" | cut -d= -f2); if [ -n \"$name\" ] && [ -n \"$exec\" ] && [ \"$nodisplay\" != \"true\" ]; then echo \"$name|||$exec|||$icon\"; fi; done | sort -u"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("|||")
                if (parts.length >= 2) {
                    var newApps = launcher.apps.slice()
                    newApps.push({ name: parts[0], exec: parts[1], icon: parts[2] || "", isCmd: false })
                    launcher.apps = newApps
                }
            }
        }
        onExited: (code, status) => {
            appsLoaded = true
            filterApps()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: launcher.hide()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 480
        height: 420
        radius: 16
        color: Theme.bgAlpha90
        border.width: 1
        border.color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.3)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 22
                color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.1)
                border.width: 1
                border.color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.2)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Text {
                        text: "\uf002"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        color: Theme.secondary
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.foreground
                        selectionColor: Theme.secondary
                        selectedTextColor: "#ffffff"
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: "Search apps or commands..."
                            font: parent.font
                            color: Theme.muted
                            visible: !parent.text
                            verticalAlignment: Text.AlignVCenter
                        }

                        onTextChanged: {
                            launcher.searchText = text
                            launcher.filterApps()
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                launcher.hide()
                            } else if (event.key === Qt.Key_Down) {
                                launcher.selectedIndex = Math.min(launcher.selectedIndex + 1, launcher.filteredApps.length - 1)
                            } else if (event.key === Qt.Key_Up) {
                                launcher.selectedIndex = Math.max(launcher.selectedIndex - 1, 0)
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (launcher.filteredApps.length > 0) {
                                    launcher.launchApp(launcher.filteredApps[launcher.selectedIndex].exec)
                                } else if (launcher.searchText.length > 0) {
                                    launcher.runCommand(launcher.searchText)
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.leftMargin: 4
                text: launcher.filteredApps.length > 0 ? (launcher.filteredApps[0].isCmd ? "Commands" : "Applications") : (launcher.searchText.length > 0 ? "Press Enter to run: " + launcher.searchText : "Type to search...")
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.muted
            }

            ListView {
                id: appsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: launcher.filteredApps
                clip: true
                spacing: 2
                currentIndex: launcher.selectedIndex
                cacheBuffer: 400

                delegate: Rectangle {
                    width: appsList.width
                    height: 42
                    radius: 10
                    color: index === launcher.selectedIndex ? Qt.rgba(modelData.isCmd ? Theme.accent.r : Theme.secondary.r, modelData.isCmd ? Theme.accent.g : Theme.secondary.g, modelData.isCmd ? Theme.accent.b : Theme.secondary.b, 0.15) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 6
                            color: Qt.rgba(modelData.isCmd ? Theme.accent.r : Theme.magenta.r, modelData.isCmd ? Theme.accent.g : Theme.magenta.g, modelData.isCmd ? Theme.accent.b : Theme.magenta.b, 0.1)

                            Image {
                                id: appIcon
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: modelData.icon ? "image://icon/" + modelData.icon : ""
                                sourceSize: Qt.size(20, 20)
                                visible: status === Image.Ready
                                asynchronous: true
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.isCmd ? "\uf120" : "\uf135"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: modelData.isCmd ? Theme.accent : Theme.magenta
                                visible: appIcon.status !== Image.Ready
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: index === launcher.selectedIndex ? (modelData.isCmd ? Theme.accent : Theme.secondary) : Theme.foreground
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: modelData.isCmd
                                text: modelData.exec
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.muted
                            }
                        }

                        Text {
                            text: modelData.isCmd ? "\uf0e7" : "\uf054"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.muted
                            visible: index === launcher.selectedIndex
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: launcher.launchApp(modelData.exec)
                        onEntered: launcher.selectedIndex = index
                    }
                }
            }

            Row {
                Layout.alignment: Qt.AlignRight
                spacing: 16

                Row {
                    spacing: 6
                    Rectangle {
                        width: 18; height: 18; radius: 4
                        color: Qt.rgba(1, 1, 1, 0.1)
                        Text {
                            anchors.centerIn: parent
                            text: "↑↓"
                            font.family: Theme.fontFamily
                            font.pixelSize: 8
                            color: Theme.muted
                        }
                    }
                    Text { text: "nav"; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                }

                Row {
                    spacing: 6
                    Rectangle {
                        width: 28; height: 18; radius: 4
                        color: Qt.rgba(1, 1, 1, 0.1)
                        Text {
                            anchors.centerIn: parent
                            text: "esc"
                            font.family: Theme.fontFamily
                            font.pixelSize: 8
                            color: Theme.muted
                        }
                    }
                    Text { text: "close"; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                }

                Row {
                    spacing: 6
                    Rectangle {
                        width: 18; height: 18; radius: 4
                        color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.2)
                        Text {
                            anchors.centerIn: parent
                            text: "↵"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.secondary
                        }
                    }
                    Text { text: "launch"; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }
}
