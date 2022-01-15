import QtQuick 2.0
import Sailfish.Silica 1.0

// changing chart orientation dynamically does not work properly
// addData(value, color, label, group, filling)
SilicaListView {
    id: barChartView
    height: orientation === ListView.Horizontal ? 3*Theme.fontSizeMedium : 4*Theme.fontSizeMedium
    width: parent.width

    delegate: delegateItem

    section {
        property: "group"

        delegate: Item {
            width: barChartView.orientation === ListView.Horizontal?
                       sectionLabel.height : parent.width
            height: barChartView.orientation === ListView.Horizontal?
                        barChartView.height : sectionLabel.height //+ Theme.paddingSmall
            z:1
            Label {
                id: sectionLabel
                text: section
                color: sectionColor
                font.pixelSize: sectionFontSize
                x: barChartView.orientation === ListView.Horizontal?
                       height : parent.width - width - Theme.horizontalPageMargin
                y: barChartView.orientation === ListView.Horizontal?
                       0 : 0//Theme.paddingSmall
                transform: [
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        angle: barChartView.orientation === ListView.Horizontal? 90 : 0
                    }
                ]
            }
        }

    }

    model: ListModel {
        // {"barValue", "barColor", "barLabel", "group"} // type: 0 - filled, 1 - top only
        id: listData

        function insertData(i, se, v1, c1, v2, c2, v3, c3, v4, c4, vMax, vMin, mmClr, lbl, vlbl) {
            var clrStr, clr2Str, clr3Str, clr4Str, vClrStr;
            if (lbl === undefined)
                lbl = "";
            if (c1 === undefined)
                c1 = "'" + Theme.highlightColor + "'";
            if (c2 === undefined)
                c2 = "'" + Theme.secondaryHighlightColor + "'";
            if (c3 === undefined)
                c3 = "'" + Theme.highlightDimmerColor + "'";
            if (c4 === undefined)
                c4 = "'" + Theme.highlightBackgroundColor + "'";
            if (v1 === undefined)
                v1 = 0;
            if (v2 !== undefined)
                nrSets = 2
            else
                v2 = 0;
            if (v3 !== undefined)
                nrSets = 3
            else
                v3 = 0;
            if (v4 !== undefined)
                nrSets = 4
            else
                v4 = 0;
            if (vlbl === undefined)
                vlbl = "";
            clrStr = "" + c1;
            clr2Str = "" + c2;
            clr3Str = "" + c3;
            clr4Str = "" + c4;
            if (showVariance < 0)
                showVariance = 0;
            if (mmClr === undefined)
                mmClr = "'" + Theme.secondaryColor + "'";
            if (vMax === undefined)
                vMax = 0
            else if (showVariance === 0 || showVariance === 2)
                showVariance += 1;
            if (vMin === undefined)
                vMin = 0
            else if (showVariance === 0 || showVariance === 1)
                showVariance += 2;
            vClrStr = "" + mmClr;
            insert(i, {"group": se, "barValue": v1*1.0, "barColor": clrStr, "barLabel": lbl,
                       "bar2Value": v2*1.0, "bar2Color": clr2Str,
                       "bar3Value": v3*1.0, "bar3Color": clr3Str,
                       "bar4Value": v4*1.0, "bar4Color": clr4Str,
                       "localMax": vMax*1.0, "localMin": vMin*1.0,
                       "maxMinColor": vClrStr, "valLabel": vlbl});
        }        
    }

    property int    arrayType: 0 // 0 - stack, 1 - side by side
    property int    barWidth: Theme.fontSizeMedium
    property int    barType: 0 // 0 - column, 1 - line at value, 2 ...
    property alias  chartData: listData
    property color  labelColor: Theme.highlightColor
    property real   labelFontSize: Theme.fontSizeExtraSmall
    property real   labelWidth: Theme.fontSizeMedium*1.5
    property int    minItemWidth: arrayType === 1? nrSets*barWidth : barWidth
    property real   maxValue: height
    property int    nrSets: 1
    property color  sectionColor: Theme.highlightColor
    property real   sectionFontSize: Theme.fontSizeExtraSmall
    property var    sectionOrientation: orientation === ListView.Horizontal ? ListView.Vertical : ListView.Horizontal
    property int    setCount: 1
    property string set1Name: ""
    property string set2Name: ""
    property string set3Name: ""
    property string set4Name: ""
    property bool   setValueLabel: false
    property int    showBarValue: 1 // 0 - no, 1 - when clicked, 2 - always
    property int    showVariance: 0 // 0 - no, 1 - max, 2 - min,  3 - max and min -- only with a single set
    property int    showLabel: 2 // 0 - no, 1 - when clicked, 2 - always
    property bool   valueLabelOutside: false
    property int    valueLabelMinY: labelFontSize + Theme.paddingSmall

    readonly property var validDataElements: ["group", "barValue",
        "barColor", "barLabel", "bar2Value", "bar2Color", "bar3Value",
        "bar3Color", "bar4Value", "bar4Color", "localMax", "localMin",
        "maxMinColor", "valLabel"]
    readonly property int showLabelNever: 0
    readonly property int showLabelOnClick: 0
    readonly property int showLabelAlways: 2

    signal barSelected(int barNr, real barValue, string barLabel, real xView, real yView)
    signal barPressAndHold(int barNr, real barValue, string barLabel)
    signal dataCleared()

    Component {
        id: delegateItem
        ListItem {
            id: barItem
            contentHeight: barChartView.orientation === ListView.Horizontal ?
                        barChartView.height : (itemLabel.height > minItemWidth? itemLabel.height: minItemWidth)
            width: barChartView.orientation === ListView.Horizontal ?
                       ((showLabel === 0 && labelWidth > minItemWidth)? labelWidth : minItemWidth) : parent.width
            propagateComposedEvents: true
            z: ListView.isCurrentItem? 1 : 0

            property real   barTop: barChartView.orientation === ListView.Horizontal ?
                                        bValue*hscale : bValue*vscale
            property real   bar2Top: barChartView.orientation === ListView.Horizontal ?
                                        b2Value*hscale : b2Value*vscale
            property real   bar3Top: barChartView.orientation === ListView.Horizontal ?
                                        b3Value*hscale : b3Value*vscale
            property real   bar4Top: barChartView.orientation === ListView.Horizontal ?
                                        b4Value*hscale : b4Value*vscale
            property string bLabel: barLabel
            property real   bLength: barType === 0 ? barTop : 2
            property real   b2Length: barType === 0 ? bar2Top : 2
            property real   b3Length: barType === 0 ? bar3Top : 2
            property real   b4Length: barType === 0 ? bar4Top : 2
            property real   bValue: barValue
            property real   b2Value: bar2Value
            property real   b3Value: bar3Value
            property real   b4Value: bar4Value
            property real   relPos: arrayType === 0 ? 0.5 : 1/(2*nrSets)
            property real   gap: Theme.paddingSmall
            property real   hscale: (barChartView.height - itemLabel.height - gap)/maxValue
            property string vlabel: valLabel
            property real   vscale: (barChartView.width - labelWidth - gap)/maxValue
            property alias  valueLblVisible: valueBg.visible

            onClicked: {
                var i, xView, yView
                i = barChartView.indexAt(x + 0.5*width, y + 0.5*height)
                if (showBarValue === 1 && currentIndex === i) {
                    currentIndex = -1
                } else {
                    currentIndex = i
                }
                xView = x - barChartView.contentX + 0.5*width // from bar center to visible area top left corner
                yView = y - barChartView.contentY + 0.5*height
                barSelected(i, bValue, bLabel, xView, yView) // signal barSelected(int barNr, real barValue, string barLabel, real xMouse, real yMouse)
            }

            onPressAndHold: {
                var i = barChartView.indexAt(mouseX+x,mouseY+y)
                barPressAndHold(i, bValue, bLabel)
                mouse.accepted = false
            }

            Rectangle {
                id: chartBar
                height: barChartView.orientation === ListView.Horizontal ? barItem.bLength : barWidth
                width: barChartView.orientation === ListView.Horizontal ? barWidth : barItem.bLength
                color: barColor
                opacity: 1.0
                y: barChartView.orientation === ListView.Horizontal ?
                       itemLabel.y - barItem.gap  - barItem.barTop:
                       barItem.relPos*(parent.contentHeight - height)
                x: barChartView.orientation === ListView.Horizontal ?
                       barItem.relPos*(parent.width - width): itemLabel.width + barItem.gap
                       + barItem.barTop - width
            }

            Rectangle {
                id: chartBar2
                height: barChartView.orientation === ListView.Horizontal ? barItem.b2Length : barWidth
                width: barChartView.orientation === ListView.Horizontal ? barWidth : barItem.b2Length
                color: bar2Color
                opacity: 1.0
                visible: nrSets > 1
                y: barChartView.orientation === ListView.Horizontal ?
                       (arrayType === 0 ? chartBar.y - barItem.bar2Top :
                                          itemLabel.y - barItem.gap - barItem.bar2Top):
                       (arrayType === 0 ? chartBar.y : chartBar.y + chartBar.height)
                x: barChartView.orientation === ListView.Horizontal ?
                       (arrayType === 0 ? chartBar.x : chartBar.x + chartBar.width) :
                       stackX + barItem.bar2Top - width
                property int stackX: arrayType === 0 ? chartBar.x + chartBar.width :
                                                       itemLabel.width + barItem.gap
            }

            Rectangle {
                id: chartBar3
                height: barChartView.orientation === ListView.Horizontal ? barItem.b3Length : barWidth
                width: barChartView.orientation === ListView.Horizontal ? barWidth : barItem.b3Length
                color: bar3Color
                opacity: 1.0
                visible: nrSets > 2
                y: barChartView.orientation === ListView.Horizontal ?
                       (arrayType === 0 ? chartBar2.y - barItem.bar3Top :
                                          itemLabel.y - barItem.gap - barItem.bar3Top):
                       (arrayType === 0 ? chartBar2.y : chartBar2.y + chartBar2.height)
                x: barChartView.orientation === ListView.Horizontal ?
                       (arrayType === 0 ? chartBar2.x : chartBar2.x + chartBar2.width) :
                       stackX + barItem.bar3Top - width
                property int stackX: arrayType === 0 ? chartBar2.x + chartBar2.width :
                                                       itemLabel.width + barItem.gap
            }

            Rectangle {
                id: chartBar4
                height: barChartView.orientation === ListView.Horizontal ? barItem.b4Length : barWidth
                width: barChartView.orientation === ListView.Horizontal ? barWidth : barItem.b4Length
                color: bar4Color
                opacity: 1.0
                visible: nrSets > 3
                y: barChartView.orientation === ListView.Horizontal ?
                       (arrayType === 0 ? chartBar3.y - barItem.bar4Top :
                                          itemLabel.y - barItem.gap - barItem.bar4Top):
                       (arrayType === 0 ? chartBar3.y : chartBar3.y + chartBar3.height)
                x: barChartView.orientation === ListView.Horizontal ?
                       (arrayType === 0 ? chartBar3.x : chartBar3.x + chartBar3.width) :
                       stackX + barItem.bar4Top - width
                property int stackX: arrayType === 0 ? chartBar3.x + chartBar3.width :
                                                       itemLabel.width + barItem.gap
            }

            Rectangle {
                id: localMaxBar
                height: barChartView.orientation === ListView.Horizontal ? 2 : barWidth + Theme.paddingSmall
                width: barChartView.orientation === ListView.Horizontal ? barWidth + Theme.paddingSmall : 2
                color: maxMinColor
                visible: showVariance === 1 || showVariance === 3
                y: barChartView.orientation === ListView.Horizontal ?
                       itemLabel.y - barItem.gap  - barItem.hscale*localMax:
                       0.5*(parent.contentHeight - height)
                x: barChartView.orientation === ListView.Horizontal ?
                       0.5*(parent.width - width) : itemLabel.x + itemLabel.width +
                       barItem.gap + barItem.vscale*localMax
                z: 1
            }

            Rectangle {
                id: localMinBar
                height: barChartView.orientation === ListView.Horizontal ? 1 : barWidth + Theme.paddingSmall
                width: barChartView.orientation === ListView.Horizontal ? barWidth + Theme.paddingSmall : 1
                color: maxMinColor
                visible: showVariance === 2 || showVariance === 3
                y: barChartView.orientation === ListView.Horizontal ?
                       itemLabel.y - barItem.gap  - barItem.hscale*localMin:
                       0.5*(parent.contentHeight - height)
                x: barChartView.orientation === ListView.Horizontal ?
                       0.5*(parent.width - width) : itemLabel.x + itemLabel.width +
                       barItem.gap + barItem.vscale*localMin
                z: 1
            }

            Label {
                id: itemLabel
                text: barItem.bLabel
                font.pixelSize: labelFontSize
                horizontalAlignment: barChartView.orientation === ListView.Horizontal?
                                         Text.AlignHCenter : Text.AlignRight
                x: barChartView.orientation === ListView.Horizontal ?
                       0.5*(parent.width - width) : 0
                y: barChartView.orientation === ListView.Horizontal ?
                       parent.height - height : 0.5*(parent.contentHeight - height)

                width: barChartView.orientation === ListView.Horizontal? parent.width : labelWidth
                color: labelColor
                visible: showLabel === 2? true : showLabel === 1 ?
                                barItem.ListView.isCurrentItem : false
            } //

            Rectangle {
                id: valueBg
                //anchors.fill: parent
                color: Theme.rgba(Theme.highlightDimmerColor, Theme.opacityHigh)
                //visible: parent.inFront ? (valueLabel.text > "") : false
                visible: showBarValue === 2? true : showBarValue === 1 ?
                                barItem.ListView.isCurrentItem : false
                width: valueLabel.width + Theme.paddingSmall
                height: valueLabel.height + Theme.paddingSmall
                x: barChartView.orientation === ListView.Horizontal ?
                       0.5*(parent.width - width) : defX
                       //(defX > parent.width ? parent.width - width : defX)
                       //chartBar.x + chartBar.width + Theme.paddingSmall
                y: barChartView.orientation === ListView.Horizontal ? // chartBar.y - height - Theme.paddingSmall
                        //defY : 0.5*(parent.contentHeight - height)
                        (inFront ? 0 : defY) : 0.5*(parent.contentHeight - height)

                property int defX: chartBar.x + chartBar.width + Theme.paddingSmall
                property int defY: chartBar4.y - height - Theme.paddingSmall
                property bool inFront: valueLabelOutside? false: (defY < -valueLabelMinY)

                Label {
                    id: valueLabel
                    anchors.centerIn: parent
                    //text: showBarValue === 2 ? barItem.bValue : ""
                    text: setValueLabel? barItem.vlabel : barItem.bValue
                    //visible: showBarValue === 2? true : showBarValue === 1 ?
                    //                barItem.ListView.isCurrentItem : false
                    font.pixelSize: labelFontSize
                    font.bold: parent.inFront
                    horizontalAlignment: barChartView.orientation === ListView.Horizontal?
                                             Text.AlignHCenter : Text.AlignLeft
                    color: labelColor
                    width: contentWidth //barChartView.orientation === ListView.Horizontal? parent.width : labelWidth
                }
            }

        }//listitem
    }

    function addData(sct, val, clr, lbl, val2, clr2, val3, clr3, val4, clr4, vlbl) {
        // {"barValue", "barColor", "barLabel", "group", "type"}
        // type: 0 - filled, 1 - top only
        var varMax, varMin, varClr, i;
        i = listData.count;
        return listData.insertData(i, sct, val, clr, val2, clr2, val3, clr3, val4, clr4,
                                   varMax, varMin, varClr, lbl, vlbl);
    }

    function addDataVariance(sct, val, clr, varMax, varMin, varClr, lbl, vlbl) {
        // {"barValue", "barColor", "localMax", "localMin", "maxMinColor", "barLabel", "group"}
        var val2, val3, val4, clr2, clr3, clr4, i;

        i = listData.count;
        return listData.insertData(i, sct, val, clr, val2, clr2, val3, clr3, val4, clr4, varMax,
                                   varMin, varClr, lbl, vlbl);
    }

    function clear(ind) {
        if (ind === undefined) {
            dataCleared();
            return listData.clear();
        }

        if (ind >= 0 && ind < listData.count) {
            return listData.remove(ind);
        }

        return -1;
    }

    function insertData(i, sct, val, clr, lbl, val2, clr2, val3, clr3, val4, clr4, vlbl) {
        var varMax, varMin, varClr;
        return listData.insertData(i, sct, val, clr, val2, clr2, val3, clr3, val4, clr4, varMax,
                                   varMin, varClr, lbl, vlbl);
    }

    function insertDataVariance(i, sct, val, clr, varMax, varMin, varClr, lbl, vlbl) {
        var val2, val3, val4, clr2, clr3, clr4;
        return listData.insertData(i, sct, val, clr, val2, clr2, val3, clr3, val4, clr4, varMax,
                                   varMin, varClr, lbl, vlbl);
    }

    function modify(i, key, value) {
        var result = false;
        if (i > listData.count) {
            return;
        }

        if (validDataElements.indexOf(key) >= 0) {
            listData.setProperty(i, key, value);
            result = true;
        }
        return result;
    }
}
