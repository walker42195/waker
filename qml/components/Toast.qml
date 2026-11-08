import QtQuick 2.12
import Lomiri.Components 1.3

// Kort meddelande längst ner, t.ex. "Larmet ringer om 7 h 12 min".
Rectangle {
    id: toast

    function show(message) {
        label.text = message
        hideTimer.restart()
        state = "shown"
    }

    anchors.horizontalCenter: parent.horizontalCenter
    width: Math.min(parent.width - units.gu(4), label.implicitWidth + units.gu(5))
    height: label.implicitHeight + units.gu(2.6)
    radius: height / 2
    color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.94)
    border.width: units.dp(1)
    border.color: Theme.accentBorder
    opacity: 0
    visible: opacity > 0
    y: parent.height

    Label {
        id: label
        anchors.centerIn: parent
        width: Math.min(implicitWidth, toast.parent.width - units.gu(9))
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        color: "white"
    }

    Timer {
        id: hideTimer
        interval: 3500
        onTriggered: toast.state = ""
    }

    states: State {
        name: "shown"
        PropertyChanges { target: toast; opacity: 1; y: toast.parent.height - toast.height - units.gu(12) }
    }
    transitions: Transition {
        NumberAnimation { properties: "opacity,y"; duration: 220; easing.type: Easing.OutCubic }
    }
}
