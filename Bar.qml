import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "components"

PanelWindow {
    id: bar

    signal launcherRequested()

    required property var targetScreen
    screen: targetScreen

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 38
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.exclusiveZone: 38

    QtObject {
        id: theme

        property color bg: Theme.bgAlpha90
        property color bgSoft: Theme.surface
        property color bgCard: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.95)
        property color bgHover: Qt.lighter(Theme.surface, 1.1)

        property color pink: Theme.secondary
        property color pinkSoft: Qt.lighter(Theme.secondary, 1.2)
        property color pinkPale: Theme.secondary
        property color lavender: Theme.magenta
        property color lavenderSoft: Qt.lighter(Theme.magenta, 1.1)
        property color mint: Theme.accent
        property color mintSoft: Qt.lighter(Theme.accent, 1.1)
        property color peach: Theme.yellow
        property color cream: Theme.surface
        property color sky: Theme.blue

        property color text: Theme.foreground
        property color textSoft: Qt.darker(Theme.foreground, 1.1)
        property color textMuted: Theme.muted

        property string font: Theme.fontFamily
        property int fontSize: 13
        property int fontSizeLg: 15
        property int fontSizeXl: 18
        property int fontSizeIcon: 18
        property int fontSizeIconLg: 20

        property int radius: 0
        property int radiusMd: 0
        property int radiusSm: 0
    }

    Rectangle {
        id: barBg
        anchors.fill: parent
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.85)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            RowLayout {
                spacing: 10
                LogoWidget { onClicked: bar.launcherRequested() }
                ClockWidget {}
                TrayWidget {}
            }

            WindowTitle {
                Layout.fillWidth: true
                Layout.maximumWidth: 220
            }

            Item { Layout.fillWidth: true }

            WorkspacesWidget {}

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 6

                SystemWidget {}
                NetworkWidget {}
                BluetoothWidget {}
                MediaWidget {}
                VolumeWidget {}
                BatteryWidget {}
            }
        }
    }
}
