import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/scripts.js" as Scripts

Item {
    id: root
    width: implicitWidth
    height: implicitHeight
    implicitWidth: weekBar.x + weekBar.contentWidth //column.x + column.width
    implicitHeight: yearBar.height > monthBar.height?
                        (yearBar.height > weekBar.height?
                             yearBar.height : weekBar.height) :
                        (monthBar.height > weekBar.height?
                             monthBar.height : weekBar.height) //column.height

    property string text // not used

    property int    average: 0
    property int    averageMonth: 0
    property int    averageWeek: 0
    property int    averageYear: 0
    property color  barHugeColor: Theme.highlightColor
    property color  barNormalColor: Theme.secondaryHighlightColor
    property color  barSmallColor: Theme.secondaryColor
    property int    barWidth: Theme.fontSizeSmall
    property int    daysRead: 0
    property int    daysInWeek: 7
    property int    daysInMonth: 30
    property int    daysInYear: 365
    property real   factor: 1.2
    property int    fontSize: Theme.fontSizeSmall
    property bool   isValid: true
    property int    labelFontSize: Theme.fontSizeExtraSmall
    property int    maxValue: 1
    property int    valueType: 0 // 0 - value, 1 - secToHM, 2 - minToHM
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

        property int contentWidth: width > yearLabel.contentWidth? width : yearLabel.contentWidth

        Label {
            id: yearLabel
            text: "" + daysInYear
            color: Theme.highlightColor
            font {
                italic: daysRead < daysInYear
                pixelSize: root.labelFontSize
            }
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.bottom
                topMargin: _vgap
            }
        }

        Rectangle {
            id: yearBg
            height: yearValue.implicitHeight + 2*anchors.bottomMargin
            width: yearValue.implicitWidth + Theme.paddingSmall
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.top
                bottomMargin: _vgap
            }
            color: Theme.rgba(Theme.highlightDimmerColor, Theme.opacityHigh)
            visible: false

            Label {
                id: yearValue
                text: valueType === 0 ? averageYear : labelTxt
                anchors.centerIn: parent
                color: Theme.highlightColor
                font.italic: daysRead < daysInYear

                property string labelTxt: ""

            }
        }

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: {
                yearBg.visible = !yearBg.visible
                monthBg.visible = false
                weekBg.visible = false
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
            leftMargin: _hgap + monthBar.extraGap
        }

        property int contentWidth: width > monthLabel.contentWidth? width : monthLabel.contentWidth
        property real extraGap: 0.5*(yearBar.contentWidth - yearBar.width + contentWidth - width)

        Label {
            id: monthLabel
            text: "" + daysInMonth
            color: Theme.highlightColor
            font.pixelSize: root.labelFontSize
            font {
                italic: daysRead < daysInMonth
                pixelSize: root.labelFontSize
            }
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.bottom
                topMargin: _vgap
            }
        }

        Rectangle {
            id: monthBg
            height: monthValue.height + 2*anchors.bottomMargin
            width: monthValue.implicitWidth + Theme.paddingSmall
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.top
                bottomMargin: _vgap
            }
            color: Theme.rgba(Theme.highlightDimmerColor, Theme.opacityHigh)
            visible: false

            Label {
                id: monthValue
                text: valueType === 0 ? averageMonth : labelTxt
                anchors.centerIn: parent
                color: Theme.highlightColor
                font.italic: daysRead < daysInMonth

                property string labelTxt: ""
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                monthBg.visible = !monthBg.visible
                yearBg.visible = false
                weekBg.visible = false
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
            leftMargin: _hgap + weekBar.extraGap
        }

        property int contentWidth: width > weekLabel.contentWidth? width : weekLabel.contentWidth
        property real extraGap: 0.5*(monthBar.contentWidth - monthBar.width + contentWidth - width)

        Label {
            id: weekLabel
            text: "" + daysInWeek
            color: Theme.highlightColor
            font {
                italic: daysRead < daysInWeek
                pixelSize: root.labelFontSize
            }
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.bottom
                topMargin: _vgap
            }
        }

        Rectangle {
            id: weekBg
            height: weekValue.height + 2*anchors.bottomMargin
            width: weekValue.implicitWidth + Theme.paddingSmall
            color: Theme.rgba(Theme.highlightDimmerColor, Theme.opacityHigh)
            visible: false
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.top
                bottomMargin: _vgap
            }

            Label {
                id: weekValue
                text: valueType === 0 ? averageWeek : labelTxt
                anchors.centerIn: parent
                color: Theme.highlightColor
                font.italic: daysRead < daysInWeek

                property string labelTxt: ""
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                weekBg.visible = !weekBg.visible
                yearBg.visible = false
                monthBg.visible = false
            }
        }
    }
}
