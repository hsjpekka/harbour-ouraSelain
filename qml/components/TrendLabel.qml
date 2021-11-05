import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/scripts.js" as Scripts

Item {
    id: root
    width: implicitWidth
    height: implicitHeight
    implicitWidth: layout === layRow? title.width + valStr.width + icon.width + 2*_hgap :
                        layout === layCol? (title.width > valStr.width? title.width : valStr.width) :
                            title.width > (valStr.width + _hgap + icon.width)? title.width : valStr.width + _hgap + icon.width
    implicitHeight: layout === layRow? Math.max(title.height, valStr.height):
                                       layout === layCol? (title.width > valStr.width? title.width : valStr.width) :
                                           title.width > (valStr.width + _hgap + icon.width)? title.width : valStr.width + _hgap + icon.width
    /*
    Component.onCompleted: {
        console.log("leveydet: otsikko " + title.width + " arvo " + valStr.width + " x " + valStr.x + " merkki " + icon.width)
    } //*/

    property alias  text: title.text

    property int    average: 0
    //property int    averageMonth: 0
    //property int    averageWeek: 0
    //property int    averageYear: 0
    //property color  barHugeColor: Theme.highlightColor
    //property color  barNormalColor: Theme.secondaryHighlightColor
    //property color  barSmallColor: Theme.secondaryColor
    //property int    barWidth: Theme.fontSizeSmall
    property real   factor: 1.2
    property int    fontSize: Theme.fontSizeSmall
    property bool   isValid: true
    //property int    labelFontSize: Theme.fontSizeExtraSmall
    //property int    maxValue: 1
    //property int    valueType: 0 // 0 - value, 1 - time
    //property int    precision: 1
    property int    score: 0
    property string layout: layCompact
    readonly property string layCol: "column"
    readonly property string layRow: "row"
    readonly property string layCompact: "compact"
    //property real   _scale: (height - yearLabel.height - _vgap)/maxValue
    property int    _vgap: Theme.paddingSmall
    property int    _hgap: Theme.paddingMedium

    //onAverageYearChanged: {
        //yearValue.labelTxt = Scripts.secToHM(averageYear)
    //}
    /*
    onScoreChanged: {
        console.log("=======================")
        console.log("leveydet: " + text + " " + title.width + " arvo " + valStr.width + " x " + valStr.x + " merkki " + icon.width)
        console.log("=======================")
    } // */

    Label {
        id: title
        text: qsTr("score")
        color: Theme.secondaryHighlightColor
        font.pixelSize: fontSize
        x: 0
        y: 0
    }

    Label {
        id: valStr
        text: isValid? score : "-"
        color: Theme.highlightColor
        font.pixelSize: fontSize
        x: layout === layRow?
               title.x + _hgap : (layout === layCol?
                    title.x + 0.5*(title.width - width) :
                    title.x + 0.5*(title.width -
                                   (width + _hgap + icon.width)))
        y: layout === layRow ? 0 : title.height + _vgap
    }

    Icon {
        id: icon
        source: score === average? "image://theme/icon-s-asterisk" :
                                   "image://theme/icon-s-arrow"
        rotation: score > average? 180 : 0
        color: (score > average*factor || score < average/factor) ?
                   Theme.primaryColor : Theme.highlightColor
        //anchors.horizontalCenter: parent.horizontalCenter
        visible: isValid
        x: layout === layCol? title.x + 0.5*(title.width - width) :
                                    valStr.x + valStr.width + _hgap + 0.5*width
        y: layout === layCol? valStr.y + valStr.height + _vgap :
                              valStr.y
    }

    Rectangle {
        anchors.fill: parent
        color: parent.z === 0? "transparent" : Theme.backgroundGlowColor
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (parent.z === 0) {
                parent.z = 1;
            } else {
                parent.z = 0;
            }
        }
    }
}
