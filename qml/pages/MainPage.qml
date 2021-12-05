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
            if (_reloaded) {
                resetActivityData()
            } else {
                fillActivityData()
            }
        }
        onFinishedBedTimes: {
            fillBedTimeData()
        }
        onFinishedReadiness: {
            if (_reloaded) {
                resetReadinessData()
            } else {
                fillReadinessData()
            }
        }
        onFinishedSleep: {
            if (_reloaded) {
                resetSleepData()
            } else {
                fillSleepData()
            }
        }
    }

    Connections {
        target: applicationWindow
        onStoredDataRead: {
            chart1.oldData()
            chart2.oldData()
            chart3.oldData()
            chart4.oldData()
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

                        remorse.execute(msg, function() {
                            DataB.updateSettings(DataB.keyPersonalToken, newTkn)
                            ouraCloud.setPersonalAccessToken(newTkn)
                            personalAccessToken = newTkn
                            ouraCloud.downloadOuraCloud()
                        })
                    })
                    subPage.cloudReloaded.connect(function () {
                        _reloaded = true;
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
        ouraCloud.setDateConsidered();
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
        ouraCloud.setDateConsidered();
        readinessTrend.fillData();
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
        ouraCloud.setDateConsidered();
        sleepTrend.fillData();
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
