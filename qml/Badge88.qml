import QtQuick

// The little 88×31 buttons of old home pages.
Bevel {
    id: badge
    property string upper
    property string lower
    property color tone: Theme.accent
    implicitWidth: 96
    implicitHeight: 34
    color: Qt.tint(Theme.raised, Qt.alpha(tone, 0.32))
    Column {
        anchors.centerIn: parent
        spacing: -3
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: badge.upper; color: Theme.text; font.family: Theme.brand; font.pixelSize: 9 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: badge.lower; color: badge.tone; font.family: Theme.brand; font.pixelSize: 8; topPadding: 3 }
    }
}
