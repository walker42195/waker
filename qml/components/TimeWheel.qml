import QtQuick 2.12
import Lomiri.Components 1.3

/*
 * Ett hjul med siffror (t.ex. timmar 0–23 eller minuter 0–59) som snäpper
 * till mitten. Den valda siffran lyser i neon och de andra tonas ut.
 */
PathView {
    id: wheel

    property int count: 24
    property int value: 0
    readonly property int itemHeight: units.gu(7)

    signal moved(int newValue)

    width: units.gu(11)
    height: itemHeight * 3
    clip: true
    model: count
    pathItemCount: 5
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange
    snapMode: PathView.SnapToItem
    flickDeceleration: 2500
    maximumFlickVelocity: 4000

    path: Path {
        startX: wheel.width / 2
        startY: -wheel.itemHeight
        PathAttribute { name: "itemOpacity"; value: 0.0 }
        PathAttribute { name: "itemScale"; value: 0.6 }
        PathLine { x: wheel.width / 2; y: wheel.height / 2 }
        PathAttribute { name: "itemOpacity"; value: 1.0 }
        PathAttribute { name: "itemScale"; value: 1.0 }
        PathLine { x: wheel.width / 2; y: wheel.height + wheel.itemHeight }
        PathAttribute { name: "itemOpacity"; value: 0.0 }
        PathAttribute { name: "itemScale"; value: 0.6 }
    }

    delegate: Item {
        width: wheel.width
        height: wheel.itemHeight
        opacity: PathView.itemOpacity !== undefined ? PathView.itemOpacity : 1
        scale: PathView.itemScale !== undefined ? PathView.itemScale : 1

        Label {
            anchors.centerIn: parent
            text: (index < 10 ? "0" : "") + index
            font.pixelSize: units.gu(6)
            font.weight: Font.Light
            color: PathView.isCurrentItem ? "white" : Theme.textDim
        }
    }

    onCurrentIndexChanged: {
        if (currentIndex !== value) {
            value = currentIndex
            moved(value)
        }
    }

    function setValue(v) {
        value = v
        currentIndex = v
    }

    Component.onCompleted: currentIndex = value
}
