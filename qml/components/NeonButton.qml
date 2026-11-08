import QtQuick 2.12
import Lomiri.Components 1.3

// Rund knapp med neongradient (violett → rosa), t.ex. för "+ Nytt larm".
AbstractButton {
    id: button
    property string iconName: "add"
    property string text: ""

    width: text ? label.implicitWidth + units.gu(8) : units.gu(7.5)
    height: units.gu(7.5)

    Rectangle {
        id: glow
        anchors.centerIn: parent
        width: parent.width + units.gu(1.6)
        height: parent.height + units.gu(1.6)
        radius: height / 2
        color: Qt.rgba(Theme.accent1.r, Theme.accent1.g, Theme.accent1.b, button.pressed ? 0.35 : 0.18)
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.accent1 }
            GradientStop { position: 1.0; color: Theme.accent2 }
        }
        border.width: units.dp(1)
        border.color: Qt.rgba(1, 1, 1, 0.35)
        scale: button.pressed ? 0.95 : 1.0
        Behavior on scale { NumberAnimation { duration: 90 } }

        Row {
            anchors.centerIn: parent
            spacing: units.gu(1)
            Icon {
                name: button.iconName
                width: units.gu(3); height: width
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                id: label
                text: button.text
                visible: text.length > 0
                color: "white"
                textSize: Label.Large
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
