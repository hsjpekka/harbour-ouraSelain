import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../utils/datab.js" as DataB
import "../utils/scripts.js" as Scripts

ListItem {
    id: chartListItem
    width: Screen.width
    contentHeight: column.height
    menu: itemMenu
    Component.onCompleted: {
        if (_manualAddition === false) {
            setUpChart()
        } else {
            newChartSettings(0)
        }
    }

    property int   chartNr: -1
    property alias chartHeight: chart.height
    property alias chCol: chart.col
    property alias chCol2: chart.col2
    property alias chCol3: chart.col3
    property alias chCol4: chart.col4
    property alias chHigh: chart.barHi
    property alias chLow: chart.barLow
    property alias chTable: chart.table
    property alias chType: chart.chType
    property alias currentIndex: chart.currentIndex
    property alias daysToFetch: dataFetcher.daysToFetch
    property alias factor: summary.factor
    property alias firstDate: chart.firstDate
    property alias heading: title.text
    property alias lastDate: chart.lastDate
    property alias latestValue: chart.fullDayValue
    property alias layout: chart.timeScale
    property alias maxValue: chart.maxValue
    property alias setValueLabel: chart.setValueLabel
    property alias valuesList: chart.model

    signal barSelected(int barNr, int xMove)
    signal parametersChanged()
    signal removeRequest()
    signal timeScaleRequest()

    ContextMenu {
        id: itemMenu
        MenuItem {
            text: qsTr("settings")
            onClicked: {
                newChartSettings(1)
            }
        }
        MenuItem {
            text: (layout === 0) ? qsTr("dense layout") : qsTr("sparce layout")
            onClicked: {
                timeScaleRequest()
            }
        }
        MenuItem {
            text: qsTr("remove graph")
            onClicked: {
                removeRequest(chartNr)
            }
        }
    }

    Connections {
        id: ouraConnection
        target: ouraCloud
        onFinishedActivity: {
            if (chTable === DataB.keyActivity) {
                if (!ouraConnection.reloaded) {
                    ouraCloud.setDateConsidered()
                    newData()
                    fillData()
                } else {
                    fillData() // updates the averages
                    oldData()
                    ouraConnection.reloaded = ouraCloud.isLoading()
                }
            }
        }
        onFinishedBedTimes: {
            //ouraCloud.setDateConsidered();
            //_refreshedBedTimes++;
        }
        onFinishedReadiness: {
            if (chTable === DataB.keyReadiness) {
                if (!ouraConnection.reloaded) {
                    ouraCloud.setDateConsidered()
                    fillData()
                    newData()
                } else {
                    fillData() // updates the averages
                    oldData()
                    ouraConnection.reloaded = ouraCloud.isLoading()
                }
            }
        }
        onFinishedSleep: {
            if (chTable === DataB.keySleep) {
                if (!ouraConnection.reloaded) {
                    ouraCloud.setDateConsidered()
                    fillData()
                    newData()
                } else {
                    fillData() // updates the averages
                    oldData()
                    ouraConnection.reloaded = ouraCloud.isLoading()
                }
            }
        }

        property bool reloaded: false // true if user has asked for old data
    }

    Connections {
        target: applicationWindow
        onStoredDataRead: {
            fillData()
            oldData() // chart
            //    dataFetcher.start()
        }
        onSettingsReady: {
            setUpChart()
        }
    }

    Connections {
        target: chartsView
        onCloudReloaded: {
            ouraConnection.reloaded = true;
        }
        onTimeScaleChanged: {
            changeTimeScale(chartsView.timeScale)
        }
        onSelectedBarChanged: {
            var dTime = flickker.interval/1000
            if (!flickker.running) { // this chart has not been clicked
                moveCurrentItemToCenter(chartsView.xDist/dTime)
            }
        }
        onSummaryDateModified: {
            selectDate(chartsView.summaryDate)
        }
    }

    Timer {
        id: flickker
        interval: 0.3*1000
        running: false
        repeat: false
        onTriggered: {
            chart.cancelFlick()
            moveCurrentItemToCenter()            
        }
    }

    Timer {
        id: dataFetcher
        interval: 1*1000
        running: false
        repeat: true
        onTriggered: {
            /*
            if (chartsView.busy === 0) {
                chartsView.busy++
                fillData()
                if (chart.count === 0) { // nopeuttaako
                    chart.visible = false
                    chart.enabled = false
                }
                console.log("vanhat tiedot kuvaajaan " + chartNr)
                oldData() // chart
                console.log("vanhat tiedot luettu kuvaajaan " + chartNr)
                chart.visible = true
                chart.enabled = true
                oldDataRead()
                running = false
                chartsView.busy--
            } // */

            //if (chartNr === chartsView.chartInitializing) {
            //    fillData() // update yearly average in summary
            //    oldData() // chart
            //    oldDataRead()
            //    running = false
            //}
        }

        property date lastDayToFetch: new Date()
        property int daysToFetch: 30
    }

    Column {
        id: column
        width: parent.width

        SectionHeader {
            id: title
            text: "chart " + chartNr
        }

        Item {
            height: Theme.itemSizeHuge
            width: parent.width

            BarChart {
                id: chart
                height: parent.height
                width: count > 0 ? parent.width : 0 //- parent.spacing - summary.width
                barWidth: timeScale === 1? narrowBar : wideBar
                showLabel: 1
                orientation: ListView.Horizontal
                maxValue: 100
                valueLabelOutside: true
                highlight: Item {
                    width: chart.currentIndex >= 0 ? chart.currentItem.width : 0
                    Rectangle {
                        height: 3
                        width: parent.width - 2*x
                        color: Theme.highlightColor
                        anchors.bottom: parent.bottom
                        x: Theme.paddingSmall
                    }
                }
                highlightFollowsCurrentItem: true
                onBarPressAndHold: {
                    chartListItem.openMenu()
                }
                onBarSelected: {
                    if (chartListItem.menuOpen) {
                        chartListItem.closeMenu()
                    } else {
                        var dX, dY, dTime = flickker.interval/1000
                        dX = 0.5*chartListItem.width - xView
                        moveCurrentItemToCenter(dX/dTime)
                        chartListItem.barSelected(barNr, dX)
                    }
                }
                footer: Item {
                    width: summary.width + summary.anchors.rightMargin + Theme.paddingMedium
                }

                BusyIndicator {
                    anchors.centerIn: parent
                    size: BusyIndicatorSize.Medium
                    running: parent.loading
                }

                property date firstDate: new Date()
                property date lastDate: new Date()
                property bool loading: false
                property string table: DataB.keyReadiness
                property string col: "score"
                property string col2: ""
                property string col3: ""
                property string col4: ""
                property string barHi: ""
                property string barLow: ""
                property string chType: DataB.chartTypeSingle
                property string fullDayValue
                property real selectedX: 0
                property real selectedY: 0
                property int timeScale: 0 // 0 - days grouped by week, 1 - days grouped by month
                property int wideBar: Theme.fontSizeMedium
                property int narrowBar: 1.5*Theme.paddingSmall

                function changeGrouping(newTimeScale) {
                    // if timeScale = 0, section = "year, week"
                    // if timeScale = 1, section = "year, month"
                    var summaryDate = firstDate, sct, week, i;

                    if (typeof newTimeScale === typeof 1 || typeof newTimeScale === typeof 1.0 || typeof newTimeScale === typeof "" ) {
                        timeScale = newTimeScale*1.0;
                    } else {
                        DataB.log("unknown timeScale: " + newTimeScale);
                        timeScale++;
                    }
                    if (timeScale > 1 || timeScale < 0) {
                        DataB.log("timeScale out of range: " + timeScale + ", set = 0");
                        timeScale = 0;
                    }

                    summaryDate.setHours(12); // avoid problems related to light saving time
                    for (i=0; i < chart.count; i++) {
                        if (timeScale === 0) {
                            week = Scripts.weekNumberAndYear(summaryDate.getTime());
                            sct = qsTr("%1, wk %2").arg(week[0]).arg(week[1]);
                        } else if (timeScale === 1) {
                            sct = summaryDate.getFullYear() + ", " + Qt.locale().monthName(summaryDate.getMonth(), Locale.ShortFormat);
                        }
                        chart.modify(i, "group", sct);

                        summaryDate.setTime(summaryDate.getTime() + Scripts.msDay)
                    }
                    return;
                }

                function newData() {
                    // ignore data before lastDate
                    // average over the day readiness periods
                    var val1, val2, val3, val4, highBar, lowBar, day, sct;
                    var now = new Date(), dayMs = 24*60*60*1000, dum;
                    var first, last, diffMs, diffDays, i;
                    var week;

                    if (ouraCloud.numberOfRecords(table) <= 0) {
                        DataB.log("no " + table + "-data")
                        return;
                    }

                    // set firstDate equal to the first date read from records
                    // and last equal to current date or the date of an empty list of records
                    first = ouraCloud.firstDate(table);
                    first.setTime(first.getTime() + 12*60*60*1000); // 12:00 to avoid problems between summer and winter
                    if (first < firstDate) {
                        firstDate = first;
                    }
                    if (chartData.count === 0) {
                        lastDate = first;
                    }
                    last = lastDate;

                    // trying to avoid long loops if the date format is wrong
                    if (first.getFullYear() < 100) {
                        first.setFullYear(first.getFullYear() + 2000);
                        last.setFullYear(last.getFullYear() + 2000);
                    }
                    diffMs = now.getTime() - lastDate.getTime();
                    diffDays = Math.ceil(diffMs/dayMs);

                    for (i=0; i<diffDays; i++) {
                        day = Scripts.dayStr(last.getDay());
                        if (timeScale === 0) {
                            week = Scripts.weekNumberAndYear(last.getTime());
                            sct = qsTr("%1, wk %2").arg(week[0]).arg(week[1]);
                        } else {
                            sct = last.getFullYear() + ", " + Qt.locale().monthName(last.getMonth(), Locale.ShortFormat);
                        }

                        if (chType === DataB.chartTypeSingle) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, last));

                            if (i === 1) {
                                fullDayValue = val1 + "";
                            }

                            // overwrite the last date
                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val1})
                            } else {
                                addData(sct, val1, Theme.highlightColor, day);
                            }
                        } else if (chType === DataB.chartTypeMin
                                   || chType === DataB.chartTypeMaxmin) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, last));
                            lowBar = Scripts.ouraToNumber(ouraCloud.value(table, barLow, last));
                            if (chType === DataB.chartTypeMin) {
                                highBar = lowBar;
                            } else {
                                highBar = Scripts.ouraToNumber(ouraCloud.value(table, barHi, last));
                            }

                            // overwrite the last date
                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val1, "localMax": highBar,
                                                  "localMin": lowBar })
                            } else {
                                addDataVariance(sct, val1, "red", highBar, lowBar,
                                                (lowBar === 0? "transparent" : Theme.secondaryColor),
                                                day);
                            }

                            if (i === 1) {
                                fullDayValue = val1 + "";
                            }
                        } else if (chType === DataB.chartTypeSleep) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, last, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = Scripts.ouraToNumber(ouraCloud.value(table, col2, last, -2)); // -1 is_longest==1
                            val3 = Scripts.ouraToNumber(ouraCloud.value(table, col3, last, -2)); // -1 is_longest==1
                            val4 = Scripts.ouraToNumber(ouraCloud.value(table, col4, last, -2)); // -1 is_longest==1
                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val1, "bar2Value": val2,
                                              "bar3Value": val3, "bar4Value": val4, "valLabel":
                                                  Scripts.secToHM(val1 + val2 + val3) })
                            } else {
                                addData(sct, val1, "DarkGreen", day, val2, "Green", val3,
                                        "LightGreen", val4, "LightYellow",
                                        Scripts.secToHM(val1 + val2 + val3));
                            }
                            if (i === 1) {
                                fullDayValue = Scripts.secToHM(val1 + val2 + val3);
                            }
                        } else {
                            if (i === 0) {
                                DataB.log("unknown chart type " + chType + ", " + table)
                            }
                        }

                        last.setTime(last.getTime() + dayMs);
                    }

                    if (i>0) {
                        last.setTime(last.getTime() - dayMs);
                    }

                    lastDate = last;

                    loading = false;
                    positionViewAtEnd();

                    return;
                }

                function oldData() {
                    var val1, val2, val3, val4, highBar, lowBar, diffMs, diffDays, dayStr, sct;
                    var first, last, dayMs = 24*60*60*1000, week, i=0;

                    loading = true;
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
                        if (timeScale === 0) {
                            week = Scripts.weekNumberAndYear(last.getTime());
                            sct = qsTr("%1, wk %2").arg(week[0]).arg(week[1]);
                        } else {
                            sct = last.getFullYear() + ", " + Qt.locale().monthName(last.getMonth(), Locale.ShortFormat);
                        }
                        dayStr = Scripts.dayStr(last.getDay());

                        if (chType === DataB.chartTypeSingle) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, last));
                            insertData(0, sct, val1, Theme.highlightColor, dayStr);
                        } else if (chType === DataB.chartTypeMin || chType === DataB.chartTypeMaxmin) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, last));
                            lowBar = Scripts.ouraToNumber(ouraCloud.value(table, barLow, last));
                            if (chType === DataB.chartTypeMin) {
                                highBar = lowBar;
                            } else {
                                highBar = Scripts.ouraToNumber(ouraCloud.value(table, barHi, last));
                            }

                            insertDataVariance(0, sct, val1, "red", highBar, lowBar,
                                               (lowBar === 0? "transparent" : Theme.secondaryColor),
                                               dayStr);
                        } else if (chType === DataB.chartTypeSleep) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, last, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = Scripts.ouraToNumber(ouraCloud.value(table, col2, last, -2)); // -1 is_longest==1
                            val3 = Scripts.ouraToNumber(ouraCloud.value(table, col3, last, -2)); // -1 is_longest==1
                            val4 = Scripts.ouraToNumber(ouraCloud.value(table, col4, last, -2)); // -1 is_longest==1

                            insertData(0, sct, val1, "DarkGreen", dayStr, val2, "Green",
                                       val3, "LightGreen", val4, "LightYellow",
                                       Scripts.secToHM(val1 + val2 + val3));
                        }

                        i++;
                        last.setTime(last.getTime() - dayMs);
                    }
                    last.setTime(last.getTime() + dayMs);
                    firstDate = last;

                    loading = false;
                    chart.positionViewAtEnd();
                    return;
                }

                function reScale(newMax) {
                    chart.maxValue = newMax;
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
                id: summary
                anchors {
                    right: parent.right
                    rightMargin: Theme.paddingMedium
                }
                height: parent.height
                text: qsTr("score")
                factor: 1.2
                maxValue: chart.maxValue
                barWidth: Theme.fontSizeExtraSmall

                property string scoreStr: chart.col

                function fillData() {
                    var day1, dayN, unit, val;

                    if (chart.chType === DataB.chartTypeSleep) {
                        val = "total";
                    } else {
                        val = chart.col
                    }
                    if (chart.table === DataB.keyActivity) {
                        unit = activityMeasures.unit(val);
                    } else if (chart.table === DataB.keyReadiness) {
                        unit = readinessMeasures.unit(val);
                    } else if (chart.table === DataB.keySleep) {
                        unit = sleepMeasures.unit(val);
                    }
                    if (unit === "second") {
                        valueType = 1;
                    } else if (unit === "minute") {
                        valueType = 2;
                    } else {
                        valueType = 0;
                    }

                    day1 = ouraCloud.firstDate();
                    dayN = ouraCloud.lastDate(1); // don't include today
                    if (dayN.getDay() >= 0 && day1.getDay() >= 0) {
                        daysRead = Math.round((dayN.getTime() - day1.getTime())/msDay) + 1;
                        //console.log("" + daysRead + " = " + dayN.toLocaleDateString() + day1.toLocaleDateString())
                        averageWeek = ouraCloud.average(chart.table, val, daysInWeek);
                        averageMonth = ouraCloud.average(chart.table, val, daysInMonth);
                        averageYear = ouraCloud.average(chart.table, val, daysInYear);
                    }

                    return;
                }

                ActivityList {
                    id: activityMeasures
                }

                ReadinessList {
                    id: readinessMeasures
                }

                SleepList {
                    id: sleepMeasures
                }
            }
        }
    }

    function changeTimeScale(newTimeScale) { // 0 - days grouped by week, 1 - days grouped by month
        return chart.changeGrouping(newTimeScale);
    }

    function fillData() {
        return summary.fillData()
    }

    function moveCurrentItemToCenter(xVelocity) {
        var factor = 2.1, maxVel = 1100, minVel, yVelocity = 0;
        if (xVelocity) {
            minVel = chart.flickDeceleration*0.2;
            xVelocity = factor*xVelocity;
            if (xVelocity < minVel && xVelocity >= 0) {
                xVelocity = minVel;
            } else if (xVelocity > -minVel && xVelocity < 0) {
                xVelocity = -minVel;
            }

            if (xVelocity > maxVel) {
                xVelocity = maxVel
            } else if (xVelocity < -maxVel) {
                xVelocity = -maxVel
            }
            flickker.start();
            chart.flick(xVelocity, yVelocity);
        } else {
            chart.currentIndex = chartsView.selectedBar
            positionViewAtIndex(currentIndex, ListView.Center)
        }
        return;
    }

    function newChartSettings(isNewChart) {
        // isNewChart === 0 if the chart is new,
        // isNewChart === 1 if current content is to be modified
        var dialog, options;
        if (isNewChart === 1) {
            options = {
                "chartTable": chTable,
                "chartTitle": heading,
                "chartType": chType,
                "chartValue1": chCol,
                "chartValue2": chCol2,
                "chartValue3": chCol3,
                "chartValue4": chCol4,
                "chartLowBar": chLow,
                "chartHighBar": chHigh,
                "chartMaxValue": maxValue
            };
        }

        if (isNewChart === 2) {
            dialog = pageStack.push(
                    Qt.resolvedUrl("../pages/chartSettings.qml"), {
                        "chartTable": chTable,
                        "chartTitle": heading,
                        "chartType": chType,
                        "chartValue1": chCol,
                        "chartValue2": chCol2,
                        "chartValue3": chCol3,
                        "chartValue4": chCol4,
                        "chartLowBar": chLow,
                        "chartHighBar": chHigh,
                        "chartMaxValue": maxValue
                    });
        } else {
        }
        dialog = pageStack.push(
                Qt.resolvedUrl("../pages/chartSettings.qml"), options);

        dialog.accepted.connect(function () {
            if (dialog.chartTable !== undefined && dialog.chartType !== undefined) {
                if (valuesModified(dialog.chartTable, dialog.chartType,
                                   dialog.chartValue1, dialog.chartValue2,
                                   dialog.chartValue3, dialog.chartValue4,
                                   dialog.chartLowBar, dialog.chartHighBar)
                        ) {
                    chTable = dialog.chartTable;
                    chType = dialog.chartType;
                    chCol = dialog.chartValue1;
                    chCol2 = dialog.chartValue2;
                    chCol3 = dialog.chartValue3;
                    chCol4 = dialog.chartValue4;
                    chHigh = dialog.chartHighBar;
                    chLow = dialog.chartLowBar;
                    heading = dialog.chartTitle;
                    maxValue = dialog.chartMaxValue;
                    parametersChanged();
                    reset();
                }

                if (dialog.chartMaxValue !== undefined &&
                        maxValue !== dialog.chartMaxValue) {
                    parametersChanged();
                    rescale(dialog.chartMaxValue);
                }
            }
        });
        dialog.rejected.connect(function () {
            if (isNewChart === 0) {
                removeRequest();
            }
            return;
        })


        _manualAddition = false;

        return;
    }

    function newData() {
        return chart.newData();
    }

    function oldData() {
        return chart.oldData();
    }

    function positionViewAtIndex(barNr, position) {
        if (position === undefined) {
            position = ListView.Center;
        }

        return chart.positionViewAtIndex(barNr, position);
    }

    function rescale(newMax) {
        return chart.reScale(newMax);
    }

    function reset() {
        summary.fillData();
        return chart.reset();
    }

    function selectDate(dateToSelect) {
        var iDate, msDay = 24*60*60*1000;
        iDate = Math.round((dateToSelect.getTime() - firstDate.getTime())/msDay);
        currentIndex = iDate;
        chart.positionViewAtIndex(currentIndex, ListView.Center)

        return;
    }

    function setUpChart() {
        var chartId, defV2, defV3, defV4, i=0, nrCharts=0;

        chart.changeGrouping(DataB.getSetting(DataB.keyChartTimeScale, 0));

        chartId = "ch" + chartNr;
        heading = DataB.getSetting(chartId + DataB.keyChartTitle, qsTr("sleep"));
        chTable = DataB.getSetting(chartId + DataB.keyChartTable, DataB.keySleep);
        chType = DataB.getSetting(chartId + DataB.keyChartType, DataB.chartTypeSleep);
        chCol = DataB.getSetting(chartId + DataB.keyChartValue1, "deep");
        if (chTable === DataB.keySleep && chType === DataB.chartTypeSleep) {
            defV2 = "light";
            defV3 = "rem";
            defV4 = "awake";
        } else {
            defV2 = "";
            defV3 = "";
            defV4 = "";
        }
        chCol2 = DataB.getSetting(chartId + DataB.keyChartValue2, defV2);
        chCol3 = DataB.getSetting(chartId + DataB.keyChartValue3, defV3);
        chCol4 = DataB.getSetting(chartId + DataB.keyChartValue4, defV4);
        chHigh = DataB.getSetting(chartId + DataB.keyChartHigh, "");
        chLow = DataB.getSetting(chartId + DataB.keyChartLow, "");
        maxValue = DataB.getSetting(chartId + DataB.keyChartMax, 8*60*60); // s
        if (chType === DataB.chartTypeSleep) {
            setValueLabel = true;
        }

        return;
    }

    function valuesModified(tb1, typ1, val1, val2, val3, val4,
                            low1, hgh1, max1) {
        var result = false;
        if (tb1 === undefined || typ1 === undefined || val1 === undefined) {
            result = false;
        } else if (chTable !== tb1 || chType !== typ1) {
            result = true;
        } else if (typ1 === DataB.chartTypeSleep) {
            result = false;
        } else if (chCol !== val1) {
            result = true;
        } else if (chCol2 !== val2) {
            result = true;
        } else if (chCol3 !== val3) {
            result = true;
        } else if (chCol4 !== val4) {
            result = true;
        } else if (typ1 === DataB.chartTypeMin && chLow !== low1) {
            result = true;
        } else if (typ1 === DataB.chartTypeMaxmin &&
                   (chLow !== low1 || chHigh !== hgh1)) {
            result = true;
        } else if (maxValue !== max1) {
            result = true;
        }
        return result;
    }
}
