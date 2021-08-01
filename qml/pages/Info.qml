import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/datab.js" as DataB

Page {
    id: page

    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height

        Column {
            id: col
            width: parent.width

            PageHeader {
                title: qsTr("About")
            }

            DetailItem {
                label: qsTr("version")
                value: Qt.application.version
            }

            LinkedLabel {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                plainText: qsTr("This app reads the contents of Oura Cloud. " +
                                "API is described in https://cloud.ouraring.com/docs/.\n" +
                                "The app cannot be used for reading the data from the ring," +
                                "nor to upload the data to Oura Cloud.")
            }

            SectionHeader {
                text: qsTr("Logs")
            }

            TextArea {
                id: logList
                width: parent.width
                placeholderText: qsTr("No logs yet.")
            }
        }
    }

    Component.onCompleted: {
        var i = 0, N = DataB.appLog.length
        while (i < N) {
            logList.text += DataB.appLog[i] + "\n"
            i++
        }
    }
}
