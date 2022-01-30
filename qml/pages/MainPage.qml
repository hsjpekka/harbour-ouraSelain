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
    property bool  _manualAddition: false

    Connections {
        target: applicationWindow
        onSettingsReady: {
            chartsView.setUpCharts()
        }
    }

    SilicaListView {
        id: chartsView
        anchors.fill: parent
        width: parent.width
        header: trends
        footer: Item {
            height: Theme.paddingLarge
        }

        /*footer: ListItem {
            width: parent.width
            contentHeight: footerTxt.height + 2*Theme.paddingMedium
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("add new chart")
                    onClicked: {
                        _manualAddition = true;
                        chartsList.add(1);
                        DataB.storeSettings(DataB.keyNrCharts, chartsList.count)
                    }
                }
            }

            Label {
                id: footerTxt
                text: qsTr("long press to add a chart")
                color: Theme.secondaryColor
                anchors.centerIn: parent
            }
        } // */
        delegate: chartDelegate
        model: ListModel {
            id: chartsList

            function add(amount) {
                var i = count, N;
                N = amount*1.0 + count;
                while (i < N) {
                    append({chartNr: i, chTable: "", chTitle: "", chMainValue: "" });
                    i++;
                }
                return i;
            }

            function modify(i, tbl, txt, val) {
                if (i >= 0 && i < count) {
                    if (tbl) {
                        set(i, {chTable: tbl});
                    }
                    if (txt) {
                        set(i, {chTitle: txt});
                    }
                    if (val) {
                        set(i, {chMainValue: val});
                    }
                }
                return;
            }

        }

        property int  busy: 0
        property real factor: 1.1 // limit for highlighting trends
        property date summaryDate: new Date(new Date().getTime() - 27*60*60*1000) // show summaries of yesterday
        property int  timeScale: 0
        property int  selectedBar: -1
        property int  xDist: 0

        signal summaryDateModified()
        signal cloudReloaded()

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
                text: qsTr("Add new chart")
                onClicked: {
                    _manualAddition = true;
                    chartsList.add(1);
                    DataB.storeSettings(DataB.keyNrCharts, chartsList.count)
                }
            }
            MenuItem {
                text: qsTr("My data")
                onClicked: {
                    var subPage = pageContainer.push(Qt.resolvedUrl("Settings.qml"),
                                                 { "token": personalAccessToken })
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
                        chartsView.cloudReloaded();
                    })
                }
            }
            MenuItem {
                text: qsTr("About")
                onClicked: {
                    pageContainer.push(Qt.resolvedUrl("Info.qml"))
                }
            }
            /*
            MenuItem {
                text: qsTr("Refresh")
                onClicked: {
                    refreshOuraCloud()
                }
            }// */
        }

        VerticalScrollDecorator {}

        function changeTimeScale() { // 0 - days grouped by week, 1 - days grouped by month
            if (timeScale > 1) {
                timeScale = 0;
            } else {
                timeScale++;
            }
            storeListParameters(selectedBar, timeScale);
            return timeScale;
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

        function chartItem(chartId) {
            var result;

            if (chartId < chartsView.count) {
                result = model.get(chartId);
            }

            return result;
        }

        function chartLatestValue(chartId) {
            var result;

            if (chartId < chartsView.count) {
                result = chartItem(chartId).chMainValue;
            }

            return result;
        }

        function chartTitle(chartId) {
            var result;

            if (chartId < chartsView.count) {
                result = chartItem(chartId).chTitle;
            }

            return result;
        }

        function selectColumn(chartNr, barNr, firstDateTime, xMove) {
            var chart, i=0;

            summaryDate = new Date(firstDateTime + barNr*msDay);
            xDist = xMove;
            selectedBar = barNr;

            return;
        }

        function setUpCharts() {
            var chart, chartId, i=0, nrCharts=0;

            timeScale = DataB.getSetting(DataB.keyChartTimeScale, timeScale);
            nrCharts = DataB.getSetting(DataB.keyNrCharts, 1)*1.0;

            model.add(nrCharts);

            return;
        }
    }

    Component {
        id: trends
        Item {
            id: summaryRow
            height: col.height
            width: page.width

            property bool dateLoop: false

            Connections {
                target: ouraCloud
                onFinishedActivity: {
                    chartsView.busy++
                    ouraCloud.setDateConsidered()
                    activityTrend.fillData()
                    chartsView.busy--
                }
                onFinishedBedTimes: {
                    //chartsView.busy++
                    //ouraCloud.setDateConsidered();
                    //_refreshedBedTimes++;
                    //chartsView.busy--
                }
                onFinishedReadiness: {
                    chartsView.busy++
                    ouraCloud.setDateConsidered()
                    readinessTrend.fillData()
                    chartsView.busy--
                }
                onFinishedSleep: {
                    chartsView.busy++
                    ouraCloud.setDateConsidered()
                    sleepTrend.fillData()
                    chartsView.busy--
                }
            }

            Connections {
                target: chartsView
                onSummaryDateChanged: {
                    if (summaryRow.dateLoop) {
                        summaryRow.dateLoop = false
                    } else {
                        txtDate.value = chartsView.summaryDate.toDateString(Qt.locale(), Locale.ShortFormat)
                        activityTrend.fillData()
                        readinessTrend.fillData()
                        sleepTrend.fillData()
                    }
                }
            }

            Column {
                id: col
                width: parent.width

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
                        value: chartsView.summaryDate.toDateString(Qt.locale(), Locale.ShortFormat)
                        y: 0

                        //property date summaryDate: new Date(new Date().getTime() - 27*60*60*1000) // 27 h ago

                        onClicked: {
                            var dialog = pageContainer.push("Sailfish.Silica.DatePickerDialog", {
                                                            "date": chartsView.summaryDate } )
                            dialog.accepted.connect( function() {
                                summaryRow.dateLoop = true;
                                chartsView.summaryDate = new Date(dialog.year, dialog.month-1, dialog.day, 11, 59, 59, 999)
                                chartsView.summaryDateModified()
                                activityTrend.fillData();
                                sleepTrend.fillData();
                                readinessTrend.fillData();
                                //chart1.selectDate(summaryDate);
                                //chart2.selectDate(summaryDate);
                                //chart3.selectDate(summaryDate);
                                //chart4.selectDate(summaryDate);
                            } )
                        }
                        //onSummaryDateChanged: {
                        //    txtDate.value = summaryDate.toDateString(Qt.locale(), Locale.ShortFormat)
                        //}
                    }

                    TrendLabel {
                        id: activityTrend
                        text: qsTr("activity")
                        //layout: layCompact
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
                        //layout: layCompact
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
                        //layout: layCompact
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
    }

    Component {
        id: chartDelegate
        ListItem {
            id: graphListItem
            contentHeight: historyPlot.height
            width: Screen.width
            menu: itemMenu

            ContextMenu {
                id: itemMenu
                MenuItem {
                    text: qsTr("settings")
                    onClicked: {
                        historyPlot.newChartSettings(1)
                    }
                }
                MenuItem {
                    text: (historyPlot.layout === 0) ? qsTr("dense layout") : qsTr("sparce layout")
                    onClicked: {
                        chartsView.changeTimeScale()
                    }
                }
                MenuItem {
                    text: qsTr("remove graph")
                    onClicked: {
                        var itemNr = chartNr
                        remorseDelete(function () {
                            removeGraph(itemNr)
                        })
                    }
                }
            }

            HistoryChart {
                id: historyPlot
                chartNr: index
                layout: chartsView.timeScale
                onBarSelected: {
                    chartsView.selectColumn(chartNr, barNr, firstDate.getTime(), xMove)
                }
                onHeadingChanged: {
                    chartsList.modify(index, undefined, heading, undefined)
                }
                onLatestValueChanged: {
                    chartsList.modify(index, undefined, undefined, latestValue)
                }
                onParametersChanged: {
                    storeChartParameters("ch" + chartNr, chTable, chType, chCol,
                                         chCol2, chCol3, chCol4, chHigh,
                                         chLow, maxValue, heading);
                    chartsList.modify(chartNr, chTable, heading);
                }
                onPressAndHold: {
                    graphListItem.openMenu()
                }
                onRemoveRequest: {
                    graphListItem.removeGraph(chartNr)
                }
            }

            function removeGraph(itemNr) {
                chartsList.remove(itemNr);
                DataB.storeSettings(DataB.keyNrCharts, chartsList.count);
                return;
            }
        }

    }

    function chartLatestValue(chrt){ // cover
        var result = chartsView.chartLatestValue(chrt);

        if (result === undefined) {
            result = "?? - " + chrt + " - ??";
        }

        return result;
    }

    function chartTitle(chrt){ // cover
        var result = chartsView.chartTitle(chrt);

        if (result === undefined) {
            result = qsTr("chart %1 not defined").arg(chrt)
        }

        return result;
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

    function storeListParameters(nrCharts, currentTimeScale) {
        if (currentTimeScale) {
            DataB.storeSettings(DataB.keyChartTimeScale, currentTimeScale + "");
        }
        if (nrCharts) {
            DataB.storeSettings(DataB.keyNrCharts, chartsView.count + "");
        }

        return;
    }
}
