import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    allowedOrientations: Orientation.All
    Component.onCompleted: {
        getUserData()
        changeToken = false // tokenField.text is changed during set up
        if (tokenField.text === "") {
            tokenField.readOnly = false
        }
    }

    Component.onDestruction: {
        if (changeToken) {
            token = tokenField.text
            setToken(tokenField.text)
        }
    }

    property bool changeToken: false
    property string token
    property bool reloaded: false

    signal setToken(string newToken)
    signal cloudReloaded(date firstReloaded)

    function getUserData() {
        var str = ouraCloud.myName(qsTr("name unknown"));
        age.value = ouraCloud.value("userinfo","age");
        gender.value = ouraCloud.value("userinfo","gender");
        user.value = str;
        if (str.indexOf("@") > 0) {
            user.label = qsTr("email");
        } else {
            user.label = qsTr("name");
        }

        weight.value = ouraCloud.value("userinfo","weight");
        return;
    }

    Connections {
        target: ouraCloud
        onFinishedActivity: {
            activityReady.ready = true
            downloadLabel.visible = ouraCloud.isLoading()
        }
        onFinishedSleep: {
            sleepReady.ready = true
            downloadLabel.visible = ouraCloud.isLoading()
        }
        onFinishedReadiness: {
            readinessReady.ready = true
            downloadLabel.visible = ouraCloud.isLoading()
        }
        onFinishedBedTimes: {
            bedtimesReady.ready = true
            downloadLabel.visible = ouraCloud.isLoading()
        }
        onFinishedInfo: {
            infoReady.ready = true
            downloadLabel.visible = ouraCloud.isLoading()
            getUserData()
        }
    }

    SilicaFlickable {
        id: flickingArea
        anchors.fill: parent
        contentHeight: col.height
        width: parent.width

        PullDownMenu {
            MenuItem {
                text: qsTr("refresh data")
                onClicked: {
                    ouraCloud.setPersonalAccessToken(tokenField.text)
                    ouraCloud.downloadOuraCloud("userinfo")
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

            Label {
                x: Theme.horizontalPageMargin
                color: Theme.secondaryHighlightColor
                text: qsTr("refresh data from the pull down menu")
                visible: changeToken
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

            Item {
                height: Theme.paddingSmall
                width: 1
            }

            TextField {
                id: tokenField
                placeholderText: qsTr("for example: %1").arg("A3EDG66YA...")
                readOnly: true
                text: token
                labelVisible: true
                label: readOnly? qsTr("press to change"): qsTr("token")
                EnterKey.onClicked: {
                    focus = false
                    readOnly = true
                }
                width: parent.width
                onPressAndHold: {
                    readOnly = false
                }
                onTextChanged: {
                    changeToken = true
                }
            }

            SectionHeader {
                text: qsTr("Download old data")
            }

            Label {
                color: Theme.secondaryHighlightColor
                width: parent.width - 2*x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin
                text: qsTr("The first downloaded record from OuraCloud is from %1. " +
                           "To retrieve older records choose the date below."
                           ).arg(Qt.formatDate(ouraCloud.firstDate(),Qt.DefaultLocaleShortDate))
            }

            ValueButton {
                id: dateButton
                label: qsTr("From date")
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

                property date firstDate: ouraCloud.firstDate()
                property int  year: firstDate.getFullYear()
                property int  month: firstDate.getMonth()
                property int  day: firstDate.getDate()
            }

            Button {
                id: downloadButton
                text: qsTr("Fetch old records")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    downloadLabel.visible = true
                    activityReady.ready = false
                    sleepReady.ready = false
                    readinessReady.ready = false
                    bedtimesReady.ready = false
                    infoReady.ready = false

                    ouraCloud.setStartDate(dateButton.year, dateButton.month, dateButton.day)
                    ouraCloud.downloadOuraCloud()
                    // move to show the rotating circle
                    flickingArea.scrollToBottom()

                    reloaded = true
                    cloudReloaded(dateButton.firstDate)
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
                height: dlLabel.height + dlIndicator.height + dlIndicator.anchors.topMargin
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
                        horizontalCenter: parent.horizontalCenter
                    }
                }

                Label {
                    id: infoReady
                    text: qsTr("info")
                    color: ready? Theme.highlightDimmerColor : Theme.secondaryHighlightColor
                    anchors {
                        bottom: dlIndicator.verticalCenter
                        bottomMargin: Theme.paddingSmall
                        right: bedtimesReady.left
                        rightMargin: Theme.paddingMedium
                    }

                    property bool ready: false
                }

                Label {
                    id: activityReady
                    text: qsTr("activity")
                    color: ready? Theme.highlightDimmerColor : Theme.secondaryHighlightColor
                    anchors {
                        top: dlIndicator.verticalCenter
                        topMargin: Theme.paddingSmall
                        left: dlIndicator.horizontalCenter
                        leftMargin: Theme.paddingMedium
                    }

                    property bool ready: false
                }

                Label {
                    id: bedtimesReady
                    text: qsTr("bedtimes")
                    color: ready? Theme.highlightDimmerColor : Theme.secondaryHighlightColor
                    anchors {
                        horizontalCenter: dlIndicator.horizontalCenter
                        bottom: dlIndicator.verticalCenter
                        bottomMargin: Theme.paddingSmall
                    }

                    property bool ready: false
                }

                Label {
                    id: readinessReady
                    text: qsTr("readiness")
                    color: ready? Theme.highlightDimmerColor : Theme.secondaryHighlightColor
                    anchors {
                        top: dlIndicator.verticalCenter
                        topMargin: Theme.paddingSmall
                        right: dlIndicator.horizontalCenter
                        rightMargin: Theme.paddingMedium
                    }

                    property bool ready: false
                }

                Label {
                    id: sleepReady
                    text: qsTr("sleep")
                    color: ready? Theme.highlightDimmerColor : Theme.secondaryHighlightColor
                    anchors {
                        bottom: dlIndicator.verticalCenter
                        bottomMargin: Theme.paddingSmall
                        left: bedtimesReady.right
                        leftMargin: Theme.paddingMedium
                    }

                    property bool ready: false
                }
            }
        }
    }
}
