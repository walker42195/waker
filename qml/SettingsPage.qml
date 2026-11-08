import QtQuick 2.12
import Lomiri.Components 1.3
import "components"

Page {
    id: page

    property var appSettings

    function themeName(id) {
        switch (id) {
        case "neon": return i18n.tr("Neon")
        case "aurora": return i18n.tr("Aurora")
        case "ocean": return i18n.tr("Ocean")
        case "ember": return i18n.tr("Ember")
        case "ice": return i18n.tr("Ice")
        }
        return id
    }

    header: PageHeader {
        id: header
        title: i18n.tr("Settings")
        StyleHints {
            backgroundColor: "transparent"
            foregroundColor: "white"
            dividerColor: "transparent"
        }
    }

    Flickable {
        anchors {
            top: header.bottom; bottom: parent.bottom
            left: parent.left; right: parent.right
        }
        contentHeight: column.height + units.gu(4)
        clip: true

        Column {
            id: column
            anchors {
                left: parent.left; right: parent.right; top: parent.top
                margins: units.gu(2)
            }
            spacing: units.gu(2)

            GlassCard {
                width: parent.width
                height: themeColumn.height + units.gu(4)
                Column {
                    id: themeColumn
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: units.gu(2)
                    }
                    spacing: units.gu(1.5)
                    Label {
                        text: i18n.tr("Theme")
                        color: Theme.textDim
                        textSize: Label.Small
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: units.dp(1.5)
                    }
                    Grid {
                        id: themeGrid
                        width: parent.width
                        columns: 2
                        spacing: units.gu(1.2)
                        Repeater {
                            model: Theme.themes
                            delegate: AbstractButton {
                                id: themeButton
                                readonly property bool on: page.appSettings.theme === modelData.id
                                objectName: "theme_" + modelData.id
                                width: (themeGrid.width - themeGrid.spacing) / 2
                                height: width * 0.42 + units.gu(3.5)
                                onClicked: page.appSettings.theme = modelData.id

                                Rectangle {
                                    id: frame
                                    width: parent.width
                                    height: parent.width * 0.42
                                    radius: units.gu(1.2)
                                    color: modelData.base
                                    border.width: themeButton.on ? units.dp(2) : units.dp(1)
                                    border.color: themeButton.on ? modelData.a2 : Theme.glassBorder
                                    Image {
                                        anchors { fill: parent; margins: units.dp(2) }
                                        source: Qt.resolvedUrl("../assets/themes/" + modelData.id + "_thumb.jpg")
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: Math.ceil(width)
                                        smooth: true
                                        asynchronous: true
                                    }
                                }
                                Label {
                                    anchors { top: frame.bottom; topMargin: units.gu(0.6); horizontalCenter: parent.horizontalCenter }
                                    text: page.themeName(modelData.id)
                                    color: themeButton.on ? "white" : Theme.textDim
                                    font.weight: themeButton.on ? Font.Medium : Font.Normal
                                }
                            }
                        }
                    }
                }
            }

            GlassCard {
                width: parent.width
                height: units.gu(9)
                Column {
                    anchors {
                        left: parent.left; leftMargin: units.gu(2)
                        right: animSwitch.left; rightMargin: units.gu(1)
                        verticalCenter: parent.verticalCenter
                    }
                    Label { text: i18n.tr("Animated background"); color: "white" }
                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr("Turn off to save battery on older phones.")
                        color: Theme.textDim
                        textSize: Label.Small
                    }
                }
                Switch {
                    id: animSwitch
                    StyleHints { checkedBackgroundColor: Theme.accent1 }
                    objectName: "animateSwitch"
                    anchors { right: parent.right; rightMargin: units.gu(2); verticalCenter: parent.verticalCenter }
                    checked: page.appSettings.animateBackground
                    onClicked: page.appSettings.animateBackground = checked
                }
            }

            GlassCard {
                width: parent.width
                height: soundColumn.height + units.gu(4)
                Column {
                    id: soundColumn
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: units.gu(2)
                    }
                    spacing: units.gu(1)
                    Label { text: i18n.tr("Volume, vibration and snooze"); color: "white" }
                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr("These are shared by all alarms on the phone and are set in System Settings.")
                        color: Theme.textDim
                        textSize: Label.Small
                    }
                    Button {
                        text: i18n.tr("Open sound settings")
                        onClicked: Qt.openUrlExternally("settings:///system/sound")
                    }
                }
            }

            GlassCard {
                width: parent.width
                height: feedbackColumn.height + units.gu(4)
                Column {
                    id: feedbackColumn
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: units.gu(2)
                    }
                    spacing: units.gu(1)
                    Label { text: i18n.tr("Ideas or problems?"); color: "white" }
                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr("Send a suggestion or a bug report straight to the developer.")
                        color: Theme.textDim
                        textSize: Label.Small
                    }
                    Button {
                        objectName: "feedbackButton"
                        text: i18n.tr("Send feedback")
                        color: Theme.accent1
                        onClicked: page.pageStack.push(Qt.resolvedUrl("FeedbackPage.qml"))
                    }
                }
            }

            GlassCard {
                width: parent.width
                height: aboutColumn.height + units.gu(4)
                Column {
                    id: aboutColumn
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: units.gu(2)
                    }
                    spacing: units.gu(1)
                    Label {
                        text: "Waker!"
                        color: "white"
                        textSize: Label.Large
                    }
                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr("Waker uses the phone's built-in alarm service. Alarms ring even in silent mode, wake the phone from sleep and work when the app is closed. Alarms are shared with the Clock app.")
                        color: Theme.textDim
                        textSize: Label.Small
                    }
                    AbstractButton {
                        id: siteLink
                        objectName: "websiteLink"
                        width: parent.width
                        height: units.gu(6)
                        onClicked: Qt.openUrlExternally("https://sandgren.one")

                        Rectangle {
                            anchors.fill: parent
                            radius: units.gu(1.2)
                            color: siteLink.pressed ? Theme.accentSoft : "transparent"
                            border.width: units.dp(1)
                            border.color: Theme.accentBorder
                        }
                        Icon {
                            id: globe
                            name: "stock_website"
                            width: units.gu(2.6); height: width
                            color: Theme.accent2
                            anchors { left: parent.left; leftMargin: units.gu(1.5); verticalCenter: parent.verticalCenter }
                        }
                        Label {
                            anchors { left: globe.right; leftMargin: units.gu(1.2); verticalCenter: parent.verticalCenter }
                            text: "sandgren.one"
                            color: "white"
                            font.weight: Font.Medium
                        }
                        Icon {
                            name: "external-link"
                            width: units.gu(2); height: width
                            color: Theme.textDim
                            anchors { right: parent.right; rightMargin: units.gu(1.5); verticalCenter: parent.verticalCenter }
                        }
                    }
                    Label {
                        text: i18n.tr("Made by Fredrik Sandgren · Free software, GPL-3.0")
                        color: Theme.textFaint
                        textSize: Label.Small
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
