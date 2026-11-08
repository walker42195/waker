import QtQuick 2.12
import QtMultimedia 5.12
import Qt.labs.folderlistmodel 2.1
import Lomiri.Components 1.3
import Lomiri.Content 1.3
import "components"

/*
 * Välj larmljud: Wakers egna, egna importerade (via Content Hub) och systemets.
 * Ett tryck väljer och provlyssnar ljudet, ett tryck till stoppar det.
 */
Page {
    id: page

    property url selected: ""
    property var appSettings
    property var activeTransfer: null

    readonly property AlarmUtils utils: AlarmUtils {}

    signal soundSelected(url url)

    header: PageHeader {
        id: header
        title: i18n.tr("Sound")
        StyleHints {
            backgroundColor: "transparent"
            foregroundColor: "white"
            dividerColor: "transparent"
        }
        trailingActionBar.actions: [
            Action {
                iconName: "add"
                text: i18n.tr("Import sound")
                onTriggered: page.pageStack.push(pickerComponent)
            }
        ]
    }

    // Installerad version, för provlyssningens sökväg (se previewUrl)
    property string appVersion: ""

    Component.onCompleted: {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try { page.appVersion = JSON.parse(xhr.responseText).version || "" } catch (e) {}
            }
        }
        xhr.open("GET", Qt.resolvedUrl("../manifest.json"))
        xhr.send()
    }

    /*
     * Provlyssningen spelas av media-hub, som bara släpper igenom filer i appens
     * versionskatalog (<click-rot>/<app>/<version>/), inte via symlänken
     * "current" som larmen sparas med. Byt därför tillbaka till versionen här.
     */
    function previewUrl(url) {
        var s = url.toString()
        if (appVersion.length > 0)
            s = s.replace("/waker.sandgren.one/current/", "/waker.sandgren.one/" + appVersion + "/")
        return s
    }

    function choose(url) {
        var again = selected.toString() === url.toString()
        selected = url
        soundSelected(url)
        // Ett nytt tryck på ljudet som spelas stoppar det
        if (again && preview.playbackState === Audio.PlayingState) {
            preview.stop()
            return
        }
        preview.stop()
        preview.source = previewUrl(url)
        preview.play()
    }

    Audio {
        id: preview
        onError: console.warn("Waker: preview failed:", errorString, source)
    }

    Connections {
        target: Qt.application
        function onStateChanged() { preview.stop() }
    }
    Component.onDestruction: preview.stop()
    onVisibleChanged: if (!visible) preview.stop()

    FolderListModel {
        id: customModel
        folder: page.appSettings ? page.appSettings.customSoundDir : ""
        showDirs: false
        nameFilters: ["*.ogg", "*.oga", "*.mp3", "*.wav", "*.flac", "*.m4a", "*.opus"]
        sortField: FolderListModel.Name
    }

    FolderListModel {
        id: systemModel
        folder: "file:///usr/share/sounds/lomiri/ringtones"
        showDirs: false
        nameFilters: ["*.ogg", "*.mp3", "*.wav", "*.flac"]
        sortField: FolderListModel.Name
    }

    // Import från andra appar (t.ex. Musik eller Filhanteraren)
    Component {
        id: pickerComponent
        Page {
            id: pickerPage
            header: PageHeader {
                title: i18n.tr("Import sound from")
                StyleHints {
                    backgroundColor: Theme.base
                    foregroundColor: "white"
                    dividerColor: "transparent"
                }
            }
            ContentPeerPicker {
                anchors { fill: parent; topMargin: pickerPage.header.height }
                handler: ContentHandler.Source
                contentType: ContentType.Music
                showTitle: false
                onPeerSelected: {
                    peer.selectionType = ContentTransfer.Single
                    page.activeTransfer = peer.request()
                    pickerPage.pageStack.pop()
                }
                onCancelPressed: pickerPage.pageStack.pop()
            }
        }
    }

    ContentTransferHint {
        anchors.fill: parent
        activeTransfer: page.activeTransfer
    }

    Connections {
        target: page.activeTransfer
        ignoreUnknownSignals: true
        function onStateChanged() {
            if (page.activeTransfer.state !== ContentTransfer.Charged)
                return
            var items = page.activeTransfer.items
            if (items.length > 0) {
                var item = items[0]
                // Filen levereras till <appdata>/HubIncoming/<n>/. Flytta till <appdata>/sounds/
                var path = decodeURIComponent(item.url.toString().replace(/^file:\/\//, ""))
                var idx = path.indexOf("/HubIncoming/")
                if (idx > 0) {
                    var dir = path.substring(0, idx) + "/sounds"
                    if (item.move(dir)) {
                        page.appSettings.customSoundDir = "file://" + dir
                    }
                }
                page.choose(item.url)
            }
            page.activeTransfer.finalize()
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

            SoundSection {
                title: "Waker!"
                model: page.utils.bundledSounds
                urlFor: function(m) { return page.utils.bundledSoundUrl(m) }
            }

            SoundSection {
                title: i18n.tr("My sounds")
                model: customModel
                isFolder: true
                emptyText: i18n.tr("Tap + to import a sound file from another app.")
            }

            SoundSection {
                title: i18n.tr("System sounds")
                model: systemModel
                isFolder: true
            }
        }
    }

    // En sektion i ett glaskort med en rad per ljud
    component SoundSection: GlassCard {
        id: section
        property string title
        property var model
        property bool isFolder: false
        property string emptyText: ""
        property var urlFor: null

        width: column.width
        height: sectionColumn.height + units.gu(2.5)

        Column {
            id: sectionColumn
            anchors {
                left: parent.left; right: parent.right; top: parent.top
                margins: units.gu(2); topMargin: units.gu(1.5)
            }

            Label {
                text: section.title
                color: Theme.textDim
                textSize: Label.Small
                font.capitalization: Font.AllUppercase
                font.letterSpacing: units.dp(1.5)
                height: units.gu(3.5)
                verticalAlignment: Text.AlignVCenter
            }

            Label {
                visible: section.emptyText.length > 0 && repeater.count === 0
                width: parent.width
                wrapMode: Text.WordWrap
                text: section.emptyText
                color: Theme.textFaint
                height: visible ? implicitHeight + units.gu(1) : 0
            }

            Repeater {
                id: repeater
                model: section.model
                delegate: AbstractButton {
                    id: row
                    readonly property url url: section.isFolder ? fileUrl : section.urlFor(modelData)
                    readonly property bool isSelected: page.selected.toString() === url.toString()
                    width: sectionColumn.width
                    height: units.gu(5.5)
                    onClicked: page.choose(url)

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: -units.gu(1)
                        anchors.rightMargin: -units.gu(1)
                        radius: units.gu(1)
                        color: row.isSelected ? Theme.accentSoft
                                              : (row.pressed ? Theme.glass : "transparent")
                    }
                    Label {
                        anchors { left: parent.left; right: check.left; verticalCenter: parent.verticalCenter }
                        text: page.utils.soundName(row.url)
                        color: row.isSelected ? "white" : Theme.text
                        elide: Text.ElideRight
                    }
                    Icon {
                        id: check
                        name: "tick"
                        visible: row.isSelected
                        width: units.gu(2.5); height: width
                        color: Theme.accent2
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }
}
