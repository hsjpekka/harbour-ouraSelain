import QtQuick 2.0
import Sailfish.Silica 1.0

Page {

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: qsTr("Manual")
            }

            SectionHeader {
                text: qsTr("sleep types")
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
                text: qsTr("The value on a day summary column is the total sleeping time " +
                           "without the periods awake.")
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin
            }

            SectionHeader {
                text: qsTr("weekly averages")
            }

            Label {
                color: Theme.highlightColor
                text: qsTr("The scores on the right hand side are average values of " +
                           "the last seven full days. The latest half finished day is not " +
                           "taken into account.")
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin
            }

            Label {
                color: Theme.highlightColor
                text: qsTr("The sign below the average score tells whether the value of the " +
                           "latest full day is larger than, smaller than, or equal to " +
                           "the average. The color changes if the difference is big.")
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin
            }

        }
    }
}
