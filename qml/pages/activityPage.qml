import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/datab.js" as DataB
import "../components/"

Page {
    id: page

    property date summaryDate: new Date()
    property bool validDate: false
    property int  dayStart: 4*60 // minutes past 00:00 (Oura's start of day)

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
        property real maxMet1min
    }

    Connections {
        target: ouraCloud
        onFinishedActivity: {
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
                    if (jsonString.visible)
                        jsonString.text = ouraCloud.printActivity()
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
                        summaryDate = new Date(dialog.year, dialog.month-1, dialog.day, 13, 43, 43, 88)
                        value = summaryDate.toDateString(Qt.locale(), Locale.ShortFormat)
                        ouraCloud.setDateConsidered(summaryDate)
                        updateValues()
                    } )
                }
            }

            ModExpandingSection { // score
                //id: score
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
                        label: qsTr("moving every hour")
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

            ModExpandingSection { // durations
                title: validDate? qsTr("active time %1").arg(locals.timeActive) : "-"
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

            ModExpandingSection { // amounts
                title: validDate? qsTr("active calories %1").arg(locals.activeCalories) : "-"
                font.pixelSize: Theme.fontSizeMedium

                content.sourceComponent: Column {
                    width: parent.width

                    DetailItem {
                        id: sumMovement
                        label: qsTr("equivalent walking")
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

            ModExpandingSection { // met
                title: validDate? qsTr("ave. metabolic activity %1").arg(locals.averageMet.toFixed(1)) : "-"
                font.pixelSize: Theme.fontSizeMedium

                content.sourceComponent: Column {
                    width: parent.width

                    DetailItem {
                        id: metMax1min
                        label: qsTr("max. met. activity")
                        value: validDate? locals.maxMet1min.toFixed(1) : "-"
                    }

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
                showLabel: met5min.showLabelAlways
                barWidth: 8
                labelWidth: barWidth
                labelFontSize: Theme.fontSizeSmall
                valueLabelOutside: true
                x: Theme.horizontalPageMargin
                onBarSelected: {
                    met1min.currentIndex = barNr*5
                    met1min.positionViewAtIndex(barNr*5, ListView.Center)
                }

                highlight: Item {
                    Rectangle {
                        width: met5min.barWidth < Theme.paddingSmall ? Theme.paddingSmall : met5min.barWidth
                        height: Theme.paddingSmall
                        color: "red"
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Theme.fontSizeMedium
                    }
                }

                highlightFollowsCurrentItem: true

                property int centerAt: (16*60 - dayStart)/5

                function fillData() {
                    var table = DataB.keyActivity, cell = "class_5min";
                    var str = ouraCloud.value(table, cell);
                    var i, j, c, clr;
                    var hour = ouraCloud.startHour(table);
                    var minute = ouraCloud.startMinute(table);

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
                                addData("", c, clr, printTime(hour, minute))
                            else
                                addData("", c, clr, "");
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

                    if (i > centerAt) {
                        currentIndex = centerAt
                        positionViewAtIndex(currentIndex, ListView.Center)
                    } else {
                        positionViewAtEnd()
                    }

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
                showLabel: met1min.showLabelAlways
                barWidth: Theme.paddingMedium
                labelWidth: barWidth
                labelFontSize: Theme.fontSizeSmall
                valueLabelOutside: true
                x: Theme.horizontalPageMargin
                onBarSelected: {
                    met5min.currentIndex = (barNr - barNr%5)/5
                    met5min.positionViewAtIndex((barNr - barNr%5)/5, ListView.Center)
                }

                highlight: Item {
                    Rectangle {
                        width: met1min.barWidth < Theme.paddingSmall ? Theme.paddingSmall : met1min.barWidth
                        height: Theme.paddingSmall
                        color: "red"
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Theme.fontSizeSmall + Theme.paddingSmall
                    }
                }

                highlightFollowsCurrentItem: true

                property int centerAt: 16*60 - dayStart

                function fillData() {
                    var table = DataB.keyActivity, cell = "met_1min";
                    var str = ouraCloud.value(table, cell), arr;
                    var i = str.indexOf("[") + 1, j = str.indexOf("]"), c, clr;
                    var hour = ouraCloud.startHour(table);
                    var minute = ouraCloud.startMinute(table);
                    var max = 0;
                    str = str.substring(i, j).trim();

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
                            if (minute === 0 || minute === 30)
                                addData("", c, clr, printTime(hour, minute))
                            else
                                addData("", c, clr, "");
                            if (c > max) {
                                max = c;
                            }
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
                    locals.maxMet1min = max;

                    if (count > centerAt) {
                        currentIndex = centerAt
                        positionViewAtIndex(currentIndex, ListView.Center)
                    } else {
                        positionViewAtEnd()
                    }

                    return;
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

    Timer {
        interval: 1*1000
        repeat: false
        running: true
        onTriggered: {
            updateValues()
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
        summaryDate = ouraCloud.dateChange(dayStep);
        txtDate.value = summaryDate.toDateString(Qt.locale(), Locale.ShortFormat);
        return;
    }

    function updateValues() {
        validDate = ouraCloud.dateAvailable(DataB.keyActivity, summaryDate);
        met1min.chartData.clear();
        met5min.chartData.clear();
        if (validDate) {
            /* scores */
            locals.score = ouraCloud.value(DataB.keyActivity, "score")*1.0;
            locals.stayActive = ouraCloud.value(DataB.keyActivity, "score_stay_active")*1.0;
            locals.moveHourly = ouraCloud.value(DataB.keyActivity, "score_move_every_hour")*1.0;
            locals.meetTargets = ouraCloud.value(DataB.keyActivity, "score_meet_daily_targets")*1.0;
            locals.trainingFreq = ouraCloud.value(DataB.keyActivity, "score_training_frequency")*1.0;
            locals.trainingVol = ouraCloud.value(DataB.keyActivity, "score_training_volume")*1.0;
            locals.recovery = ouraCloud.value(DataB.keyActivity, "score_recovery_time")*1.0;
            /* minutes */
            locals.nonWear = hm(ouraCloud.value(DataB.keyActivity, "non_wear"));
            locals.rest = hm(ouraCloud.value(DataB.keyActivity, "rest"));
            locals.timeInactive = hm(ouraCloud.value(DataB.keyActivity, "inactive"));
            locals.timeLow = hm(ouraCloud.value(DataB.keyActivity, "low"));
            locals.timeMedium = hm(ouraCloud.value(DataB.keyActivity, "medium"));
            locals.timeHigh = hm(ouraCloud.value(DataB.keyActivity, "high"));
            locals.timeActive = hm(ouraCloud.value(DataB.keyActivity, "low")*1.0 +
                                     ouraCloud.value(DataB.keyActivity, "medium")*1.0 +
                                     ouraCloud.value(DataB.keyActivity, "high")*1.0);
            /* misc */
            locals.movement = ouraCloud.value(DataB.keyActivity, "daily_movement")*1.0;
            locals.steps = ouraCloud.value(DataB.keyActivity, "steps")*1.0;
            locals.alerts = ouraCloud.value(DataB.keyActivity, "inactivity_alerts")*1.0;
            locals.totalCalories = ouraCloud.value(DataB.keyActivity, "cal_total")*1.0;
            locals.activeCalories = ouraCloud.value(DataB.keyActivity, "cal_active")*1.0;
            locals.metInactive = ouraCloud.value(DataB.keyActivity, "met_min_inactive")
            locals.metLow = ouraCloud.value(DataB.keyActivity, "met_min_low")
            locals.metMedium = ouraCloud.value(DataB.keyActivity, "met_min_medium")
            locals.metMediumPlus = ouraCloud.value(DataB.keyActivity, "met_min_medium_plus")
            locals.metHigh = ouraCloud.value(DataB.keyActivity, "met_min_high")
            locals.averageMet = ouraCloud.value(DataB.keyActivity, "average_met")
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
}
