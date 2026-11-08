import QtQuick 2.12
import Lomiri.Components 1.3

/*
 * Visar nästa larm och en nedräkning ("om 7 h 12 min").
 * Uppdateras en gång per minut (inte varje sekund) för att spara batteri.
 */
GlassCard {
    id: banner

    property var alarmModel
    property var nextDate: null
    property string nextMessage: ""
    property date now: new Date()

    readonly property AlarmUtils utils: AlarmUtils {}

    implicitHeight: content.implicitHeight + units.gu(4)
    highlighted: nextDate !== null

    function refresh() {
        now = new Date()
        var best = null
        var bestMsg = ""
        if (alarmModel) {
            for (var i = 0; i < alarmModel.count; ++i) {
                var a = alarmModel.get(i)
                var n = utils.nextForAlarm(a, now)
                if (n && (!best || n < best)) {
                    best = n
                    bestMsg = a.message
                }
            }
        }
        nextDate = best
        nextMessage = bestMsg
    }

    Timer {
        // Synka till hel minut, därefter var 60:e sekund
        interval: 60000 - (new Date().getSeconds() * 1000)
        running: Qt.application.state === Qt.ApplicationActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            interval = 60000
            banner.refresh()
        }
    }

    Connections {
        target: banner.alarmModel
        ignoreUnknownSignals: true
        function onCountChanged() { banner.refresh() }
        function onModelReset() { banner.refresh() }
        function onDataChanged() { banner.refresh() }
        function onRowsInserted() { banner.refresh() }
        function onRowsRemoved() { banner.refresh() }
    }

    Column {
        id: content
        anchors {
            left: parent.left; right: parent.right
            verticalCenter: parent.verticalCenter
            margins: units.gu(2.5)
        }
        spacing: units.gu(0.5)

        Label {
            text: banner.nextDate ? i18n.tr("Next alarm") : i18n.tr("No active alarms")
            color: Theme.textDim
            textSize: Label.Small
            font.capitalization: Font.AllUppercase
            font.letterSpacing: units.dp(1.5)
        }
        Row {
            spacing: units.gu(1.5)
            visible: banner.nextDate !== null
            Label {
                id: bigTime
                text: banner.nextDate ? banner.utils.formatTime(banner.nextDate) : ""
                font.pixelSize: units.gu(6.5)
                font.weight: Font.Light
                color: "white"
            }
            Column {
                anchors.verticalCenter: bigTime.verticalCenter
                Label {
                    text: banner.nextDate ? banner.utils.countdownText(banner.nextDate, banner.now) : ""
                    color: Theme.accent2
                    textSize: Label.Large
                }
                Label {
                    text: banner.nextDate ? Qt.formatDate(banner.nextDate, "dddd") : ""
                    color: Theme.textDim
                }
            }
        }
        Label {
            visible: banner.nextDate === null
            width: parent.width
            wrapMode: Text.WordWrap
            text: i18n.tr("Tap + to set an alarm. Waker rings even when the phone is in silent mode.")
            color: Theme.textDim
        }
    }
}
