import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    allowedOrientations: Orientation.All
    Component.onCompleted: {
        getUserData()
        changeToken = false // tokenField.text is changed during set up
        /*
        if (tokenField.text === "") {
            tokenField.readOnly = false
        }
        // */
    }

    Component.onDestruction: {
        if (changeToken) {
            token = tokenSection.token
            setToken(token)
        }
    }

    property bool changeToken: false
    property string newToken
    property string token
    property bool reloaded: false

    signal cloudReloading(date firstReloaded)
    signal setToken(string newToken)
    signal resetToken()

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
            downloadLabel.showLoading = ouraCloud.isLoading()
        }
        onFinishedSleep: {
            sleepReady.ready = true
            downloadLabel.showLoading = ouraCloud.isLoading()
        }
        onFinishedReadiness: {
            readinessReady.ready = true
            downloadLabel.showLoading = ouraCloud.isLoading()
        }
        onFinishedBedTimes: {
            bedtimesReady.ready = true
            downloadLabel.showLoading = ouraCloud.isLoading()
        }
        onFinishedInfo: {
            infoReady.ready = true
            downloadLabel.showLoading = ouraCloud.isLoading()
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
                    ouraCloud.setPersonalAccessToken(tokenSection.token)
                    ouraCloud.downloadOuraCloud("userinfo")
                }
            }

            MenuItem {
                text: qsTr("reset token")
                onClicked: {
                    tokenSection.token = token
                    resetToken()
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

            /*DetailItem {
                id: myToken
                label: qsTr("token")
                value: tokenField.text
                highlighted: changeToken
            }//*/

            ModExpandingSection {
                id: tokenSection
                title: qsTr("Personal access token")
                expanded: token > "" ? false : true
                //font.color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeMedium
                content.sourceComponent: Column {
                    spacing: Theme.paddingSmall

                    Connections {
                        target: page
                        onResetToken: {
                            tokenField.text = tokenSection.token
                        }
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
                        readOnly: text > ""
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
                            tokenSection.token = text
                        }
                    }

                }

                property string token: value
            }

            /*SectionHeader {
                text: qsTr("Personal access token")
            }//*/

            SectionHeader {
                text: qsTr("Download old data")
            }

            Label {
                id: txtDataFrom
                color: Theme.secondaryHighlightColor
                width: parent.width - 2*x
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                x: Theme.horizontalPageMargin
                text: qsTr("The first downloaded record from OuraCloud is from %1. " +
                           "To retrieve older records choose the date below."
                           ).arg(fromDate)

                property string fromDate: updateFromDate(1) // Qt.formatDate(ouraCloud.firstDate(),Qt.DefaultLocaleShortDate)

                function updateFromDate(initialize) {
                    var result;
                    result = Qt.formatDate(ouraCloud.firstDate(),Qt.DefaultLocaleShortDate)
                    if (initialize === undefined) {
                        fromDate = result;
                    }

                    return result;
                }
            }

            ValueButton {
                id: dateButton
                label: qsTr("From date")
                value: firstDate.toDateString(Qt.locale(), Locale.ShortFormat)
                onClicked: {
                    var dialog = pageContainer.push("Sailfish.Silica.DatePickerDialog", {
                                                    "date": firstDate } )
                    dialog.accepted.connect( function() {
                        value = dialog.dateText;
                        firstDate = new Date(dialog.year, dialog.month-1, dialog.day, 13, 43, 43, 88);
                        //year = dialog.year;
                        //month = dialog.month;
                        //day = dialog.day;
                    } )
                }

                property date firstDate: ouraCloud.firstDate()

            }

            Button {
                id: downloadButton
                text: qsTr("Fetch old records")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    var year, month, date
                    downloadLabel.showLoading = true
                    activityReady.ready = false
                    sleepReady.ready = false
                    readinessReady.ready = false
                    bedtimesReady.ready = false
                    infoReady.ready = false

                    cloudReloading(dateButton.firstDate)
                    year = dateButton.firstDate.getFullYear();
                    month = dateButton.firstDate.getMonth() + 1;
                    date = dateButton.firstDate.getDate();
                    ouraCloud.setStartDate(year, month, date)
                    ouraCloud.downloadOuraCloud()
                    //dateButton.updateDate()

                    // move to show the rotating circle
                    flickingArea.scrollToBottom()
                    reloaded = true
                }
            }

            Item {
                id: downloadLabel
                width: parent.width - 2*x
                height: showLoading? dlLabel.height + dlIndicator.height
                                     + dlIndicator.anchors.topMargin : Theme.paddingLarge
                x: Theme.horizontalPageMargin
                visible: false
                onShowLoadingChanged: {
                    if (showLoading === false) {
                        txtDataFrom.updateFromDate()
                    }
                }

                property bool showLoading: false

                Label {
                    id: dlLabel
                    color: Theme.highlightColor
                    text: qsTr("downloading records")
                    visible: parent.showLoading
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                    }
                }

                BusyIndicator {
                    id: dlIndicator
                    running: parent.showLoading
                    visible: running
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
                    visible: parent.showLoading
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
                    visible: parent.showLoading
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
                    visible: parent.showLoading
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
                    visible: parent.showLoading
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
                    visible: parent.showLoading
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
