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

    property real factor: 1.1
    property date _dateNow: new Date()
    property bool _reloaded: false

    Connections {
        target: ouraCloud
        onFinishedActivity: {
            if (_reloaded) {
                activityChart.reset()
                chart1Summary.fillData()
            } else {
                fillActivityData()
            }
        }
        onFinishedBedTimes: {
            fillBedTimeData()
        }
        onFinishedReadiness: {
            if (_reloaded) {
               readinessChart.reset()
                chart4Summary.fillData()
            } else {
                fillReadinessData()
            }
        }
        onFinishedSleep: {
            if (_reloaded) {
                sleepType.reset()
                chart2Summary.fillData()
                sleepHBR.reset()
                chart3Summary.fillData()
            } else {
                fillSleepData()
            }
        }
    }

    Connections {
        target: applicationWindow
        onStoredDataRead: {
            activityChart.oldData();
            sleepType.oldData();
            sleepHBR.oldData();
            readinessChart.oldData();
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

                    property date firstDate: _dateNow
                    property date lastDate: _dateNow
                    property string table: DataB.keyActivity
                    property string cell: "cal_active"

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

                        first = ouraCloud.firstDate(table);
                        console.log("eka " + first.toDateString() + " " + first.getHours() + ":" + first.getMinutes() + ":" + first.getSeconds() + "  " + first.getUTCHours())
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

                        DataB.log("activity chart " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + ouraCloud.lastDate(table).getDate() + "." + (ouraCloud.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        for (i=0; i<diffDays; i++) {
                            val = Scripts.ouraToNumber(ouraCloud.value(table, cell, last));

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
                            val = Scripts.ouraToNumber(ouraCloud.value(table, cell, last));
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
                        oldData();
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

                    function fillData() {
                        var val;
                        ouraCloud.setDateConsidered();
                        averageWeek = ouraCloud.average(activityChart.table, activityChart.cell, 7);
                        averageMonth = ouraCloud.average(activityChart.table, activityChart.cell, 30);
                        averageYear = ouraCloud.average(activityChart.table, activityChart.cell, 365);
                        average = ouraCloud.average(activityChart.table, "score"); // defaults to previous 7 days
                        val = ouraCloud.value(activityChart.table, "score"); // defaults to yesterday
                        if (val === "-")
                            isValid = false
                        else
                            score = val*1.0;
                    }
                }
            }

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

                    property date firstDate: _dateNow
                    property date lastDate: _dateNow
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
                        oldData();
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

                    function fillData() {
                        var val;
                        averageWeek = ouraCloud.average(sleepType.table, "total", 7);
                        averageMonth = ouraCloud.average(sleepType.table, "total", 30);
                        averageYear = ouraCloud.average(sleepType.table, "total", 365);
                        average = ouraCloud.average(sleepType.table, "score"); // defaults to previous 7 days
                        val = ouraCloud.value(sleepType.table, "score"); // defaults to yesterday
                        if (val === "-")
                            isValid = false
                        else
                            score = val*1.0;
                    }
                }
            }

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

                    property date firstDate: _dateNow
                    property date lastDate: _dateNow
                    property string table: DataB.keySleep
                    property string cell: "hr_average"
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
                            val = Scripts.ouraToNumber(ouraCloud.value(table, cell, last));
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
                            val = Scripts.ouraToNumber(ouraCloud.value(table, cell, last));
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
                        oldData();
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

                    function fillData() {
                        var val;
                        averageWeek = ouraCloud.average(sleepHBR.table, sleepHBR.cell, 7);
                        averageMonth = ouraCloud.average(sleepHBR.table, sleepHBR.cell, 30);
                        averageYear = ouraCloud.average(sleepHBR.table, sleepHBR.cell, 365);
                        average = averageWeek;
                        val = ouraCloud.value(sleepHBR.table, sleepHBR.cell); // defaults to yesterday
                        if (val === "-")
                            isValid = false
                        else
                            score = val*1.0;
                    }
                }
            }

            SectionHeader {
                text: qsTr("readiness")
            }

            Row {
                height: Theme.itemSizeExtraLarge
                spacing: Theme.paddingMedium
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin

                BarChart {
                    id: readinessChart
                    width: parent.width - parent.spacing - chart4Summary.width
                    height: parent.height
                    orientation: ListView.Horizontal
                    maxValue: 100
                    valueLabelOutside: true

                    property date firstDate: _dateNow
                    property date lastDate: _dateNow
                    property string table: DataB.keyReadiness
                    property string cell: "score"

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
                            val = ouraCloud.average(table, cell, 1, last.getFullYear(),
                                               last.getMonth() + 1, last.getDate());
                            day = Scripts.dayStr(last.getDay());
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));
                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val})
                            } else {
                                addData(sct, val, Theme.highlightColor, day);
                            }
                            last.setTime(last.getTime() + dayMs);
                        }

                        if (i>0) {
                            last.setTime(last.getTime() - dayMs);
                        }

                        lastDate = last;
                        DataB.log("readiness chart done " + i + " " + firstDate + " - " + lastDate);

                        positionViewAtEnd();

                        return;
                    }

                    function oldData() {
                        var table = DataB.keyReadiness, cell = "score";
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
                            val = Scripts.ouraToNumber(ouraCloud.value(table, cell, last, 0));
                            sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));

                            insertData(0, sct, val, Theme.highlightColor, Scripts.dayStr(last.getDay()));

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
                        oldData();
                        return;
                    }
                }

                TrendView {
                    id: chart4Summary
                    //width: Theme.iconSizeLarge
                    anchors.bottom: parent.bottom
                    height: parent.height
                    text: qsTr("score")
                    factor: page.factor
                    maxValue: readinessChart.maxValue

                    function fillData() {
                       var val;
                        averageWeek = ouraCloud.average(readinessChart.table, readinessChart.cell, 7);
                        averageMonth = ouraCloud.average(readinessChart.table, readinessChart.cell, 30);
                        averageYear = ouraCloud.average(readinessChart.table, readinessChart.cell, 365);
                        average = ouraCloud.average(readinessChart.table, "score"); // defaults to previous 7 days
                        val = ouraCloud.value(readinessChart.table, "score"); // defaults to yesterday
                        if (val === "-")
                            isValid = false
                        else
                            score = val*1.0;
                    }
                }
            }

            TextArea {
                id: jsonString
                width: parent.width
                readOnly: true
            }

        }
        VerticalScrollDecorator {}
    }

    function fillActivityData() {
        console.log("....activity....")
        ouraCloud.setDateConsidered();
        activityChart.newData();
        chart1Summary.fillData();
    }

    function fillBedTimeData() {
    }

    function fillReadinessData() {
        console.log("....readiness....")
        ouraCloud.setDateConsidered();
        readinessChart.newData();
        chart4Summary.fillData();
    }

    function fillSleepData() {
        console.log("....sleep....")
        ouraCloud.setDateConsidered();
        sleepType.newData();
        chart2Summary.fillData();
        sleepHBR.newData();
        chart3Summary.fillData();
    }

}
