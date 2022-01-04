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
                                "API and values are described in %1.\n" +
                                "The app cannot be used for reading the data from the ring, " +
                                "nor to upload the data to Oura Cloud.").arg("https://cloud.ouraring.com/docs/")
            }

            SectionHeader {
                text: qsTr("sleep levels")
            }

            Row {
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin
                spacing: Theme.paddingMedium

                Column { // deep
                    width: (parent.width - 3*parent.spacing)/4
                    Rectangle {
                        width: parent.width
                        height: Theme.fontSizeMedium
                        color: Theme.highlightColor
                    }
                    Label {
                        color: Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("deep")
                    }
                }

                Column { // light
                    width: (parent.width - 3*parent.spacing)/4
                    Rectangle {
                        width: parent.width
                        height: Theme.fontSizeMedium
                        color: Theme.secondaryHighlightColor
                    }
                    Label {
                        color: Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("light")
                    }
                }

                Column { // rem
                    width: (parent.width - 3*parent.spacing)/4
                    Rectangle {
                        width: parent.width
                        height: Theme.fontSizeMedium
                        color: Theme.secondaryColor
                    }
                    Label {
                        color: Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("rem")
                    }
                }

                Column { // awake
                    width: (parent.width - 3*parent.spacing)/4
                    Rectangle {
                        width: parent.width
                        height: Theme.fontSizeMedium
                        color: Theme.primaryColor
                    }
                    Label {
                        color: Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("awake")
                    }
                }

            }

            Label {
                color: Theme.highlightColor
                text: qsTr("The value of the day sleep types column is the total sleeping time " +
                           "without the awake periods.")
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
            }

            SectionHeader {
                text: qsTr("averages")
            }

            Label {
                color: Theme.highlightColor
                text: qsTr("The scores on the right hand side are average values over " +
                           "365, 30 or 7 days. The latest half finished day is not " +
                           "taken into account.")
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
            }

            SectionHeader {
                text: qsTr("Yesterday's summaries")
            }

            Label {
                color: Theme.highlightColor
                text: qsTr("The sign next to the score tells whether the score of the latest " +
                           "full day is larger than, smaller than, or equal to the average " +
                           "of the week. The color changes if the difference is big.")
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
            }
        }
    }
}
