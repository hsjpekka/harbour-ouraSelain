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

    property alias chartCount: chartsView.count

    Connections {
        target: ouraCloud
        onFinishedActivity: {
            if (_reloaded) {
                resetActivityData()
            } else {
                cloudActivityData()
            }
        }
        onFinishedBedTimes: {
            cloudBedTimeData()
        }
        onFinishedReadiness: {
            if (_reloaded) {
                resetReadinessData()
            } else {
                cloudReadinessData()
            }
        }
        onFinishedSleep: {
            if (_reloaded) {
                resetSleepData()
            } else {
                cloudSleepData()
            }
        }
    }

    Connections {
        target: applicationWindow
        onStoredDataRead: {
            chartsView.oldData()
        }
        onSettingsReady: {
            setUpPage()
        }
    }

    SilicaListView {
        id: chartsView
        anchors.fill: parent
        width: parent.width
        header: trends
        footer: ListItem {
            contentHeight: footerTxt.height
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("add new chart")
                    onClicked: {
                        chartsList.add(1);
                    }
                }
            }

            Label {
                id: footerTxt
                text: qsTr("long press to add a chart")
                color: Theme.secondaryColor
                visible: !column.visible
                x: Theme.horizontalPageMargin
            }
        }

        delegate: chartDelegate
        model: ListModel {
            id: chartsList

            function add(totalCount) {
                var i = 0, N;
                N = totalCount - count;
                while (i < N) {
                    append({chartNr: i, chartTable: "", title: "",
                               mainValue: "" })
                    i++;
                }
                return i;
            }
        }

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

        VerticalScrollDecorator {}

        function changeTimeScales(chartTimeScale) {
            var i = 0;
            while (i < count) {
                model.get(i).changeTimeScale(chartTimeScale);
                i++;
            }
            return;
        }

        function latestItem(chartId) {
            var result, chart, i;

            if (chartId < count) {
                chart = model.get(chartId);
                if (chart.valuesList.count > 1) {
                    i = chart.valuesList.count - 2;
                    result = chart.valuesList.get(valuesList.count - 2);
                } else if (chart.valuesList.count === 1) {
                    result = chart.valuesList.get(0);
                }
            }

            return result;
        }

        function latestType(chartId) {
            var result;

            if (chartId < count) {
                result = model.get(chartId).chType;
            }

            return result;
        }

        function latestValue(chartId) {
            var result;

            if (chartId < count) {
                result = model.get(chartId).latestValue;
            }

            return;
        }

        function newData(dataType) {
            var chart, i=0;

            while (i < count) {
                chart = model.get(i);
                if (chart.chTable === dataType) {
                    chart.newData();
                    chart.fillData();
                }
            }

            return;
        }

        function oldData() {
            var i=0;

            while (i < count) {
                model.get(i).oldData();
                i++;
            }

            return;
        }

        function resetData(dataType) {
            var chart, i=0;
            while (i < count) {
                chart = model.get(i);
                if (chart.chTable === dataType) {
                    chart.reset();
                }
            }
            return;
        }

        function selectColumn(chartId, barNr, firstDateTime) {
            var chart, i=0;

            txtDate.summaryDate = new Date(firstDateTime + barNr*msDay);

            while(i < count) {
                if (i !== chartId) {
                    chart = model.get(i);
                    chart.currentIndex = barNr;
                    chart.positionViewAtIndex(barNr, ListView.Center);
                }
                i++;
            }

            activityTrend.fillData();
            readinessTrend.fillData();
            sleepTrend.fillData();

            return;
        }

        function setUpPage() {
            var i=0;
            while(i < count) {
                model.get(i).setUpChart();
                i++;
            }
        }

    }

    Component {
        id: trends
        Item {
            width: page.width

            PageHeader {
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

        }
    }

    Component {
        id: chartDelegate
        HistoryChart {
            onParametersChanged: {
                storeChartParameters(chartId, chTable, chType,
                                     chCol, chCol2, chCol3,
                                     chCol4, chHigh, chLow,
                                     maxValue, heading)
                chartsList.set(index)
            }
            onBarSelected: {
                selectColumn(chartId, barNr, firstDate.getTime())
            }
            onTimeScaleChanged: {
                storeChartTimeScale(chartTimeScale)
            }
            onHideChart: {
                chartsList.remove(chartsList.index)
            }

            property string chartId: "ch" + index

            function setUpChart(defTitle, defTable, defType, defM1, defM2,
                                defM3, defM4, defHigh, defLow, defMax) {
                heading = DataB.getSetting(chartId + DataB.keyChartTitle, defTitle);
                chTable = DataB.getSetting(chartId + DataB.keyChartTable, defTable);
                chType = DataB.getSetting(chartId + DataB.keyChartType, defType);
                chCol = DataB.getSetting(chartId + DataB.keyChartCol, defM1);
                chCol2 = DataB.getSetting(chartId + DataB.keyChartCol2, defM2);
                chCol3 = DataB.getSetting(chartId + DataB.keyChartCol3, defM3);
                chCol4 = DataB.getSetting(chartId + DataB.keyChartCol4, defM4);
                chHigh = DataB.getSetting(chartId + DataB.keyChartHigh, defHigh);
                chLow = DataB.getSetting(chartId + DataB.keyChartLow, defLow);
                maxValue = DataB.getSetting(chartId + DataB.keyChartMax, defMax);
                if (chType === DataB.chartTypeSleep) {
                    setValueLabel = true;
                }
                changeTimeScale(DataB.getSetting(DataB.keyChartTimeScale));
                return;
            }
        }
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

    function chartTitle(chrt){ // cover
        var result;
        if (chrt < chartsList.count) {
            result = chartsList.get(i).chartTitle
        }

        return result;
    }

    function cloudActivityData() {
        ouraCloud.setDateConsidered();
        activityTrend.fillData();
        chartsView.fillData(DataB.keyActivity);

        return;
    }

    function cloudBedTimeData() {
        return;
    }

    function cloudReadinessData() {
        ouraCloud.setDateConsidered();
        readinessTrend.fillData();
        chartsView.fillData(DataB.keyReadiness);
        return;
    }

    function cloudSleepData() {
        ouraCloud.setDateConsidered();
        sleepTrend.fillData();
        chartsView.fillData(DataB.keySleep);
        return;
    }

    function latestItem(chartId) {
        return chartsView.latestItem(chartId);
    }

    function latestType(chartId) {
        return chartsView.latestType(chartId);
    }

    function latestValue(chrt){
        return chartsView.latestValue(chrt);
    }

    function resetActivityData() {
        ouraCloud.setDateConsidered();
        activityTrend.fillData();
        chartsView.resetData(DataB.keyActivity);
        return;
    }

    function resetReadinessData() {
        ouraCloud.setDateConsidered();
        readinessTrend.fillData();
        chartsView.resetData(DataB.keyReadiness);
        return;
    }

    function resetSleepData() {
        ouraCloud.setDateConsidered();
        sleepTrend.fillData();
        chartsView.resetData(DataB.keySleep);
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

    function storeChartTimeScale(currentTimeScale) {
        return DataB.storeSettings(DataB.keyChartTimeScale, currentTimeScale + "");
    }
}
