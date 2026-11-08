import QtQuick 2.12
import Lomiri.Components 1.3

// Hjälpfunktioner för larm: veckodagsflaggor, nästa förekomst och nedräkningstext.
QtObject {
    id: utils

    readonly property var bundledSounds: ["Dawn", "Classic", "Pulse"]

    // JS-veckodag (0 = söndag) → Alarm-flagga
    function dayFlag(jsDay) {
        switch (jsDay) {
        case 0: return Alarm.Sunday
        case 1: return Alarm.Monday
        case 2: return Alarm.Tuesday
        case 3: return Alarm.Wednesday
        case 4: return Alarm.Thursday
        case 5: return Alarm.Friday
        case 6: return Alarm.Saturday
        }
        return 0
    }

    // Veckodagar enligt språkinställningen (i Sverige mån–fre)
    function weekdaysMask() {
        var mask = 0
        var days = Qt.locale().weekDays
        for (var i = 0; i < days.length; ++i)
            mask |= dayFlag(days[i] % 7)
        return mask
    }

    function weekendMask() {
        return Alarm.Daily & ~weekdaysMask()
    }

    // Dagarna i visningsordning, från lokalens första veckodag (JS-veckodagar)
    function orderedDays() {
        var first = Qt.locale().firstDayOfWeek % 7
        var list = []
        for (var i = 0; i < 7; ++i)
            list.push((first + i) % 7)
        return list
    }

    // Läsbar text för upprepningen
    function daysText(mask, type) {
        if (type !== Alarm.Repeating || mask === 0 || mask === Alarm.AutoDetect)
            return i18n.tr("Once")
        if (mask === Alarm.Daily)
            return i18n.tr("Every day")
        if (mask === weekdaysMask())
            return i18n.tr("Weekdays")
        if (mask === weekendMask())
            return i18n.tr("Weekends")
        var names = []
        var days = orderedDays()
        for (var i = 0; i < days.length; ++i) {
            if (mask & dayFlag(days[i]))
                names.push(Qt.locale().dayName(days[i], Locale.ShortFormat))
        }
        return names.join(" · ")
    }

    // Nästa gång ett larm med tid h:m och dagmask ringer (efter "now")
    function nextOccurrence(hours, minutes, mask, type, now) {
        now = now || new Date()
        var d = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hours, minutes, 0, 0)
        if (type !== Alarm.Repeating || mask === 0 || mask === Alarm.AutoDetect) {
            if (d <= now)
                d.setDate(d.getDate() + 1)
            return d
        }
        for (var i = 0; i < 8; ++i) {
            if (d > now && (mask & dayFlag(d.getDay())))
                return d
            d.setDate(d.getDate() + 1)
        }
        return null
    }

    // Nästa förekomst för ett sparat larm (Alarm-objekt eller modellroll)
    function nextForAlarm(alarm, now) {
        if (!alarm || !alarm.enabled)
            return null
        now = now || new Date()
        if (alarm.type !== Alarm.Repeating) {
            // Engångslarm: datumet i larmet gäller
            return alarm.date > now ? alarm.date : null
        }
        return nextOccurrence(alarm.date.getHours(), alarm.date.getMinutes(),
                              alarm.daysOfWeek, alarm.type, now)
    }

    // "om 7 h 12 min" / "om 1 d 3 h" / "om 4 min"
    function countdownText(target, now) {
        if (!target)
            return ""
        now = now || new Date()
        var ms = target.getTime() - now.getTime()
        if (ms < 0)
            return ""
        var totalMin = Math.ceil(ms / 60000)
        var days = Math.floor(totalMin / 1440)
        var hours = Math.floor((totalMin % 1440) / 60)
        var mins = totalMin % 60
        if (days > 0)
            // TRANSLATORS: time until the alarm, e.g. "in 1 d 3 h"
            return i18n.tr("in %1 d %2 h").arg(days).arg(hours)
        if (hours > 0)
            // TRANSLATORS: time until the alarm, e.g. "in 7 h 12 min"
            return i18n.tr("in %1 h %2 min").arg(hours).arg(mins)
        // TRANSLATORS: time until the alarm, e.g. "in 4 min"
        return i18n.tr("in %1 min").arg(Math.max(1, mins))
    }

    function formatTime(date) {
        if (!date || isNaN(date.getTime()))
            return "--:--"
        return Qt.formatTime(date, "hh:mm")
    }

    // Visningsnamn för en ljud-URL (översätter Wakers egna ljud)
    function soundName(url) {
        var s = url ? url.toString() : ""
        if (s.length === 0)
            return i18n.tr("Default")
        var base = decodeURIComponent(s.substring(s.lastIndexOf("/") + 1))
        var dot = base.lastIndexOf(".")
        if (dot > 0)
            base = base.substring(0, dot)
        if (base === "Dawn") return i18n.tr("Dawn")
        if (base === "Classic") return i18n.tr("Classic")
        if (base === "Pulse") return i18n.tr("Pulse")
        return base
    }

    /*
     * URL till ett medföljande ljud. Versionskatalogen i sökvägen byts mot
     * "current", så att larmet hittar ljudet även efter en uppdatering av appen
     * (larmet sparas med fullständig sökväg och spelas upp av systemet).
     */
    function bundledSoundUrl(name) {
        var u = Qt.resolvedUrl("../../sounds/" + name + ".ogg").toString()
        return u.replace(/\/waker\.sandgren\/\d[^\/]*\/sounds\//, "/waker.sandgren/current/sounds/")
    }
}
