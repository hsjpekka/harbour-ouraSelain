import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../utils/datab.js" as DataB

Page {
    id: page

    allowedOrientations: Orientation.All
    onStatusChanged: {
        var str
        if (page.status === PageStatus.Inactive) {
            str = "inactive"
        } else if (page.status === PageStatus.Active) {
            str = "FirstPage active\n\n "
        } else if (page.status === PageStatus.Activating) {
            str = "activating"
        } else if (page.status === PageStatus.Deactivating) {
            str = "deactivating"
        }
        DataB.log("page status - " + str)
    }

//    property var db: null
//    property date latestStored: new Date(0)
//  property int  contents: 0 // 0 - summaries, 1 - activity, 2 - sleep, 3 - readiness, 4 - bed times
//    property string personalAccessToken: ""

    /*
    function downloadOuraCloud(){
        oura.refreshDownloads();
        return;
    }

    function readDb() {
        if(db === null) {
            try {
                db = LocalStorage.openDatabaseSync("oura", "0.1", "daily records", 10000);
            } catch (err) {
                DataB.log("Error in opening the database: " + err);
                return -1;
            };
        }

        DataB.dbas = db;
        DataB.createTables();
        DataB.readCloudDb(); // read all || since date1 || date1 - date2
        DataB.readSettingsDb();

        personalAccessToken = DataB.getSetting(DataB.keyPersonalToken, "");
        if (personalAccessToken > "")
            oura.setPersonalAccessToken(personalAccessToken);
        //DataB.log(personalAccessToken);

        return;
    }

    function setUpNow() {
        var subPage = pageContainer.push(Qt.resolvedUrl("Settings.qml"), {
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
                DataB.updateSettings(.keyPersonalToken, newTkn)
                personalAccessToken = newTkn
                oura.setPersonalAccessToken(newTkn)
                downloadOuraCloud()
            })
        })

        return
    }
    // */

    Connections {
        target: applicationWindow
        onOuraActivityReady: {
            fillActivityData()
        }
        onOuraBedTimesReady: {
            fillBedTimeData()
        }
        onOuraReadinessReady: {
            fillReadinessData()
        }
        onOuraSleepReady: {
            fillSleepData()
        }
    }

    /*
    Connections {
        target: oura
        onFinishedActivity: {
            activityChart.fillData()
            chart1Summary.fillData()
        }
    }

    Connections {
        target: oura
        onFinishedSleep: {
            sleepType.fillData()
            chart2Summary.fillData()
            sleepHBR.fillData()
            chart3Summary.fillData()
        }
    }

    Connections {
        target: oura
        onFinishedReadiness: {
            readiness.fillData()
            chart4Summary.fillData()
        }
    }
    // */

    RemorsePopup {
        id: remorse
    }

    /*
    Timer {
        id: setUp
        interval: 0.8*1000
        running: false
        repeat: false
        onTriggered: {
            setUpNow()
        }
    }
    // */

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height
        width: parent.width

        PullDownMenu {
            MenuItem {
                text: qsTr("Activity")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("activityPage.qml"), {
                                           "summaryDate": oura.dateChange(0)
                                       })
                }
            }
            MenuItem {
                text: qsTr("Readiness")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("readinessPage.qml"), {
                                           "summaryDate": oura.dateChange(0)
                                       })
                }
            }
            MenuItem {
                text: qsTr("Sleep")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("sleepPage.qml"), {
                                           "summaryDate": oura.dateChange(0)
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
                    downloadOuraCloud()
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
                width: parent.width

                BarChart {
                    id: activityChart
                    width: parent.width - chart1Summary.width
                    height: Theme.itemSizeHuge
                    orientation: ListView.Horizontal
                    maxValue: 700

                    function fillData() {
                        var table = DataB.keyActivity, cell = "cal_active";
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first = now, nowEarly, diffMs, diffDays, i, val, day;
                        if (latestStored === undefined || latestStored.getFullYear() < 2012) {
                            first = oura.firstDate();
                        } else {
                            first.setFullYear(latestStored.getFullYear());
                            first.setMonth(latestStored.getMonth());
                            first.setDate(latestStored.getDate());
                            first.setHours(latestStored.getHours());
                            first.setMinutes(latestStored.getMinutes());
                        }
                        nowEarly = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 5, 0, 0, 0);
                        diffMs = nowEarly.getTime() - first.getTime();
                        diffDays = Math.ceil(diffMs/dayMs);

                        DataB.log(" -- " + new Date().getTime() + " " + latestStored.getTime() + " " + first.getTime())
                        //DataB.log("calories " + first.getDate() + "." + (first.getMonth() + 1) + ". - " + now.getDate() + "." + (now.getMonth() + 1) + ".")
                        for (i=0; i<diffDays; i++) {
                            val = 1.0*oura.value(table, cell, first);
                            //DataB.log("adding " + val);
                            day = dayStr(first.getDay());
                            addData(val, Theme.highlightColor, day);
                            first.setTime(first.getTime() + dayMs);
                        }
                        //DataB.log("calories done");

                        return;
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
                        color: (parent.score > parent.average*1.1 ||
                                parent.score < parent.average*0.9) ?
                                   Theme.highlightColor : Theme.secondaryHighlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: parent.isValid
                    }

                    function fillData() {
                        var val;
                        average = oura.average(DataB.keyActivity, "score"); // defaults to previous 7 days
                        val = oura.value(DataB.keyActivity, "score"); // defaults to yesterday
                        if (val === "-")
                            isValid = false
                        else
                            score = val*1.0;
                    }
                }
            }

            /*
            BarChart {
                id: activeScore
                width: parent.width
                height: Theme.itemSizeExtraLarge
                orientation: ListView.Horizontal
                maxValue: 100

                function fillData() {
                    var table = "activity", cell = "score";
                    var now = new Date(), dayMs = 24*60*60*1000;
                    var first = now, nowEarly, diffMs, diffDays, i, val, day;
                    if (latestStored === undefined || latestStored.getFullYear() < 2012) {
                        first = oura.firstDate();
                    } else {
                        first.setFullYear(latestStored.getFullYear());
                        first.setMonth(latestStored.getMonth());
                        first.setDate(latestStored.getDate());
                        first.setHours(latestStored.getHours());
                        first.setMinutes(latestStored.getMinutes());
                    }
                    nowEarly = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 4, 0, 0, 0);
                    diffMs = nowEarly.getTime() - first.getTime();
                    diffDays = Math.ceil(diffMs/dayMs);

                    DataB.log("score " + first.getDate() + "." + first.getMonth() + ". - " + now.getDate() + "." + now.getMonth() + ".")
                    for (i=0; i<diffDays; i++) {
                        val = oura.value(table, cell, first);
                        day = dayStr(first.getDay());
                        addData(val, Theme.highlightColor, day);
                        first.setTime(first.getTime() + dayMs);
                    }

                    return;
                }
            }
            // */

            SectionHeader {
                text: qsTr("sleep")
            }

            Row {
                width: parent.width

                BarChart {
                    id: sleepType
                    width: parent.width - chart2Summary.width
                    height: Theme.itemSizeHuge
                    orientation: ListView.Horizontal
                    maxValue: 10*60*60
                    arrayType: 0

                    function fillData() {
                        var table = "sleep", cell = "deep", cell2 = "light", cell3 = "rem", cell4 = "awake";
                        var now = new Date(), dayMs = 24*60*60*1000, maxSleepHr = 10*60*60*1000;
                        var first = now, nowEarly, diffMs, diffDays, i, day;
                        var val, val2, val3, val4;
                        if (latestStored === undefined || latestStored.getFullYear() < 2012) {
                            first = oura.firstDate();
                        } else {
                            first.setFullYear(latestStored.getFullYear());
                            first.setMonth(latestStored.getMonth());
                            first.setDate(latestStored.getDate());
                            first.setHours(latestStored.getHours());
                            first.setMinutes(latestStored.getMinutes());
                        }
                        nowEarly = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 4, 0, 0, 0);
                        diffMs = nowEarly.getTime() - first.getTime();
                        diffDays = Math.ceil(diffMs/dayMs);

                        DataB.log("sleep: eka " + first.getDate() + "." + (first.getMonth()+1) + ". - " + now.getDate() + "." + (now.getMonth() + 1) + ".")
                        for (i=0; i<diffDays; i++) {
                            val = oura.value(table, cell, first, -2); // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = oura.value(table, cell2, first, -2); // -1 is_longest==1
                            val3 = oura.value(table, cell3, first, -2); // -1 is_longest==1
                            val4 = oura.value(table, cell4, first, -2); // -1 is_longest==1
                            day = dayStr(first.getDay());
                            addData(val, "DarkGreen", day, val2, "Green", val3, "LightGreen", val4, "LightYellow");
                            first.setTime(first.getTime() + dayMs);
                        }
                        //DataB.log("sleep score done")

                        return;
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
                        color: (parent.score > parent.average*1.1 ||
                                parent.score < parent.average*0.9) ?
                                   Theme.highlightColor : Theme.secondaryHighlightColor
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
                width: parent.width

                BarChart {
                    id: sleepHBR
                    width: parent.width - chart3Summary.width
                    height: Theme.itemSizeLarge
                    orientation: ListView.Horizontal
                    maxValue: 60

                    function fillData() {
                        var table = "sleep", cell = "hr_average", cellLow = "hr_lowest";
                        var val, lowest, day;
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first = now, nowEarly, diffMs, diffDays, i;
                        if (latestStored === undefined || latestStored.getFullYear() < 2012) {
                            first = oura.firstDate();
                        } else {
                            first.setFullYear(latestStored.getFullYear());
                            first.setMonth(latestStored.getMonth());
                            first.setDate(latestStored.getDate());
                            first.setHours(latestStored.getHours());
                            first.setMinutes(latestStored.getMinutes());
                        }
                        nowEarly = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 4, 0, 0, 0);
                        diffMs = nowEarly.getTime() - first.getTime();
                        diffDays = Math.ceil(diffMs/dayMs);

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
                        color: (parent.score > parent.average*1.1 ||
                                parent.score < parent.average*0.9) ?
                                   Theme.highlightColor : Theme.secondaryHighlightColor
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
                width: parent.width

                BarChart {
                    id: readiness
                    width: parent.width - chart4Summary.width
                    height: Theme.itemSizeLarge
                    orientation: ListView.Horizontal
                    maxValue: 100

                    function fillData() {
                        var table = "readiness", cell = "score";
                        var val, day;
                        var now = new Date(), dayMs = 24*60*60*1000;
                        var first = now, nowEarly, diffMs, diffDays, i;
                        if (latestStored === undefined || latestStored.getFullYear() < 2012) {
                            first = oura.firstDate();
                        } else {
                            first.setFullYear(latestStored.getFullYear());
                            first.setMonth(latestStored.getMonth());
                            first.setDate(latestStored.getDate());
                            first.setHours(latestStored.getHours());
                            first.setMinutes(latestStored.getMinutes());
                        }
                        nowEarly = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 4, 0, 0, 0);
                        diffMs = nowEarly.getTime() - first.getTime();
                        diffDays = Math.ceil(diffMs/dayMs);

                        //DataB.log("readiness " + first.getDate() + "." + (first.getMonth() + 1) + ". - " + now.getDate() + "." + (now.getMonth() + 1) + ".")
                        for (i=0; i<diffDays; i++) {
                            val = 1.0*oura.value(table, cell, first, 0);
                            day = dayStr(first.getDay());
                            //DataB.log("adding " + val);
                            addData(val, Theme.highlightColor, day);
                            first.setTime(first.getTime() + dayMs);
                        }
                        //DataB.log("readiness done " + i);

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
                        color: (parent.score > parent.average*1.1 ||
                                parent.score < parent.average*0.9) ?
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
        activityChart.fillData();
        chart1Summary.fillData();
    }

    function fillBedTimeData() {
    }

    function fillReadinessData() {
        console.log("....readiness....")
        readiness.fillData();
        chart4Summary.fillData();
    }

    function fillSleepData() {
        console.log("....sleep....")
        sleepType.fillData();
        chart2Summary.fillData();
        sleepHBR.fillData();
        chart3Summary.fillData();
    }

    Component.onCompleted: {
        //readDb()
//        if (personalAccessToken > "")
//            downloadOuraCloud()
//        else {
//            setUp.start()
//        }
    }
}
