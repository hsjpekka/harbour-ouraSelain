import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/datab.js" as DataB
import "../components/"

Page {
    id: page

    property date summaryDate: new Date()
    property bool validDate: true

    onStatusChanged: {
        if (page.status === PageStatus.Active) {
            DataB.log("sleepPage \n\n ")
        }
    }

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

    /*
    Component {
        id: scoresList

        property alias sleepTime: scoreTime.value
        property alias disturbances: scoreDisturbances.value
        property alias efficiency: scoreEfficiency.value
        property alias latency: scoreLatency.value
        property alias rem: scoreREM.value
        property alias deep: scoreDeep.value
        property alias alignment: scoreAlignment.value


        Column {
            id: scoreColumn
            width: parent.width
            DetailItem {
                id: scoreTime
                label: qsTr("sleep time")
            }

            DetailItem {
                id: scoreDisturbances
                label: qsTr("disturbances")
            }

            DetailItem {
                id: scoreEfficiency
                label: qsTr("efficiency")
            }

            DetailItem {
                id: scoreLatency
                label: qsTr("latency")
            }

            DetailItem {
                id: scoreREM
                label: qsTr("REM")
            }

            DetailItem {
                id: scoreDeep
                label: qsTr("deep sleep")
            }

            DetailItem {
                id: scoreAlignment
                label: qsTr("alignment")
            }
        }
    } //*/

    /*
    Component {
        id: timesList

        property alias bedTime: timeBed.value
        property alias awake:   timeAwake.value
        property alias light:   timeLight.value
        property alias rem:     timeREM.value
        property alias deep:    timeDeep.value
        property alias latency: timeLatency.value
        property alias midpoint: timeMidpoint.value

        Column {
            width: parent.width

            DetailItem {
                id: timeBed
                label: qsTr("bed time")
            }

            DetailItem {
                id: timeAwake
                label: qsTr("awake")
            }

            DetailItem {
                id: timeLight
                label: qsTr("light")
            }

            DetailItem {
                id: timeREM
                label: qsTr("REM")
            }

            DetailItem {
                id: timeDeep
                label: qsTr("deep")
            }

            DetailItem {
                id: timeLatency
                label: qsTr("latency")
            }

            DetailItem {
                id: timeMidpoint
                label: qsTr("to midpoint")
            }
        }
    } //*/

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("json")
                onClicked: {
                    jsonString.visible = !jsonString.visible
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
                        oura.setDateConsidered(summaryDate)
                        updateValues()
                    } )
                }
            }

            /*
            Row {
                spacing: Theme.paddingMedium
                anchors.horizontalCenter: parent.horizontalCenter

                Label {
                    color: Theme.highlightColor
                    text: qsTr("deep")
                }

                Label {
                    color: Theme.secondaryHighlightColor
                    text: qsTr("light")
                }

                Label {
                    color: Theme.secondaryColor
                    text: qsTr("rem")
                }

                Label {
                    color: Theme.primaryColor
                    text: qsTr("awake")
                }
            } // */
            //*
            SectionHeader {
                text: qsTr("sleep type")
                font.pixelSize: Theme.fontSizeMedium
            }
            //*/
            /*
            Item {
                height: twoRows? sleepType.height + startTime.height : sleepType.height
                width: parent.width


                Label {
                    id: startTime
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        leftMargin: Theme.horizontalPageMargin
                        rightMargin: Theme.paddingMedium
                    }
                    color: Theme.secondaryHighlightColor
                }

                //*/
                BarChart {
                    id: sleepType
                    //anchors {
                    //    horizontalCenter: parent.horizontalCenter
                    //    top: parent.top
                    //}
                    clip: false
                    height: Theme.itemSizeMedium
                    //width: parent.twoRows? parent.width : parent.availableWidth
                    width: parent.width - 2*x
                    orientation: ListView.Horizontal
                    maxValue: 4
                    showLabel: true
                    barWidth: minBarWidth > barTargetWidth ?
                                  minBarWidth : barTargetWidth
                    labelWidth: barWidth
                    labelFontSize: Theme.fontSizeSmall
                    x: Theme.horizontalPageMargin
                    highlight: Item {
                        Rectangle {
                            width: hr5min.barWidth
                            height: Theme.paddingSmall
                            color: "red"
                            anchors.top: parent.bottom
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
                        var str = oura.value(table, cell);
                        var i, j, c, clr, lbl, dMin = 5;
                        var hour = oura.startHour(table);
                        var minute = oura.startMinute(table);

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
                                addData(5 - c, clr, lbl);
                            } else {
                                addData(0, "transparent", "");
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

                /*
                Label {
                    id: endTime
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                        leftMargin: Theme.paddingMedium
                        rightMargin: Theme.horizontalPageMargin
                    }
                    color: Theme.secondaryHighlightColor
                }

            }// */

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
                }
            }


            /*
            DetailItem {
                id: startTime
                label: qsTr("start")
            }
            */

            //SectionHeader {
            //    text: qsTr("scores")
            //}

            //DetailItem {
            //    id: scoreSleep
            //    label: qsTr("score")
            //}

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

            /*
            SectionHeader {
                text: qsTr("durations")
            }

            DetailItem {
                id: timeTotal
                label: qsTr("total sleep time")
            }
            //*/

            SectionHeader {
                text: qsTr("relative amounts")
                font.pixelSize: Theme.fontSizeMedium
            }

            DetailItem {
                id: timeRestless
                label: qsTr("restless")
            }

            DetailItem {
                id: timeEfficiency
                label: qsTr("sleep time")
            }

            /*
            SectionHeader {
                text: qsTr("body")
                font.pixelSize: Theme.fontSizeMedium
            }
            // */

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
                x: Theme.horizontalPageMargin
                highlight: Item {
                    Rectangle {
                        width: hr5min.barWidth
                        height: Theme.paddingSmall
                        color: "red"
                        anchors.top: parent.bottom
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
                    var str = oura.value(table, cell), arr;
                    var c, clr, dMin = 5, lbl;
                    var hour = oura.startHour(table);
                    var minute = oura.startMinute(table);

                    //"hr_5min": [0, 53, 51, 0, 50, 50, 49, 49, 50, 50, 51, 52, 52, 51, 53, 58, 60, 60, 59, 58, 58, 58, 58, 55, 55, 55, 55, 56, 56, 55, 53, 53, 53, 53, 53, 53, 57, 58, 60, 60, 59, 57, 59, 58, 56, 56, 56, 56, 55, 55, 56, 56, 57, 58, 55, 56, 57, 60, 58, 58, 59, 57, 54, 54, 53, 52, 52, 55, 53, 54, 56, 0],
                    //console.log("5min " + i + ", " + j + str.substring(i,j))

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
                        addData(c, clr, lbl);

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

                    /*
                    DetailItem {
                        id: hrAve
                        label: qsTr("average rate")
                        value: validDate? qsTr("%1 beat/min").arg(locals.hrAve.toFixed(1)) : "-"
                    }
                    // */

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
                        anchors.top: parent.bottom
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
                    var str = oura.value(table, cell), arr;
                    var c, clr, lbl, dMin=5;
                    var hour = oura.startHour(table);
                    var minute = oura.startMinute(table);

                    //"rmssd_5min": [0, 0, 62, 0, 75, 52, 56, 56, 64, 57, 55, 78, 77, 83, 70, 35, 21, 25, 49, 44, 48, 48, 62, 69, 66, 64, 79, 59, 67, 66, 70, 63, 53, 57, 53, 57, 38, 26, 18, 24, 30, 35, 36, 46, 53, 59, 50, 50, 53, 53, 57, 52, 41, 37, 49, 47, 48, 35, 32, 34, 52, 57, 62, 57, 70, 81, 81, 65, 69, 72, 64, 0]
                    //console.log("5min " + i + ", " + j + str.substring(i,j))

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

                        addData(c, clr, lbl);
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
            /*
                "bedtime_start": "2017-11-06T02:13:19+02:00",
                "bedtime_end": "2017-11-06T08:12:19+02:00",
                "score": 70,
                "score_total": 57,
                "score_disturbances": 83,
                "score_efficiency": 99,
                "score_latency": 88,
                "score_rem": 97,
                "score_deep": 59,
                "score_alignment": 31,
                "total": 20310,
                "duration": 21540,
                "awake": 1230,
                "light": 10260,
                "rem": 7140,
                "deep": 2910,
                "onset_latency": 480,
                "restless": 39,
                "efficiency": 94,
                "midpoint_time": 11010,
                "hr_lowest": 49,
                "hr_average": 56.375,
                "rmssd": 54
                "breath_average": 13,
                "temperature_delta": -0.06,
                "hypnogram_5min": "443432222211222333321112222222222111133333322221112233333333332232222334",
                "hr_5min": [0, 53, 51, 0, 50, 50, 49, 49, 50, 50, 51, 52, 52, 51, 53, 58, 60, 60, 59, 58, 58, 58, 58, 55, 55, 55, 55, 56, 56, 55, 53, 53, 53, 53, 53, 53, 57, 58, 60, 60, 59, 57, 59, 58, 56, 56, 56, 56, 55, 55, 56, 56, 57, 58, 55, 56, 57, 60, 58, 58, 59, 57, 54, 54, 53, 52, 52, 55, 53, 54, 56, 0],
                "rmssd_5min": [0, 0, 62, 0, 75, 52, 56, 56, 64, 57, 55, 78, 77, 83, 70, 35, 21, 25, 49, 44, 48, 48, 62, 69, 66, 64, 79, 59, 67, 66, 70, 63, 53, 57, 53, 57, 38, 26, 18, 24, 30, 35, 36, 46, 53, 59, 50, 50, 53, 53, 57, 52, 41, 37, 49, 47, 48, 35, 32, 34, 52, 57, 62, 57, 70, 81, 81, 65, 69, 72, 64, 0]
            */

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
        summaryDate = oura.dateChange(dayStep);
        //console.log("on " + summaryDate.toDateString() + " p.o. " + tmpDate.toDateString() + " -1");
        txtDate.value = summaryDate.toDateString(Qt.locale(), Locale.ShortFormat);
        return;
    }

    function updateValues() {
        //startTime.value = printTime(oura.startHour(DataB.keySleep), oura.startMinute(DataB.keySleep))
        validDate = oura.dateAvailable(DataB.keySleep, summaryDate);
        sleepType.chartData.clear();
        hr5min.chartData.clear();
        var5min.chartData.clear();
        if (validDate) {
            //startTime.text = printTime(oura.startHour(DataB.keySleep), oura.startMinute(DataB.keySleep));
            //endTime.text = printTime(oura.endHour(DataB.keySleep), oura.endMinute(DataB.keySleep));
            scoreSleep.value = oura.value(DataB.keySleep, "score");
            locals.timeScore = oura.value(DataB.keySleep, "score_total");
            locals.disturbances = oura.value(DataB.keySleep, "score_disturbances");
            locals.efficiency = oura.value(DataB.keySleep, "score_efficiency");
            locals.latencyScore = oura.value(DataB.keySleep, "score_latency");
            locals.remScore = oura.value(DataB.keySleep, "score_rem");
            locals.deepScore = oura.value(DataB.keySleep, "score_deep");
            locals.alignment = oura.value(DataB.keySleep, "score_alignment");
            timeTotal.value = oura.value(DataB.keySleep, "total")/3600;
            locals.bedTime = oura.value(DataB.keySleep, "duration")/3600;
            locals.awake = oura.value(DataB.keySleep, "awake")/3600;
            locals.lightTime = oura.value(DataB.keySleep, "light")/3600;
            locals.remTime = oura.value(DataB.keySleep, "rem")/3600;
            locals.deepTime = oura.value(DataB.keySleep, "deep")/3600;
            locals.latencyTime = oura.value(DataB.keySleep, "onset_latency")/60;
            //console.log(oura.value(DataB.keySleep, "midpoint_time") + " keskipiste <<<<<<<<<<<")
            locals.midpoint = printTime(oura.startHour(DataB.keySleep), oura.startMinute(DataB.keySleep),
                                           0, oura.value(DataB.keySleep, "midpoint_time")/60);
            timeRestless.value = oura.value(DataB.keySleep, "restless") + " %";
            timeEfficiency.value = oura.value(DataB.keySleep, "efficiency") + " %";
            locals.hrMin = oura.value(DataB.keySleep, "hr_lowest");
            locals.hrAve = oura.value(DataB.keySleep, "hr_average");
            locals.hrVariation = oura.value(DataB.keySleep, "rmssd");
            locals.breath = oura.value(DataB.keySleep, "breath_average")
            locals.dT = oura.value(DataB.keySleep, "temperature_delta");
            sleepType.fillData();
            hr5min.fillData();
            var5min.fillData();
        } else {
            //startTime.text = "--:--";
            //endTime.text = "--:--";
            timeRestless.value = "-";
            timeEfficiency.value = "-";
            //hrMin.value = "-";
            //hrAve.value = "-";
            //hrVariation.value = "-";
            //breath.value = "-";
            //temperature.value = "-";
            sleepType.chartData.clear();
            hr5min.chartData.clear();
            var5min.chartData.clear();
        }
        return;
    }

    Component.onCompleted: {
        updateValues();
        jsonString.text = oura.printSleep();
    }
}
