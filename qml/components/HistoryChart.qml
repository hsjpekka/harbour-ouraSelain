import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import "../utils/datab.js" as DataB
import "../utils/scripts.js" as Scripts

Item {
    id: rootItem
    width: parent.width
    height: column.height
    Component.onCompleted: {
        if (_manualAddition === false) {
            setUpChart()
            //readStoredRecords()
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
    property int   daysToFetch: 1
    property alias factor: summary.factor
    property alias firstDate: chart.firstDate
    property alias firstItemDate: chart.firstItemDate
    property alias heading: title.text
    property alias lastDate: chart.lastDate
    property alias latestValue: chart.fullDayValue
    property alias layout: chart.timeScale
    property alias maxValue: chart.maxValue
    property alias setValueLabel: chart.setValueLabel
    property bool  startingUp: true
    property alias valuesList: chart.model

    signal barSelected(int barNr, int xMove)
    signal parametersChanged()
    signal pressAndHold()
    signal removeRequest()

    Connections {
        id: ouraConnection
        target: ouraCloud
        onFinishedActivity: {
            if (chTable === DataB.keyActivity) {
                readNewRecords()
            }
        }
        //onFinishedBedTimes: {
            //ouraCloud.setDateConsidered();
            //_refreshedBedTimes++;
        //}
        onFinishedReadiness: {
            if (chTable === DataB.keyReadiness) {
                readNewRecords()
            }
        }
        onFinishedSleep: {
            if (chTable === DataB.keySleep) {
                readNewRecords()
            }
        }

        property bool reloaded: false // true if user has asked for old data
    }

    Connections {
        target: applicationWindow
        onStoredDataRead: {
            console.log("luetut kuvaajaan")
            //readStoredRecords()
            //var readDays
            //summary.fillData()
            //chart.reserveColumns()
            //readDays = chart.fillData(rootItem.daysToFetch) // chart
            //console.log("viimeksi luettu " + readDays)
            //if (readDays >= daysToFetch) {
            dataFetcher.start()
            //}
        }
        onSettingsReady: {
            setUpChart()
            console.log("kuvaaja valmisteltu")
        }
    }

    Connections {
        target: chartsView
        onCloudReloading: {
            ouraConnection.reloaded = true;
        }
        onTimeScaleChanged: {
            chart.changeGrouping(chartsView.timeScale)
        }
        onSelectedBarChanged: {
            var dTime = flickker.interval/1000
            if (chartsView.selectedBar < 0) {
                currentIndex = -1
            } else if (!flickker.running) { // this chart has not been clicked
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
            var unFetchedDays, dtf

            if (interval === 1*1000) {
                readStoredRecords(rootItem.daysToFetch)
                interval = 0.3*1000
            } else {
                //dtf = rootItem.daysToFetch
                unFetchedDays = chart.fillData(rootItem.daysToFetch)//rootItem.daysToFetch)
                console.log("ch" + chartNr + ": " + chTable + ", unfetched " + unFetchedDays + " days, " + rootItem.daysToFetch)//rootItem.daysToFetch)
                if (unFetchedDays <= 0) {
                    stop()
                    console.log("all old data read")
                }
            }

            /*
            if (chartsView.busy === 0) {
                chartsView.busy++
                fillData()
                if (chart.count === 0) { // nopeuttaako
                    chart.visible = false
                    chart.enabled = false
                }
                console.log("vanhat tiedot kuvaajaan " + chartNr)
                fillData() // chart
                console.log("vanhat tiedot luettu kuvaajaan " + chartNr)
                chart.visible = true
                chart.enabled = true
                fillDataRead()
                running = false
                chartsView.busy--
            } // */

            //if (chartNr === chartsView.chartInitializing) {
            //    fillData() // update yearly average in summary
            //    fillData() // chart
            //    fillDataRead()
            //    running = false
            //}
        }
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
                    pressAndHold()
                }
                onBarSelected: {
                    var dX, dY, dTime = flickker.interval/1000
                    if (currentIndex >= 0) {
                        dX = 0.5*rootItem.width - xView
                        moveCurrentItemToCenter(dX/dTime)
                        rootItem.barSelected(barNr, dX)
                    } else {
                        rootItem.barSelected(-1, 0)
                    }
                }
                footer: Item {
                    width: summary.width + summary.anchors.rightMargin + Theme.paddingMedium
                }

                property string barHi: ""
                property string barLow: ""
                property bool   checkLastDate: true
                property string chType: DataB.chartTypeSingle
                property string col: "score"
                property string col2: ""
                property string col3: ""
                property string col4: ""
                property date   firstItemDate
                property date   firstDate
                property string fullDayValue
                property date   lastDate
                property bool   loading: false
                property int    narrowBar: 1.5*Theme.paddingSmall
                property real   selectedX: 0
                property real   selectedY: 0
                property string table: DataB.keyReadiness
                property int    timeScale: 0 // 0 - days grouped by week, 1 - days grouped by month
                property int    wideBar: Theme.fontSizeMedium

                function addDay(i, dt, checkValue) {
                    // i=0 => at the beginning, i=count => at the end
                    // dt - date
                    // checkValue > 0 => read the value from ouraCloud
                    var dayStr, result, sct, week, highBar, lowBar, val1, val2, val3, val4;

                    highBar = 0;
                    lowBar = 0;
                    val1 = 0;
                    val2 = 0;
                    val3 = 0;
                    val4 = 0;

                    if (timeScale === 0) {
                        week = Scripts.weekNumberAndYear(dt.getTime());
                        sct = qsTr("%1, wk %2").arg(week[0]).arg(week[1]);
                    } else {
                        sct = dt.getFullYear() + ", " + Qt.locale().monthName(dt.getMonth(), Locale.ShortFormat);
                    }
                    dayStr = Scripts.dayStr(dt.getDay());

                    if (chType === DataB.chartTypeSingle) {
                        if (checkValue > 0) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, dt));
                        }
                        result = insertData(i, sct, val1, Theme.highlightColor, dayStr);
                    } else if (chType === DataB.chartTypeMin ||
                               chType === DataB.chartTypeMaxmin) {
                        if (checkValue > 0) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, dt));
                            lowBar = Scripts.ouraToNumber(ouraCloud.value(table, barLow, dt));
                            if (chType === DataB.chartTypeMin) {
                                highBar = lowBar;
                            } else {
                                highBar = Scripts.ouraToNumber(ouraCloud.value(table, barHi, dt));
                            }
                        }
                        result = insertDataVariance(i, sct, val1, "red", highBar,
                                            lowBar, Theme.secondaryColor, dayStr);
                    } else if (chType === DataB.chartTypeSleep) {
                        if (checkValue > 0) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, dt, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = Scripts.ouraToNumber(ouraCloud.value(table, col2, dt, -2)); // -1 is_longest==1
                            val3 = Scripts.ouraToNumber(ouraCloud.value(table, col3, dt, -2)); // -1 is_longest==1
                            val4 = Scripts.ouraToNumber(ouraCloud.value(table, col4, dt, -2)); // -1 is_longest==1
                        }
                        result = insertData(i, sct, val1, "DarkGreen", dayStr, val2,
                                   "Green", val3, "LightGreen", val4, "LightYellow",
                                   Scripts.secToHM(val1 + val2 + val3));
                    }

                    return result;
                }

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

                /*
                function newData() {
                    // ignore data before lastDate
                    // average over the day readiness periods
                    var val1, val2, val3, val4, highBar, lowBar, day, sct;
                    var now = new Date(), dayMs = 24*60*60*1000, result;
                    var first, last, diffMs, diffDays, i;
                    var week;

                    if (ouraCloud.numberOfRecords(table) <= 0) {
                        DataB.log("no " + table + "-data")
                        return;
                    }

                    // set firstDate equal to the first date read from records
                    // and last equal to current date or the date of an empty list of records
                    first = ouraCloud.firstDate(table);
                    first.setHours(4); // 04:00 to avoid problems between summer and winter
                    // trying to avoid long loops if the date format is wrong
                    if (first.getFullYear() < 100) {
                        first.setFullYear(first.getFullYear() + 2000);
                    }
                    // read max daysToFetch days to the chart
                    diffMs = now.getTime() - first.getTime();
                    diffDays = Math.ceil(diffMs/dayMs);
                    if (diffDays > daysToFetch) {
                        result = diffDays - daysToFetch;
                        diffDays = daysToFetch;
                        first.setTime(first.getTime() + result*dayMs);
                        firstDate = first;
                    }

                    if (first < firstDate) {
                        firstDate = first;
                    }
                    if (chartData.count === 0) {
                        lastDate = first;
                    }
                    last = lastDate;
                    last.setHours(4);

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

                    currentIndex = -1;

                    return result;
                }
                //*/

                function fillData(maxDays) {
                    // returns the number of days updated
                    // sets lastDate == last date in Oura Cloud or in the stored records
                    // sets firstDate == first date read into the chart
                    var val1, val2, val3, val4, highBar, lowBar, diffMs;
                    var dayStr, firstDB, fetchDate, sct, week, i, iN, nPost, nPre;
                    var hourMs = 60*60*1000, dayMs = 24*hourMs, overwriteDays;

                    console.log("ch" + chartNr + ", max " + maxDays + " vika-4 = " + chart.read(count - 4, "barValue"))
                    fetchDate = new Date();
                    if (fetchDate.getHours() < 4) { // oura-day changes at 04
                        fetchDate.setTime(fetchDate.getTime() - dayMs);
                    }
                    fetchDate.setHours(7);

                    if (checkLastDate || !(lastDate.getDate() > 0)) { // if new data has come from oura cloud
                        checkLastDate = false;
                        if (lastDate.getDate() > 0) { // if lastDate has been set
                            firstDB = lastDate;
                            lastDate = new Date(ouraCloud.lastDate(table).getTime() + 7*hourMs);
                            console.log(" täällä " + lastDate.getDate())
                        } else {
                            lastDate = new Date(ouraCloud.lastDate(table).getTime() + 7*hourMs);
                            firstDB = lastDate;
                            console.log(" täälläpä " + lastDate.getDate())
                        }
                        if (table === DataB.keyActivity) { // update today
                            firstDB.setTime(firstDB.getTime() - dayMs);
                        }

                        diffMs = fetchDate.getTime() - firstDB.getTime();
                        nPost = Math.round(diffMs/dayMs); // some new days have been read
                    } else {
                        nPost = 0; //only fill old records
                    }

                    // update new days
                    loading = true;
                    i = 0;
                    while(i < nPost) {
                        modifyDay(count - 1 - i, fetchDate);
                        fetchDate.setTime(fetchDate.getTime() - dayMs);
                        i++;
                    }

                    firstDB = ouraCloud.firstDate(table);
                    if (!(firstDB.getDate() > 0)) { // date === 1-31
                        return -1;
                    }
                    firstDB.setHours(4); // avoid light-saving-time changes, and oura-day changes at 04

                    if (firstDate.getDate() > 0) {
                        fetchDate.setTime(firstDate.getTime() - dayMs);
                        fetchDate.setHours(7);
                        diffMs = fetchDate.getTime() - firstDB.getTime();
                        nPre = Math.round(diffMs/dayMs) + 1;
                    } else {
                        nPre = count - nPost;
                    }

                    /*
                    if (firstDate === undefined){// || ouraConnection.reloaded) {// charts empty or rewrite chart
                        // reserveColumns() creates chart columns from ouraCloud.firstDate to the current date
                        //if (ouraConnection.reloaded) {
                        //    fetchDate = ouraCloud.firstDate(table);
                        //} else {
                            fetchDate = new Date();
                            if (fetchDate.getHours() > 3) { // if count = 0, make sure diffDays > 0
                                fetchDate.setTime(fetchDate.getTime() + dayMs);
                            }
                            fetchDate.setTime(fetchDate.getTime() - count*dayMs);
                            //fetchDate = new Date();
                            //if (fetchDate.getHours() < 4) {
                            //    fetchDate.setTime(fetchDate.getTime() - dayMs)
                            //}
                            //if (table !== DataB.keyActivity) {
                            //    fetchDate.setTime(fetchDate.getTime() - dayMs)
                            //}
                        //}
                        fetchDate.setHours(7);

                        //overwriteDays = 1;
                        lastDate = ouraCloud.lastDate(table);
                        firstDate = lastDate;
                    } else {
                        fetchDate = firstDate;
                        fetchDate.setHours(7);
                        overwriteDays = 0;
                    }

                    if (firstDate.getTime() <= firstDB.getTime()) {
                        return 0;
                    }

                    diffMs = fetchDate.getTime() - firstDB.getTime(); // first in chart - first in cloud
                    diffDays = Math.floor(diffMs/dayMs) + overwriteDays;
                    if (maxDays > 0 && diffDays > maxDays) {
                        diffDays = maxDays;
                    }

                    iN = Math.round((lastDate.getTime() - fetchDate.getTime())/dayMs);
                    i = count - iN - 1;


                    indexStore = currentIndex;
                    //*/

                    //console.log("ch" + chartNr + " - " + table + ", iMax " + maxDays + ", nPost " + nPost + ", nPre " + nPre);
                    // update old days
                    if (maxDays < 0 || maxDays === undefined) {
                        maxDays = nPre;
                    }

                    i = 0;
                    while(i < nPre && i < maxDays) {
                        i++;
                        modifyDay(nPre - i, fetchDate);
                        fetchDate.setTime(fetchDate.getTime() - dayMs);
                    }

                    /*
                    while (i >= count - (iN + diffDays) ) {
                        //if (timeScale === 0) {
                        //    week = Scripts.weekNumberAndYear(fetchDate.getTime());
                        //    sct = qsTr("%1, wk %2").arg(week[0]).arg(week[1]);
                        //} else {
                        //    sct = fetchDate.getFullYear() + ", " + Qt.locale().monthName(fetchDate.getMonth(), Locale.ShortFormat);
                        //}
                        //dayStr = Scripts.dayStr(fetchDate.getDay());

                        if (chType === DataB.chartTypeSingle) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, fetchDate));
                            modify(i, "barValue", val1);
                        } else if (chType === DataB.chartTypeMin || chType === DataB.chartTypeMaxmin) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, fetchDate));
                            lowBar = Scripts.ouraToNumber(ouraCloud.value(table, barLow, fetchDate));
                            if (chType === DataB.chartTypeMin) {
                                highBar = lowBar;
                            } else {
                                highBar = Scripts.ouraToNumber(ouraCloud.value(table, barHi, fetchDate));
                            }

                            modify(i, "barValue", val1);
                            modify(i, "localMax", highBar);
                            modify(i, "localMin", lowBar);
                        } else if (chType === DataB.chartTypeSleep) {
                            val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, fetchDate, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                            val2 = Scripts.ouraToNumber(ouraCloud.value(table, col2, fetchDate, -2)); // -1 is_longest==1
                            val3 = Scripts.ouraToNumber(ouraCloud.value(table, col3, fetchDate, -2)); // -1 is_longest==1
                            val4 = Scripts.ouraToNumber(ouraCloud.value(table, col4, fetchDate, -2)); // -1 is_longest==1

                            modify(i, "barValue", val1);
                            modify(i, "bar2Value", val2);
                            modify(i, "bar3Value", val3);
                            modify(i, "bar4Value", val4);
                            modify(i, "valLabel", Scripts.secToHM(val1 + val2 + val3));
                        }

                        fetchDate.setTime(fetchDate.getTime() - dayMs);
                        i--;
                    }

                    //*/

                    //if (i < 0 && diffDays > 0 ) {
                    //    fetchDate.setTime(fetchDate.getTime() + dayMs);
                    //}

                    loading = false;
                    fetchDate.setTime(fetchDate.getTime() + dayMs);
                    firstDate = fetchDate;

                    console.log("ch" + chartNr + " - " + table + ", nPost " + nPost + ", nPre " + nPre + ", vika " + lastDate.getDate() + "." + (lastDate.getMonth() + 1) + "., i= " + i + " eka " + firstDate.getDate() );

                    return nPre - i;
                }

                function modifyDay(i, t) {
                    // i=0 => at the beginning, i=count => at the end
                    // dt - date
                    // checkValue > 0 => read the value from ouraCloud
                    var result, highBar, lowBar, val1, val2, val3, val4;

                    if (chType === DataB.chartTypeSingle) {
                        val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, t));
                        result = modify(i, "barValue", val1);
                    } else if (chType === DataB.chartTypeMin ||
                               chType === DataB.chartTypeMaxmin) {
                        val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, t));
                        lowBar = Scripts.ouraToNumber(ouraCloud.value(table, barLow, t));
                        if (chType === DataB.chartTypeMin) {
                            highBar = lowBar;
                        } else {
                            highBar = Scripts.ouraToNumber(ouraCloud.value(table, barHi, t));
                        }
                        result = modify(i, "barValue", val1);
                        modify(i, "localMin", lowBar);
                        modify(i, "localMax", highBar);
                    } else if (chType === DataB.chartTypeSleep) {
                        val1 = Scripts.ouraToNumber(ouraCloud.value(table, col, t, -2)); // -1 is_longest==1, -2 sum of all suitable entries
                        val2 = Scripts.ouraToNumber(ouraCloud.value(table, col2, t, -2)); // -1 is_longest==1
                        val3 = Scripts.ouraToNumber(ouraCloud.value(table, col3, t, -2)); // -1 is_longest==1
                        val4 = Scripts.ouraToNumber(ouraCloud.value(table, col4, t, -2)); // -1 is_longest==1
                        result = modify(i, "barValue", val1);
                        modify(i, "bar2Value", val2);
                        modify(i, "bar3Value", val3);
                        modify(i, "bar4Value", val4);
                        modify(i, "valLabel", Scripts.secToHM(val1 + val2 + val3));
                    }

                    return result;
                }

                function reScale(newMax) {
                    chart.maxValue = newMax;
                    return;
                }

                function reserveColumns() {
                    // creates a column for each day from ouraCloud.firstDate() to now
                    var val1, val2, val3, val4, highBar, lowBar, diffMs, totalDays;
                    var dayStr, sct, first, last, dumDay, week, i, indexStorage, nPre, nPost;
                    var hourMs = 60*60*1000, dayMs = 24*hourMs;

                    //console.log(" " + " vika = " + chart.read(count - 1, "barValue"))

                    indexStorage = currentIndex;

                    first = ouraCloud.firstDate(table);
                    first.setHours(4);
                    firstItemDate = first;

                    /*
                    if (firstDate === undefined) {
                        last = new Date();
                        if (last.getHours() > 3) { // make sure totalDays > 0
                            last.setTime(last.getTime() + dayMs);
                        }
                        last.setTime(last.getTime() - count*dayMs);
                        //if (last.getHours() < 4) {
                        //    last.setTime(last.getTime() - dayMs);
                        //}
                        //if (table !== DataB.keyActivity) {
                        //    last.setTime(last.getTime() - dayMs)
                        //}
                    } else {
                        last = firstDate;
                    }
                    //*/
                    last = new Date();
                    if (last.getHours() < 4) { // oura-day changes at 04
                        last.setTime(last.getTime() - dayMs);
                    }
                    last.setHours(7);

                    diffMs = last.getTime() - first.getTime();
                    totalDays = Math.floor(diffMs/dayMs) + 1;

                    if (count >= totalDays) {
                        return totalDays - count;
                    }

                    loading = true;

                    // create empty columns at the now-end of the graph
                    if (lastDate.getDate() > 0) {
                        //lastDate.setHours(9);
                        dumDay = lastDate;
                        diffMs = last.getTime() - lastDate.getTime();
                        nPost = Math.floor(diffMs/dayMs);
                        i = 0;
                        while (i < nPost) {
                            dumDay.setTime(dumDay.getTime() + dayMs);
                            addDay(count, dumDay);
                            i++;
                        }
                    }

                    // create empty columns at the past-end of the graph
                    // if firstDate is not set, prepare totalDays of columns
                    if (firstDate.getDate() > 0) {
                        //firstDate.setHours(9);
                        diffMs = firstDate.getTime() + 7*hourMs - first.getTime();
                        nPre = Math.floor(diffMs/dayMs);
                        first.setTime(firstDate.getTime() - dayMs);
                    } else {
                        if (count > 0) {
                            chartData.clear()
                        }
                        first = last;
                        nPre = totalDays;
                    }

                    i = 0;
                    while (i < nPre) {
                        addDay(0, first);
                        /*
                        if (ouraConnection.reloaded) {
                            last.setTime(last.getTime() - dayMs);
                        }
                        if (timeScale === 0) {
                            week = Scripts.weekNumberAndYear(last.getTime());
                            sct = qsTr("%1, wk %2").arg(week[0]).arg(week[1]);
                        } else {
                            sct = last.getFullYear() + ", " + Qt.locale().monthName(last.getMonth(), Locale.ShortFormat);
                        }
                        dayStr = Scripts.dayStr(last.getDay());

                        if (chType === DataB.chartTypeSingle) {
                            val1 = 0;
                            insertData(0, sct, val1, Theme.highlightColor, dayStr);
                        } else if (chType === DataB.chartTypeMin || chType === DataB.chartTypeMaxmin) {
                            val1 = 0;
                            lowBar = 0;
                            highBar = 0;

                            insertDataVariance(0, sct, val1, "red", highBar, lowBar,
                                               Theme.secondaryColor,
                                               dayStr);
                        } else if (chType === DataB.chartTypeSleep) {
                            val1 = 0;
                            val2 = 0;
                            val3 = 0;
                            val4 = 0;

                            insertData(0, sct, val1, "DarkGreen", dayStr, val2, "Green",
                                       val3, "LightGreen", val4, "LightYellow",
                                       Scripts.secToHM(val1 + val2 + val3));
                        }
                        //*/

                        first.setTime(first.getTime() - dayMs);
                        i++;
                    }

                    loading = false;
                    //if (indexStorage >= 0) {
                    //      currentIndex = indexStorage + totalDays;
                    //      chart.positionViewAtIndex(currentIndex, ListView.Contain);
                    //} else {
                    //      chart.positionViewAtEnd();
                    //}

                    if (!lastDate.getDate() > 0) {
                        chart.positionViewAtEnd();
                    }

                    console.log("ch" + chartNr + " - " + table + ", nPost " + nPost + ", nPre " + nPre + ", kaikki " + totalDays + ", vika " + lastDate.getDate() + "." + (lastDate.getMonth() + 1) + "., eka " + firstDate.getDate() + "." + (firstDate.getMonth() + 1) + "." + " vika = " + chart.read(count - 4, "barValue"));

                    if (startingUp) {
                        startingUp = false;
                        currentIndex = count - 1;
                        rootItem.barSelected(currentIndex, 0)
                    }

                    return totalDays;
                }

                function reset() {
                    chartData.clear();
                    loading = true;
                    reserveColumns();
                    fillData();
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

    //function changeTimeScale(newTimeScale) { // 0 - days grouped by week, 1 - days grouped by month
    //    return chart.changeGrouping(newTimeScale);
    //}

    function moveCurrentItemToCenter(xVelocity) {
        var factor = 2.1, maxVel = 1100, minVel, yVelocity = 0;
        if (xVelocity) {
            minVel = chart.flickDeceleration*0.2;
            xVelocity = factor*xVelocity;
            if (xVelocity < minVel && xVelocity > 0) {
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
                    chart.rescale(dialog.chartMaxValue);
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

    function positionViewAtIndex(barNr, position) {
        if (position === undefined) {
            position = ListView.Center;
        }

        return chart.positionViewAtIndex(barNr, position);
    }

    //function rescale(newMax) {
    //    return chart.reScale(newMax);
    //}

    function readNewRecords() {
        chart.checkLastDate = true
        summary.fillData()
        chart.reserveColumns()
        if (!ouraConnection.reloaded) {
            chart.fillData(0)
        } else {
            dataFetcher.stop()
            chart.fillData()
            ouraConnection.reloaded = false
        }
        return;
    }

    function readStoredRecords() {
        var unReadDays;
        summary.fillData();
        chart.reserveColumns();
        unReadDays = chart.fillData(rootItem.daysToFetch);
        console.log("lukematta " + unReadDays);
        if (unReadDays >= daysToFetch) {
            dataFetcher.start();
        }

        return unReadDays;
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

        chart.currentIndex = -1;

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
