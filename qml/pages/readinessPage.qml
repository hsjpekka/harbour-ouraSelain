import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/datab.js" as DataB

Page {
    id: page
    property date summaryDate: new Date()
    property int  periodId: 0
    property int  maxPeriod: 0

    onStatusChanged: {
        if (page.status === PageStatus.Active) {
            DataB.log("readinessPage\n\n ")
        }
    }
    Component.onCompleted: {
        updateValues()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: pageColumn.height

        PullDownMenu {
            MenuItem {
                text: "json"
                onClicked: {
                    jsonString.visible = !jsonString.visible
                    jsonString.text = ouraCloud.printReadiness()
                }
            }
            MenuItem {
                text: qsTr("next day")
                onClicked: {
                    previousDay(1);
                    updateValues();
                }
            }
            MenuItem {
                text: qsTr("previous day")
                onClicked: {
                    previousDay();
                    updateValues();
                }
            }
            MenuItem {
                text: qsTr("next period")
                visible: maxPeriod > 0
                onClicked: {
                    nextPeriod();
                    updateValues();
                }
            }
        }

        Column {
            id: pageColumn
            width: parent.width

            PageHeader {
                title: qsTr("Readiness")
            }

            ValueButton {
                id: txtDate
                label: qsTr("date")
                value: summaryDate.toDateString(Qt.locale(), Locale.ShortFormat)
                onClicked: {
                    var dialog = pageContainer.push("Sailfish.Silica.DatePickerDialog", {
                                                    "date": summaryDate } )
                    dialog.accepted.connect( function() {
                        value = dialog.dateText
                        summaryDate = new Date(dialog.year, dialog.month-1, dialog.day, 13, 43, 43, 88)
                        periodId = 0
                        ouraCloud.setDateConsidered(summaryDate)
                        updateValues()
                    } )
                }
            }

            DetailItem {
                id: itemScore
                label: qsTr("score")
            }

            DetailItem {
                id: itemPrevNight
                label: qsTr("previous night")
            }

            DetailItem {
                id: itemSleepBalance
                label: qsTr("sleep balance")
            }

            DetailItem {
                id: itemPrevDay
                label: qsTr("previous day")
            }

            DetailItem {
                id: itemActivity
                label: qsTr("activity balance")
            }

            DetailItem {
                id: itemRestHr
                label: qsTr("resting hearth rate")
            }

            DetailItem {
                id: itemHrv
                label: qsTr("hearth rate variance")
            }

            DetailItem {
                id: itemRecovery
                label: qsTr("recovery index")
            }

            DetailItem {
                id: itemTemperature
                label: qsTr("temperature")
            }

            DetailItem {
                id: itemRestMode
                label: qsTr("rest mode")
            }

            DetailItem {
                id: itemPeriods
                label: qsTr("rest periods")
                value: maxPeriod + 1
                //visible: maxPeriod > 0
            }

            TextArea {
                id: jsonString
                width: parent.width
                readOnly: true
                visible: false
            }

            /*
            "score": 62,
            "score_previous_night": 5,
            "score_sleep_balance": 75,
            "score_previous_day": 61,
            "score_activity_balance": 77,
            "score_resting_hr": 98,
            "score_hrv_balance": 90,
            "score_recovery_index": 45,
            "score_temperature": 86,
            "rest_mode_state": 0
            */
        }
    }

    function nextPeriod(step) {
        if (step === undefined)
            step = 1;
        periodId++;
        if (periodId > maxPeriod)
            periodId = 0;
        return;
    }

    function previousDay(dayStep) {
        if (dayStep === undefined)
            dayStep = -1;
        summaryDate = ouraCloud.dateChange(dayStep);
        txtDate.value = summaryDate.toDateString(Qt.locale(), Locale.ShortFormat);
        periodId = 0;
        maxPeriod = ouraCloud.periodCount(DataB.keyReadiness, summaryDate) - 1;
        return;
    }

    function updateValues() {
        itemScore.value = ouraCloud.value(DataB.keyReadiness, "score", summaryDate, periodId);
        itemPrevNight.value = ouraCloud.value(DataB.keyReadiness, "score_previous_night", summaryDate, periodId);
        itemSleepBalance.value = ouraCloud.value(DataB.keyReadiness, "score_sleep_balance", summaryDate, periodId);
        itemPrevDay.value = ouraCloud.value(DataB.keyReadiness, "score_previous_day", summaryDate, periodId);
        itemActivity.value = ouraCloud.value(DataB.keyReadiness, "score_activity_balance", summaryDate, periodId);
        itemRestHr.value = ouraCloud.value(DataB.keyReadiness, "score_resting_hr", summaryDate, periodId);
        itemHrv.value = ouraCloud.value(DataB.keyReadiness, "score_hrv_balance", summaryDate, periodId);
        itemRecovery.value = ouraCloud.value(DataB.keyReadiness, "score_recovery_index", summaryDate, periodId);
        itemTemperature.value = ouraCloud.value(DataB.keyReadiness, "score_temperature", summaryDate, periodId);
        itemRestMode.value = ouraCloud.value(DataB.keyReadiness, "rest_mode_state", summaryDate, periodId);
        return;
    }
}
