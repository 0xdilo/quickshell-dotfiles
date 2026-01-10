import QtQuick
import Quickshell.Hyprland

Rectangle {
    id: root
    implicitWidth: 30
    implicitHeight: 30
    radius: 15
    color: powerMouse.containsMouse ? Qt.rgba(theme.pink.r, theme.pink.g, theme.pink.b, 0.25) : Qt.rgba(theme.pink.r, theme.pink.g, theme.pink.b, 0.1)
    border.width: 1
    border.color: powerMouse.containsMouse ? theme.pink : Qt.rgba(theme.pink.r, theme.pink.g, theme.pink.b, 0.3)

    Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.OutQuad } }
    Behavior on border.color { ColorAnimation { duration: 100; easing.type: Easing.OutQuad } }

    Text {
        anchors.centerIn: parent
        text: "⏻"
        font.pixelSize: 15
        font.weight: Font.Medium
        color: powerMouse.containsMouse ? theme.pink : theme.pinkSoft

        Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.OutQuad } }

    }

    MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) Hyprland.dispatch("exec wlogout")
            else Hyprland.dispatch("exec hyprlock")
        }
    }
}
