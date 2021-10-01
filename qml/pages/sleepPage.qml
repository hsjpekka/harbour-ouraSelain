import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/datab.js" as DataB
import "../utils/scripts.js" as Scripts
import "../components/"

Page {
    id: page

    property date summaryDate: new Date()
    property bool validDate: true

    QtObject {
        id: locals

        property string midpoint
        // hours
        property real bedTime
        property real awake
        property real lightTime
        property real remTime
        property real deepTime
        // minutes
        property real latencyTime
        // percentages
        property real restless
        property real timeEfficiency
        // scores
        property int timeScore
        property int disturbances
        property int efficiency
        property int latencyScore
        property int remScore
        property int deepScore
        property int alignment
        // body
        property int hrMin
        property real hrAve
        property int hrVariation
        property real breath
        property real dT

    } //*/

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: jsonString.visible? qsTr("hide json") : qsTr("show json")
                onClicked: {
                    jsonString.visible = !jsonString.visible
                    if (jsonString.visible)
                        jsonString.text = ouraCloud.printSleep()
                }
            }
            MenuItem {
                text: qsTr("next day")
                onClicked: {
                    previousDay(1);
                    updateValues();
                }
            }
            MenuItem {
                text: qsTr("previous day")
                onClicked: {
                    previousDay();
                    updateValues();
                }
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: qsTr("Sleep")
            }

            ValueButton {
                id: txtDate
                label: qsTr("date")
                value: summaryDate.toDateString(Qt.locale(), Locale.ShortFormat)
                onClicked: {
                    var dialog = pageContainer.push("Sailfish.Silica.DatePickerDialog", {
                                                    "date": summaryDate } )
                    dialog.accepted.connect( function() {
                        value = dialog.dateText
                        summaryDate = new Date(dialog.year, dialog.month-1, dialog.day, 13, 43, 43, 88)
                        ouraCloud.setDateConsidered(summaryDate)
                        updateValues()
                    } )
                }
            }

            ModExpandingSection {
                id: scoreSleep
                title: validDate? qsTr("score %1").arg(value) : "-"
                font.pixelSize: Theme.fontSizeMedium

                property int value

                content.sourceComponent: Column {
                        width: parent.width

                        DetailItem {
                            id: scoreTime
                            label: qsTr("sleep time")
                            value: validDate? locals.timeScore : "-"
                        }

                        DetailItem {
                            id: scoreDisturbances
                            label: qsTr("disturbances")
                            value: validDate? locals.disturbances : "-"
                        }

                        DetailItem {
                            id: scoreEfficiency
                            label: qsTr("efficiency")
                            value: validDate? locals.efficiency : "-"
                        }

                        DetailItem {
                            id: scoreLatency
                            label: qsTr("latency")
                            value: validDate? locals.latencyScore : "-"
                        }

                        DetailItem {
                            id: scoreREM
                            label: qsTr("REM")
                            value: validDate? locals.remScore : "-"
                        }

                        DetailItem {
                            id: scoreDeep
                            label: qsTr("deep sleep")
                            value: validDate? locals.deepScore : "-"
                        }

                        DetailItem {
                            id: scoreAlignment
                            label: qsTr("alignment")
                            value: validDate? locals.alignment : "-"
                        }
                    }
            }

            ModExpandingSection {
                id: timeTotal
                title: validDate? qsTr("sleep time %1 h").arg(value.toFixed(1)) : "-"
                font.pixelSize: Theme.fontSizeMedium

                property real value

                content.sourceComponent: Column {
                    width: parent.width

                    DetailItem {
                        id: timeBed
                        label: qsTr("bed time")
                        value: validDate? locals.bedTime.toFixed(1) + " h" : "-"
                    }

                    DetailItem {
                        id: timeAwake
                        label: qsTr("awake")
                        value: validDate? locals.awake.toFixed(1) + " h" : "-"
                    }

                    DetailItem {
                        id: timeLight
                        label: qsTr("light")
                        value: validDate? locals.lightTime.toFixed(1) + " h" : "-"
                    }

                    DetailItem {
                        id: timeREM
                        label: qsTr("REM")
                        value: validDate? locals.remTime.toFixed(1) + " h" : "-"
                    }

                    DetailItem {
                        id: timeDeep
                        label: qsTr("deep")
                        value: validDate? locals.deepTime.toFixed(1) + " h" : "-"
                    }

                    DetailItem {
                        id: timeLatency
                        label: qsTr("latency")
                        value: validDate? locals.latencyTime.toFixed(1) + " min" : "-"
                    }

                    DetailItem {
                        id: timeMidpoint
                        label: qsTr("midpoint")
                        value: validDate? locals.midpoint : "-"
                    }

                    DetailItem {
                        id: timeRestless
                        label: qsTr("restless")
                        value: validDate? locals.restless + " %" : "-"
                    }

                    DetailItem {
                        id: timeEfficiency
                        label: qsTr("sleep time")
                        value: validDate? locals.timeEfficiency + " %" : "-"
                    }
                }
            }

            ModExpandingSection {
                id: hrAve
                title: validDate? qsTr("ave. hearth beat rate %1").arg(locals.hrAve.toFixed(1)) : "-"
                font.pixelSize: Theme.fontSizeMedium

                content.sourceComponent: Column {
                    width: parent.width

                    DetailItem {
                        id: hrMin
                        label: qsTr("min hearth beat rate")
                        value: validDate? qsTr("%1 beat/min").arg(locals.hrMin) : "-"
                    }

                    DetailItem {
                        id: hrVariation
                        label: qsTr("beat rate variation")
                        value: validDate? qsTr("%1 ms").arg(locals.hrVariation) : "-"
                    }

                    DetailItem {
                        id: breath
                        label: qsTr("average breath rate")
                        value: validDate? qsTr("%1 times/min").arg(locals.breath) : "-"
                    }

                    DetailItem {
                        id: temperature
                        label: qsTr("temperature change")
                        value: validDate? locals.dT + " °C" : "-"
                    }
                }
            }

            SectionHeader {
                text: qsTr("sleep type")
                font.pixelSize: Theme.fontSizeMedium
            }

            BarChart {
                id: sleepType
                clip: false
                height: Theme.itemSizeMedium
                width: parent.width - 2*x
                orientation: ListView.Horizontal
                maxValue: 4
                showLabel: true
                barWidth: minBarWidth > barTargetWidth ? minBarWidth : barTargetWidth
                labelWidth: barWidth
                labelFontSize: Theme.fontSizeSmall
                valueLabelOutside: true
                x: Theme.horizontalPageMargin
                highlight: Item {
                    Rectangle {
                        width: hr5min.barWidth
                        height: Theme.paddingSmall
                        color: "red"
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Theme.fontSizeSmall + Theme.paddingSmall
                    }
                }
                highlightFollowsCurrentItem: true
                onBarSelected: {
                    var5min.currentIndex = barNr
                    var5min.positionViewAtIndex(barNr, ListView.Center)
                    hr5min.currentIndex = barNr
                    hr5min.positionViewAtIndex(barNr, ListView.Center)
                }


                property int  barTargetWidth: sleepType.count > 0 ?
                                                  (width/sleepType.count).toFixed(0) : 20
                property int  minBarWidth: 3
                //property bool twoRows: width < sleepType.count*minBarWidth

                function fillData() {
                    var table = DataB.keySleep, cell = "hypnogram_5min";
                    var str = ouraCloud.value(table, cell);
                    var i, j, c, clr, lbl, dMin = 5;
                    var hour = ouraCloud.startHour(table);
                    var minute = ouraCloud.startMinute(table);

                    //"hypnogram_5min": "443432222211222333321112222222222111133333322221112233333333332232222334",
                    // '4 = '1' = deep (N3) sleep - '2' = light (N1 or N2) sleep - '3' = REM sleep - '4' = awake
                    j=str.length;
                    //console.log("5min, " + i + ", " + j + ", " + str.substring(i,j))
                    for (i=0; i<j; i++) {
                        c = str.charAt(i)*1.0;
                        if (c >= 0 && c <= 9) {
                            clr = "transparent";
                            if (c === 1) {
                                c = 4;
                                clr = Theme.highlightColor;
                            } else if (c === 2) {
                                clr = Theme.secondaryHighlightColor;
                            } else if (c === 3) {
                                clr = Theme.secondaryColor;
                            } else if (c === 4) {
                                c = 1;
                                clr = Theme.primaryColor;
                            }
                            //console.log("lisää " + c + ", " + clr + ", " + printTime(hour, minute))
                            if (i === 0 || i === j-1 || (i > 10 && i < j-10 && minute < dMin))
                                lbl = printTime(hour, minute)
                            else
                                lbl = "";
                            addData("", 5 - c, clr, lbl);
                        } else {
                            addData("", 0, "transparent", "");
                        }

                        minute += dMin;
                        if (minute >= 60){
                            minute -= 60;
                            hour++;
                            if (hour >= 24) {
                                hour -= 24;
                            }
                        }
                    }

                    return;
                }
            }

            SectionHeader {
                text: qsTr("hearth beats per minute")
                font.pixelSize: Theme.fontSizeMedium
            }

            BarChart {
                id: hr5min
                clip: false
                height: Theme.itemSizeLarge
                width: parent.width - 2*x
                orientation: ListView.Horizontal
                maxValue: 50
                showLabel: true
                barWidth: 10
                labelWidth: barWidth
                labelFontSize: Theme.fontSizeSmall
                valueLabelOutside: true
                x: Theme.horizontalPageMargin
                highlight: Item {
                    Rectangle {
                        width: hr5min.barWidth
                        height: Theme.paddingSmall
                        color: "red"
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Theme.fontSizeSmall + Theme.paddingSmall
                    }
                }
                highlightFollowsCurrentItem: true
                onBarSelected: {
                    var5min.currentIndex = barNr
                    var5min.positionViewAtIndex(barNr, ListView.Center)
                    sleepType.currentIndex = barNr
                    sleepType.positionViewAtIndex(barNr, ListView.Center)
                }

                function fillData() {
                    var table = DataB.keySleep, cell = "hr_5min";
                    var str = ouraCloud.value(table, cell), arr;
                    var c, clr, dMin = 5, lbl;
                    var hour = ouraCloud.startHour(table);
                    var minute = ouraCloud.startMinute(table);

                    //"hr_5min": [0, 53, 51, 0, 50, 50, 49, 49, 50, 50, 51, 52, 52, 51, 53, 58, 60, 60, 59, 58, 58, 58, 58, 55, 55, 55, 55, 56, 56, 55, 53, 53, 53, 53, 53, 53, 57, 58, 60, 60, 59, 57, 59, 58, 56, 56, 56, 56, 55, 55, 56, 56, 57, 58, 55, 56, 57, 60, 58, 58, 59, 57, 54, 54, 53, 52, 52, 55, 53, 54, 56, 0],
                    //console.log("5min " + i + ", " + j + str.substring(i,j))

                    if (str.indexOf("[") >= 0) {
                        str = str.substring(str.indexOf("[")+1,
                                            Math.max(str.indexOf("]"), str.length) )
                    }

                    arr = str.split(",");

                    arr.forEach(function(val, ind, ar) {
                        c = val*1.0;
                        clr = "transparent";
                        if (c >= 0) {
                            clr = Theme.secondaryHighlightColor;
                            if (c > 60 || c < 30)
                                clr = Theme.highlightColor;
                        }

                        if (minute < dMin) {
                            lbl = printTime(hour, minute);
                        } else {
                            lbl = "";
                        }
                        addData("", c, clr, lbl);

                        minute += dMin;
                        if (minute >= 60){
                            minute -= 60;
                            hour++;
                            if (hour >= 24) {
                                hour -= 24;
                            }
                        }
                    })

                    return;
                }
            }

            SectionHeader {
                text: qsTr("hearth beat rate variation [ms]")
                font.pixelSize: Theme.fontSizeMedium
            }

            BarChart {
                id: var5min
                clip: false
                height: Theme.itemSizeLarge
                width: parent.width - 2*x
                orientation: ListView.Horizontal
                maxValue: 120
                showLabel: true
                barWidth: 10
                labelWidth: barWidth
                labelFontSize: Theme.fontSizeSmall
                x: Theme.horizontalPageMargin
                highlight: Item {
                    Rectangle {
                        width: var5min.barWidth
                        height: Theme.paddingSmall
                        color: "red"
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Theme.fontSizeSmall + Theme.paddingSmall
                    }
                }
                highlightFollowsCurrentItem: true
                onBarSelected: {
                    hr5min.currentIndex = barNr
                    hr5min.positionViewAtIndex(barNr, ListView.Center)
                    sleepType.currentIndex = barNr
                    sleepType.positionViewAtIndex(barNr, ListView.Center)
                }

                function fillData() {
                    var table = DataB.keySleep, cell = "rmssd_5min";
                    var str = ouraCloud.value(table, cell), arr;
                    var c, clr, lbl, dMin=5;
                    var hour = ouraCloud.startHour(table);
                    var minute = ouraCloud.startMinute(table);

                    //"rmssd_5min": [0, 0, 62, 0, 75, 52, 56, 56, 64, 57, 55, 78, 77, 83, 70, 35, 21, 25, 49, 44, 48, 48, 62, 69, 66, 64, 79, 59, 67, 66, 70, 63, 53, 57, 53, 57, 38, 26, 18, 24, 30, 35, 36, 46, 53, 59, 50, 50, 53, 53, 57, 52, 41, 37, 49, 47, 48, 35, 32, 34, 52, 57, 62, 57, 70, 81, 81, 65, 69, 72, 64, 0]
                    //console.log("5min " + i + ", " + j + str.substring(i,j))
                    if (str.indexOf("[") >= 0) {
                        str = str.substring(str.indexOf("[")+1,
                                            Math.max(str.indexOf("]"), str.length) )
                    }

                    arr = str.split(",");

                    arr.forEach(function(val, ind, ar) {
                        c = val*1.0;
                        clr = "transparent";
                        if (c >= 0) {
                            clr = Theme.secondaryHighlightColor;
                            if (c > 90)
                                clr = Theme.highlightColor
                        }
                        if (minute < dMin) {
                            lbl = printTime(hour, minute);
                        } else {
                            lbl = "";
                        }

                        addData("", c, clr, lbl);
                        minute += dMin;
                        if (minute >= 60){
                            minute -= 60;
                            hour++;
                            if (hour >= 24) {
                                hour -= 24;
                            }
                        }
                    })

                    return;
                }
            }

            Item {
                width: 1
                height: Theme.paddingSmall
                visible: !jsonString.visible
                opacity: 0
            }

            TextArea {
                id: jsonString
                width: parent.width
                readOnly: true
                visible: false
            }

        } // column
    }

    Timer {
        running: true
        repeat: false
        interval: 1*1000
        onTriggered: {
            updateValues();
        }
    }

    function printTime(hour, minute, dh, dmin){
        var str = "";
        if (dh === undefined)
            dh = 0;
        if (dmin === undefined)
            dmin = 0;
        minute += dmin;
        while (minute > 59) {
            minute -= 60;
            hour += 1;
        }
        hour += dh;
        while (hour > 23)
            hour -= 24;
        if (hour < 10)
            str += "0";
        str += hour + ":";
        if (minute < 10)
            str += "0";
        str += minute;
        if (minute < 0 || hour < 0)
            str = "--:--"
        return str;
    }

    function previousDay(dayStep) {
        //var tmpDate = new Date(summaryDate.getFullYear(), summaryDate.getMonth(), summaryDate.getDate(), 7, 48, 52, 74);
        //var ms = summaryDate.getTime();
        if (dayStep === undefined)
            dayStep = -1;
        //ms += dayStep*24*60*60*1000;
        //summaryDate = new Date(ms);
        //tmpDate.setTime(ms);
        //summaryDate = tmpDate;
        summaryDate = ouraCloud.dateChange(dayStep);
        //console.log("on " + summaryDate.toDateString() + " p.o. " + tmpDate.toDateString() + " -1");
        txtDate.value = summaryDate.toDateString(Qt.locale(), Locale.ShortFormat);
        return;
    }

    function updateValues() {
        DataB.log("sleep update 1: " + new Date().toTimeString().substring(0,8) )
        //startTime.value = printTime(ouraCloud.startHour(DataB.keySleep), ouraCloud.startMinute(DataB.keySleep))
        validDate = ouraCloud.dateAvailable(DataB.keySleep, summaryDate);
        sleepType.chartData.clear();
        hr5min.chartData.clear();
        var5min.chartData.clear();
        if (validDate) {
            //startTime.text = printTime(ouraCloud.startHour(DataB.keySleep), ouraCloud.startMinute(DataB.keySleep));
            //endTime.text = printTime(ouraCloud.endHour(DataB.keySleep), ouraCloud.endMinute(DataB.keySleep));
            scoreSleep.value = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "score"), 0);
            locals.timeScore = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "score_total"), 0);
            locals.disturbances = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "score_disturbances"), 0);
            locals.efficiency = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "score_efficiency"), 0);
            locals.latencyScore = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "score_latency"), 0);
            locals.remScore = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "score_rem"), 0);
            locals.deepScore = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "score_deep"), 0);
            locals.alignment = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "score_alignment"), 0);
            timeTotal.value = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "total"), 0)/3600;
            locals.bedTime = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "duration"), 0)/3600;
            locals.awake = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "awake"), 0)/3600;
            locals.lightTime = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "light"), 0)/3600;
            locals.remTime = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "rem"), 0)/3600;
            locals.deepTime = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "deep"), 0)/3600;
            locals.latencyTime = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "onset_latency"), 0)/60;
            //console.log(ouraCloud.value(DataB.keySleep, "midpoint_time") + " keskipiste <<<<<<<<<<<")
            locals.midpoint = printTime(ouraCloud.startHour(DataB.keySleep), ouraCloud.startMinute(DataB.keySleep),
                                           0, ouraCloud.value(DataB.keySleep, "midpoint_time")/60);
            locals.restless = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "restless"), 0);
            locals.timeEfficiency = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "efficiency"), 0);
            locals.hrMin = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "hr_lowest"), 0);
            locals.hrAve = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "hr_average"), 0);
            locals.hrVariation = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "rmssd"), 0);
            locals.breath = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "breath_average"), 0);
            locals.dT = Scripts.ouraToNumber(ouraCloud.value(DataB.keySleep, "temperature_delta"), 0);
            DataB.log("sleep update 2: " + new Date().toTimeString().substring(0,8) )
            sleepType.fillData();
            DataB.log("sleep update 3: " + new Date().toTimeString().substring(0,8) )
            hr5min.fillData();
            DataB.log("sleep update 4: " + new Date().toTimeString().substring(0,8) )
            var5min.fillData();
            DataB.log("sleep update 5: " + new Date().toTimeString().substring(0,8) )
        } else {
            //startTime.text = "--:--";
            //endTime.text = "--:--";
            //timeRestless.value = "-";
            //timeEfficiency.value = "-";
            //hrMin.value = "-";
            //hrAve.value = "-";
            //hrVariation.value = "-";
            //breath.value = "-";
            //temperature.value = "-";
        }
        return;
    }

}
