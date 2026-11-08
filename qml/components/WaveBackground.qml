import QtQuick 2.12

/*
 * Böljande bakgrund som är billig att rita.
 *
 * En förrenderad ultrabred bild (3440×1440-förhållande) panoreras långsamt
 * fram och tillbaka (ca 80 s per riktning). Ett spegelvänt lager tonas in och
 * ut ovanpå, vilket ger ett mjukt böljande intryck. Bara x och opacity
 * animeras, utan shaders, blur eller partiklar. Animationen pausas när appen
 * inte är aktiv eller när "Animerad bakgrund" är avstängd.
 */
Item {
    id: root

    property bool animate: true
    property url source: Theme.background

    readonly property bool running: animate && Qt.application.state === Qt.ApplicationActive
    readonly property real imgHeight: height * 1.04
    readonly property real imgWidth: Math.max(width * 1.2, imgHeight * 2.389)
    readonly property real travel: imgWidth - width

    clip: true

    Rectangle {
        anchors.fill: parent
        color: Theme.base
    }

    Image {
        id: layerA
        source: root.source
        width: root.imgWidth
        height: root.imgHeight
        y: -root.height * 0.02
        x: -root.travel * 0.5
        fillMode: Image.Stretch
        sourceSize.height: Math.min(1080, Math.ceil(root.imgHeight))
        asynchronous: true
        smooth: true

        SequentialAnimation on x {
            loops: Animation.Infinite
            paused: !root.running
            NumberAnimation { from: -root.travel * 0.5; to: -root.travel; duration: 40000; easing.type: Easing.InOutSine }
            NumberAnimation { from: -root.travel; to: 0; duration: 80000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0; to: -root.travel * 0.5; duration: 40000; easing.type: Easing.InOutSine }
        }
    }

    Image {
        id: layerB
        source: root.source
        mirror: true
        width: root.imgWidth
        height: root.imgHeight
        y: root.height * 0.01
        x: -root.travel * 0.5
        fillMode: Image.Stretch
        sourceSize.height: layerA.sourceSize.height
        asynchronous: true
        smooth: true
        opacity: 0.0

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            paused: !root.running
            NumberAnimation { from: 0.0; to: 0.45; duration: 26000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.45; to: 0.0; duration: 26000; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on x {
            loops: Animation.Infinite
            paused: !root.running
            NumberAnimation { from: -root.travel * 0.5; to: 0; duration: 52000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0; to: -root.travel * 0.5; duration: 52000; easing.type: Easing.InOutSine }
        }
    }

    // Statisk toning som gör texten läsbar uppe och nere.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
            GradientStop { position: 0.30; color: Qt.rgba(0, 0, 0, 0.12) }
            GradientStop { position: 0.70; color: Qt.rgba(0, 0, 0, 0.15) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.60) }
        }
    }
}
