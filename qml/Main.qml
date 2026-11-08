/*
 * Copyright (C) 2026  Fredrik Sandgren
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Waker! is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import Lomiri.Components 1.3
import Qt.labs.settings 1.0
import "components"

/*
 * Waker! använder systemets alarm-API (Lomiri.Components Alarm/AlarmModel).
 * Larmen avfyras av datum/tid-indikatorn, som väcker telefonen, spelar ljudet
 * med rollen "alarm" (tystas aldrig av ljudlöst läge) och visar Snooza/Stäng,
 * även när Waker inte körs.
 */
MainView {
    id: root
    objectName: "mainView"
    applicationName: "waker.sandgren"
    anchorToKeyboard: true

    width: units.gu(45)
    height: units.gu(80)

    backgroundColor: Theme.base
    theme.name: "Lomiri.Components.Themes.SuruDark"

    Settings {
        id: appSettings
        property bool animateBackground: true
        property string customSoundDir: ""
        property string lastSound: ""
        property string theme: "neon"
    }

    Binding {
        target: Theme
        property: "themeId"
        value: appSettings.theme
    }

    AlarmModel {
        id: alarmModel
    }

    WaveBackground {
        anchors.fill: parent
        animate: appSettings.animateBackground
    }

    PageStack {
        id: pageStack
        anchors.fill: parent
        Component.onCompleted: push(Qt.resolvedUrl("AlarmListPage.qml"), {
            alarmModel: alarmModel,
            appSettings: appSettings
        })
    }
}
