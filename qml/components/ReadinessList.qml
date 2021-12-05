import QtQuick 2.0

ListModel {
    id: list

    function unit(dsc) {
        var i, result;
        i = 0;
        while (i < list.count) {
            if (list.get(i).field === dsc) {
                result = list.get(i).unit;
                i = list.count;
            }

            i++;
        }
        return result;
    }

    /*
    {
        "readiness": {
            "summary_date": "2016-09-03",
            "period_id": 0,
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
        }
    }
    // */
    ListElement {
        field: "score"
        max: 100
        desc: qsTr("readiness")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_previous_night"
        max: 100
        desc: qsTr("previous night")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_sleep_balance"
        max: 100
        desc: qsTr("sleep balance")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_previous_day"
        max: 100
        desc: qsTr("previous day")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_activity_balance"
        max: 100
        desc: qsTr("activity balance")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_resting_hr"
        max: 100
        desc: qsTr("resting hearth beat rate")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_hrv_balance"
        max: 100
        desc: qsTr("hearth beat rate variation")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_recovery_index"
        max: 100
        desc: qsTr("recovery")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_temperature"
        max: 100
        desc: qsTr("temperature")
        unit: ""
        array: false
    }
    ListElement {
        field: "rest_mode_state"
        max: 4
        desc: qsTr("rest mode state")
        unit: ""
        array: false
    }
}
