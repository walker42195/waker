pragma Singleton
import QtQuick 2.12

/*
 * Wakers färger. Varje bakgrundstema (förrenderade "veil"-bilder) har en egen
 * bas och två accentfärger; resten av appen läser bara Theme.*.
 */
QtObject {
    id: theme

    property string themeId: "neon"

    readonly property var themes: [
        { id: "neon",   base: "#0b0d2a", a1: "#b46cff", a2: "#ff5fd2" },
        { id: "aurora", base: "#0d0b26", a1: "#c77dff", a2: "#ff6fb5" },
        { id: "ocean",  base: "#04161c", a1: "#2fd6c3", a2: "#5aa8ff" },
        { id: "ember",  base: "#160a12", a1: "#ff8a3d", a2: "#ff4f6d" },
        { id: "ice",    base: "#0a1426", a1: "#7fb6ff", a2: "#c9dcff" }
    ]

    function find(id) {
        for (var i = 0; i < themes.length; ++i)
            if (themes[i].id === id)
                return themes[i]
        return themes[0]
    }

    readonly property var current: find(themeId)
    readonly property url background: Qt.resolvedUrl("../../assets/themes/" + current.id + ".jpg")

    readonly property color base: current.base
    readonly property color accent1: current.a1
    readonly property color accent2: current.a2
    readonly property color accentSoft: Qt.rgba(accent1.r, accent1.g, accent1.b, 0.25)
    readonly property color accentBorder: Qt.rgba(accent1.r, accent1.g, accent1.b, 0.65)

    readonly property color text: "#f4f1ff"
    readonly property color textDim: Qt.rgba(0.96, 0.94, 1.0, 0.66)
    readonly property color textFaint: Qt.rgba(0.96, 0.94, 1.0, 0.42)
    // Mörkt tonat "glas" så att texten syns även över de ljusa vågorna
    readonly property color glass: Qt.rgba(base.r, base.g, base.b, 0.58)
    readonly property color glassStrong: Qt.rgba(base.r, base.g, base.b, 0.68)
    readonly property color glassBorder: Qt.rgba(1, 1, 1, 0.16)
    readonly property color danger: "#ff5f7a"
}
