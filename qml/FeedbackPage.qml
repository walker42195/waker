import QtQuick 2.12
import QtQuick.Window 2.2
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import "components"

// Förbättringsförslag och buggrapporter. Skickas till developer@sandgren.one via
// https://waker.sandgren.one/api/feedback.php (källa: waker-website/api/feedback.php).
// Ubuntu Touch har ingen förinstallerad e-postapp, därför går det via servern och
// mailto finns bara som reserv.
Page {
    id: page

    readonly property string endpoint: "https://waker.sandgren.one/api/feedback.php"
    readonly property string recipient: "developer@sandgren.one"

    property string kind: "idea"          // "idea" | "bug"
    property bool sending: false
    property string errorText: ""
    property string appVersion: "?"
    property string framework: ""

    readonly property string deviceInfo: {
        var parts = ["Waker " + appVersion]
        if (framework) parts.push(framework)
        parts.push(Qt.locale().name)
        parts.push(Screen.width + "×" + Screen.height + " @" + units.gridUnit + "px/gu")
        return parts.join(" · ")
    }
    readonly property bool canSend: messageArea.text.trim().length >= 5 && !sending
                                    && (emailField.text.trim() === "" || emailField.acceptableInput)

    header: PageHeader {
        id: header
        title: i18n.tr("Feedback")
        StyleHints {
            backgroundColor: "transparent"
            foregroundColor: "white"
            dividerColor: "transparent"
        }
    }

    // Läs versionen ur manifest.json i installationskatalogen.
    Component.onCompleted: {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.responseText) {
                try {
                    var m = JSON.parse(xhr.responseText)
                    page.appVersion = m.version || "?"
                    page.framework = m.framework || ""
                } catch (e) {}
            }
        }
        xhr.open("GET", Qt.resolvedUrl("../manifest.json"))
        xhr.send()
    }

    function mailtoUrl() {
        var subject = "[Waker] " + (kind === "bug" ? "Bug report" : "Suggestion")
        var body = messageArea.text + (infoSwitch.checked ? "\n\n--\n" + deviceInfo : "")
        return "mailto:" + recipient + "?subject=" + encodeURIComponent(subject)
               + "&body=" + encodeURIComponent(body)
    }

    function send() {
        if (!canSend)
            return
        sending = true
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            page.sending = false
            var res = {}
            try { res = JSON.parse(xhr.responseText) } catch (e) {}
            if (xhr.status === 200 && res.ok) {
                PopupUtils.open(sentDialog)
                return
            }
            switch (res.error) {
            case "rate": page.errorText = i18n.tr("Too many messages in a short time. Please try again later."); break
            case "email": page.errorText = i18n.tr("The email address doesn't look valid."); break
            case "short": page.errorText = i18n.tr("Please write a little more."); break
            case "long": page.errorText = i18n.tr("The message is too long."); break
            default: page.errorText = xhr.status === 0
                     ? i18n.tr("Could not reach the server. Check your internet connection.")
                     : i18n.tr("The server could not send the message (error %1).").arg(xhr.status)
            }
            PopupUtils.open(errorDialog)
        }
        xhr.open("POST", endpoint)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify({
            type: kind,
            message: messageArea.text.trim(),
            email: emailField.text.trim(),
            info: infoSwitch.checked ? deviceInfo : ""
        }))
    }

    Component {
        id: sentDialog
        Dialog {
            id: dlg
            title: i18n.tr("Thank you!")
            text: i18n.tr("Your message has been sent to the developer.")
            Button {
                text: i18n.tr("OK")
                color: Theme.accent1
                onClicked: { PopupUtils.close(dlg); page.pageStack.pop() }
            }
        }
    }

    Component {
        id: errorDialog
        Dialog {
            id: edlg
            title: i18n.tr("Could not send")
            text: page.errorText
            Button {
                text: i18n.tr("Try again")
                color: Theme.accent1
                onClicked: { PopupUtils.close(edlg); page.send() }
            }
            Button {
                text: i18n.tr("Use email app instead")
                onClicked: { PopupUtils.close(edlg); Qt.openUrlExternally(page.mailtoUrl()) }
            }
            Button {
                text: i18n.tr("Close")
                onClicked: PopupUtils.close(edlg)
            }
        }
    }

    Flickable {
        id: flick
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
                height: formColumn.height + units.gu(4)
                Column {
                    id: formColumn
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: units.gu(2)
                    }
                    spacing: units.gu(1.5)

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr("Have an idea for Waker, or did something not work? Tell the developer.")
                        color: "white"
                    }

                    // Typ: förslag eller bugg
                    Row {
                        spacing: units.gu(1)
                        Repeater {
                            model: [
                                { label: i18n.tr("Suggestion"), value: "idea", icon: "info" },
                                { label: i18n.tr("Bug report"), value: "bug", icon: "dialog-warning-symbolic" }
                            ]
                            delegate: AbstractButton {
                                id: kindButton
                                objectName: "kind_" + modelData.value
                                readonly property bool on: page.kind === modelData.value
                                width: kindRow.implicitWidth + units.gu(3)
                                height: units.gu(4.4)
                                onClicked: page.kind = modelData.value
                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: kindButton.on ? Theme.accentSoft : "transparent"
                                    border.width: units.dp(1)
                                    border.color: kindButton.on ? Theme.accentBorder : Theme.glassBorder
                                }
                                Row {
                                    id: kindRow
                                    anchors.centerIn: parent
                                    spacing: units.gu(0.8)
                                    Icon {
                                        name: modelData.icon
                                        width: units.gu(2); height: width
                                        color: kindButton.on ? Theme.accent2 : Theme.textDim
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Label {
                                        text: modelData.label
                                        color: kindButton.on ? "white" : Theme.textDim
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }

                    TextArea {
                        id: messageArea
                        objectName: "feedbackMessage"
                        width: parent.width
                        height: units.gu(18)
                        placeholderText: page.kind === "bug"
                                         ? i18n.tr("What happened, and what did you expect to happen?")
                                         : i18n.tr("Describe your idea…")
                    }

                    TextField {
                        id: emailField
                        objectName: "feedbackEmail"
                        width: parent.width
                        placeholderText: i18n.tr("Your email (optional, for a reply)")
                        inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                        validator: RegExpValidator { regExp: /^$|^[^\s@]+@[^\s@]+\.[^\s@]+$/ }
                    }

                    Item {
                        width: parent.width
                        height: Math.max(infoText.height, infoSwitch.height)
                        Column {
                            id: infoText
                            anchors { left: parent.left; right: infoSwitch.left; rightMargin: units.gu(1); verticalCenter: parent.verticalCenter }
                            Label {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: i18n.tr("Include app version and device info")
                                color: "white"
                            }
                            Label {
                                width: parent.width
                                wrapMode: Text.WrapAnywhere
                                text: page.deviceInfo
                                color: Theme.textDim
                                textSize: Label.Small
                            }
                        }
                        Switch {
                            id: infoSwitch
                            objectName: "feedbackInfo"
                            checked: true
                            StyleHints { checkedBackgroundColor: Theme.accent1 }
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: units.gu(8)
                NeonButton {
                    id: sendButton
                    objectName: "feedbackSend"
                    anchors.centerIn: parent
                    iconName: "send"
                    text: i18n.tr("Send")
                    enabled: page.canSend
                    opacity: enabled ? 1 : 0.45
                    onClicked: page.send()
                    visible: !page.sending
                }
                ActivityIndicator {
                    anchors.centerIn: parent
                    running: page.sending
                    visible: running
                }
            }

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: i18n.tr("Sent to %1 via waker.sandgren.one. Only what you see here is sent.").arg(page.recipient)
                color: Theme.textFaint
                textSize: Label.Small
            }

            AbstractButton {
                id: mailLink
                objectName: "feedbackMailto"
                anchors.horizontalCenter: parent.horizontalCenter
                width: mailLabel.implicitWidth + units.gu(3)
                height: units.gu(5)
                onClicked: Qt.openUrlExternally(page.mailtoUrl())
                Label {
                    id: mailLabel
                    anchors.centerIn: parent
                    text: i18n.tr("Or write an email to %1").arg(page.recipient)
                    color: mailLink.pressed ? "white" : Theme.accent2
                    textSize: Label.Small
                }
            }
        }
    }
}
