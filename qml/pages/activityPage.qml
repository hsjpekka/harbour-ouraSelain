import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/datab.js" as DataB
import "../components/"

Page {
    id: page

    property date summaryDate: new Date()
    property bool validDate: false

    onStatusChanged: {
        if (page.status === PageStatus.Active) {
            DataB.log("activityPage\n\n ")
        }
    }

    QtObject {
        id: locals
        /* scores */
        property int score
        property int stayActive
        property int moveHourly
        property int meetTargets
        property int trainingFreq
        property int trainingVol
        property int recovery
        /* minutes */
        property string nonWear
        property string rest
        property string timeInactive
        property string timeLow
        property string timeMedium
        property string timeHigh
        property string timeActive
        /* misc */
        property real movement
        property int steps
        property int alerts
        property int totalCalories
        property int activeCalories
        property string metInactive
        property string metLow
        property string metMedium
        property string metMediumPlus
        property string metHigh
        property real averageMet
    }

    Connections {
        target: applicationWindow
        onOuraActivityReady: {
            updateValues()
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: "json"
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
                title: qsTr("Activity")
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

            SectionHeader {
                text: qsTr("met levels per 5 min")
                font.pixelSize: Theme.fontSizeMedium
            }

            BarChart {
                id: met5min
                clip: false
                height: Theme.itemSizeExtraLarge
                width: parent.width - 2*x
                orientation: ListView.Horizontal
                maxValue: 5
                showLabel: true
                barWidth: 8
                labelWidth: barWidth
                labelFontSize: Theme.fontSizeSmall
                x: Theme.horizontalPageMargin
                onBarSelected: {
                    met1min.currentIndex = barNr*5
                    met1min.positionViewAtIndex(barNr*5, ListView.Center)
                    console.log("5min " + currentIndex + " " + barNr + ", 1min " + met1min.currentIndex)
                }

                //*
                highlight: Item {
                    Rectangle {
                        width: met5min.barWidth < Theme.paddingSmall ? Theme.paddingSmall : met5min.barWidth
                        height: Theme.paddingSmall
                        color: "red"
                        anchors.top: parent.bottom
                    }
                }

                highlightFollowsCurrentItem: true
                // */

                function fillData() {
                    var table = DataB.keyActivity, cell = "class_5min";
                    var str = oura.value(table, cell);
                    var i, j, c, clr;
                    var hour = oura.startHour(table);
                    var minute = oura.startMinute(table);

                    //console.log("5min " + i + ", " + j + ", " + str.substring(i,j))

                    for (i=0, j=str.length; i<j; i++) {
                        c = str.charAt(i)*1.0;
                        if (c >= 0 && c <= 9) {
                            if (c > 4)
                                clr = Theme.highlightColor
                            else if (c > 2)
                                clr = Theme.secondaryHighlightColor
                            else
                                clr = Theme.highlightDimmerColor
                            if (minute === 0 && hour%2 === 0)
                                addData(c, clr, printTime(hour, minute))
                            else
                                addData(c, clr, "");
                        }
                        minute += 5;
                        if (minute >= 60){
                            minute -= 60;
                            hour++;
                            if (hour >= 24) {
                                hour -= 24;
                            }
                        }
                    }

                    currentIndex = 4*12; // 8:00 = 4:00 + 4*12*5 min
                    positionViewAtIndex(currentIndex, ListView.Beginning)
                    return;
                }

                // 0: Non-wear
                // 1: Rest (MET level below 1.05)
                // 2: Inactive (MET level between 1.05 and 2)
                // 3: Low intensity activity (MET level between 2 and age/gender dependent limit)
                // 4: Medium intensity activity
                // 5: High intensity activity

            }

            SectionHeader {
                text: qsTr("met levels per 1 min")
                font.pixelSize: Theme.fontSizeMedium
            }

            BarChart {
                id: met1min
                clip: false
                height: Theme.itemSizeExtraLarge
                width: parent.width - 2*x
                orientation: ListView.Horizontal
                maxValue: 12
                showLabel: true
                barWidth: 3
                labelWidth: barWidth
                labelFontSize: Theme.fontSizeSmall
                x: Theme.horizontalPageMargin
                onBarSelected: {
                    met5min.currentIndex = (barNr - barNr%5)/5
                    met5min.positionViewAtIndex((barNr - barNr%5)/5, ListView.Center)
                    console.log("1min " + currentIndex + ", 5min " + met5min.currentIndex)
                }

                //*
                highlight: Item {
                    Rectangle {
                        width: met1min.barWidth < Theme.paddingSmall ? Theme.paddingSmall : met1min.barWidth
                        height: Theme.paddingSmall
                        color: "red"
                        anchors.top: parent.bottom
                    }
                }

                highlightFollowsCurrentItem: true
                // */

                function fillData() {
                    var table = DataB.keyActivity, cell = "met_1min";
                    var str = oura.value(table, cell), arr;
                    var i = str.indexOf("[") + 1, j = str.indexOf("]"), c, clr;
                    var hour = oura.startHour(table);
                    var minute = oura.startMinute(table);
                    //var time = oura.value(table, "day_start", summaryDate), date0, h0, m0, t0;
                    str = str.substring(i, j).trim();
                    //DataB.log(cell + " " + str);

                    arr = str.split(",");
                    arr.forEach(function(val, ind, ar) {
                        c = val*1.0;
                        if (c >= 0 && c <= 100) {
                            if (c > 4.0)
                                clr = Theme.highlightColor
                            else if (c > 2.4)
                                clr = Theme.secondaryHighlightColor
                            else
                                clr = Theme.highlightDimmerColor
                            if (minute === 0)
                                addData(c, clr, printTime(hour, minute))
                            else
                                addData(c, clr, "");
                        }
                        minute += 1;
                        if (minute >= 60){
                            minute -= 60;
                            hour++;
                            if (hour >= 24) {
                                hour -= 24;
                            }
                        }
                    })

                    currentIndex = 4*60; // 8:00 = 4:00 + 4*60*1 min
                    positionViewAtIndex(currentIndex, ListView.Beginning)
                    return;
                }

            }

            /*SectionHeader {
            //    text: qsTr("Scores")
            //}
            DetailItem {
                id: valueScore
                label: qsTr("sum")
                value: locals.score
            }


            //*/

            ModExpandingSection {
                id: score
                title: validDate? qsTr("score %1").arg(locals.score.toFixed(0)) : "-"
                font.pixelSize: Theme.fontSizeMedium

                content.sourceComponent: Column {
                    width: parent.width

                    DetailItem {
                        id: valueActive
                        label: qsTr("being active")
                        value: validDate? locals.stayActive : "-"
                    }

                    DetailItem {
                        id: valueMove
                        label: qsTr("moving about")
                        value: validDate? locals.moveHourly : "-"
                    }

                    DetailItem {
                        id: valueTargets
                        label: qsTr("meeting targets")
                        value: validDate? locals.meetTargets : "-"
                    }

                    DetailItem {
                        id: valueTrainingFreq
                        label: qsTr("training frequency")
                        value: validDate? locals.trainingFreq : "-"
                    }

                    DetailItem {
                        id: valueTrainingVol
                        label: qsTr("training volume")
                        value: validDate? locals.trainingVol : "-"
                    }

                    DetailItem {
                        id: valueRecovery
                        label: qsTr("recovery time")
                        value: validDate? locals.recovery : "-"
                    }
                }
            }

            /*
            SectionHeader {
                text: qsTr("durations")
            }
            // */
            ModExpandingSection {
                id: durations
                title: validDate? qsTr("active %1").arg(locals.timeActive) : "-"
                font.pixelSize: Theme.fontSizeMedium

                content.sourceComponent: Column {
                    width: parent.width

                    DetailItem {
                        id: timeNonWear
                        label: qsTr("ring not worn")
                        value: validDate? locals.nonWear : "-"
                    }

                    DetailItem {
                        id: timeRest
                        label: qsTr("resting")
                        value: validDate? locals.rest : "-"
                    }

                    DetailItem {
                        id: timeInactive
                        label: qsTr("inactive")
                        value: validDate? locals.timeInactive : "-"
                    }

                    DetailItem {
                        id: timeLow
                        label: qsTr("low activity")
                        value: validDate? locals.timeLow : "-"
                    }

                    DetailItem {
                        id: timeMedium
                        label: qsTr("medium activity")
                        value: validDate? locals.timeMedium : "-"
                    }

                    DetailItem {
                        id: timeHigh
                        label: qsTr("high activity")
                        value: validDate? locals.timeHigh : "-"
                    }
                }
            }

            /*
            SectionHeader {
                text: qsTr("counts")
            }

            DetailItem {
                id: sumActiveCal
                label: qsTr("active calories")
                value: validDate? locals.activeCalories : "-"
            }
            // */

            ModExpandingSection {
                title: validDate? qsTr("active calories %1").arg(locals.activeCalories) : "-"
                font.pixelSize: Theme.fontSizeMedium

                content.sourceComponent: Column {
                    width: parent.width

                    DetailItem {
                        id: sumMovement
                        label: qsTr("daily movement")
                        value: validDate? (locals.movement/1000).toFixed(1) + " km" : "-"
                    }

                    DetailItem {
                        id: sumSteps
                        label: qsTr("steps")
                        value: validDate? locals.steps : "-"
                    }

                    DetailItem {
                        id: sumAlerts
                        label: qsTr("inactivity alerts")
                        value: validDate? locals.alerts : "-"
                    }

                    DetailItem {
                        id: sumCalories
                        label: qsTr("total calories")
                        value: validDate? locals.totalCalories : "-"
                    }
                }
            }

            /*
            SectionHeader {
                text: qsTr("metabolic activity [min]")
            }
            //*/

            ModExpandingSection {
                title: validDate? qsTr("ave. metabolic activity %1").arg(locals.averageMet.toFixed(1)) : "-"
                font.pixelSize: Theme.fontSizeMedium

                content.sourceComponent: Column {
                    width: parent.width

                    DetailItem {
                        id: metInactive
                        label: qsTr("inactive")
                        value: validDate? locals.metInactive + " min" : "-"
                    }

                    DetailItem {
                        id: metLow
                        label: qsTr("low")
                        value: validDate? locals.metLow + " min" : "-"
                    }

                    DetailItem {
                        id: metMedium
                        label: qsTr("medium")
                        value: validDate? locals.metMedium + " min" : "-"
                    }

                    DetailItem {
                        id: metMediumPlus
                        label: qsTr("medium plus")
                        value: validDate? locals.metMediumPlus + " min" : "-"
                    }

                    DetailItem {
                        id: metHigh
                        label: qsTr("high")
                        value: validDate? locals.metHigh + " min" : "-"
                    }

                    /*
                    DetailItem {
                        id: metLevel
                        label: qsTr("average level")
                        value: validDate? locals.averageMet: "-"
                    } //*/
                }
            }

            TextArea {
                id: jsonString
                width: parent.width
                readOnly: true
                visible: false
            }

        }
    }

    function printTime(hour, minute){
        var str = "";
        if (hour < 10)
            str += "0";
        str += hour + ":";
        if (minute < 10)
            str += "0";
        str += minute;
        return str;
    }

    function previousDay(dayStep) {
        if (dayStep === undefined)
            dayStep = -1;
        summaryDate = oura.dateChange(dayStep);
        //console.log("on " + summaryDate.toDateString() + " p.o. " + tmpDate.toDateString() + " -1");
        txtDate.value = summaryDate.toDateString(Qt.locale(), Locale.ShortFormat);
        return;
    }

    /*
        "summary_date": "2016-09-03",
        "day_start": "2016-09-03T04:00:00+03:00",
        "day_end": "2016-09-04T03:59:59+03:00",
        "timezone": 180,
        "score": 87,
        "score_stay_active": 90,
        "score_move_every_hour": 100,
        "score_meet_daily_targets": 60,
        "score_training_frequency": 96,
        "score_training_volume": 95,
        "score_recovery_time": 100,
        "daily_movement": 7806,
        "non_wear": 313,
        "rest": 426,
        "inactive": 429,
        "inactivity_alerts": 0,
        "low": 224,
        "medium": 49,
        "high": 0,
        "steps": 9206,
        "cal_total": 2540,
        "cal_active": 416,
        "met_min_inactive": 9,
        "met_min_low": 167,
        "met_min_medium_plus": 159,
        "met_min_medium": 159,
        "met_min_high": 0,
        "average_met": 1.4375,
        "class_5min":"1112211111111111111111111111111111111111111111233322322223333323322222220000000000000000000000000000000000000000000000000000000233334444332222222222222322333444432222222221230003233332232222333332333333330002222222233233233222212222222223121121111222111111122212321223211111111111111111",
        "met_1min": [ 1.2,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,1.2,0.9,1.1,1.2,1.1,1.1,0.9,0.9,0.9,1.1,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,1.2,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.3,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.3,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.2,0.9,0.9,0.9,1.1,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.9,2.7,2.8,1.6,1.8,1.5,1.5,1.8,1.6,1.9,1.4,1.9,1.4,1.5,1.7,1.7,1.4,1.5,1.5,1.7,1.3,1.7,1.7,1.9,1.5,1.4,1.8,2.2,1.4,1.6,1.7,1.7,1.4,1.5,1.6,1.4,1.4,1.7,1.6,1.3,1.3,1.4,1.3,2.6,1.6,1.7,1.5,1.6,1.6,1.8,1.9,1.8,1.7,2,1.8,2,1.7,1.5,1.3,2.4,1.4,1.6,2,2.8,1.8,1.5,1.8,1.6,1.5,1.8,1.8,1.4,1.6,1.7,1.7,1.6,1.5,1.5,1.8,1.8,1.7,1.8,1.8,1.5,2.4,1.9,1.3,1.2,1.4,1.3,1.5,1.2,1.4,1.4,1.6,1.5,1.6,1.4,1.4,1.6,1.6,1.6,1.8,1.7,1.3,1.9,1.3,1.2,1.2,1.3,1.5,1.4,1.4,1.3,1.7,1.2,1.3,1.5,1.7,1.5,2.6,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.9,3.6,0.9,0.1,0.1,0.1,0.1,0.1,3.3,3.8,3.6,2.3,3.1,3.2,3.5,4.3,3.6,1.7,1.6,2.8,2.1,3.3,4.9,3.3,1.8,5,4.6,5.3,4.9,4.9,5.4,5.4,5.2,5.3,4.5,5.3,4.5,4.4,5,5.3,4.8,4.6,1.8,4.4,3.6,3.5,2.9,2.6,3.1,0.9,0.1,2.9,3.8,1.7,2.8,1.8,1.5,1.4,1.4,1.3,1.4,1.3,1.4,1.3,1.3,1.2,1.3,1.6,1.5,1.5,1.4,1.8,1.3,1.4,1.3,1.4,1.6,1.6,1.4,1.3,1.4,1.4,1.6,1.5,1.4,2,1.5,1.4,1.4,1.3,1.2,1.3,1.3,1.6,1.6,1.5,1.5,1.8,1.5,1.2,1.2,1.5,1.6,1.5,1.7,1.7,1.5,1.6,2.5,1.5,1.3,1.2,1.4,1.6,1.3,1.6,1.7,2,1.2,1.3,1.9,3.3,2.8,1.7,1.4,1.4,1.4,1.5,1.4,1.5,1.3,2,1.4,1.2,1.5,1.2,1.2,1.8,2.4,3,4.6,4,3.6,2.2,0.9,4,3.3,2.6,4.4,2.3,4.5,5.2,5.2,5,5.3,5,4.6,5.4,5.7,5.5,5.2,5.5,3.8,5,5,4.4,4.8,5.5,4.1,4.5,3.2,3.3,2.6,4,3.4,2.1,1.5,1.5,1.4,1.4,1.5,1.3,1.3,1.5,1.4,1.2,1.2,1.4,1.2,1.2,1.2,1.2,1.1,1.3,1.6,1.8,1.5,1.3,1.5,1.5,1.6,1.5,1.6,1.4,1.4,1.4,1.3,1.3,1.3,1.3,1.2,1.3,1.2,1.2,1.2,0.9,1.1,1.1,1.1,1.1,1.7,1.1,0.9,0.9,0.9,1.1,1.1,0.9,1.1,0.9,1.2,1.3,2.4,2.2,1.6,0.9,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,2.4,2.7,1.3,1.4,1.3,1.2,1.3,1.2,1.4,1.4,2.2,1.7,2.9,1.3,1.4,1.2,1.3,1.8,2.1,2.2,2.5,1.9,2.3,2.7,2.3,2,1.7,2,2.1,1.7,1.8,1.2,1.2,0.9,0.9,1.3,1.4,1.2,1.6,1.7,2.4,2.4,2,1.2,1.3,1.3,1.2,1.3,2.4,1.2,1.2,1.3,2,1.3,1.8,1.2,1.2,1.2,1.2,1.8,1.7,1.3,1.3,1.6,1.8,2.2,1.3,1.5,1.5,1.8,1.3,1.7,1.8,2.1,2,1.9,1.6,2,1.8,2,1.6,1.2,1.7,1.5,1.5,2.3,2.6,3.3,3.3,1.5,1.2,1.3,1.5,1.3,1.5,1.5,3.7,2.4,3.3,3,3.7,4.5,2.8,1.3,1.9,2.2,1.6,1.3,1.2,1.3,1.3,2.9,3.3,2,2.2,2.6,2.7,4.5,3.2,4.5,3.3,2.1,3.4,3,2.7,3.3,2.1,2.3,1.7,1.7,2.8,0.9,2.2,0.9,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,1.4,1.6,1.2,1.2,1.3,1.7,1.3,1.5,1.3,1.3,1.3,1.3,1.5,2.9,1.5,1.2,1.4,1.2,1.3,1.3,1.4,1.3,1.4,1.4,1.2,1.2,1.3,1.2,1.2,1.2,1.2,1.4,1.4,1.3,1.2,1.2,1.2,1.9,1.4,1.3,1.4,1.3,1.7,1.3,2.1,2.9,1.9,1.8,1.6,1.4,1.4,1.7,1.2,1.5,1.6,1.9,1.5,1.8,1.3,1.2,1.8,2.3,2,2.2,1.7,1.5,1.2,1.2,1.2,1.1,1.1,1.4,3.3,2,1.5,2.4,2.4,1.6,2.6,2.5,2.3,1.5,1.2,1.2,1.2,1.3,1.2,1.2,1.3,2,1.5,1.7,1.2,1.3,1.6,1.5,1.4,1.4,1.4,1.2,1.2,1.1,1.1,0.9,0.9,1.3,0.9,0.9,0.9,0.9,0.9,1.3,1.1,1.1,1.3,0.9,0.9,1.3,0.9,1.5,2.1,2.1,1.2,1.2,1.3,1.2,1.2,1.5,1.4,1.3,1.2,1.2,1.3,1.3,1.2,1.3,1.2,1.2,1.2,1.2,1.2,1.4,1.2,1.5,1.5,1.4,1.4,1.5,1.5,1.3,1.2,1.2,0.9,2.3,1.8,1.3,1.2,1.2,1.1,0.9,0.9,0.9,1.2,1.6,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,1.9,1.2,1.3,1.1,1.3,1.1,0.9,0.9,0.9,1.2,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,1.1,0.9,0.9,0.9,0.9,1.2,0.9,0.9,0.9,1.1,0.9,0.9,1.2,1.6,1.4,1.3,1.4,1.5,1.2,1.2,1.1,0.9,0.9,1.1,1.1,0.9,0.9,1.1,1.1,0.9,0.9,0.9,0.9,0.9,1.1,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,1.1,1.3,0.9,1.3,1.1,1.1,0.9,1.1,0.9,1.1,0.9,1.3,1.2,0.9,1.1,0.9,0.9,0.9,1.1,0.9,0.9,1.1,1.2,1.6,0.9,1.1,1.4,3.7,2.8,3.2,2.7,1.2,1.2,1.3,1.3,1.3,1.2,1.2,0.9,0.9,0.9,1.1,1.1,0.9,1.1,1.3,0.9,1.1,1.1,1.1,1.3,4.1,1.5,1.7,1.2,1.2,1.2,1.2,1.2,1.2,1.2,1.1,0.9,0.9,0.9,1.1,1.3,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,1.1,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,1.3,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9 ],
        "rest_mode_state": 0
    */
    function updateValues() {
        validDate = oura.dateAvailable(DataB.keySleep, summaryDate);
        console.log("löytyykö päivä " + summaryDate + "? " + validDate);
        met1min.chartData.clear();
        met5min.chartData.clear();
        if (validDate) {
            /* scores */
            locals.score = oura.value(DataB.keyActivity, "score")*1.0;
            locals.stayActive = oura.value(DataB.keyActivity, "score_stay_active")*1.0;
            locals.moveHourly = oura.value(DataB.keyActivity, "score_move_every_hour")*1.0;
            locals.meetTargets = oura.value(DataB.keyActivity, "score_meet_daily_targets")*1.0;
            locals.trainingFreq = oura.value(DataB.keyActivity, "score_training_frequency")*1.0;
            locals.trainingVol = oura.value(DataB.keyActivity, "score_training_volume")*1.0;
            locals.recovery = oura.value(DataB.keyActivity, "score_recovery_time")*1.0;
            /* minutes */
            locals.nonWear = hm(oura.value(DataB.keyActivity, "non_wear"));
            locals.rest = hm(oura.value(DataB.keyActivity, "rest"));
            locals.timeInactive = hm(oura.value(DataB.keyActivity, "inactive"));
            locals.timeLow = hm(oura.value(DataB.keyActivity, "low"));
            locals.timeMedium = hm(oura.value(DataB.keyActivity, "medium"));
            locals.timeHigh = hm(oura.value(DataB.keyActivity, "high"));
            locals.timeActive = hm(oura.value(DataB.keyActivity, "low")*1.0 +
                                     oura.value(DataB.keyActivity, "medium")*1.0 +
                                     oura.value(DataB.keyActivity, "high")*1.0);
            /* misc */
            locals.movement = oura.value(DataB.keyActivity, "daily_movement")/1000;
            locals.steps = oura.value(DataB.keyActivity, "steps")*1.0;
            locals.alerts = oura.value(DataB.keyActivity, "inactivity_alerts")*1.0;
            locals.totalCalories = oura.value(DataB.keyActivity, "cal_total")*1.0;
            locals.activeCalories = oura.value(DataB.keyActivity, "cal_active")*1.0;
            locals.metInactive = oura.value(DataB.keyActivity, "met_min_inactive")
            locals.metLow = oura.value(DataB.keyActivity, "met_min_low")
            locals.metMedium = oura.value(DataB.keyActivity, "met_min_medium")
            locals.metMediumPlus = oura.value(DataB.keyActivity, "met_min_medium_plus")
            locals.metHigh = oura.value(DataB.keyActivity, "met_min_high")
            locals.averageMet = oura.value(DataB.keyActivity, "average_met")
            met5min.fillData();
            met1min.fillData();
        }
    }

    function hm(min){
        var h, m;
        m = min%60;
        h = ((min-m)/60).toFixed(0);
        return h + " h " + m + " min";
    }

    Component.onCompleted: {
        summaryDate = oura.dateChange(0)
        updateValues()
        jsonString.text = oura.printActivity();
    }
}
