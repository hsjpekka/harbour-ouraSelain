import QtQuick 2.0
import Sailfish.Silica 1.0

// changing chart orientation dynamically does not work properly
// addData(value, color, label, group, filling)
SilicaListView {
    id: barChartView

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
    property int    showBarValue: 1 // 0 - no, 1 - when clicked, 2 - always
    property int    showVariance: 0 // 0 - no, 1 - max, 2 - min,  3 - max and min -- only with a single set
    property bool   showLabel: true
    property bool   valueLabelOutside: false
    //property real   selectedBarHeight: 0
    //property string selectedBarLabel: ""
    property int ed: -1

    signal barSelected(int barNr, real barValue, string barLabel)
    signal barPressAndHold(int barNr, real barValue, string barLabel)

    function addData(val, clr, lbl, val2, clr2, val3, clr3, val4, clr4) {
        // {"barValue", "barColor", "barLabel", "group", "type"}
        // type: 0 - filled, 1 - top only
        var varMax, varMin, varClr;
        return listData.add(val, clr, val2, clr2, val3, clr3, val4, clr4, varMax, varMin,
                            varClr, lbl);
    }

    function addDataVariance(val, clr, varMax, varMin, varClr, lbl) {
        // {"barValue", "barColor", "localMax", "localMin", "maxMinColor", "barLabel", "group"}
        var val2, val3, val4, clr2, clr3, clr4;
        console.log("add " + val + ", " + varMax + ", " + varMin + ", " + varClr)
        return listData.add(val, clr, val2, clr2, val3, clr3, val4, clr4, varMax, varMin,
                            varClr, lbl);
    }

    height: orientation === ListView.Horizontal ? 3*Theme.fontSizeMedium : 4*Theme.fontSizeMedium
    width: parent.width

    delegate: ListItem {
        id: barItem
        contentHeight: barChartView.orientation === ListView.Horizontal ?
                    barChartView.height : (itemLabel.height > minItemWidth? itemLabel.height: minItemWidth)
        width: barChartView.orientation === ListView.Horizontal ?
                   ((showLabel && (labelWidth > minItemWidth))? labelWidth : minItemWidth) : parent.width
        propagateComposedEvents: true

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
        // bar height = barValue*scale
        property real   hscale: (barChartView.height - itemLabel.height - gap)/maxValue
        property real   vscale: (barChartView.width - labelWidth - gap)/maxValue
        property alias  valueLblVisible: valueLabel.visible

        onClicked: {
            var i = barChartView.indexAt(mouseX+x,mouseY+y)
            barSelected(i, bValue, bLabel)
            currentIndex = i
            if (!showLabel)
                itemLabel.visible = !itemLabel.visible
        }

        onPressAndHold: {
            var i = barChartView.indexAt(mouseX+x,mouseY+y)
            barPressAndHold(i, bValue, bLabel)
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
            visible: showLabel
        } //

        Label {
            id: valueLabel
            //text: showBarValue === 2 ? barItem.bValue : ""
            text: barItem.bValue
            visible: showBarValue === 2? true : (showBarValue === 1 ?
                                                     barItem.ListView.isCurrentItem : false)
            font.pixelSize: labelFontSize
            font.bold: inFront
            horizontalAlignment: barChartView.orientation === ListView.Horizontal?
                                     Text.AlignHCenter : Text.AlignLeft
            x: barChartView.orientation === ListView.Horizontal ?
                   0.5*(parent.width - width) : defX
                   //(defX > parent.width ? parent.width - width : defX)
                   //chartBar.x + chartBar.width + Theme.paddingSmall
            y: barChartView.orientation === ListView.Horizontal ? // chartBar.y - height - Theme.paddingSmall
                    //defY : 0.5*(parent.contentHeight - height)
                    (inFront ? 0 : defY) : 0.5*(parent.contentHeight - height)
            z: 1
            color: labelColor
            width: contentWidth //barChartView.orientation === ListView.Horizontal? parent.width : labelWidth

            property int defX: chartBar.x + chartBar.width + Theme.paddingSmall
            property int defY: chartBar4.y - height - Theme.paddingSmall
            property bool inFront: valueLabelOutside? false: (defY < 0)

            //*
            Rectangle {
                id: tausta
                anchors.fill: parent
                color: "black" //Theme.highlightDimmerColor
                opacity: Theme.opacityHigh
                //visible: parent.inFront ? (valueLabel.text > "") : false
                visible: parent.inFront ? parent.visible : false
                z:-1
            }
            // */
        }
    }//listitem

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
        function add(val, clr, val2, clr2, val3, clr3, val4, clr4, vMax, vMin, mmClr, lbl) {
            var clrStr, clr2Str, clr3Str, clr4Str, vClrStr;
            if (lbl === undefined)
                lbl = "";
            if (clr === undefined)
                clr = "'" + Theme.highlightColor + "'";
            if (clr2 === undefined)
                clr2 = "'" + Theme.secondaryHighlightColor + "'";
            if (clr3 === undefined)
                clr3 = "'" + Theme.highlightDimmerColor + "'";
            if (clr4 === undefined)
                clr4 = "'" + Theme.highlightBackgroundColor + "'";
            if (val === undefined)
                val = 0;
            if (val2 !== undefined)
                nrSets = 2
            else
                val2 = 0;
            if (val3 !== undefined)
                nrSets = 3
            else
                val3 = 0;
            if (val4 !== undefined)
                nrSets = 4
            else
                val4 = 0;
            clrStr = "" + clr;
            clr2Str = "" + clr2;
            clr3Str = "" + clr3;
            clr4Str = "" + clr4;
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
            append({"barValue": val*1.0, "barColor": clrStr, "barLabel": lbl,
                                "bar2Value": val2*1.0, "bar2Color": clr2Str,
                                "bar3Value": val3*1.0, "bar3Color": clr3Str,
                                "bar4Value": val4*1.0, "bar4Color": clr4Str,
                                "localMax": vMax*1.0, "localMin": vMin*1.0,
                                "maxMinColor": vClrStr});
        }
    }
}
