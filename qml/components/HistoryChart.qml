import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../utils/datab.js" as DataB
import "../utils/scripts.js" as Scripts

ListItem {
    id: liRoot
    width: parent.width
    contentHeight: column.height
    menu: itemMenu

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
    property alias factor: summary.factor
    property alias firstDate: chart.firstDate
    property alias heading: title.text
    property alias lastDate: chart.lastDate
    property alias latestValue: chart.fullDayValue
    property alias maxValue: chart.maxValue
    property alias setValueLabel: chart.setValueLabel
    property alias valuesList: chart.model

    signal parametersChanged()
    signal barSelected(int barNr)
    signal timeScaleChanged(int chartTimeScale)

    ContextMenu {
        id: itemMenu
        MenuItem {
            text: qsTr("settings")
            onClicked: {
                var dialog = pageContainer.push(
                            Qt.resolvedUrl("../pages/chartSettings.qml"), {
                                "chartTable": chart.table,
                                "chartTitle": title.text,
                                "chartType": chart.chType,
                                "chartValue1": chart.col,
                                "chartValue2": chart.col2,
                                "chartValue3": chart.col3,
                                "chartValue4": chart.col4,
                                "chartLowBar": chart.barLow,
                                "chartHighBar": chart.barHi,
                                "chartMaxValue": chart.maxValue
                            })
                dialog.accepted.connect(function () {
                    if (dialog.chartTable !== undefined && dialog.chartType !== undefined) {
                        if (valuesModified(chTable, chType, chCol, chCol2, chCol3, chCol4,
                                           chLow, chHigh,
                                           dialog.chartTable, dialog.chartType, dialog.chartValue1,
                                           dialog.chartValue2, dialog.chartValue3, dialog.chartValue4,
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
                            rescale(maxValue, dialog.chartMaxValue);
                        }
                    }
                })
            }
        }
        MenuItem {
            text: (chart.timeScale === 0) ? qsTr("dense layout") : qsTr("sparce layout")
            onClicked: {
                changeTimeScale()
                timeScaleChanged(chart.timeScale)
            }
        }
    }

    Column {
        id: column
        width: parent.width

        SectionHeader {
            id: title
            text: "header"
        }

        Item {
            height: Theme.itemSizeHuge
            width: parent.width - 2*x
            x: Theme.horizontalPageMargin
            //spacing: Theme.paddingMedium

            BarChart {
                id: chart
                height: parent.height
                width: parent.width //- parent.spacing - summary.width
                barWidth: timeScale === 1? narrowBar : wideBar
                showLabel: timeScale !== 1
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
                        //anchors.bottomMargin: Theme.fontSizeSmall + Theme.paddingSmall
                    }
                }
                highlightFollowsCurrentItem: true
                onBarPressAndHold: {
                    liRoot.openMenu()
                }
                onBarSelected: {
                    liRoot.closeMenu()
                    liRoot.barSelected(barNr)
                }
                footer: Item {
                    width: summary.width + Theme.paddingMedium
                }
                //header: Item {
                //    width: summary.width + Theme.paddingMedium
                //}

                BusyIndicator {
                    anchors.centerIn: parent
                    size: BusyIndicatorSize.Medium
                    running: parent.loading
                }

                property date firstDate: new Date()
                property date lastDate: new Date()
                property bool loading: true
                property string table: DataB.keyReadiness
                property string col: "score"
                property string col2: ""
                property string col3: ""
                property string col4: ""
                property string barHi: ""
                property string barLow: ""
                property string chType: DataB.chartTypeSingle
                property string fullDayValue
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
                        DataB.log("unknown timeScale: " + newTimeScale + ", set to 0");
                        timeScale = 0;
                    }
                    if (timeScale > 1 || timeScale < 0) {
                        DataB.log("unknown timeScale: " + timeScale);
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

                function reset() {
                    chartData.clear();
                    loading = true;
                    oldData();
                    loading = false;
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

                    return;
                }

                function reScale(oldMax, newMax) {
                    chart.maxValue = newMax;
                    return;
                }
            }

            TrendView {
                id: summary
                height: parent.height
                text: qsTr("score")
                factor: 1.2
                maxValue: chart.maxValue
                anchors.right: parent.right

                property string scoreStr: chart.col

                function fillData() {
                    var unit, val;

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
                    }

                    averageWeek = ouraCloud.average(chart.table, val, 7);
                    averageMonth = ouraCloud.average(chart.table, val, 30);
                    averageYear = ouraCloud.average(chart.table, val, 365);
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
        if (newTimeScale === undefined) {
            if (chart.timeScale === 0) {
                newTimeScale = 1;
            } else {
                newTimeScale = 0;
            }
        }
        return chart.changeGrouping(newTimeScale);
    }

    function fillData() {
        return summary.fillData()
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

    function rescale(oldMax, newMax) {
        return chart.reScale(oldMax, newMax);
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

    function valuesModified(tb0, typ0, val0a, val0b, val0c, val0d,
                            low0, hgh0, max0,
                          tb1, typ1, val1a, val1b, val1c, val1d,
                            low1, hgh1, max1) {
        var result = false;
        if (tb1 === undefined || typ1 === undefined || val1a === undefined) {
            result = false;
        } else if (tb0 !== tb1 || typ0 !== typ1) {
            result = true;
        } else if (typ1 === DataB.chartTypeSleep) {
            result = false;
        } else if (val0a !== val1a) {
            result = true;
        } else if (val0b !== val1b) {
            result = true;
        } else if (val0c !== val1c) {
            result = true;
        } else if (val0d !== val1d) {
            result = true;
        } else if (typ1 === DataB.chartTypeMin && low0 !== low1) {
            result = true;
        } else if (typ1 === DataB.chartTypeMaxmin &&
                   (low0 !== low1 || hgh0 !== hgh1)) {
            result = true;
        } else if (max0 !== max1) {
            result = true;
        }
        return result;
    }
}
