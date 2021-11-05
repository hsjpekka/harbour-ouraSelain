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

    property real factor: 1.1 // limit for highlighting trends
    property date _dateNow: new Date()
    property bool _reloaded: false

    Connections {
        target: ouraCloud
        onFinishedActivity: {
            console.log("ouraCloud --- onFinishedActivity >>>")
            if (_reloaded) {
                activityChart.reset()
                chart1Summary.fillData()
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
                readinessChart.reset()
                chart4Summary.fillData()
            } else {
                fillReadinessData()
            }
            console.log("ouraCloud --- onFinishedReadiness <<<")
        }
        onFinishedSleep: {
            console.log("ouraCloud --- onFinishedSleep >>>")
            if (_reloaded) {
                sleepType.reset()
                chart2Summary.fillData()
                sleepHBR.reset()
                chart3Summary.fillData()
                graph2.reset();
                graph2.fillData();
                graph2.newData();
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
                    DataB.log("activity update 0: " + new Date().toTimeString().substring(0,8))
                    pageContainer.push(Qt.resolvedUrl("activityPage.qml"), {
                                           "summaryDate": ouraCloud.lastDate(DataB.keyActivity, 1) //
                                       })
                }
            }
            MenuItem {
                text: qsTr("Readiness")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("readinessPage.qml"), {
                                           "summaryDate": ouraCloud.lastDate(DataB.keyReadiness, 1)
                                       })
                }
            }
            MenuItem {
                text: qsTr("Sleep")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("sleepPage.qml"), {
                                           "summaryDate": ouraCloud.lastDate(DataB.keySleep, 1)
                                       })
                }
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("about")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("Info.qml"))
                }
            }
            MenuItem {
                text: qsTr("settings")
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
                text: qsTr("refresh")
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
                height: activityTrend.height
                x: Theme.horizontalPageMargin

                readonly property string scoreStr: "score"

                TrendLabel {
                    id: activityTrend
                    text: qsTr("activity")
                    layout: layCompact
                    score: 0
                    isValid: false
                    anchors.left: parent.left
                    anchors.top: parent.top

                    function fillData() {
                        var val;
                        ouraCloud.setDateConsidered();
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
                    anchors.top: parent.top

                    function fillData() {
                        var val;
                        ouraCloud.setDateConsidered();
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
                    anchors.top: parent.top

                    function fillData() {
                        var val;
                        ouraCloud.setDateConsidered();
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
                chartId: "ch1"
                onParametersChanged: {
                    storeChartParameters(chartId, chTable, chType,
                                         chCol, chCol2, chCol3,
                                         chCol4, chHigh, chLow,
                                         maxValue, heading)
                }
                onBarSelected: {
                    chart2.currentIndex = barNr
                    chart2.positionViewAtIndex(barNr, ListView.Center)
                    chart3.currentIndex = barNr
                    chart3.positionViewAtIndex(barNr, ListView.Center)
                    chart4.currentIndex = barNr
                    chart4.positionViewAtIndex(barNr, ListView.Center)
                }

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

            /*
            SectionHeader {
                text: qsTr("sleep")
            }

            Row {
                height: Theme.itemSizeHuge
                spacing: Theme.paddingMedium
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin

                BarChart {
                    id: sleepType
                    width: parent.width - parent.spacing - chart2Summary.width
                    height: parent.height
                    orientation: ListView.Horizontal
                    maxValue: 10*60*60
                    arrayType: 0
                    valueLabelOutside: true
                    setValueLabel: true

                    BusyIndicator {
                        anchors.centerIn: parent
                        size: BusyIndicatorSize.Medium
                        running: parent.loading
                    }

                    property date firstDate: _dateNow
                    property date lastDate: _dateNow
                    property bool loading: true
                    property string table: DataB.keySleep
                    property string cell1: "deep"
                    property string cell2: "light"
                    property string cell3: "rem"
                    property string cell4: "awake"

                    function newData() {
                        // ignore data before lastDate
                        // average over the day readiness periods
                        var val1, val2, val3, val4, day, sct;
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first, last, diffMs, diffDays, i;

                        if (ouraCloud.numberOfRecords(table) <= 0) {
                            DataB.log("no " + table + "-data")
                            return;
                        }

                        first = ouraCloud.firstDate(table);
                        console.log("eka " + first.toDateString())
                        if (first < firstDate) {
                            firstDate = first;
                        }
                        if (chartData.count === 0) {
                            lastDate = first;
                        }
                        last = lastDate;

                        if (firstDate.getFullYear() > 2000) {
                            diffMs = now.getTime() - lastDate.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else {
                            DataB.log("first date in " + table + "-data from year " +
                                      firstDate.getFullYear())
                        }

                        DataB.log("sleep chart " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + ouraCloud.lastDate(table).getDate() + "." + (ouraCloud.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        for (i=0; i<diffDays; i++) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, cell1, last, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = Scripts.ouraToNumber(ouraCloud.value(table, cell2, last, -2)); // -1 is_longest==1
                            val3 = Scripts.ouraToNumber(ouraCloud.value(table, cell3, last, -2)); // -1 is_longest==1
                            val4 = Scripts.ouraToNumber(ouraCloud.value(table, cell4, last, -2)); // -1 is_longest==1

                            day = Scripts.dayStr(last.getDay());
                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val1, "bar2Value": val2,
                                              "bar3Value": val3, "bar4Value": val4, "valLabel":
                                                  Scripts.secToHM(val1 + val2 + val3) })
                            } else {
                                sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));
                                addData(sct, val1, "DarkGreen", day, val2, "Green", val3,
                                        "LightGreen", val4, "LightYellow",
                                        Scripts.secToHM(val1 + val2 + val3));
                            }
                            last.setTime(last.getTime() + dayMs);
                        }

                        if (i>0) {
                            last.setTime(last.getTime() - dayMs);
                        }

                        lastDate = last;
                        DataB.log("sleep chart done " + i + " " + firstDate + " - " + lastDate);

                        loading = false;
                        positionViewAtEnd();

                        return;
                    }

                    function oldData() {
                        var val1, val2, val3, val4, diffMs, diffDays, sct;
                        var first, last, dayMs = 24*60*60*1000, day, i=0;

                        first = ouraCloud.firstDate(table);

                        if (count === 0) {
                            last = new Date();
                            if (first.getFullYear() < 10) {
                                first = last;
                            }
                            lastDate = last;
                        } else if (firstDate <= first) {
                            return;
                        } else {
                            last = firstDate;
                            last.setTime(last.getTime() - dayMs);
                        }

                        diffMs = last.getTime() - first.getTime();
                        diffDays = Math.ceil(diffMs/dayMs);

                        while (i< diffDays) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, cell1, last, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = Scripts.ouraToNumber(ouraCloud.value(table, cell2, last, -2)); // -1 is_longest==1
                            val3 = Scripts.ouraToNumber(ouraCloud.value(table, cell3, last, -2)); // -1 is_longest==1
                            val4 = Scripts.ouraToNumber(ouraCloud.value(table, cell4, last, -2)); // -1 is_longest==1

                            day = Scripts.dayStr(last.getDay());
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));
                            insertData(0, sct, val1, "DarkGreen", day, val2, "Green", val3,
                                       "LightGreen", val4, "LightYellow",
                                       Scripts.secToHM(val1 + val2 + val3));

                            i++;
                            if (i === 300) {
                                console.log("300 luuppia " + firstDate.toDateString())
                            }
                            last.setTime(last.getTime()- dayMs);
                        }
                        last.setTime(last.getTime() + dayMs);
                        firstDate = last;

                        positionViewAtEnd();

                        return;
                    }

                    function reset() {
                        chartData.clear();
                        loading = true;
                        oldData();
                        loading = false;
                        return;
                    }

                    function newData2(chartType) { // chartType: 0 - single value, 1 - average and min, 4 - sleep types
                        // ignore data before lastDate
                        // average over the day readiness periods
                        var val1, val2, val3, val4, day, sct;
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
                        // poista kokeiluajan jälkeen
                        if (last.getFullYear() >= 2000) {
                            diffMs = now.getTime() - last.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else if (first.getFullYear() >= 0 && first.getFullYear() < 100) {
                            first.setFullYear(first.getFullYear() + 2000);
                            last.setFullYear(last.getFullYear() + 2000);
                            diffMs = now.getTime() - lastDate.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else {
                            DataB.log("first date in " + table + "-data from year " +
                                      firstDate.getFullYear())
                            return;
                        }

                        DataB.log("activity chart " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + ouraCloud.lastDate(table).getDate() + "." + (ouraCloud.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        for (i=0; i<diffDays; i++) {
                            day = Scripts.dayStr(last.getDay());
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));

                            if (chartType === 0) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));

                                if (i === 0 && count > 0) {
                                    chartData.set(i, {"barValue": val1})
                                } else {
                                    addData(sct, val1, Theme.highlightColor, day);
                                }
                            } else if (chartType === 4) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, cell1, last, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                                val2 = Scripts.ouraToNumber(ouraCloud.value(table, cell2, last, -2)); // -1 is_longest==1
                                val3 = Scripts.ouraToNumber(ouraCloud.value(table, cell3, last, -2)); // -1 is_longest==1
                                val4 = Scripts.ouraToNumber(ouraCloud.value(table, cell4, last, -2)); // -1 is_longest==1
                                if (i === 0 && count > 0) {
                                    chartData.set(i, {"barValue": val1, "bar2Value": val2,
                                                  "bar3Value": val3, "bar4Value": val4, "valLabel":
                                                      Scripts.secToHM(val1 + val2 + val3) })
                                } else {
                                    addData(sct, val1, "DarkGreen", day, val2, "Green", val3,
                                            "LightGreen", val4, "LightYellow",
                                            Scripts.secToHM(val1 + val2 + val3));
                                }
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

                    function oldData2(chartType) {
                        var val1, val2, val3, val4, diffMs, diffDays, dayStr, sct;
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
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));
                            dayStr = Scripts.dayStr(last.getDay());

                            if (chartType === 0) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));
                                insertData(0, sct, val1, Theme.highlightColor, dayStr);
                            } else if (chartType === 4) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, cell1, last, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                                val2 = Scripts.ouraToNumber(ouraCloud.value(table, cell2, last, -2)); // -1 is_longest==1
                                val3 = Scripts.ouraToNumber(ouraCloud.value(table, cell3, last, -2)); // -1 is_longest==1
                                val4 = Scripts.ouraToNumber(ouraCloud.value(table, cell4, last, -2)); // -1 is_longest==1

                                insertData(0, sct, val1, "DarkGreen", dayStr, val2, "Green",
                                           val3, "LightGreen", val4, "LightYellow",
                                           Scripts.secToHM(val1 + val2 + val3));
                            }

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


                }

                TrendView {
                    id: chart2Summary
                    //width: Theme.iconSizeLarge
                    anchors.bottom: parent.bottom
                    height: parent.height
                    text: qsTr("score")
                    factor: page.factor
                    maxValue: sleepType.maxValue
                    valueType: 1

                    property string scoreStr: "score"

                    function fillData() {
                        var val;
                        averageWeek = ouraCloud.average(sleepType.table, "total", 7);
                        averageMonth = ouraCloud.average(sleepType.table, "total", 30);
                        averageYear = ouraCloud.average(sleepType.table, "total", 365);
                        average = ouraCloud.average(sleepType.table, scoreStr); // defaults to previous 7 days
                        val = ouraCloud.value(sleepType.table, scoreStr); // defaults to yesterday
                        if (val === "-")
                            isValid = false
                        else
                            score = val*1.0;
                    }
                }
            }
            //*/
            HistoryChart {
                id: chart2
                chartId: "ch2"
                onBarSelected: {
                    chart1.currentIndex = barNr
                    chart1.positionViewAtIndex(barNr, ListView.Center)
                    chart3.currentIndex = barNr
                    chart3.positionViewAtIndex(barNr, ListView.Center)
                    chart4.currentIndex = barNr
                    chart4.positionViewAtIndex(barNr, ListView.Center)
                }
                onParametersChanged: {
                    storeChartParameters(chartId, chTable, chType,
                                         chCol, chCol2, chCol3,
                                         chCol4, chHigh, chLow,
                                         maxValue, heading)
                }

                function setUpChart() {
                    heading = DataB.getSetting(chartId + DataB.keyChartTitle, qsTr("sleep stages"));
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

            /*
            SectionHeader {
                text: qsTr("sleep time heart beat rate")
            }

            Row {
                height: Theme.itemSizeExtraLarge
                spacing: Theme.paddingMedium
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin

                BarChart {
                    id: sleepHBR
                    width: parent.width - parent.spacing - chart3Summary.width
                    height: parent.height
                    orientation: ListView.Horizontal
                    maxValue: 60
                    valueLabelOutside: true

                    BusyIndicator {
                        anchors.centerIn: parent
                        size: BusyIndicatorSize.Medium
                        running: parent.loading
                    }

                    property date firstDate: _dateNow
                    property date lastDate: _dateNow
                    property bool loading: true
                    property string table: DataB.keySleep
                    property string chartColumn: "hr_average"
                    property string cellLow: "hr_lowest"

                    function newData() {
                        // ignore data before lastDate
                        var val, lowest, day, sct;
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first, last, diffMs, diffDays, i;

                        if (ouraCloud.numberOfRecords(table) <= 0) {
                            DataB.log("no " + table + "-data")
                            return;
                        }

                        first = ouraCloud.firstDate(table);
                        console.log("hbr eka " + first.toDateString())
                        if (first < firstDate) {
                            firstDate = first;
                        }
                        if (chartData.count === 0) {
                            lastDate = first;
                        }
                        last = lastDate;

                        if (firstDate.getFullYear() > 2000) {
                            diffMs = now.getTime() - lastDate.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else {
                            DataB.log("first date in " + table + "-data from year " +
                                      firstDate.getFullYear())
                        }

                        DataB.log("hbr chart " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + ouraCloud.lastDate(table).getDate() + "." + (ouraCloud.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        for (i=0; i<diffDays; i++) {
                            val = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));
                            lowest = Scripts.ouraToNumber(ouraCloud.value(table, cellLow, last));

                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val, "localMax": lowest,
                                                  "localMin": lowest })
                            } else {
                                day = Scripts.dayStr(last.getDay());
                                sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));
                                addDataVariance(sct, val, "red", lowest, lowest,
                                                (lowest === 0? "transparent" : Theme.secondaryColor),
                                                day);
                            }

                            last.setTime(last.getTime() + dayMs);
                        }

                        if (i>0) {
                            last.setTime(last.getTime() - dayMs);
                        }

                        lastDate = last;
                        DataB.log("hbr chart done " + i + " " + firstDate + " - " + lastDate);

                        loading = false;
                        positionViewAtEnd();

                        return;
                    }

                    function oldData() {
                        var val, lowest, diffMs, diffDays, sct;
                        var first, last, day, dayMs = 24*60*60*1000, i=0;

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

                        while (i < diffDays) {
                            val = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));
                            lowest = Scripts.ouraToNumber(ouraCloud.value(table, cellLow, last));

                            day = Scripts.dayStr(last.getDay());
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));
                            insertDataVariance(0, sct, val, "red", lowest, lowest,
                                               (lowest === 0? "transparent" : Theme.secondaryColor),
                                               day);

                            if (i === 300) {
                                console.log("300 luuppia " + firstDate.toDateString())
                            }
                            last.setTime(last.getTime()- dayMs);
                            i++;
                        }

                        last.setTime(last.getTime() + dayMs);
                        firstDate = last;

                        positionViewAtEnd();

                        return;
                    }

                    function reset() {
                        chartData.clear();
                        loading = true;
                        oldData();
                        loading = false;
                        return;
                    }

                    function newData2(chartType) { // chartType: 0 - single value, 1 - average and min, 4 - sleep types
                        // ignore data before lastDate
                        // average over the day readiness periods
                        var val1, val2, val3, val4, lowest, day, sct;
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
                        // poista kokeiluajan jälkeen
                        if (last.getFullYear() >= 2000) {
                            diffMs = now.getTime() - last.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else if (first.getFullYear() >= 0 && first.getFullYear() < 100) {
                            first.setFullYear(first.getFullYear() + 2000);
                            last.setFullYear(last.getFullYear() + 2000);
                            diffMs = now.getTime() - lastDate.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else {
                            DataB.log("first date in " + table + "-data from year " +
                                      firstDate.getFullYear())
                            return;
                        }

                        DataB.log("activity chart " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + ouraCloud.lastDate(table).getDate() + "." + (ouraCloud.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        for (i=0; i<diffDays; i++) {
                            day = Scripts.dayStr(last.getDay());
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));

                            if (chartType === 0) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));

                                if (i === 0 && count > 0) {
                                    chartData.set(i, {"barValue": val1})
                                } else {
                                    addData(sct, val1, Theme.highlightColor, day);
                                }
                            } else if (chartType === 2) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));
                                lowest = Scripts.ouraToNumber(ouraCloud.value(table, cellLow, last));
                                if (i === 0 && count > 0) {
                                    chartData.set(i, {"barValue": val, "localMax": lowest,
                                                      "localMin": lowest })
                                } else {
                                    addDataVariance(sct, val1, "red", lowest, lowest,
                                                    (lowest === 0? "transparent" : Theme.secondaryColor),
                                                    day);
                                }
                            } else if (chartType === 4) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, cell1, last, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                                val2 = Scripts.ouraToNumber(ouraCloud.value(table, cell2, last, -2)); // -1 is_longest==1
                                val3 = Scripts.ouraToNumber(ouraCloud.value(table, cell3, last, -2)); // -1 is_longest==1
                                val4 = Scripts.ouraToNumber(ouraCloud.value(table, cell4, last, -2)); // -1 is_longest==1
                                if (i === 0 && count > 0) {
                                    chartData.set(i, {"barValue": val1, "bar2Value": val2,
                                                  "bar3Value": val3, "bar4Value": val4, "valLabel":
                                                      Scripts.secToHM(val1 + val2 + val3) })
                                } else {
                                    addData(sct, val1, "DarkGreen", day, val2, "Green", val3,
                                            "LightGreen", val4, "LightYellow",
                                            Scripts.secToHM(val1 + val2 + val3));
                                }
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

                    function oldData2(chartType) {
                        var val1, val2, val3, val4, lowest, diffMs, diffDays, dayStr, sct;
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
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));
                            dayStr = Scripts.dayStr(last.getDay());

                            if (chartType === 0) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));
                                insertData(0, sct, val1, Theme.highlightColor, dayStr);
                            } else if (chartType === 2) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));
                                lowest = Scripts.ouraToNumber(ouraCloud.value(table, cellLow, last));
                                insertDataVariance(0, sct, val1, "red", lowest, lowest,
                                                   (lowest === 0? "transparent" : Theme.secondaryColor),
                                                   dayStr);
                            } else if (chartType === 4) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, cell1, last, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                                val2 = Scripts.ouraToNumber(ouraCloud.value(table, cell2, last, -2)); // -1 is_longest==1
                                val3 = Scripts.ouraToNumber(ouraCloud.value(table, cell3, last, -2)); // -1 is_longest==1
                                val4 = Scripts.ouraToNumber(ouraCloud.value(table, cell4, last, -2)); // -1 is_longest==1

                                insertData(0, sct, val1, "DarkGreen", dayStr, val2, "Green",
                                           val3, "LightGreen", val4, "LightYellow",
                                           Scripts.secToHM(val1 + val2 + val3));
                            }

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

                }

                TrendView {
                    id: chart3Summary
                    //width: Theme.iconSizeLarge
                    height: parent.height
                    anchors.bottom: parent.bottom
                    text: qsTr("rate")
                    factor: page.factor
                    maxValue: sleepHBR.maxValue

                    property string scoreStr: sleepHBR.chartColumn

                    function fillData() {
                        var val;
                        averageWeek = ouraCloud.average(sleepHBR.table, sleepHBR.chartColumn, 7);
                        averageMonth = ouraCloud.average(sleepHBR.table, sleepHBR.chartColumn, 30);
                        averageYear = ouraCloud.average(sleepHBR.table, sleepHBR.chartColumn, 365);
                        if (sleepHBR.chartColumn != scoreStr) {
                            average = ouraCloud.average(sleepHBR.table, scoreStr, 7)
                        } else {
                            average = averageWeek;
                        }

                        val = ouraCloud.value(sleepHBR.table, scoreStr); // defaults to yesterday
                        if (val === "-")
                            isValid = false
                        else
                            score = val*1.0;
                    }
                }
            }
            // */
            HistoryChart {
                id: chart3
                chartId: "ch3"
                onBarSelected: {
                    chart1.currentIndex = barNr
                    chart1.positionViewAtIndex(barNr, ListView.Center)
                    chart2.currentIndex = barNr
                    chart2.positionViewAtIndex(barNr, ListView.Center)
                    chart4.currentIndex = barNr
                    chart4.positionViewAtIndex(barNr, ListView.Center)
                }
                onParametersChanged: {
                    storeChartParameters(chartId, chTable, chType,
                                         chCol, chCol2, chCol3,
                                         chCol4, chHigh, chLow,
                                         maxValue, heading)
                }

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

            /*
            SectionHeader {
                id: title4
                text: qsTr("readiness")
            }

            Item {
                id: rowChart4
                height: contentHeight + chartMenu.height
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin

                property int contentHeight: Theme.itemSizeExtraLarge
                property int spacing: Theme.paddingMedium

                ContextMenu {
                    id: chartMenu
                    //active: parent.menuVisible
                    MenuItem {
                        text: qsTr("settings")
                        onClicked: {
                            var dialog = pageContainer.push(
                                        Qt.resolvedUrl("chartSettings.qml"), {
                                            "chartTable": readinessChart.table,
                                            "chartType": readinessChart.chartType,
                                            "chartValue1": readinessChart.chartColumn,
                                            "chartValue2": readinessChart.chartColumn2,
                                            "chartValue3": readinessChart.chartColumn3,
                                            "chartValue4": readinessChart.chartColumn4,
                                            "chartMinBar": readinessChart.chartLowBar,
                                            "chartMaxBar": readinessChart.chartHighBar,
                                            "chartMaxValue": readinessChart.maxValue
                                        })
                            dialog.accepted.connect(function () {
                                var reset = false
                                if (dialog.chartTable !== undefined && dialog.chartType !== undefined) {
                                    if (chartChanged(readinessChart.table, readinessChart.chartType,
                                                     readinessChart.chartColumn, readinessChart.chartMinBar,
                                                     readinessChart.chartMaxBar,
                                                     dialog.chartTable, dialog.chartType, dialog.chartValue1,
                                                     dialog.chartMinBar, dialog.chartMaxBar)) {
                                        readinessChart.table = dialog.chartTable;
                                        readinessChart.chartType = dialog.chartType;
                                        readinessChart.chartColumn = dialog.chartValue1;
                                        readinessChart.chartColumn2 = dialog.chartValue2;
                                        readinessChart.chartColumn3 = dialog.chartValue3;
                                        readinessChart.chartColumn4 = dialog.chartValue4;
                                        readinessChart.chartLowBar = dialog.chartMinBar;
                                        readinessChart.chartHighBar = dialog.chartMaxBar;
                                        title4.text = dialog.chartTitle;
                                        readinessChart.reset();
                                        DataB.storeSettings(DataB.keyChart4Table, readinessChart.table);
                                        DataB.storeSettings(DataB.keyChart4Type, readinessChart.chartType);
                                        DataB.storeSettings(DataB.keyChart4Value1, readinessChart.chartColumn);
                                        DataB.storeSettings(DataB.keyChart4Value2, readinessChart.chartColumn2);
                                        DataB.storeSettings(DataB.keyChart4Value3, readinessChart.chartColumn3);
                                        DataB.storeSettings(DataB.keyChart4Value4, readinessChart.chartColumn4);
                                        DataB.storeSettings(DataB.keyChart4High, readinessChart.chartHighBar);
                                        DataB.storeSettings(DataB.keyChart4Low, readinessChart.chartLowBar);
                                        DataB.storeSettings(DataB.keyChart4Title, title4.text);
                                    }

                                    if (dialog.chartMaxValue !== undefined &&
                                            readinessChart.maxValue !== dialog.chartMaxValue) {
                                        readinessChart.reScale(readinessChart.maxValue, dialog.chartMaxValue);
                                    }
                                }
                            })
                        }
                    }
                }

                BarChart {
                    id: readinessChart
                    anchors.left: parent.left
                    width: parent.width - parent.spacing - chart4Summary.width
                    height: parent.contentHeight
                    orientation: ListView.Horizontal
                    maxValue: 100
                    valueLabelOutside: true
                    onBarPressAndHold: {
                        menuVisible = !menuVisible
                        chartMenu.open(rowChart4)
                    }
                    onBarSelected: {
                        menuVisible = false

                    }

                    BusyIndicator {
                        anchors.centerIn: parent
                        size: BusyIndicatorSize.Medium
                        running: parent.loading
                    }

                    property date firstDate: _dateNow
                    property date lastDate: _dateNow
                    property bool loading: true
                    property bool menuVisible: false
                    property string table: DataB.keyReadiness
                    property string chartColumn: "score"
                    property string chartColumn2: ""
                    property string chartColumn3: ""
                    property string chartColumn4: ""
                    property string chartHighBar: ""
                    property string chartLowBar: ""
                    property string chartType: "ctSingle"

                    function newData2() {
                        // ignore data before lastDate
                        // average over the day readiness periods
                        var val, day, sct;
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first, last, diffMs, diffDays, i;

                        if (ouraCloud.numberOfRecords(table) <= 0) {
                            DataB.log("no " + table + "-data")
                            return;
                        }

                        //readiness.clear();

                        first = ouraCloud.firstDate(table);
                        console.log("eka " + first.toDateString())
                        if (first < firstDate) {
                            firstDate = first;
                        }
                        if (chartData.count === 0) {
                            lastDate = first;
                        }
                        last = lastDate;

                        if (firstDate.getFullYear() > 2000) {
                            diffMs = now.getTime() - lastDate.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else {
                            DataB.log("first date in " + table + "-data from year " +
                                      firstDate.getFullYear())
                        }

                        DataB.log("readiness chart new " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + ouraCloud.lastDate(table).getDate() + "." + (ouraCloud.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        for (i=0; i<diffDays; i++) {
                            val = ouraCloud.average(table, chartColumn, 1, last.getFullYear(),
                                               last.getMonth() + 1, last.getDate());

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
                        DataB.log("readiness chart done " + i + " " + firstDate + " - " + lastDate);

                        loading = false;
                        positionViewAtEnd();

                        return;
                    }

                    function oldData2() {
                        var table = DataB.keyReadiness, chartColumn = "score";
                        var val, diffMs, diffDays, sct;
                        var first, last, dayMs = 24*60*60*1000, i=0;

                        first = ouraCloud.firstDate(table);

                        if (count === 0) {
                            last = new Date();
                            if (first.getFullYear() < 10) {
                                first = last;
                            }
                            lastDate = last;
                        } else if (firstDate <= first) {
                            return;
                        } else {
                            last = firstDate;
                            last.setTime(last.getTime() - dayMs);
                        }

                        diffMs = last.getTime() - first.getTime();
                        diffDays = Math.ceil(diffMs/dayMs);

                        while (i< diffDays) {
                            val = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last, 0));
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));

                            insertData(0, sct, val, Theme.highlightColor, Scripts.dayStr(last.getDay()));

                            i++;
                            if (i === 300) {
                                console.log("300 luuppia " + firstDate.toDateString())
                            }
                            last.setTime(last.getTime() - dayMs);
                        }
                        last.setTime(last.getTime() + dayMs);
                        firstDate = last;

                        positionViewAtEnd();

                        return;
                    }

                    function reset() {
                        chartData.clear();
                        loading = true;
                        oldData();
                        loading = false;
                        return;
                    }

                    //*
                    function newData() {
                        // ignore data before lastDate
                        // average over the day readiness periods
                        var val1, val2, val3, val4, highBar, lowBar, day, sct;
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
                        // poista kokeiluajan jälkeen
                        if (firstDate.getFullYear() >= 2000) {
                            diffMs = now.getTime() - lastDate.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else if (first.getFullYear() >= 0 && first.getFullYear() < 100) {
                            first.setFullYear(first.getFullYear() + 2000);
                            last.setFullYear(last.getFullYear() + 2000);
                            diffMs = now.getTime() - lastDate.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else {
                            DataB.log("first date in " + table + "-data from year " +
                                      firstDate.getFullYear())
                            return;
                        }

                        console.log("readiness chart " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + ouraCloud.lastDate(table).getDate() + "." + (ouraCloud.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        console.log("dDays " + diffDays + " " + chartType)
                        for (i=0; i<diffDays; i++) {
                            //console.log("______ " + chartType + " " + chartColumn)
                            day = Scripts.dayStr(last.getDay());
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));

                            if (chartType === DataB.chartTypeSingle) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));

                                // overwrite the last date
                                if (i === 0 && count > 0) {
                                    chartData.set(i, {"barValue": val1})
                                } else {
                                    addData(sct, val1, Theme.highlightColor, day);
                                }
                                //console.log("single " + val1 + " i=" + i)
                            } else if (chartType === DataB.chartTypeMin
                                       || chartType === DataB.chartTypeMaxmin) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));
                                lowBar = Scripts.ouraToNumber(ouraCloud.value(table, chartLowBar, last));
                                if (chartType === DataB.chartTypeMin) {
                                    highBar = lowBar;
                                } else {
                                    highBar = Scripts.ouraToNumber(ouraCloud.value(table, chartHighBar, last));
                                }

                                // overwrite the last date
                                if (i === 0 && count > 0) {
                                    chartData.set(count -1, {"barValue": val1, "localMax": highBar,
                                                      "localMin": lowBar })
                                } else {
                                    addDataVariance(sct, val1, "red", highBar, lowBar,
                                                    (lowBar === 0? "transparent" : Theme.secondaryColor),
                                                    day);
                                }
                                console.log("min/max " + val1 + "," + lowBar + " " + highBar + " i=" + i)
                            } else if (chartType === DataB.chartTypeSleep) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                                val2 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn2, last, -2)); // -1 is_longest==1
                                val3 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn3, last, -2)); // -1 is_longest==1
                                val4 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn4, last, -2)); // -1 is_longest==1
                                if (i === 0 && count > 0) {
                                    chartData.set(count - 1, {"barValue": val1, "bar2Value": val2,
                                                  "bar3Value": val3, "bar4Value": val4, "valLabel":
                                                      Scripts.secToHM(val1 + val2 + val3) })
                                } else {
                                    addData(sct, val1, "DarkGreen", day, val2, "Green", val3,
                                            "LightGreen", val4, "LightYellow",
                                            Scripts.secToHM(val1 + val2 + val3));
                                }
                                //console.log("unityypit" + i)
                            } else {
                                if (i === 0) {
                                    log("unknown chart type " + chartType)
                                }
                            }

                            last.setTime(last.getTime() + dayMs);
                        }

                        if (i>0) {
                            last.setTime(last.getTime() - dayMs);
                        }

                        lastDate = last;
                        console.log("readiness chart done " + i + " " + firstDate + " - " + lastDate);

                        loading = false;
                        positionViewAtEnd();

                        return;
                    }

                    function oldData() {
                        var val1, val2, val3, val4, highBar, lowBar, diffMs, diffDays, dayStr, sct;
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
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));
                            dayStr = Scripts.dayStr(last.getDay());

                            if (chartType === DataB.chartTypeSingle) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));
                                insertData(0, sct, val1, Theme.highlightColor, dayStr);
                            } else if (chartType === DataB.chartTypeMin || chartType === DataB.chartTypeMaxmin) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last));
                                lowBar = Scripts.ouraToNumber(ouraCloud.value(table, chartLowBar, last));
                                if (chartType === DataB.chartTypeMin) {
                                    highBar = lowBar;
                                } else {
                                    highBar = Scripts.ouraToNumber(ouraCloud.value(table, chartHighBar, last));
                                }

                                insertDataVariance(0, sct, val1, "red", highBar, lowBar,
                                                   (lowBar === 0? "transparent" : Theme.secondaryColor),
                                                   dayStr);
                            } else if (chartType === DataB.chartTypeSleep) {
                                val1 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn, last, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                                val2 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn2, last, -2)); // -1 is_longest==1
                                val3 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn3, last, -2)); // -1 is_longest==1
                                val4 = Scripts.ouraToNumber(ouraCloud.value(table, chartColumn4, last, -2)); // -1 is_longest==1

                                insertData(0, sct, val1, "DarkGreen", dayStr, val2, "Green",
                                           val3, "LightGreen", val4, "LightYellow",
                                           Scripts.secToHM(val1 + val2 + val3));
                            }

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

                    function reScale(oldMax, newMax) {
                        readinessChart.maxValue = newMax;
                        return;
                    }

                    // /
                }

                TrendView {
                    id: chart4Summary
                    //width: Theme.iconSizeLarge
                    anchors.right: parent.right
                    height: parent.contentHeight
                    text: qsTr("score")
                    factor: page.factor
                    maxValue: readinessChart.maxValue

                    property string scoreStr: readinessChart.chartColumn

                    function fillData() {
                       var val;
                        averageWeek = ouraCloud.average(readinessChart.table, readinessChart.chartColumn, 7);
                        averageMonth = ouraCloud.average(readinessChart.table, readinessChart.chartColumn, 30);
                        averageYear = ouraCloud.average(readinessChart.table, readinessChart.chartColumn, 365);
                        //average = ouraCloud.average(readinessChart.table, "score"); // defaults to previous 7 days
                        //val = ouraCloud.value(readinessChart.table, "score"); // defaults to yesterday
                        //if (val === "-")
                        //    isValid = false
                        //else
                        //    score = val*1.0;
                    }
                }
            }
            // */
            HistoryChart {
                id: chart4
                chartId: "ch4"
                onBarSelected: {
                    chart2.currentIndex = barNr
                    chart2.positionViewAtIndex(barNr, ListView.Center)
                    chart3.currentIndex = barNr
                    chart3.positionViewAtIndex(barNr, ListView.Center)
                    chart1.currentIndex = barNr
                    chart1.positionViewAtIndex(barNr, ListView.Center)
                }
                onParametersChanged: {
                    storeChartParameters(chartId, chTable, chType,
                                         chCol, chCol2, chCol3,
                                         chCol4, chHigh, chLow,
                                         maxValue, heading)
                }

                function setUpChart() {
                    heading = DataB.getSetting(chartId + DataB.keyChartTitle, qsTr("readiness"));
                    chTable = DataB.getSetting(chartId + DataB.keyChartTable, DataB.keyReadiness);
                    chType = DataB.getSetting(chartId + DataB.keyChartType, DataB.chartTypeSingle);
                    chCol = DataB.getSetting(chartId + DataB.keyChartCol, "score");
                    chCol2 = DataB.getSetting(chartId + DataB.keyChartCol2, "");
                    chCol3 = DataB.getSetting(chartId + DataB.keyChartCol3, "");
                    chCol4 = DataB.getSetting(chartId + DataB.keyChartCol4, "");
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
