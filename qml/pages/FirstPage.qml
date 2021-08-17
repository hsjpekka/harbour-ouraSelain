import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../utils/datab.js" as DataB

Page {
    id: page

    allowedOrientations: Orientation.All

    signal refreshOuraCloud()
    signal openSettings()

    property real factor: 1.1
    property date _dateNow: new Date()

    Connections {
        target: oura
        onFinishedActivity: {
            fillActivityData()
        }
        onFinishedBedTimes: {
            fillBedTimeData()
        }
        onFinishedReadiness: {
            fillReadinessData()
        }
        onFinishedSleep: {
            fillSleepData()
        }
    }

    Connections {
        target: applicationWindow
        onStoredDataRead: {
            activityChart.oldData();
            sleepType.oldData();
            sleepHBR.oldData();
            readiness.oldData();
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
                                           "summaryDate": oura.lastDate(DataB.keyActivity, 1) //
                                       })
                }
            }
            MenuItem {
                text: qsTr("Readiness")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("readinessPage.qml"), {
                                           "summaryDate": oura.lastDate(DataB.keyReadiness, 1)
                                       })
                }
            }
            MenuItem {
                text: qsTr("Sleep")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("sleepPage.qml"), {
                                           "summaryDate": oura.lastDate(DataB.keySleep, 1)
                                       })
                }
            }
            MenuItem {
                text: "poista oura-taulukko"
                onClicked: {
                    DataB.removeTableCloud()
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
                    setUpNow()
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
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin

                BarChart {
                    id: activityChart
                    width: parent.width - chart1Summary.width
                    height: Theme.itemSizeHuge
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
                        var val, day;
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first, last, diffMs, diffDays, i;

                        if (oura.numberOfRecords(table) <= 0) {
                            DataB.log("no " + table + "-data")
                            return;
                        }

                        first = oura.firstDate(table);
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

                        DataB.log("activity chart " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + oura.lastDate(table).getDate() + "." + (oura.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        for (i=0; i<diffDays; i++) {
                            val = oura.value(table, cell, last);
                            if (val === "-")
                                val = 0;
                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val})
                            } else {
                                day = dayStr(last.getDay());
                                addData(val, Theme.highlightColor, day);
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
                        var val, diffMs, diffDays;
                        var first, last, dayMs = 24*60*60*1000, i=0;

                        first = oura.firstDate(table);
                        if (firstDate <= first) {
                            return;
                        }

                        if (count === 0) {
                            last = new Date();
                            firstDate = last;
                            lastDate = last;
                        } else {
                            last = firstDate;
                            last.setTime(last.getTime() - dayMs);
                        }

                        diffMs = last.getTime() - first.getTime();
                        diffDays = Math.ceil(diffMs/dayMs);

                        while (i< diffDays) {
                            val = oura.value(table, cell, last);
                            if (val === "-")
                                val = 0;
                            insertData(0, val, Theme.highlightColor, dayStr(last.getDay()));

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

                    function fillData() {
                        var table = DataB.keyActivity, cell = "cal_active";
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first = now, diffMs, diffDays, i, val;

                        if (oura.numberOfRecords(table) <= 0) {
                            DataB.log("no " + table + "-data")
                            return;
                        }

                        activityChart.clear();

                        first = oura.firstDate(table);
                        if (first.getFullYear() > 2000) {
                            diffMs = now.getTime() - first.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else {
                            DataB.log("first date in " + table + "-data from year " +
                                      first.getFullYear())
                        }
                        firstDate = first;
                        lastDate = oura.lastDate(table);

                        for (i=0; i<diffDays; i++) {
                            val = oura.value(table, cell, first);
                            //DataB.log("adding " + val);
                            //day = ;
                            addData(val, Theme.highlightColor, dayStr(first.getDay()));
                            first.setTime(first.getTime() + dayMs);
                        }

                        return;
                    }

                    function updateBars() {
                        var table = DataB.keyActivity, cell = "cal_active";
                        var val;
                        var now = new Date(), dayMs = 24*60*60*1000, i=0;

                        if (firstDate <= oura.firstDate(table)) {
                            return;
                        }

                        now.setFullYear(firstDate.getFullYear());
                        now.setMonth(firstDate.getMonth());
                        now.setDate(firstDate.getDate());
                        now.setHour(5);
                        while (firstDate > oura.firstDate(table) && i < 300) {
                            now.setTime(now.getTime()- dayMs);
                            val = oura.value(table, cell, now, 0);
                            if (val === "-")
                                val = 0;
                            insertData(0, val, Theme.highlightColor, dayStr(now.getDay()));

                            firstDate.setFullYear(now.getFullYear());
                            firstDate.setMonth(now.getMonth());
                            firstDate.setDate(now.getDate());
                            i++;
                            if (i === 300) {
                                console.log("300 luuppia " + firstDate.toDateString())
                            }
                        }
                    }
                }

                Column {
                    id: chart1Summary
                    width: Theme.iconSizeLarge

                    property int average: 0
                    property int score: 0
                    property bool isValid: true

                    Label {
                        text: qsTr("score")
                        color: Theme.secondaryHighlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: parent.isValid? parent.score : "-"
                        color: Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Icon {
                        source: parent.score === parent.average? "image://theme/icon-s-asterisk" :
                                                   "image://theme/icon-s-arrow"
                        rotation: parent.score > parent.average? 180 : 0
                        color: (parent.score > parent.average*factor*factor ||
                                parent.score < parent.average/factor/factor) ?
                                   Theme.primaryColor : Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: parent.isValid
                    }

                    function fillData() {
                        var val;
                        oura.setDateConsidered();
                        average = oura.average(DataB.keyActivity, "score"); // defaults to previous 7 days
                        val = oura.value(DataB.keyActivity, "score"); // defaults to yesterday
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
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin

                BarChart {
                    id: sleepType
                    width: parent.width - chart2Summary.width
                    height: Theme.itemSizeHuge
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
                        var val1, val2, val3, val4, day;
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first, last, diffMs, diffDays, i;

                        if (oura.numberOfRecords(table) <= 0) {
                            DataB.log("no " + table + "-data")
                            return;
                        }

                        first = oura.firstDate(table);
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

                        DataB.log("sleep chart " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + oura.lastDate(table).getDate() + "." + (oura.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        for (i=0; i<diffDays; i++) {
                            val1 = oura.value(table, cell1, last, -2); // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = oura.value(table, cell2, last, -2); // -1 is_longest==1
                            val3 = oura.value(table, cell3, last, -2); // -1 is_longest==1
                            val4 = oura.value(table, cell4, last, -2); // -1 is_longest==1
                            if (val1 === "-")
                                val1 = 0;
                            if (val2 === "-")
                                val2 = 0;
                            if (val3 === "-")
                                val3 = 0;
                            if (val4 === "-")
                                val4 = 0;

                            day = dayStr(last.getDay());
                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val1, "bar2Value": val2,
                                              "bar3Value": val3, "bar4Value": val4, "valLabel":
                                                  secToHM(val1*1.0 + val2*1.0 + val3*1.0) })
                            } else {
                                addData(val1, "DarkGreen", day, val2, "Green", val3,
                                        "LightGreen", val4, "LightYellow",
                                        secToHM(val1*1.0 + val2*1.0 + val3*1.0));
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
                        var val1, val2, val3, val4, diffMs, diffDays;
                        var first, last, dayMs = 24*60*60*1000, day, i=0;

                        first = oura.firstDate(table);
                        if (firstDate <= first) {
                            return;
                        }

                        if (count === 0) {
                            last = new Date();
                            firstDate = last;
                            lastDate = last;
                        } else {
                            last = firstDate;
                            last.setTime(last.getTime() - dayMs);
                        }

                        diffMs = last.getTime() - first.getTime();
                        diffDays = Math.ceil(diffMs/dayMs);

                        while (i< diffDays) {
                            val1 = oura.value(table, cell1, first, -2); // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = oura.value(table, cell2, first, -2); // -1 is_longest==1
                            val3 = oura.value(table, cell3, first, -2); // -1 is_longest==1
                            val4 = oura.value(table, cell4, first, -2); // -1 is_longest==1
                            if (val1 === "-")
                                val1 = 0;
                            if (val2 === "-")
                                val2 = 0;
                            if (val3 === "-")
                                val3 = 0;
                            if (val4 === "-")
                                val4 = 0;

                            day = dayStr(first.getDay());
                            insertData(0, val1, "DarkGreen", day, val2, "Green", val3,
                                       "LightGreen", val4, "LightYellow",
                                       secToHM(val1+val2+val3));

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

                    function fillData() {
                        var table = DataB.keySleep, cell = "deep", cell2 = "light", cell3 = "rem", cell4 = "awake";
                        var now = new Date(), dayMs = 24*60*60*1000, maxSleepHr = 10*60*60*1000;
                        var first, diffDays, i, day, diffMs;
                        var val, val2, val3, val4;

                        if (oura.numberOfRecords(table) <= 0) {
                            DataB.log("no " + table + "-data")
                            return;
                        }

                        sleepType.clear();

                        first = oura.firstDate(table);
                        if (first.getFullYear() > 2000) {
                            diffMs = now.getTime() - first.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else {
                            DataB.log("first date in " + table + "-data from year " +
                                      first.getFullYear())
                        }
                        firstDate = first;
                        lastDate = oura.lastDate(table);

                        for (i=0; i<diffDays; i++) {
                            val = oura.value(table, cell, first, -2)*1.0; // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = oura.value(table, cell2, first, -2)*1.0; // -1 is_longest==1
                            val3 = oura.value(table, cell3, first, -2)*1.0; // -1 is_longest==1
                            val4 = oura.value(table, cell4, first, -2)*1.0; // -1 is_longest==1
                            day = dayStr(first.getDay());
                            addData(val, "DarkGreen", day, val2, "Green", val3, "LightGreen", val4, "LightYellow", secToHM(val+val2+val3));
                            first.setTime(first.getTime() + dayMs);
                        }
                        //DataB.log("sleep score done")

                        return;
                    }

                    function updateBars() {
                        var table = DataB.keySleep, cell = "deep", cell2 = "light", cell3 = "rem", cell4 = "awake";
                        var val, val2, val3, val4, lowest, day;
                        var now = new Date(), dayMs = 24*60*60*1000, i=0;

                        if (firstDate <= oura.firstDate(table)) {
                            return;
                        }

                        now.setFullYear(firstDate.getFullYear());
                        now.setMonth(firstDate.getMonth());
                        now.setDate(firstDate.getDate());
                        now.setHour(5);
                        while (firstDate > oura.firstDate(table) && i < 300) {
                            now.setTime(now.getTime()- dayMs);
                            val = oura.value(table, cell, now, -2)*1.0; // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = oura.value(table, cell2, now, -2)*1.0; // -1 is_longest==1
                            val3 = oura.value(table, cell3, now, -2)*1.0; // -1 is_longest==1
                            val4 = oura.value(table, cell4, now, -2)*1.0; // -1 is_longest==1
                            if (val === "-")
                                val = 0;
                            if (val2 === "-")
                                val2 = 0;
                            if (val3 === "-")
                                val3 = 0;
                            if (val4 === "-")
                                val4 = 0;

                            day = dayStr(first.getDay());
                            insertData(0, val, "DarkGreen", day, val2, "Green", val3, "LightGreen", val4, "LightYellow", secToHM(val+val2+val3));

                            firstDate.setFullYear(now.getFullYear());
                            firstDate.setMonth(now.getMonth());
                            firstDate.setDate(now.getDate());
                            i++;
                            if (i === 300) {
                                console.log("300 luuppia " + firstDate.toDateString())
                            }
                        }
                    }

                }

                Column {
                    id: chart2Summary
                    width: Theme.iconSizeLarge

                    property int average: 0
                    property int score: 0
                    property bool isValid: true

                    Label {
                        text: qsTr("score")
                        color: Theme.secondaryHighlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: parent.isValid? parent.score : "-"
                        color: Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Icon {
                        source: parent.score === parent.average? "image://theme/icon-s-asterisk" :
                                                   "image://theme/icon-s-arrow"
                        rotation: parent.score > parent.average? 180 : 0
                        color: (parent.score > parent.average*factor ||
                                parent.score < parent.average/factor) ?
                                   Theme.primaryColor : Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: parent.isValid
                    }

                    function fillData() {
                        var val;
                        average = oura.average(DataB.keySleep, "score"); // defaults to previous 7 days
                        val = oura.value(DataB.keySleep, "score"); // defaults to yesterday
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
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin

                BarChart {
                    id: sleepHBR
                    width: parent.width - chart3Summary.width
                    height: Theme.itemSizeLarge
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
                        var val, lowest, day;
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first, last, diffMs, diffDays, i;

                        if (oura.numberOfRecords(table) <= 0) {
                            DataB.log("no " + table + "-data")
                            return;
                        }

                        first = oura.firstDate(table);
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

                        DataB.log("hbr chart " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + oura.lastDate(table).getDate() + "." + (oura.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        for (i=0; i<diffDays; i++) {
                            val = oura.value(table, cell, last);
                            if (val === "-")
                                val = 0;
                            lowest = oura.value(table, cellLow, last);
                            if (lowest === "-")
                                lowest = 0;

                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val, "localMax": lowest,
                                                  "localMin": lowest })
                            } else {
                                day = dayStr(first.getDay());
                                addDataVariance(val, "red", lowest, lowest, (lowest === 0? "transparent" : Theme.secondaryColor), day);
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
                        var val, lowest, diffMs, diffDays;
                        var first, last, dayMs = 24*60*60*1000, i=0;

                        first = oura.firstDate(table);
                        if (firstDate <= first) {
                            return;
                        }

                        if (count === 0) {
                            last = new Date();
                            firstDate = last;
                            lastDate = last;
                        } else {
                            last = firstDate;
                            last.setTime(last.getTime() - dayMs);
                        }

                        diffMs = last.getTime() - first.getTime();
                        diffDays = Math.ceil(diffMs/dayMs);

                        while (i < diffDays) {
                            val = oura.value(table, cell, last);
                            if (val === "-")
                                val = 0;
                            lowest = oura.value(table, cellLow, last);
                            if (lowest === "-")
                                lowest = 0;
                            insertDataVariance(0, val, "red", lowest, lowest, (lowest === 0? "transparent" : Theme.secondaryColor), day);

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

                    function fillData() {
                        var table = DataB.keySleep, cell = "hr_average", cellLow = "hr_lowest";
                        var val, lowest, day;
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first = now, diffMs, diffDays, i;

                        if (oura.numberOfRecords(table) <= 0) {
                            DataB.log("no " + table + "-data")
                            return;
                        }

                        sleepHBR.clear();

                        first = oura.firstDate(table);
                        if (first.getFullYear() > 2000) {
                            diffMs = now.getTime() - first.getTime();
                            diffDays = Math.ceil(diffMs/dayMs);
                        } else {
                            DataB.log("first date in " + table + "-data from year " +
                                      first.getFullYear())
                        }
                        firstDate = first;
                        lastDate = oura.lastDate(table);

                        //DataB.log("hbr " + first.getDate() + "." + first.getMonth() + ". - " + now.getDate() + "." + now.getMonth() + ".")
                        for (i=0; i<diffDays; i++) {
                            val = oura.value(table, cell, first, 0);
                            if (val === "-")
                                val = 0;
                            lowest = oura.value(table, cellLow, first, 0);
                            if (lowest === "-")
                                lowest = 0;
                            day = dayStr(first.getDay());
                            addDataVariance(val, "red", lowest, lowest, (lowest === 0? "transparent" : Theme.secondaryColor), day);
                            first.setTime(first.getTime() + dayMs);
                        }
                        //DataB.log("hbr done");

                        return;
                    }

                    function updateBars() {
                        var table = DataB.keySleep, cell = "hr_average", cellLow = "hr_lowest";
                        var val, lowest, day;
                        var now = new Date(), dayMs = 24*60*60*1000, i=0;

                        if (firstDate <= oura.firstDate(table)) {
                            return;
                        }

                        now.setFullYear(firstDate.getFullYear());
                        now.setMonth(firstDate.getMonth());
                        now.setDate(firstDate.getDate());
                        now.setHour(5);
                        while (firstDate > oura.firstDate(table) && i < 300) {
                            now.setTime(now.getTime()- dayMs);
                            val = oura.value(table, cell, now, 0);
                            if (val === "-")
                                val = 0;
                            lowest = oura.value(table, cellLow, now, 0);
                            if (lowest === "-")
                                lowest = 0;
                            day = dayStr(now.getDay());
                            insertDataVariance(0, val, "red", lowest, lowest, (lowest === 0? "transparent" : Theme.secondaryColor), day);

                            firstDate.setFullYear(now.getFullYear());
                            firstDate.setMonth(now.getMonth());
                            firstDate.setDate(now.getDate());
                            i++;
                            if (i === 300) {
                                console.log("300 luuppia " + firstDate.toDateString())
                            }
                        }
                    }
                }

                Column {
                    id: chart3Summary
                    width: Theme.iconSizeLarge

                    property int average: 0
                    property int score: 0
                    property bool isValid: true

                    Label {
                        text: qsTr("rate")
                        color: Theme.secondaryHighlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: parent.isValid? parent.score : "-"
                        color: Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Icon {
                        source: parent.score === parent.average? "image://theme/icon-s-asterisk" :
                                                   "image://theme/icon-s-arrow"
                        rotation: parent.score > parent.average? 180 : 0
                        color: (parent.score > parent.average*factor ||
                                parent.score < parent.average/factor) ?
                                   Theme.primaryColor : Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: parent.isValid
                    }

                    function fillData() {
                        var val;
                        average = oura.average(DataB.keySleep, "hr_average"); // defaults to previous 7 days
                        val = oura.value(DataB.keySleep, "hr_average"); // defaults to yesterday
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
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin

                BarChart {
                    id: readiness
                    width: parent.width - chart4Summary.width
                    height: Theme.itemSizeLarge
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
                        var val, day;
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first, last, diffMs, diffDays, i;

                        if (oura.numberOfRecords(table) <= 0) {
                            DataB.log("no " + table + "-data")
                            return;
                        }

                        //readiness.clear();

                        first = oura.firstDate(table);
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

                        DataB.log("readiness chart " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + ". - " + oura.lastDate(table).getDate() + "." + (oura.lastDate(table).getMonth() + 1) + ". = " + diffDays)
                        for (i=0; i<diffDays; i++) {
                            val = oura.average(table, cell, last.getFullYear(),
                                               last.getMonth() + 1, last.getDate(), 1);
                            day = dayStr(last.getDay());
                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val})
                            } else {
                                addData(val, Theme.highlightColor, day);
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
                        var val, diffMs, diffDays;
                        var first, last, dayMs = 24*60*60*1000, i=0;

                        first = oura.firstDate(table);
                        if (firstDate <= first) {
                            return;
                        }

                        if (count === 0) {
                            last = new Date();
                            firstDate = last;
                            lastDate = last;
                        } else {
                            last = firstDate;
                            last.setTime(last.getTime() - dayMs);
                        }

                        diffMs = last.getTime() - first.getTime();
                        diffDays = Math.ceil(diffMs/dayMs);

                        while (i< diffDays) {
                            val = oura.value(table, cell, last, 0);
                            if (val === "-")
                                val = 0;
                            insertData(0, val, Theme.highlightColor, dayStr(last.getDay()));

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
                }

                Column {
                    id: chart4Summary
                    width: Theme.iconSizeLarge

                    property int average: 0
                    property int score: 0
                    property bool isValid: true

                    Label {
                        text: qsTr("score")
                        color: Theme.secondaryHighlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: parent.isValid? parent.score : "-"
                        color: Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Icon {
                        source: parent.score === parent.average? "image://theme/icon-s-asterisk" :
                                                   "image://theme/icon-s-arrow"
                        rotation: parent.score > parent.average? 180 : 0
                        color: (parent.score > parent.average*factor ||
                                parent.score < parent.average/factor) ?
                                   Theme.highlightColor : Theme.secondaryHighlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: parent.isValid
                    }

                    function fillData() {
                       var val;
                        average = oura.average(DataB.keyReadiness, "score"); // defaults to previous 7 days
                        val = oura.value(DataB.keyReadiness, "score"); // defaults to yesterday
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

    function dayStr(day){
        var result;
        if (day === 0)
            result = qsTr("Sun")
        else if (day === 1)
            result = qsTr("Mon")
        else if (day === 2)
            result = qsTr("Tue")
        else if (day === 3)
            result = qsTr("Wed")
        else if (day === 4)
            result = qsTr("Thu")
        else if (day === 5)
            result = qsTr("Fri")
        else if (day === 6)
            result = qsTr("Sat");
        return result
    }

    function fillActivityData() {
        console.log("....activity....")
        oura.setDateConsidered();
        activityChart.newData();
        chart1Summary.fillData();
    }

    function fillBedTimeData() {
    }

    function fillReadinessData() {
        console.log("....readiness....")
        oura.setDateConsidered();
        readiness.newData();
        chart4Summary.fillData();
    }

    function fillSleepData() {
        console.log("....sleep....")
        oura.setDateConsidered();
        sleepType.newData();
        chart2Summary.fillData();
        sleepHBR.newData();
        chart3Summary.fillData();
    }

    function secToHM(sec) {
        var hours, mins, result;

        mins = (sec-sec%60)/60;
        hours = (mins - mins%60)/60;
        mins = mins - hours*60;

        result = hours + ":";
        if (mins < 10) {
            result += "0";
        }
        result += mins;

        return result;
    }

}
