import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    id: root
    implicitWidth: netRow.implicitWidth + 16
    implicitHeight: 28
    radius: 14
    color: netMouse.containsMouse ? Qt.rgba(theme.icon.r, theme.icon.g, theme.icon.b, 0.1) : "transparent"

    Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.OutQuad } }

    property string ssid: ""
    property string status: "disconnected"

    Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    Process {
        id: netProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2"]
        stdout: SplitParser {
            onRead: data => { if (data && data.length > 0) { ssid = data; status = "wifi" } }
        }
        onExited: (code, st) => { if (!ssid) ethProc.running = true }
    }

    Process {
        id: ethProc
        command: ["sh", "-c", "nmcli -t -f type,state dev 2>/dev/null | grep '^ethernet:connected'"]
        stdout: SplitParser {
            onRead: data => { if (data) { status = "ethernet"; ssid = "Wired" } }
        }
        onExited: (code, st) => {
            if (status !== "wifi" && status !== "ethernet") { status = "disconnected"; ssid = "" }
        }
    }

    Row {
        id: netRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: status === "ethernet" ? "\uf6ff" : "\uf1eb"
            font.family: theme.font
            font.pixelSize: 16
            color: status === "disconnected" ? theme.textMuted : theme.icon
            anchors.verticalCenter: parent.verticalCenter

        }

        Text {
            text: ssid || "Offline"
            font.family: theme.font
            font.pixelSize: 12
            font.weight: Font.Medium
            color: netMouse.containsMouse ? theme.iconHover : theme.text
            anchors.verticalCenter: parent.verticalCenter
            visible: ssid.length > 0 || status === "disconnected"

            Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.OutQuad } }
        }
    }

    MouseArea {
        id: netMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("exec nm-connection-editor")
    }
}
