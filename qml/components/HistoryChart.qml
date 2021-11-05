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
    property string chartId: ""
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
    property alias lastDate: chart.lastDate
    property alias heading: title.text
    property alias maxValue: chart.maxValue
    property alias setValueLabel: chart.setValueLabel

    signal parametersChanged()
    signal barSelected(int barNr)

    function valuesModified(tb0, typ0, val0, low0, hgh0,
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

    function fillData() {
        console.log(chartId + ": " + chType + ", " + chTable + ", " + chCol)
        return summary.fillData()
    }

    function newData() {
        console.log(chartId + ": " + chType + ", " + chTable + ", " + chCol)
        return chart.newData();
    }

    function oldData() {
        console.log(chartId + ": " + chType + ", " + chTable + ", " + chCol)
        return chart.oldData();
    }

    function positionViewAtIndex(barNr, position) {
        return chart.positionViewAtIndex(barNr, position);
    }

    function reset() {
        summary.fillData();
        return chart.reset();
    }

    function rescale(oldMax, newMax) {
        return chart.reScale(oldMax, newMax);
    }

    ContextMenu {
        id: itemMenu
        MenuItem {
            text: qsTr("settings")
            onClicked: {
                var dialog = pageContainer.push(
                            Qt.resolvedUrl("../pages/chartSettings.qml"), {
                                "chartTable": chart.table,
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
                        if (valuesModified(chTable, chType, chCol,
                                           chLow, chHigh,
                                           dialog.chartTable, dialog.chartType, dialog.chartValue1,
                                           dialog.chartLowBar, dialog.chartHighBar)
                                ) {
                            chTable = dialog.chartTable;
                            chType = dialog.chartType;
                            chCol = dialog.chartValue1;
                            chCol2 = dialog.chartValue2;
                            chCol3 = dialog.chartValue3;
                            chCol4 = dialog.chartValue4;
                            chLow = dialog.chartLowBar;
                            chHigh = dialog.chartHighBar;
                            maxValue = dialog.chartMaxValue;
                            heading = dialog.chartTitle;
                            parametersChanged();
                            reset();
                        }

                        if (dialog.chartMaxValue !== undefined &&
                                maxValue !== dialog.chartMaxValue) {
                            rescale(maxValue, dialog.chartMaxValue);
                        }
                    }
                })
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

        Row {
            width: parent.width - 2*x
            x: Theme.horizontalPageMargin
            spacing: Theme.paddingMedium

            BarChart {
                id: chart
                width: parent.width - parent.spacing - summary.width
                height: Theme.itemSizeHuge
                orientation: ListView.Horizontal
                maxValue: 100
                valueLabelOutside: true
                highlight: Item {
                    width: chart.currentItem.width
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

                    if (ouraCloud.numberOfRecords(table) <= 0) {
                        DataB.log("no " + table + "-data")
                        return;
                    }

                    // set firstDate equal to the first date read from records
                    // and last equal to current date or the date of an empty list of records
                    first = ouraCloud.firstDate(table);
                    first.setTime(first.getTime() + 8*60*60*1000); // avoid problems when changing to light saving time
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

                    console.log(chartId + " dDays " + diffDays + " " + chType)
                    for (i=0; i<diffDays; i++) {
                        //console.log("______ " + chType + " " + col)
                        day = Scripts.dayStr(last.getDay());
                        sct = qsTr("%1, wk %2").arg(last.getFullYear()).arg(Scripts.weekNumber(last.getTime()));

                        if (chType === DataB.chartTypeSingle) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, last));

                            // ----
                            if (i === diffDays-1 || i === 0) {
                                console.log(" " + table + ", " + col + ", " + last.toDateString() + ": " + val1)
                            }
                            // ----

                            // overwrite the last date
                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val1})
                            } else {
                                addData(sct, val1, Theme.highlightColor, day);
                            }
                            //console.log("single " + val1 + " i=" + i)
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
                            console.log("min/max " + val1 + "," + lowBar + " " + highBar + " i=" + i)
                        } else if (chType === DataB.chartTypeSleep) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, last, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = Scripts.ouraToNumber(ouraCloud.value(table, col2, last, -2)); // -1 is_longest==1
                            val3 = Scripts.ouraToNumber(ouraCloud.value(table, col3, last, -2)); // -1 is_longest==1
                            val4 = Scripts.ouraToNumber(ouraCloud.value(table, col4, last, -2)); // -1 is_longest==1
                            if (i === 0 && count > 0) {
                                chartData.set(i, {"barValue": val1, "bar2Value": val2,
                                              "bar3Value": val3, "bar4Value": val4, "valLabel":
                                                  Scripts.secToHM(val1 + val2 + val3) })
                                console.log(" ______ ")
                                console.log(" " + (val1 + val2 + val3) + " = " + Scripts.secToHM(val1 + val2 + val3))
                                console.log(" ______ ")
                            } else {
                                addData(sct, val1, "DarkGreen", day, val2, "Green", val3,
                                        "LightGreen", val4, "LightYellow",
                                        Scripts.secToHM(val1 + val2 + val3));
                                console.log(" ______ ")
                                console.log(" " + (val1 + val2 + val3) + " = " + Scripts.secToHM(val1 + val2 + val3))
                                console.log(" ______ ")
                            }
                            //console.log("unityypit" + i)
                        } else {
                            if (i === 0) {
                                log("unknown chart type " + chType + ", " + table)
                            }
                        }

                        last.setTime(last.getTime() + dayMs);
                    }

                    if (i>0) {
                        last.setTime(last.getTime() - dayMs);
                    }

                    lastDate = last;
                    console.log(chartId + " done " + i + " " + firstDate + " - " + lastDate);

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
                    chart.maxValue = newMax;
                    return;
                }

            }

            TrendView {
                id: summary
                height: chart.height
                text: qsTr("score")
                factor: 1.2
                maxValue: chart.maxValue

                property string scoreStr: chart.col

                function fillData() {
                    var val;
                    console.log(chartId + " " + chart.table + ", " + chart.col)
                    if (chart.chType === DataB.chartTypeSleep) {
                        val = "score";
                        summary.maxValue = 100;
                    } else {
                        val = chart.col
                        summary.maxValue = chart.maxValue;
                    }

                    averageWeek = ouraCloud.average(chart.table, val, 7);
                    averageMonth = ouraCloud.average(chart.table, val, 30);
                    averageYear = ouraCloud.average(chart.table, val, 365);
                }
            }
        }
    }
}
