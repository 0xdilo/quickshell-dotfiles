import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    id: root
    implicitWidth: volRow.implicitWidth + 18
    implicitHeight: 28
    radius: 14
    color: volMouse.containsMouse ? Qt.rgba(theme.lavender.r, theme.lavender.g, theme.lavender.b, 0.15) : "transparent"

    property int vol: 0
    property bool muted: false

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            volProc.running = true
            muteProc.running = true
        }
    }

    Process {
        id: volProc
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+%' | head -1 | tr -d '%'"]
        stdout: SplitParser { onRead: data => vol = parseInt(data) || 0 }
    }

    Process {
        id: muteProc
        command: ["sh", "-c", "pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q yes && echo 1 || echo 0"]
        stdout: SplitParser { onRead: data => muted = (parseInt(data) === 1) }
    }

    Process {
        id: setVolProc
        command: ["sh", "-c", "pactl set-sink-volume @DEFAULT_SINK@ " + volChange]
        property string volChange
    }

    Process {
        id: setMuteProc
        command: ["sh", "-c", "pactl set-sink-mute @DEFAULT_SINK@ toggle"]
    }

    Row {
        id: volRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: muted ? "\uf00d" : (vol < 30 ? "\uf026" : (vol < 70 ? "\uf027" : "\uf028"))
            font.family: theme.font
            font.pixelSize: 18
            color: muted ? theme.textMuted : theme.lavender
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: vol + "%"
            font.family: theme.font
            font.pixelSize: 13
            font.weight: Font.Medium
            color: muted ? theme.textMuted : (volMouse.containsMouse ? theme.lavender : theme.text)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: volMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) Hyprland.dispatch("exec pavucontrol")
            else {
                setMuteProc.running = true
                muteProc.running = true
            }
        }

        onWheel: wheel => {
            var delta = wheel.angleDelta.y > 0 ? "+5%" : "-5%"
            setVolProc.volChange = delta
            setVolProc.running = true
            volProc.running = true
        }
    }
}
