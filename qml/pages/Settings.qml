import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    allowedOrientations: Orientation.All

    property bool changeToken: false
    property string token

    signal setToken(string newToken)

    function getUserData() {
        var str = oura.myName(qsTr("name unknown"));
        age.value = oura.value("userinfo","age");
        gender.value = oura.value("userinfo","gender");
        user.value = str;
        if (str.indexOf("@") > 0) {
            user.label = qsTr("email");
        } else {
            user.label = qsTr("name");
        }

        weight.value = oura.value("userinfo","weight");
        return;
    }

    Connections {
        target: oura
        onFinishedActivity: {
            downloadLabel.visible = oura.isLoading()
        }
        onFinishedSleep: {
            downloadLabel.visible = oura.isLoading()
        }
        onFinishedReadiness: {
            downloadLabel.visible = oura.isLoading()
        }
        onFinishedBedTimes: {
            downloadLabel.visible = oura.isLoading()
        }
        onFinishedInfo: {
            downloadLabel.visible = oura.isLoading()
            getUserData()
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height
        width: parent.width

        PullDownMenu {
            MenuItem {
                text: qsTr("refresh data")
                onClicked: {
                    console.log("==== vaihtuu ==== " + token + ", " + tokenField.text)
                    oura.setPersonalAccessToken(tokenField.text)
                    oura.refreshDownloads()
                }
            }

            MenuItem {
                text: qsTr("reset token")
                onClicked: {
                    tokenField.text = token
                    changeToken = false
                }
            }

            MenuItem {
                text: qsTr("check database")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("dataBase.qml"))
                }
            }
        }

        Column {
            id: col
            width: parent.width

            PageHeader {
                id: header
                title: qsTr("Info")
            }

            SectionHeader {
                text: qsTr("Me")
            }

            DetailItem {
                id: user
                label: qsTr("email")
                value: ""
                anchors.horizontalCenterOffset: parent.width/4
            }

            DetailItem {
                id: age
                label: qsTr("age")
                value: ""
                anchors.horizontalCenterOffset: -parent.width/4
            }

            DetailItem {
                id: weight
                label: qsTr("weight")
                value: ""
                anchors.horizontalCenterOffset: parent.width/6
            }

            DetailItem {
                id: gender
                label: qsTr("gender")
                value: ""
            }

            DetailItem {
                id: myToken
                label: qsTr("token")
                value: tokenField.text
                highlighted: changeToken
            }

            SectionHeader {
                text: qsTr("Personal access token")
            }

            LinkedLabel {
                color: Theme.secondaryHighlightColor
                width: parent.width - 2*x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin
                plainText: qsTr("Get your token from %1. And copy it to the field below.").arg("https://cloud.ouraring.com/account/login?next=%2Fpersonal-access-tokens")
            }

            TextField {
                id: tokenField
                placeholderText: qsTr("for example: %1").arg("A3EDG66YA...")
                text: token
                label: changeToken? qsTr("token changed"): qsTr("token")
                EnterKey.onClicked: {
                    focus = false
                }
                width: parent.width
                onPressAndHold: {
                    text = token
                }
                onTextChanged: {
                    changeToken = true
                }
            }

            SectionHeader {
                text: qsTr("Download old data")
            }

            Label {
                color: Theme.highlightColor
                width: parent.width - 2*x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin
                text: qsTr("The first downloaded record from OuraCloud is from %1. " +
                           "To retrieve older records choose the date below."
                           ).arg(Qt.formatDate(oura.firstDate(),Qt.DefaultLocaleShortDate))
            }

            ValueButton {
                id: dateButton
                label: qsTr("Fetch dates starting from")
                value: firstDate.toDateString(Qt.locale(), Locale.ShortFormat)
                onClicked: {
                    var dialog = pageContainer.push("Sailfish.Silica.DatePickerDialog", {
                                                    "date": firstDate } )
                    dialog.accepted.connect( function() {
                        value = dialog.dateText
                        firstDate = new Date(dialog.year, dialog.month-1, dialog.day, 13, 43, 43, 88)
                        year = dialog.year
                        month = dialog.month
                        day = dialog.day
                    } )
                }

                property date firstDate: oura.firstDate()
                property int  year: firstDate.getFullYear()
                property int  month: firstDate.getMonth()
                property int  day: firstDate.getDate()
            }

            Button {
                id: downloadButton
                text: qsTr("Fetch old records")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    oura.setStartDate(dateButton.year, dateButton.month, dateButton.day)
                    oura.downloadOuraCloud()
                    downloadLabel.visible = true
                }
            }

            Item {
                height: Theme.itemSizeMedium
                width: 1
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item {
                id: downloadLabel
                width: parent.width - 2*x
                height: dlIndicator.y + dlIndicator.height
                x: Theme.horizontalPageMargin
                visible: false

                Label {
                    id: dlLabel
                    color: Theme.highlightColor
                    text: qsTr("downloading records")
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                    }
                }

                BusyIndicator {
                    id: dlIndicator
                    running: parent.visible
                    size: BusyIndicatorSize.Large
                    anchors {
                        top: dlLabel.bottom
                        topMargin: Theme.paddingLarge
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        getUserData()
        changeToken = false // resetting required due to getUserData()
    }

    Component.onDestruction: {
        if (changeToken) {
            token = tokenField.text
            setToken(tokenField.text)
        }
    }
}
