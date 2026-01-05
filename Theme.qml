pragma Singleton
import QtQuick

QtObject {
    readonly property color background: "#241b1e"
    readonly property color surface: "#2b2024"
    readonly property color foreground: "#dad6d8"
    readonly property color muted: "#6c515a"

    readonly property color accent: "#9d4746"
    readonly property color secondary: "#469c9d"

    readonly property color red: "#c5413f"
    readonly property color blue: "#3fc3c5"
    readonly property color yellow: "#67f767"
    readonly property color magenta: "#6767f7"
    readonly property color pink: "#95848c"
    readonly property color error: "#f38ba8"

    readonly property color bgAlpha90: Qt.rgba(background.r, background.g, background.b, 0.9)
    readonly property color bgAlpha80: Qt.rgba(background.r, background.g, background.b, 0.8)
    readonly property color bgAlpha50: Qt.rgba(0, 0, 0, 0.5)

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}
