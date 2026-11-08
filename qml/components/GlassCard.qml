import QtQuick 2.12
import Lomiri.Components 1.3

// Halvgenomskinligt "glaskort" med tunn ljus kant. Ingen realtidsblur (CPU/GPU-snålt).
Rectangle {
    id: card
    property bool highlighted: false

    radius: units.gu(2.2)
    color: highlighted ? Theme.glassStrong : Theme.glass
    border.width: units.dp(1)
    border.color: highlighted ? Theme.accentBorder : Theme.glassBorder

    Behavior on color { ColorAnimation { duration: 150 } }
}
