import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../utils/datab.js" as DataB
import "../utils/scripts.js" as Scripts

Page {
    id: page

    allowedOrientations: Orientation.All

    signal refreshOuraCloud()
    signal openSettings()

    Connections {
        target: ouraCloud
        onFinishedActivity: {
            console.log("ouraCloud --- onFinishedActivity >>>")
            if (_reloaded) {
                resetActivityData()
            } else {
                fillActivityData()
            }
            console.log("ouraCloud --- onFinishedActivity <<<")
        }
        onFinishedBedTimes: {
            console.log("ouraCloud --- onFinishedBedTimes >>>")
            fillBedTimeData()
            console.log("ouraCloud --- onFinishedBedTimes <<<")
        }
        onFinishedReadiness: {
            console.log("ouraCloud --- onFinishedReadiness >>>")
            if (_reloaded) {
                resetReadinessData()
            } else {
                fillReadinessData()
            }
            console.log("ouraCloud --- onFinishedReadiness <<<")
        }
        onFinishedSleep: {
            console.log("ouraCloud --- onFinishedSleep >>>")
            if (_reloaded) {
                resetSleepData()
            } else {
                fillSleepData()
            }
            console.log("ouraCloud --- onFinishedSleep <<<")
        }
    }

    Connections {
        target: applicationWindow
        onStoredDataRead: {
            console.log("vanhat luettu ---> kuvaajien piirto")
            //activityChart.oldData()
            //sleepType.oldData()
            //sleepHBR.oldData()
            //readinessChart.oldData()
            console.log("vanhat luettu ---> graph5")
            chart1.oldData()
            chart2.oldData()
            chart3.oldData()
            chart4.oldData()
            console.log("vanhat luettu ---> kuvaajien piirto valmis")
        }
        onSettingsReady: {
            setUpPage()
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height
        width: parent.width

        PullDownMenu {
            MenuItem {
                text: qsTr("Activity")
                onClicked: {
                    var showDate = ouraCloud.lastDate(DataB.keyActivity, 0)
                    DataB.log("activity update 0: " + new Date().toTimeString().substring(0,8))
                    ouraCloud.setDateConsidered(showDate)
                    pageContainer.push(Qt.resolvedUrl("activityPage.qml"), {
                                           "summaryDate": showDate //
                                       })
                }
            }
            MenuItem {
                text: qsTr("Readiness")
                onClicked: {
                    var showDate = ouraCloud.lastDate(DataB.keyReadiness, 0)
                    ouraCloud.setDateConsidered(showDate)
                    pageContainer.push(Qt.resolvedUrl("readinessPage.qml"), {
                                           "summaryDate": showDate
                                       })
                }
            }
            MenuItem {
                text: qsTr("Sleep")
                onClicked: {
                    var showDate = ouraCloud.lastDate(DataB.keySleep, 0)
                    ouraCloud.setDateConsidered(showDate)
                    pageContainer.push(Qt.resolvedUrl("sleepPage.qml"), {
                                           "summaryDate": showDate
                                       })
                }
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("Info.qml"))
                }
            }
            MenuItem {
                text: qsTr("Settings")
                onClicked: {
                    var subPage = pageStack.push(Qt.resolvedUrl("Settings.qml"), {
                                                         "token": personalAccessToken
                                                     })
                    subPage.setToken.connect(function () {
                        var msg, newTkn = subPage.token
                        if (newTkn === "") {
                            msg = qsTr("Clearing token!")
                        } else {
                            msg = qsTr("Changing token to %1.").arg(newTkn)
                        }

                        DataB.log("new token >>" + newTkn.slice(0, 8) + "... <<")

                        remorse.execute(msg, function() {
                            DataB.updateSettings(DataB.keyPersonalToken, newTkn)
                            ouraCloud.setPersonalAccessToken(newTkn)
                            personalAccessToken = newTkn
                            ouraCloud.downloadOuraCloud()
                        })
                    })
                    subPage.cloudReloaded.connect(function () {
                        _reloaded = true;
                        //activityChart.clear();
                        //sleepType.clear();
                        //sleepHBR.clear();
                        //readiness.clear();
                        //activityChart.reset();
                        //sleepType.reset();
                        //sleepHBR.reset();
                        //readiness.reset();
                        // refresh charts, oura content changed
                    })
                }
            }
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    refreshOuraCloud()
                }
            }
        }

        Column {
            id: col
            width: parent.width

            PageHeader {
                id: header
                title: qsTr("Summary")
            }

            Item {
                id: scoreRow
                width: parent.width - 2*x
                height: txtDate.height + activityTrend.height
                x: Theme.horizontalPageMargin

                readonly property string scoreStr: "score"

                ValueButton {
                    id: txtDate
                    label: qsTr("date")
                    value: summaryDate.toDateString(Qt.locale(), Locale.ShortFormat)
                    y: 0

                    property date summaryDate: new Date(_dateNow.getTime() - 24*60*60*1000)

                    onClicked: {
                        var dialog = pageContainer.push("Sailfish.Silica.DatePickerDialog", {
                                                        "date": summaryDate } )
                        dialog.accepted.connect( function() {
                            //value = dialog.dateText
                            summaryDate = new Date(dialog.year, dialog.month-1, dialog.day, 11, 59, 59, 999)
                            activityTrend.fillData();
                            sleepTrend.fillData();
                            readinessTrend.fillData();
                            chart1.selectDate(summaryDate);
                            chart2.selectDate(summaryDate);
                            chart3.selectDate(summaryDate);
                            chart4.selectDate(summaryDate);
                        } )
                    }
                    onSummaryDateChanged: {
                        txtDate.value = summaryDate.toDateString(Qt.locale(), Locale.ShortFormat)
                    }
                }

                TrendLabel {
                    id: activityTrend
                    text: qsTr("activity")
                    layout: layCompact
                    score: 0
                    isValid: false
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom //y: txtDate.height + Theme.paddingSmall

                    function fillData() {
                        var val;
                        ouraCloud.setDateConsidered(txtDate.summaryDate);
                        average = ouraCloud.average(DataB.keyActivity, scoreRow.scoreStr); // defaults to previous 7 days
                        val = ouraCloud.value(DataB.keyActivity, scoreRow.scoreStr); // defaults to yesterday
                        if (val === "-")
                            isValid = false
                        else {
                            isValid = true;
                            score = val*1.0;
                        }
                    }
                }
                TrendLabel {
                    id: readinessTrend
                    text: qsTr("readiness")
                    layout: layCompact
                    score: 0
                    isValid: false
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom //y: parent.height - height//anchors.bottom: parent.bottom

                    function fillData() {
                        var val;
                        ouraCloud.setDateConsidered(txtDate.summaryDate);
                        average = ouraCloud.average(DataB.keyReadiness, scoreRow.scoreStr); // defaults to previous 7 days
                        val = ouraCloud.value(DataB.keyReadiness, scoreRow.scoreStr); // defaults to yesterday
                        if (val === "-")
                            isValid = false
                        else {
                            isValid = true;
                            score = val*1.0;
                        }
                    }
                }
                TrendLabel {
                    id: sleepTrend
                    text: qsTr("sleep")
                    layout: layCompact
                    score: 0
                    isValid: false
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom //y: parent.height - height//anchors.bottom: parent.bottom

                    function fillData() {
                        var val;
                        ouraCloud.setDateConsidered(txtDate.summaryDate);
                        average = ouraCloud.average(DataB.keySleep, scoreRow.scoreStr); // defaults to previous 7 days
                        val = ouraCloud.value(DataB.keySleep, scoreRow.scoreStr); // defaults to yesterday
                        if (val === "-")
                            isValid = false
                        else {
                            isValid = true;
                            score = val*1.0;
                        }
                    }
                }
            }

            /*
            SectionHeader {
                text: qsTr("active calories")
            }

            Row {
                height: Theme.itemSizeHuge
                spacing: Theme.paddingMedium
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin

                BarChart {
                    id: activityChart
                    height: parent.height
                    width: parent.width - parent.spacing - chart1Summary.width
                    orientation: ListView.Horizontal
                    maxValue: 700
                    valueLabelOutside: true

                    BusyIndicator {
                        anchors.centerIn: parent
                        size: BusyIndicatorSize.Medium
                        running: parent.loading
                    }

                    property date firstDate: _dateNow
                    property date lastDate: _dateNow
                    property string table: DataB.keyActivity
                    property string chartColumn: "cal_active"
                    property bool loading: true

                    function newData() {
                        // ignore data before lastDate
                        // average over the day readiness periods
                        var val, day, sct;
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first, last, diffMs, diffDays, i;

                        if (ouraCloud.numberOfRecords(table) <= 0) {
                            DataB.log("no " + table + "-data")
                            return;
                        }

                        // set firstDate equal to the first date read from records
                        // and last equal to current date or the date of an empty list of records
                        first = ouraCloud.firstDate(table);
                        console.log("eka " + first.toDateString() + " " + first.getHours() + ":" + first.getMinutes() + ":" + first.getSeconds() + "  " + first.getUTCHours())
                        if (first < firstDate) {
                            firstDate = first;
                        }
                        if (chartData.count === 0) {
                            lastDate = first;
                        }
                        last = lastDate;

                        // trying to avoid long loops if the date format is wrong
                        if (firstDate.getFullYear() >= 2000) {
                            diffMs = now.getTime() - lastDate.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else if (firstDate.getFullYear() >= 0 && firstDate.getFullYear() < 100) {
                            var dum = new Date(2000,0,1).getTime() - new Date(1,0,1).getTime();
                            diffMs = now.getTime() - (lastDate.getTime() + dum);
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else {
                            DataB.log("first date in " + table + "-data from year " +
                                      firstDate.getFullYear())
                            return;
                        }

                        DataB.log("activity chart " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + ouraCloud.lastDate(table).getDate() + "." + (ouraCloud.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        for (i=0; i<diffDays; i++) {
                            val = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));

                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val})
                            } else {
                                day = Scripts.dayStr(last.getDay());
                                sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));
                                addData(sct, val, Theme.highlightColor, day);
                            }
                            last.setTime(last.getTime() + dayMs);
                        }

                        if (i>0) {
                            last.setTime(last.getTime() - dayMs);
                        }

                        lastDate = last;
                        DataB.log("activity chart done " + i + " " + firstDate + " - " + lastDate);

                        loading = false;
                        positionViewAtEnd();

                        return;
                    }

                    function oldData() {
                        var val, diffMs, diffDays, sct;
                        var first, last, dayMs = 24*60*60*1000, i=0;

                        first = ouraCloud.firstDate(table);

                        if (count === 0) {
                            last = new Date();
                            console.log("ouraCloud.firstDate(" + table + ") " + first.toDateString());
                            if (first.getFullYear() < 10) {
                                first = last;
                            }
                            lastDate = last;
                        } else if (firstDate <= first) {
                            console.log("ouraCloud.firstDate(" + table + ") " + first.toDateString()
                                        + " " + firstDate.toDateString());
                            return;
                        } else {
                            last = firstDate;
                            last.setTime(last.getTime() - dayMs);
                        }

                        diffMs = last.getTime() - first.getTime();
                        diffDays = Math.ceil(diffMs/dayMs);

                        console.log("diffDays " + diffDays + " i " + i);

                        while (i< diffDays) {
                            val = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));
                            insertData(0, sct, val, Theme.highlightColor,
                                       Scripts.dayStr(last.getDay()));

                            i++;
                            if (i === 30000) {
                                console.log("30000 luuppia " + firstDate.toDateString());
                            }
                            last.setTime(last.getTime() - dayMs);
                        }                        
                        last.setTime(last.getTime() + dayMs);
                        firstDate = last;

                        positionViewAtEnd();

                        console.log("haettuja arvoja " + i);
                        return;
                    }

                    function reset() {
                        chartData.clear();
                        loading = true;
                        oldData();
                        loading = false;
                        return;
                    }
                }

                TrendView {
                    id: chart1Summary
                    //width: Theme.iconSizeLarge
                    anchors.bottom: parent.bottom
                    height: parent.height                    
                    text: qsTr("score")
                    factor: page.factor
                    maxValue: activityChart.maxValue

                    property string scoreStr: "score"

                    function fillData() {
                        var val;
                        ouraCloud.setDateConsidered();
                        averageWeek = ouraCloud.average(activityChart.table, activityChart.chartColumn, 7);
                        averageMonth = ouraCloud.average(activityChart.table, activityChart.chartColumn, 30);
                        averageYear = ouraCloud.average(activityChart.table, activityChart.chartColumn, 365);
                        average = ouraCloud.average(activityChart.table, scoreStr); // defaults to previous 7 days
                        val = ouraCloud.value(activityChart.table, scoreStr); // defaults to yesterday
                        if (val === "-")
                            isValid = false
                        else
                            score = val*1.0;
                    }
                }
            }

            // */
            HistoryChart {
                id: chart1
                onParametersChanged: {
                    storeChartParameters(chartId, chTable, chType,
                                         chCol, chCol2, chCol3,
                                         chCol4, chHigh, chLow,
                                         maxValue, heading)
                }
                onBarSelected: {
                    selectColumn(chartId, barNr, firstDate.getTime())
                }

                property string chartId: "ch1"

                function setUpChart() {
                    heading = DataB.getSetting(chartId + DataB.keyChartTitle, qsTr("active calories"));
                    chTable = DataB.getSetting(chartId + DataB.keyChartTable, DataB.keyActivity);
                    chType = DataB.getSetting(chartId + DataB.keyChartType, DataB.chartTypeSingle);
                    chCol = DataB.getSetting(chartId + DataB.keyChartCol, "cal_active");
                    chCol2 = DataB.getSetting(chartId + DataB.keyChartCol2, "");
                    chCol3 = DataB.getSetting(chartId + DataB.keyChartCol3, "");
                    chCol4 = DataB.getSetting(chartId + DataB.keyChartCol4, "");
                    chHigh = DataB.getSetting(chartId + DataB.keyChartHigh, "");
                    chLow = DataB.getSetting(chartId + DataB.keyChartLow, "");
                    maxValue = DataB.getSetting(chartId + DataB.keyChartMax, 700);
                    if (chType === DataB.chartTypeSleep) {
                        setValueLabel = true;
                    }
                    return;
                }
            }

            HistoryChart {
                id: chart2
                onBarSelected: {
                    selectColumn(chartId, barNr, firstDate.getTime())
                }
                onParametersChanged: {
                    storeChartParameters(chartId, chTable, chType,
                                         chCol, chCol2, chCol3,
                                         chCol4, chHigh, chLow,
                                         maxValue, heading)
                }

                property string chartId: "ch2"

                function setUpChart() {
                    heading = DataB.getSetting(chartId + DataB.keyChartTitle, qsTr("sleep levels"));
                    chTable = DataB.getSetting(chartId + DataB.keyChartTable, DataB.keySleep);
                    chType = DataB.getSetting(chartId + DataB.keyChartType, DataB.chartTypeSleep);
                    chCol = DataB.getSetting(chartId + DataB.keyChartCol, "deep");
                    chCol2 = DataB.getSetting(chartId + DataB.keyChartCol2, "light");
                    chCol3 = DataB.getSetting(chartId + DataB.keyChartCol3, "rem");
                    chCol4 = DataB.getSetting(chartId + DataB.keyChartCol4, "awake");
                    chHigh = DataB.getSetting(chartId + DataB.keyChartHigh, "");
                    chLow = DataB.getSetting(chartId + DataB.keyChartLow, "");
                    maxValue = DataB.getSetting(chartId + DataB.keyChartMax, 10*60*60);
                    if (chType === DataB.chartTypeSleep) {
                        setValueLabel = true;
                    }
                    return;
                }
            }

            HistoryChart {
                id: chart3
                onBarSelected: {
                    selectColumn(chartId, barNr, firstDate.getTime())
                }
                onParametersChanged: {
                    storeChartParameters(chartId, chTable, chType,
                                         chCol, chCol2, chCol3,
                                         chCol4, chHigh, chLow,
                                         maxValue, heading)
                }

                property string chartId: "ch3"

                function setUpChart() {
                    heading = DataB.getSetting(chartId + DataB.keyChartTitle, qsTr("sleep time hearth beat rate"));
                    chTable = DataB.getSetting(chartId + DataB.keyChartTable, DataB.keySleep);
                    chType = DataB.getSetting(chartId + DataB.keyChartType, DataB.chartTypeMin);
                    chCol = DataB.getSetting(chartId + DataB.keyChartCol, "hr_average");
                    chCol2 = DataB.getSetting(chartId + DataB.keyChartCol2, "");
                    chCol3 = DataB.getSetting(chartId + DataB.keyChartCol3, "");
                    chCol4 = DataB.getSetting(chartId + DataB.keyChartCol4, "");
                    chHigh = DataB.getSetting(chartId + DataB.keyChartHigh, "");
                    chLow = DataB.getSetting(chartId + DataB.keyChartLow, "hr_lowest");
                    maxValue = DataB.getSetting(chartId + DataB.keyChartMax, 60);
                    if (chType === DataB.chartTypeSleep) {
                        setValueLabel = true;
                    }
                    return;
                }
            }

            HistoryChart {
                id: chart4
                onBarSelected: {
                    selectColumn(chartId, barNr, firstDate.getTime())
                }
                onParametersChanged: {
                    storeChartParameters(chartId, chTable, chType,
                                         chCol, chCol2, chCol3,
                                         chCol4, chHigh, chLow,
                                         maxValue, heading)
                }

                property string chartId: "ch4"

                function setUpChart() {
                    heading = DataB.getSetting(chartId + DataB.keyChartTitle, qsTr("readiness"));
                    chTable = DataB.getSetting(chartId + DataB.keyChartTable, DataB.keyReadiness);
                    chType = DataB.getSetting(chartId + DataB.keyChartType, DataB.chartTypeSingle);
                    chCol = DataB.getSetting(chartId + DataB.keyChartValue1, "score");
                    chCol2 = DataB.getSetting(chartId + DataB.keyChartValue2, "");
                    chCol3 = DataB.getSetting(chartId + DataB.keyChartValue3, "");
                    chCol4 = DataB.getSetting(chartId + DataB.keyChartValue4, "");
                    chHigh = DataB.getSetting(chartId + DataB.keyChartHigh, "");
                    chLow = DataB.getSetting(chartId + DataB.keyChartLow, "");
                    maxValue = DataB.getSetting(chartId + DataB.keyChartMax, 100);
                    if (chType === DataB.chartTypeSleep) {
                        setValueLabel = true;
                    }
                    return;
                }
            }

            Rectangle {
                height: Theme.fontSizeExtraSmall
                width: 1
                color: "transparent"
            }
        }
        VerticalScrollDecorator {}
    }

    property real factor: 1.1 // limit for highlighting trends
    property date _dateNow: new Date()
    property bool _reloaded: false

    function chartChanged(tb0, typ0, val0, low0, hgh0,
                          tb1, typ1, val1, low1, hgh1) {
        var result = false;
        if (tb1 === undefined || typ1 === undefined || val1 === undefined) {
            result = false;
        } else if (tb0 !== tb1 || typ0 !== typ1) {
            result = true;
        } else if (typ1 === DataB.chartTypeSleep) {
            result = false;
        } else if (val0 !== val1) {
            result = true;
        } else if (typ1 === DataB.chartTypeMin && low0 !== low1) {
            result = true;
        } else if (typ1 === DataB.chartTypeMaxmin &&
                   (low0 !== low1 || hgh0 !== hgh1)) {
            result = true;
        }
        return result;
    }

    function chartTitle(chrt){
        var result;
        if (chrt === chart1.chartId){
            result = chart1.heading;
        } else if (chrt === chart2.chartId){
            result = chart2.heading;
        } else if (chrt === chart3.chartId){
            result = chart3.heading;
        } else if (chrt === chart4.chartId){
            result = chart4.heading;
        }

        return result;
    }

    function fillActivityData() {
        console.log("....activity....")
        ouraCloud.setDateConsidered();
        //activityChart.newData();
        //chart1Summary.fillData();
        activityTrend.fillData();
        if (chart1.chTable === DataB.keyActivity) {
            chart1.newData();
            chart1.fillData();
        }
        if (chart2.chTable === DataB.keyActivity) {
            chart2.newData();
            chart2.fillData();
        }
        if (chart3.chTable === DataB.keyActivity) {
            chart3.newData();
            chart3.fillData();
        }
        if (chart4.chTable === DataB.keyActivity) {
            chart4.newData();
            chart4.fillData();
        }

        return;
    }

    function fillBedTimeData() {
        return;
    }

    function fillReadinessData() {
        console.log("....readiness....")
        ouraCloud.setDateConsidered();
        //readinessChart.newData();
        //chart4Summary.fillData();
        readinessTrend.fillData();
        //graph4.newData();
        //graph4.fillData();
        if (chart1.chTable === DataB.keyReadiness) {
            chart1.newData();
            chart1.fillData();
        }
        if (chart2.chTable === DataB.keyReadiness) {
            chart2.newData();
            chart2.fillData();
        }
        if (chart3.chTable === DataB.keyReadiness) {
            chart3.newData();
            chart3.fillData();
        }
        if (chart4.chTable === DataB.keyReadiness) {
            chart4.newData();
            chart4.fillData();
        }
        return;
    }

    function fillSleepData() {
        console.log("....sleep....")
        ouraCloud.setDateConsidered();
        //sleepType.newData();
        //chart2Summary.fillData();
        //sleepHBR.newData();
        //chart3Summary.fillData();
        sleepTrend.fillData();
        //graph2.fillData();
        //graph2.newData();
        if (chart1.chTable === DataB.keySleep) {
            chart1.newData();
            chart1.fillData();
        }
        if (chart2.chTable === DataB.keySleep) {
            chart2.newData();
            chart2.fillData();
        }
        if (chart3.chTable === DataB.keySleep) {
            chart3.newData();
            chart3.fillData();
        }
        if (chart4.chTable === DataB.keySleep) {
            chart4.newData();
            chart4.fillData();
        }
        return;
    }

    function latestItem(chartId) {
        var result, i;
        if (chartId === chart1.chartId) {
            i = chart1.valuesList.count - 2; //count - 1 = current day
            result = chart1.valuesList.get(i);
        } else if (chartId === chart3.chartId) {
            i = chart2.valuesList.count - 2; //count - 1 = current day
            result = chart2.valuesList.get(i);
        } else if (chartId === chart3.chartId) {
            i = chart3.valuesList.count - 2; //count - 1 = current day
            result = chart3.valuesList.get(i);
        } else if (chartId === chart4.chartId) {
            i = chart4.valuesList.count - 2; //count - 1 = current day
            result = chart4.valuesList.get(i);
        }
        return result;
    }

    function latestType(chartId) {
        var result;
        if (chartId === chart1.chartId) {
            result = chart1.chType;
        } else if (chartId === chart2.chartId) {
            result = chart2.chType;
        } else if (chartId === chart3.chartId) {
            result = chart3.chType;
        } else if (chartId === chart4.chartId) {
            result = chart4.chType;
        }
        return result;
    }

    function latestValue(chrt){
        var result;
        if (chrt === chart1.chartId){
            result = chart1.latestValue;
        } else if (chrt === chart2.chartId){
            result = chart2.latestValue;
        } else if (chrt === chart3.chartId){
            result = chart3.latestValue;
        } else if (chrt === chart4.chartId){
            result = chart4.latestValue;
        }

        return result;
    }

    function resetActivityData() {
        ouraCloud.setDateConsidered();
        activityTrend.fillData();
        if (chart1.chTable === DataB.keyActivity) {
            chart1.reset();
        }
        if (chart2.chTable === DataB.keyActivity) {
            chart2.reset();
        }
        if (chart3.chTable === DataB.keyActivity) {
            chart3.reset();
        }
        if (chart4.chTable === DataB.keyActivity) {
            chart4.reset();
        }
        return;
    }

    function resetReadinessData() {
        ouraCloud.setDateConsidered();
        readinessTrend.fillData();
        if (chart1.chTable === DataB.keyReadiness) {
            chart1.reset();
        }
        if (chart2.chTable === DataB.keyReadiness) {
            chart2.reset();
        }
        if (chart3.chTable === DataB.keyReadiness) {
            chart3.reset();
        }
        if (chart4.chTable === DataB.keyReadiness) {
            chart4.reset();
        }
        return;
    }

    function resetSleepData() {
        ouraCloud.setDateConsidered();
        sleepTrend.fillData();
        if (chart1.chTable === DataB.keySleep) {
            chart1.reset();
        }
        if (chart2.chTable === DataB.keySleep) {
            chart2.reset();
        }
        if (chart3.chTable === DataB.keySleep) {
            chart3.reset();
        }
        if (chart4.chTable === DataB.keySleep) {
            chart4.reset();
        }
        return;
    }

    function selectColumn(chartId, barNr, firstDateTime) {
        txtDate.summaryDate = new Date(firstDateTime + barNr*msDay);
        if (chartId !== chart1.chartId) {
            chart1.currentIndex = barNr;
        }
        chart1.positionViewAtIndex(barNr, ListView.Center);
        if (chartId !== chart2.chartId) {
            chart2.currentIndex = barNr;
        }
        chart2.positionViewAtIndex(barNr, ListView.Center);
        if (chartId !== chart3.chartId) {
            chart3.currentIndex = barNr;
        }
        chart3.positionViewAtIndex(barNr, ListView.Center);
        if (chartId !== chart4.chartId) {
            chart4.currentIndex = barNr;
        }
        chart4.positionViewAtIndex(barNr, ListView.Center);

        activityTrend.fillData();
        readinessTrend.fillData();
        sleepTrend.fillData();

        return;
    }

    function setUpPage() {
        chart1.setUpChart();
        chart2.setUpChart();
        chart3.setUpChart();
        chart4.setUpChart();
        /*
        readinessChart.table = DataB.getSetting(DataB.keyChart4Table, DataB.keyReadiness);
        readinessChart.chartColumn = DataB.getSetting(DataB.keyChart4Value1, "score");
        readinessChart.chartColumn2 = DataB.getSetting(DataB.keyChart4Value2, "");
        readinessChart.chartColumn3 = DataB.getSetting(DataB.keyChart4Value3, "");
        readinessChart.chartColumn4 = DataB.getSetting(DataB.keyChart4Value4, "");
        readinessChart.chartHighBar = DataB.getSetting(DataB.keyChart4High, "");
        readinessChart.chartLowBar = DataB.getSetting(DataB.keyChart4Low, "");
        readinessChart.chartType = DataB.getSetting(DataB.keyChart4Type, DataB.chartTypeSingle);
        title4.text = DataB.getSetting(DataB.keyChart4Title, "readiness");
        // */

        /*
        graph5.chType = DataB.getSetting(graph5.chartId + DataB.keyChartType, DataB.chartTypeSingle);
        graph5.chTable = DataB.getSetting(graph5.chartId + DataB.keyChartTable, DataB.keyReadiness);
        graph5.chCol = DataB.getSetting(graph5.chartId + DataB.keyChartValue1, "score");
        graph5.chCol2 = DataB.getSetting(graph5.chartId + DataB.keyChartValue2, "");
        graph5.chCol3 = DataB.getSetting(graph5.chartId + DataB.keyChartValue3, "");
        graph5.chCol4 = DataB.getSetting(graph5.chartId + DataB.keyChartValue4, "");
        graph5.chHigh = DataB.getSetting(graph5.chartId + DataB.keyChartHigh, "");
        graph5.chLow = DataB.getSetting(graph5.chartId + DataB.keyChartLow, "");
        graph5.heading = DataB.getSetting(graph5.chartId + DataB.keyChartTitle, "readiness");
        // */

        return;
    }

    function storeChartParameters(chartId, chTable, chType, chCol,
                                  chCol2, chCol3, chCol4, chHigh,
                                  chLow, chMax, chTitle) {
        DataB.storeSettings(chartId + DataB.keyChartTable, chTable);
        DataB.storeSettings(chartId + DataB.keyChartType, chType);
        DataB.storeSettings(chartId + DataB.keyChartValue1, chCol);
        DataB.storeSettings(chartId + DataB.keyChartValue2, chCol2);
        DataB.storeSettings(chartId + DataB.keyChartValue3, chCol3);
        DataB.storeSettings(chartId + DataB.keyChartValue4, chCol4);
        DataB.storeSettings(chartId + DataB.keyChartHigh, chHigh);
        DataB.storeSettings(chartId + DataB.keyChartLow, chLow);
        DataB.storeSettings(chartId + DataB.keyChartMax, chMax);
        DataB.storeSettings(chartId + DataB.keyChartTitle, chTitle);

        return;
    }

}
