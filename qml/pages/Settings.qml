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
        var str = oura.myName();
        age.value = oura.value("userinfo","age");
        gender.value = oura.value("userinfo","gender");
        user.value = str;
        if (str.indexOf("@") < 0) {
            user.label = qsTr("name");
        }
        weight.value = oura.value("userinfo","weight");
        return;
    }

    Connections {
        target: oura
        onFinishedInfo: {
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
                text: "Personal access token"
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
