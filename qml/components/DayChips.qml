import QtQuick 2.12
import Lomiri.Components 1.3

/*
 * Sju runda knappar för veckodagarna, plus snabbval. Ingen dag vald = engångslarm.
 * mask använder Alarm-flaggorna (Alarm.Monday ...).
 */
Column {
    id: chips

    property int mask: 0
    property AlarmUtils utils: AlarmUtils {}

    spacing: units.gu(1.5)

    Row {
        id: dayRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: units.gu(0.8)

        Repeater {
            model: chips.utils.orderedDays()
            delegate: AbstractButton {
                id: chip
                readonly property int flag: chips.utils.dayFlag(modelData)
                readonly property bool on: (chips.mask & flag) !== 0
                width: Math.min(units.gu(5), (chips.width - 6 * dayRow.spacing) / 7)
                height: width

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    visible: !chip.on
                    color: Theme.glass
                    border.width: units.dp(1)
                    border.color: Theme.glassBorder
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    visible: chip.on
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.accent1 }
                        GradientStop { position: 1.0; color: Theme.accent2 }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    text: {
                        var n = Qt.locale().dayName(modelData, Locale.ShortFormat)
                        return n.charAt(0).toUpperCase() + n.substring(1, 2)
                    }
                    color: chip.on ? "white" : Theme.textDim
                    font.weight: chip.on ? Font.Medium : Font.Normal
                }
                onClicked: chips.mask = chips.mask ^ flag
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: units.gu(1)

        Repeater {
            model: [
                { label: i18n.tr("Once"), value: 0 },
                { label: i18n.tr("Weekdays"), value: chips.utils.weekdaysMask() },
                { label: i18n.tr("Weekends"), value: chips.utils.weekendMask() },
                { label: i18n.tr("Every day"), value: Alarm.Daily }
            ]
            delegate: AbstractButton {
                id: preset
                readonly property bool on: chips.mask === modelData.value
                width: presetLabel.implicitWidth + units.gu(2.4)
                height: units.gu(3.6)
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: preset.on ? Theme.accentSoft : "transparent"
                    border.width: units.dp(1)
                    border.color: preset.on ? Theme.accentBorder : Theme.glassBorder
                }
                Label {
                    id: presetLabel
                    anchors.centerIn: parent
                    text: modelData.label
                    textSize: Label.Small
                    color: preset.on ? "white" : Theme.textDim
                }
                onClicked: chips.mask = modelData.value
            }
        }
    }
}
