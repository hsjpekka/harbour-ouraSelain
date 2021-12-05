import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/scripts.js" as Scripts

Item {
    id: root
    width: implicitWidth
    height: implicitHeight
    implicitWidth: weekBar.x + weekBar.width //column.x + column.width
    implicitHeight: yearBar.height > monthBar.height?
                        (yearBar.height > weekBar.height?
                             yearBar.height : weekBar.height) :
                        (monthBar.height > weekBar.height?
                             monthBar.height : weekBar.height) //column.height

    //property alias  text: title.text
    property string text

    property int    average: 0
    property int    averageMonth: 0
    property int    averageWeek: 0
    property int    averageYear: 0
    property color  barHugeColor: Theme.highlightColor
    property color  barNormalColor: Theme.secondaryHighlightColor
    property color  barSmallColor: Theme.secondaryColor
    property int    barWidth: Theme.fontSizeSmall
    property real   factor: 1.2
    property int    fontSize: Theme.fontSizeSmall
    property bool   isValid: true
    property int    labelFontSize: Theme.fontSizeExtraSmall
    property int    maxValue: 1
    property int    valueType: 0 // 0 - value, 1 - secToHM, 2 - minToHM
    //property int    precision: 1
    property int    score: 0
    property real   _scale: (height - yearLabel.height - _vgap)/maxValue
    property int    _vgap: Theme.paddingSmall
    property int    _hgap: Theme.paddingSmall

    onAverageYearChanged: {
        if (valueType === 1) {
            yearValue.labelTxt = Scripts.secToHM(averageYear)
        } else if (valueType === 2) {
            yearValue.labelTxt = Scripts.minToHM(averageYear)
        }

    }
    onAverageMonthChanged: {
        if (valueType === 1) {
            monthValue.labelTxt = Scripts.secToHM(averageMonth)
        } else if (valueType === 2) {
            monthValue.labelTxt = Scripts.minToHM(averageMonth)
        }
    }
    onAverageWeekChanged: {
        if (valueType === 1) {
            weekValue.labelTxt = Scripts.secToHM(averageWeek)
        } else if (valueType === 2) {
            weekValue.labelTxt = Scripts.minToHM(averageWeek)
        }
    }
    onValueTypeChanged: {
        if (valueType === 1) {
            yearValue.labelTxt = Scripts.secToHM(averageYear)
            monthValue.labelTxt = Scripts.secToHM(averageMonth)
            weekValue.labelTxt = Scripts.secToHM(averageWeek)
        } else if (valueType === 2) {
            yearValue.labelTxt = Scripts.minToHM(averageYear)
            monthValue.labelTxt = Scripts.minToHM(averageMonth)
            weekValue.labelTxt = Scripts.minToHM(averageWeek)
        }
    }

    Rectangle {
        id: yearBar
        width: barWidth
        color: barNormalColor
        height: _scale*averageYear
        anchors {
            bottom: parent.bottom
            bottomMargin: root.labelFontSize + _vgap + Theme.paddingSmall
            left: parent.left
        }

        Label {
            id: yearLabel
            text: "365"
            color: Theme.highlightColor
            font.pixelSize: root.labelFontSize
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.bottom
                topMargin: _vgap
            }
        }

        Label {
            id: yearValue
            text: valueType === 0 ? averageYear : labelTxt
            visible: false
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.top
                bottomMargin: _vgap
            }

            property string labelTxt: ""
        }

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: {
                yearValue.visible = !yearValue.visible
                monthValue.visible = false
                weekValue.visible = false
            }
            onPressAndHold: {
                mouse.accepted = false
            }
        }
    }

    Rectangle {
        id: monthBar
        width: barWidth
        color: averageMonth > averageYear*factor? barHugeColor :
                    averageMonth > averageYear/factor? barNormalColor: barSmallColor
        height: _scale*averageMonth
        anchors {
            bottom: yearBar.bottom
            left: yearBar.right
            leftMargin: _hgap
        }

        Label {
            text: "30"
            color: Theme.highlightColor
            font.pixelSize: root.labelFontSize
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.bottom
                topMargin: _vgap
            }
        }

        Label {
            id: monthValue
            text: valueType === 0 ? averageMonth : labelTxt
            visible: false
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.top
                bottomMargin: _vgap
            }

            property string labelTxt: ""
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                monthValue.visible = !monthValue.visible
                yearValue.visible = false
                weekValue.visible = false
            }
        }
    }

    Rectangle {
        id: weekBar
        color: averageWeek > averageYear*factor? barHugeColor :
                    averageWeek > averageYear/factor? barNormalColor: barSmallColor
        width: barWidth
        height: _scale*averageWeek
        anchors {
            bottom: yearBar.bottom
            left: monthBar.right
            leftMargin: _hgap
        }

        Label {
            text: "7"
            color: Theme.highlightColor
            font.pixelSize: root.labelFontSize
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.bottom
                topMargin: _vgap
            }
        }

        Label {
            id: weekValue
            text: valueType === 0 ? averageWeek : labelTxt
            visible: false
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.top
                bottomMargin: _vgap
            }

            property string labelTxt: ""
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                weekValue.visible = !weekValue.visible
                yearValue.visible = false
                monthValue.visible = false
            }
        }
    }

    /*
    Column {
        id: column
        anchors {
            left: weekBar.right
            leftMargin: Theme.paddingSmall
        }

        Label {
            id: title
            text: qsTr("score")
            color: Theme.secondaryHighlightColor
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            text: isValid? score : "-"
            color: Theme.highlightColor
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Icon {
            source: score === average? "image://theme/icon-s-asterisk" :
                                       "image://theme/icon-s-arrow"
            rotation: score > average? 180 : 0
            color: (score > average*factor || score < average/factor) ?
                       Theme.primaryColor : Theme.highlightColor
            anchors.horizontalCenter: parent.horizontalCenter
            visible: isValid
        }
    }
    // */
}
