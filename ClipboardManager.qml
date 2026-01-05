import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: clipboard
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

    property var items: []
    property var filteredItems: []
    property int selectedIndex: 0
    property string searchText: ""

    function show() {
        visible = true
        searchInput.text = ""
        searchText = ""
        selectedIndex = 0
        items = []
        filteredItems = []
        searchInput.forceActiveFocus()
        loadHistory()
    }

    function hide() {
        visible = false
    }

    function loadHistory() {
        historyProc.running = true
    }

    function filterItems() {
        if (searchText === "") {
            filteredItems = items.slice(0, 15)
        } else {
            var query = searchText.toLowerCase()
            var result = []
            for (var i = 0; i < items.length && result.length < 15; i++) {
                if (items[i].text.toLowerCase().indexOf(query) !== -1) {
                    result.push(items[i])
                }
            }
            filteredItems = result
        }
        selectedIndex = 0
    }

    function selectItem(id) {
        selectProc.command = ["sh", "-c", "echo '" + id + "' | cliphist decode | wl-copy"]
        selectProc.running = true
        hide()
    }

    Process {
        id: historyProc
        command: ["sh", "-c", "cliphist list"]
        stdout: SplitParser {
            onRead: data => {
                var idx = data.indexOf("\t")
                if (idx > 0) {
                    var id = data.substring(0, idx)
                    var text = data.substring(idx + 1)
                    var newItems = clipboard.items.slice()
                    newItems.push({ id: id, text: text })
                    clipboard.items = newItems
                }
            }
        }
        onExited: (code, status) => filterItems()
    }

    Process {
        id: selectProc
    }

    MouseArea {
        anchors.fill: parent
        onClicked: clipboard.hide()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 520
        height: 450
        radius: 16
        color: Theme.bgAlpha90
        border.width: 1
        border.color: Qt.rgba(Theme.magenta.r, Theme.magenta.g, Theme.magenta.b, 0.3)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 22
                color: Qt.rgba(Theme.magenta.r, Theme.magenta.g, Theme.magenta.b, 0.1)
                border.width: 1
                border.color: Qt.rgba(Theme.magenta.r, Theme.magenta.g, Theme.magenta.b, 0.2)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Text {
                        text: "\uf0c5"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        color: Theme.magenta
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.foreground
                        selectionColor: Theme.magenta
                        selectedTextColor: "#ffffff"
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: "Search clipboard..."
                            font: parent.font
                            color: Theme.muted
                            visible: !parent.text
                            verticalAlignment: Text.AlignVCenter
                        }

                        onTextChanged: {
                            clipboard.searchText = text
                            clipboard.filterItems()
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                clipboard.hide()
                            } else if (event.key === Qt.Key_Down) {
                                clipboard.selectedIndex = Math.min(clipboard.selectedIndex + 1, clipboard.filteredItems.length - 1)
                            } else if (event.key === Qt.Key_Up) {
                                clipboard.selectedIndex = Math.max(clipboard.selectedIndex - 1, 0)
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (clipboard.filteredItems.length > 0) {
                                    clipboard.selectItem(clipboard.filteredItems[clipboard.selectedIndex].id)
                                }
                            }
                        }
                    }

                    Text {
                        text: clipboard.items.length + " items"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.muted
                    }
                }
            }

            Text {
                Layout.leftMargin: 4
                text: clipboard.filteredItems.length > 0 ? "Clipboard History" : (clipboard.searchText.length > 0 ? "No matches found" : "Loading...")
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.muted
            }

            ListView {
                id: clipList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: clipboard.filteredItems
                clip: true
                spacing: 2
                currentIndex: clipboard.selectedIndex
                cacheBuffer: 400

                delegate: Rectangle {
                    width: clipList.width
                    height: 48
                    radius: 10
                    color: index === clipboard.selectedIndex ? Qt.rgba(Theme.magenta.r, Theme.magenta.g, Theme.magenta.b, 0.15) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 6
                            color: Qt.rgba(Theme.magenta.r, Theme.magenta.g, Theme.magenta.b, 0.1)

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    var t = modelData.text.toLowerCase()
                                    if (t.startsWith("http")) return "\uf0c1"
                                    if (t.includes("@")) return "\uf0e0"
                                    if (t.match(/^\d+$/)) return "\uf292"
                                    if (t.startsWith("/") || t.includes(":\\")) return "\uf07b"
                                    return "\uf15c"
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.magenta
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: {
                                    var t = modelData.text.replace(/\n/g, " ").replace(/\s+/g, " ").trim()
                                    return t.length > 50 ? t.substring(0, 50) + "…" : t
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: index === clipboard.selectedIndex ? Theme.magenta : Theme.foreground
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.text.length + " chars"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.muted
                            }
                        }

                        Text {
                            text: "\uf0ea"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.muted
                            visible: index === clipboard.selectedIndex
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clipboard.selectItem(modelData.id)
                        onEntered: clipboard.selectedIndex = index
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
                        color: Qt.rgba(Theme.magenta.r, Theme.magenta.g, Theme.magenta.b, 0.2)
                        Text {
                            anchors.centerIn: parent
                            text: "↵"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.magenta
                        }
                    }
                    Text { text: "paste"; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }
}
