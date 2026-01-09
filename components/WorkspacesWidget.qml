import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Item {
    id: root
    implicitWidth: wsRow.implicitWidth + 12
    implicitHeight: 30

    property int maxWs: {
        if (!Hyprland.focusedMonitor) return 5
        var max = 5
        var list = Hyprland.workspaces?.values ?? []
        for (var i = 0; i < list.length; i++) {
            if (list[i].id > max) max = list[i].id
        }
        var active = Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
        if (active > max) max = active
        return max
    }

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.maxWs

            Item {
                id: ws
                property int wsId: index + 1
                property var focused: Hyprland.focusedMonitor?.activeWorkspace
                property bool active: focused?.id === wsId
                property bool occupied: {
                    var list = Hyprland.workspaces?.values ?? []
                    for (var i = 0; i < list.length; i++) {
                        if (list[i].id === wsId && list[i].windows > 0) return true
                    }
                    return false
                }

                width: 26
                height: 26

                Text {
                    anchors.centerIn: parent
                    text: active ? "\uf004" : (occupied ? "\uf004" : "\uf08a")
                    font.family: theme.font
                    font.pixelSize: 18
                    color: active ? theme.pink : (occupied ? theme.pink : theme.pinkSoft)
                    opacity: (active || occupied) ? 1.0 : 0.4
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + ws.wsId)
                }
            }
        }
    }
}
