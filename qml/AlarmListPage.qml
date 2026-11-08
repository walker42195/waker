import QtQuick 2.12
import Lomiri.Components 1.3
import "components"

Page {
    id: page

    property var alarmModel
    property var appSettings

    readonly property AlarmUtils utils: AlarmUtils {}
    property date now: new Date()

    header: PageHeader {
        id: header
        title: "Waker!"
        StyleHints {
            backgroundColor: "transparent"
            foregroundColor: "white"
            dividerColor: "transparent"
        }
        trailingActionBar.actions: [
            Action {
                iconName: "settings"
                text: i18n.tr("Settings")
                onTriggered: page.pageStack.push(Qt.resolvedUrl("SettingsPage.qml"),
                                                 { appSettings: page.appSettings })
            }
        ]
    }

    function openEditor(alarm) {
        var editor = page.pageStack.push(Qt.resolvedUrl("EditAlarmPage.qml"), {
            alarmModel: page.alarmModel,
            appSettings: page.appSettings,
            tempAlarm: alarm || null,
            isNewAlarm: !alarm
        })
        editor.saved.connect(function(next) {
            toast.show(i18n.tr("Alarm set for %1 – %2")
                       .arg(utils.formatTime(next)).arg(utils.countdownText(next)))
        })
    }

    // Klockappens beprövade sätt att slå på/av ett sparat larm
    function setEnabled(alarm, on) {
        if (on === alarm.enabled)
            return
        var today = new Date()
        // Sekunden växlas 0/1 så att ändringen alltid skrivs (lomiri-clock-app #129)
        var date = new Date(alarm.date.getTime() + (alarm.date.getTime() % 60 ? -1000 : 1000))
        date.setFullYear(today.getFullYear(), today.getMonth(), today.getDate())
        if (alarm.type === Alarm.OneTime) {
            alarm.daysOfWeek = Alarm.AutoDetect
            if (date < new Date()) {
                var tomorrow = new Date()
                tomorrow.setDate(today.getDate() + 1)
                alarm.daysOfWeek = utils.dayFlag(tomorrow.getDay())
            }
        }
        alarm.date = date
        alarm.enabled = on
        alarm.save()
        if (on) {
            var next = utils.nextOccurrence(date.getHours(), date.getMinutes(),
                                            alarm.daysOfWeek, alarm.type)
            toast.show(i18n.tr("Rings %1").arg(utils.countdownText(next)))
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: Qt.application.state === Qt.ApplicationActive
        onTriggered: page.now = new Date()
    }

    ListView {
        id: list
        anchors {
            top: header.bottom; bottom: parent.bottom
            left: parent.left; right: parent.right
        }
        model: page.alarmModel
        spacing: units.gu(1.2)
        bottomMargin: units.gu(14)
        clip: true

        header: Item {
            width: list.width
            height: banner.height + units.gu(3)
            NextAlarmBanner {
                id: banner
                alarmModel: page.alarmModel
                anchors {
                    left: parent.left; right: parent.right; top: parent.top
                    leftMargin: units.gu(2); rightMargin: units.gu(2); topMargin: units.gu(1)
                }
                height: implicitHeight
            }
        }

        delegate: ListItem {
            id: item
            width: list.width
            height: card.height
            color: "transparent"
            highlightColor: "transparent"
            divider.visible: false
            enabled: model.status === Alarm.Ready

            readonly property var next: model.enabled ? page.utils.nextForAlarm(model, page.now) : null

            leadingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "delete"
                        text: i18n.tr("Delete")
                        onTriggered: {
                            item.enabled = false
                            model.cancel()
                        }
                    }
                ]
            }

            onClicked: page.openEditor(model)

            GlassCard {
                id: card
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: units.gu(2); rightMargin: units.gu(2)
                }
                height: units.gu(11.5)
                highlighted: model.enabled
                opacity: model.enabled ? 1.0 : 0.6

                Column {
                    anchors {
                        left: parent.left; leftMargin: units.gu(2.5)
                        right: toggle.left; rightMargin: units.gu(1)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: units.gu(0.3)

                    Row {
                        spacing: units.gu(1.2)
                        Label {
                            id: timeLabel
                            text: page.utils.formatTime(model.date)
                            font.pixelSize: units.gu(5)
                            font.weight: Font.Light
                            color: model.enabled ? "white" : Theme.textDim
                        }
                        Label {
                            anchors.baseline: timeLabel.baseline
                            text: model.message
                            elide: Text.ElideRight
                            width: Math.max(0, card.width - timeLabel.width - units.gu(15))
                            color: Theme.textDim
                        }
                    }
                    Label {
                        text: {
                            var days = page.utils.daysText(model.daysOfWeek, model.type)
                            return item.next ? days + "  ·  " + page.utils.countdownText(item.next, page.now) : days
                        }
                        color: item.next ? Theme.accent2 : Theme.textFaint
                        textSize: Label.Small
                    }
                }

                Switch {
                    id: toggle
                    StyleHints { checkedBackgroundColor: Theme.accent1 }
                    anchors {
                        right: parent.right; rightMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                    checked: model.enabled
                    onClicked: {
                        page.setEnabled(model, checked)
                        checked = Qt.binding(function() { return model.enabled })
                    }
                }
            }
        }

        // Tomt läge
        Label {
            visible: list.count === 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: list.headerItem ? list.headerItem.height + units.gu(6) : units.gu(30)
            text: i18n.tr("No alarms yet")
            color: Theme.textFaint
            textSize: Label.Large
        }
    }

    NeonButton {
        objectName: "addAlarmButton"
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom; bottomMargin: units.gu(4)
        }
        iconName: "add"
        text: i18n.tr("New alarm")
        onClicked: page.openEditor(null)
    }

    Toast {
        id: toast
    }
}
