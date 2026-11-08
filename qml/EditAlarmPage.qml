import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "components"

Page {
    id: page

    property var alarmModel
    property var appSettings
    property var tempAlarm: null      // befintligt larm (Alarm-objekt) vid redigering
    property bool isNewAlarm: true

    // Det som redigeras
    property int hours: 7
    property int minutes: 0
    property int daysMask: 0
    property string message: ""
    property url sound: ""

    property bool saving: false
    property int errorCode: 0
    readonly property AlarmUtils utils: AlarmUtils {}
    readonly property var target: isNewAlarm ? newAlarm : tempAlarm
    readonly property var previewNext: utils.nextOccurrence(hours, minutes, daysMask,
                                                            daysMask ? Alarm.Repeating : Alarm.OneTime)

    signal saved(var next)

    header: PageHeader {
        id: header
        title: page.isNewAlarm ? i18n.tr("New alarm") : i18n.tr("Edit alarm")
        StyleHints {
            backgroundColor: "transparent"
            foregroundColor: "white"
            dividerColor: "transparent"
        }
        trailingActionBar.actions: [
            Action {
                objectName: "saveAlarmAction"
                iconName: "ok"
                text: i18n.tr("Save")
                enabled: !page.saving
                onTriggered: page.save()
            }
        ]
    }

    Component.onCompleted: {
        if (!isNewAlarm && tempAlarm) {
            hours = tempAlarm.date.getHours()
            minutes = tempAlarm.date.getMinutes()
            daysMask = tempAlarm.type === Alarm.Repeating ? (tempAlarm.daysOfWeek & Alarm.Daily) : 0
            message = tempAlarm.message
            sound = tempAlarm.sound
        } else {
            hours = 7
            minutes = 0
            message = ""
            sound = appSettings && appSettings.lastSound ? appSettings.lastSound
                                                         : utils.bundledSoundUrl("Dawn")
        }
        hourWheel.setValue(hours)
        minuteWheel.setValue(minutes)
        dayChips.mask = daysMask
    }

    function save() {
        var alarm = target
        if (!alarm)
            return
        var repeating = daysMask !== 0
        var date = new Date()
        // Sekunden växlas 0/1 vid uppdatering så att ändringen alltid skrivs (lomiri-clock-app #129)
        var sec = (!isNewAlarm && tempAlarm.date.getTime() % 60000 === 0) ? 1 : 0
        date.setHours(hours, minutes, sec, 0)

        alarm.message = message.trim().length > 0 ? message.trim() : i18n.tr("Alarm")
        alarm.type = repeating ? Alarm.Repeating : Alarm.OneTime
        if (repeating) {
            alarm.daysOfWeek = daysMask
        } else {
            alarm.daysOfWeek = Alarm.AutoDetect
            if (date < new Date()) {
                var tomorrow = new Date()
                tomorrow.setDate(tomorrow.getDate() + 1)
                alarm.daysOfWeek = utils.dayFlag(tomorrow.getDay())
            }
        }
        alarm.date = date
        alarm.sound = sound
        alarm.enabled = true

        if (appSettings)
            appSettings.lastSound = sound.toString()

        saving = true
        alarm.save()
        // Valideringsfel kan rapporteras direkt utan statusbyte
        if (saving && alarm.status === Alarm.Ready && alarm.error !== Alarm.NoError)
            finishSave()
    }

    function finishSave() {
        saving = false
        if (target.error !== Alarm.NoError) {
            errorCode = target.error
            PopupUtils.open(errorDialogComponent)
            return
        }
        if (alarmModel && !isNewAlarm)
            alarmModel.refresh()
        saved(previewNext)
        page.pageStack.pop()
    }

    function deleteAlarm() {
        if (tempAlarm) {
            tempAlarm.cancel()
            page.pageStack.pop()
        }
    }

    Alarm {
        id: newAlarm
    }

    // Spara är asynkront: vänta på status Ready och kontrollera fel
    Connections {
        target: page.target
        ignoreUnknownSignals: true
        function onStatusChanged() {
            if (page.saving && page.target.status === Alarm.Ready)
                page.finishSave()
        }
    }

    Component {
        id: errorDialogComponent
        Dialog {
            id: dlg
            title: i18n.tr("Could not save the alarm")
            text: i18n.tr("Error code %1. Check that the time is valid and try again.").arg(page.errorCode)
            Button {
                text: i18n.tr("OK")
                onClicked: PopupUtils.close(dlg)
            }
        }
    }

    Flickable {
        id: flick
        anchors {
            top: header.bottom; bottom: parent.bottom
            left: parent.left; right: parent.right
        }
        contentHeight: column.height + units.gu(6)
        clip: true

        Column {
            id: column
            anchors {
                left: parent.left; right: parent.right; top: parent.top
                margins: units.gu(2)
            }
            spacing: units.gu(2)

            // Tid
            GlassCard {
                width: parent.width
                height: timeColumn.height + units.gu(3)
                highlighted: true

                Column {
                    id: timeColumn
                    anchors.centerIn: parent
                    spacing: units.gu(0.5)

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(0.5)
                        TimeWheel {
                            id: hourWheel
                            objectName: "hourWheel"
                            count: 24
                            onMoved: page.hours = newValue
                        }
                        Label {
                            text: ":"
                            font.pixelSize: units.gu(6)
                            font.weight: Font.Light
                            color: Theme.accent1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        TimeWheel {
                            id: minuteWheel
                            objectName: "minuteWheel"
                            count: 60
                            onMoved: page.minutes = newValue
                        }
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.previewNext ? i18n.tr("Rings %1").arg(page.utils.countdownText(page.previewNext)) : ""
                        color: Theme.accent2
                    }
                }
            }

            // Upprepning
            GlassCard {
                width: parent.width
                height: repeatColumn.height + units.gu(4)
                Column {
                    id: repeatColumn
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: units.gu(2)
                    }
                    spacing: units.gu(1.5)
                    Label {
                        text: i18n.tr("Repeat")
                        color: Theme.textDim
                        textSize: Label.Small
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: units.dp(1.5)
                    }
                    DayChips {
                        id: dayChips
                        width: parent.width
                        onMaskChanged: page.daysMask = mask
                    }
                }
            }

            // Namn och ljud
            GlassCard {
                width: parent.width
                height: detailsColumn.height + units.gu(4)
                Column {
                    id: detailsColumn
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: units.gu(2)
                    }
                    spacing: units.gu(1.5)

                    Label {
                        text: i18n.tr("Name")
                        color: Theme.textDim
                        textSize: Label.Small
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: units.dp(1.5)
                    }
                    TextField {
                        id: nameField
                        objectName: "alarmName"
                        width: parent.width
                        placeholderText: i18n.tr("Alarm")
                        text: page.message
                        onTextChanged: page.message = text
                        inputMethodHints: Qt.ImhNoPredictiveText
                    }

                    Rectangle { width: parent.width; height: units.dp(1); color: Theme.glassBorder }

                    AbstractButton {
                        id: soundRow
                        width: parent.width
                        height: units.gu(6)
                        onClicked: {
                            var p = page.pageStack.push(Qt.resolvedUrl("SoundPage.qml"), {
                                selected: page.sound,
                                appSettings: page.appSettings
                            })
                            p.soundSelected.connect(function(url) { page.sound = url })
                        }
                        Icon {
                            id: noteIcon
                            name: "stock_music"
                            width: units.gu(3); height: width
                            color: Theme.accent1
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        }
                        Column {
                            anchors {
                                left: noteIcon.right; leftMargin: units.gu(1.5)
                                right: chevron.left
                                verticalCenter: parent.verticalCenter
                            }
                            Label { text: i18n.tr("Sound"); color: "white" }
                            Label {
                                text: page.utils.soundName(page.sound)
                                color: Theme.textDim
                                textSize: Label.Small
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                        Icon {
                            id: chevron
                            name: "go-next"
                            width: units.gu(2); height: width
                            color: Theme.textDim
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: i18n.tr("The alarm rings even in silent mode and when Waker is closed. Snooze length and alarm volume are set in System Settings → Sound.")
                color: Theme.textFaint
                textSize: Label.Small
            }

            Button {
                visible: !page.isNewAlarm
                width: parent.width
                text: i18n.tr("Delete alarm")
                color: Theme.danger
                onClicked: page.deleteAlarm()
            }
        }
    }
}
