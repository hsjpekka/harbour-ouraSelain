import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/datab.js" as DataB

ComboBox {
    property string record
    property alias activityModel: activityItemList
    property alias readinessModel: readinessItemList
    property alias sleepModel: sleepItemList
    signal selected(string selectedStr, real max, string titleStr)

    menu: ContextMenu {
        Repeater {
            model: record === DataB.keyActivity? activityItemList :
                        record === DataB.keyReadiness? readinessItemList :
                            record === DataB.keySleep? sleepItemList: 0
            MenuItem {
                text: model.text
                onClicked: {
                    selected(text, max, name)
                }
                property real max: model.max
                property string name: model.name
            }
        }
    }

    ListModel {
        id: activityItemList
        ListElement {
            text: "score"
            max: 100
            name: qsTr("activity score")
        }
        ListElement {
            text: "score_stay_active"
            max: 100
            name: qsTr("staying active score")
        }
        ListElement {
            text: "score_move_every_hour"
            max: 100
            name: qsTr("every hour movement score")
        }
        ListElement {
            text: "score_meet_daily_targets"
            max: 100
            name: qsTr("meet activity targets")
        }
        ListElement {
            text: "score_training_frequency"
            max: 100
            name: qsTr("training frequency score")
        }
        ListElement {
            text: "score_training_volume"
            max: 100
            name: qsTr("training volume score")
        }
        ListElement {
            text: "score_recovery_time"
            max: 100
            name: qsTr("recovery time score")
        }
        ListElement {
            text: "daily_movement"
            max: 10000 // meter
            name: qsTr("daily movement")
        }
        ListElement {
            text: "non_wear"
            max: 60 // minutes
            name: qsTr("time not worn")
        }
        ListElement {
            text: "rest"
            max: 600 // minutes
            name: qsTr("resting time")
        }
        ListElement {
            text: "inactive"
            max: 480 // minutes
            name: qsTr("inactive time")
        }
        ListElement {
            text: "inactivity_alerts"
            max: 10
            name: qsTr("inactivity alerts")
        }
        ListElement {
            text: "low"
            max: 180 // minutes
            name: qsTr("low activity time")
        }
        ListElement {
            text: "medium"
            max: 180 // minutes
            name: qsTr("medium activity time")
        }
        ListElement {
            text: "high"
            max: 120 // minutes
            name: qsTr("high activity time")
        }
        ListElement {
            text: "steps"
            max: 15000
            name: qsTr("steps")
        }
        ListElement {
            text: "cal_total"
            max: 3000
            name: qsTr("total calories")
        }
        ListElement {
            text: "cal_active"
            max: 900
            name: qsTr("active calories")
        }
        ListElement {
            text: "met_min_inactive"
            max: 360
            name: qsTr("metabolic minutes when inactive")
        }
        ListElement {
            text: "met_min_low"
            max: 360
            name: qsTr("metabolic minutes in low activity")
        }
        ListElement {
            text: "met_min_medium_plus"
            max: 180
            name: qsTr("metabolic minutes in medium plus activity")
        }
        ListElement {
            text: "met_min_medium"
            max: 180
            name: qsTr("metabolic minutes in medium activity")
        }
        ListElement {
            text: "met_min_high"
            max: 120
            name: qsTr("metabolic minutes in high activity")
        }
        ListElement {
            text: "average_met"
            max: 3
            name: qsTr("average metabolic level")
        }
        //ListElement { // not a single value
        //    text: "class_5min"
        //    max: 3
        //}
        //ListElement { // not a single value
        //    text: "met_1min"
        //}
        ListElement {
            text: "rest_mode_state"
            max: 5
            name: qsTr("rest mode state")
        }
    }

    ListModel {
        id: readinessItemList
        ListElement {
            text: "score"
            max: 100
            name: qsTr("readiness score")
        }
        ListElement {
            text: "score_previous_night"
            max: 100
            name: qsTr("previous night score")
        }
        ListElement {
            text: "score_sleep_balance"
            max: 100
            name: qsTr("sleep balance score")
        }
        ListElement {
            text: "score_previous_day"
            max: 100
            name: qsTr("previous day score")
        }
        ListElement {
            text: "score_activity_balance"
            max: 100
            name: qsTr("activity balance score")
        }
        ListElement {
            text: "score_resting_hr"
            max: 100
            name: qsTr("resting hearth beat rate score")
        }
        ListElement {
            text: "score_hrv_balance"
            max: 100
            name: qsTr("hearth beat rate variation score")
        }
        ListElement {
            text: "score_recovery_index"
            max: 100
            name: qsTr("recovery score")
        }
        ListElement {
            text: "score_temperature"
            max: 100
            name: qsTr("temperature score")
        }
        ListElement {
            text: "rest_mode_state"
            max: 4
            name: qsTr("rest mode state")
        }
    }

    ListModel {
        id: sleepItemList
        ListElement {
            text: "score"
            max: 100
            name: qsTr("sleep score")
        }
        ListElement {
            text: "score_total"
            max: 100
            name: qsTr("sleep time score")
        }
        ListElement {
            text: "score_disturbances"
            max: 100
            name: qsTr("sleep disturbances score")
        }
        ListElement {
            text: "score_efficiency"
            max: 100
            name: qsTr("sleep efficiency score")
        }
        ListElement {
            text: "score_latency"
            max: 100
            name: qsTr("sleep latency score")
        }
        ListElement {
            text: "score_rem"
            max: 100
            name: qsTr("REM sleep score")
        }
        ListElement {
            text: "score_deep"
            max: 100
            name: qsTr("deep sleep score")
        }
        ListElement {
            text: "score_alignment"
            max: 100
            name: qsTr("sleep alignment score")
        }
        ListElement {
            text: "total"
            max: 32400
            name: qsTr("total sleep time")
        }
        ListElement {
            text: "duration"
            max: 36000
            name: qsTr("bed time")
        }
        ListElement {
            text: "awake"
            max: 7200
            name: qsTr("night time awake")
        }
        ListElement {
            text: "light"
            max: 14400
            name: qsTr("light sleep")
        }
        ListElement {
            text: "rem"
            max: 14400
            name: qsTr("REM sleep")
        }
        ListElement {
            text: "deep"
            max: 14400
            name: qsTr("deep sleep")
        }
        ListElement {
            text: "onset_latency"
            max: 7200
            name: qsTr("sleep latency")
        }
        ListElement {
            text: "restless"
            max: 100
            name: qsTr("restless sleep %")
        }
        ListElement {
            text: "efficiency"
            max: 100
            name: qsTr("sleep efficiency %")
        }
        ListElement {
            text: "midpoint_time"
            max: 18000
            name: qsTr("time to midpoint")
        }
        ListElement {
            text: "hr_lowest"
            max: 50
            name: qsTr("lowest hearth beat rate")
        }
        ListElement {
            text: "hr_average"
            max: 60
            name: qsTr("average hearth beat rate")
        }
        ListElement {
            text: "rmssd"
            max: 100
            name: qsTr("hearth beat rate variation")
        }
        ListElement {
            text: "breath_average"
            max: 20
            name: qsTr("average breath rate")
        }
        ListElement {
            text: "temperature_delta"
            max: 3
            name: qsTr("temperature change")
        }
        //ListElement {
        //    text: "hypnogram_5min"
        //}
        //ListElement {
        //    text: "hr_5min"
        //}
        //ListElement {
        //    text: "rmssd_5min"
        //}
    }

    /*
    "activity": {
        "summary_date": "2016-09-03",
        "day_start": "2016-09-03T04:00:00+03:00",
        "day_end": "2016-09-04T03:59:59+03:00",
        "timezone": 180,
        "score": 87,
        "score_stay_active": 90,
        "score_move_every_hour": 100,
        "score_meet_daily_targets": 60,
        "score_training_frequency": 96,
        "score_training_volume": 95,
        "score_recovery_time": 100,
        "daily_movement": 7806,
        "non_wear": 313,
        "rest": 426,
        "inactive": 429,
        "inactivity_alerts": 0,
        "low": 224,
        "medium": 49,
        "high": 0,
        "steps": 9206,
        "cal_total": 2540,
        "cal_active": 416,
        "met_min_inactive": 9,
        "met_min_low": 167,
        "met_min_medium_plus": 159,
        "met_min_medium": 159,
        "met_min_high": 0,
        "average_met": 1.4375,
        "class_5min":"1112211111111111111111111111111111111111111111233322322223333323322222220000000000000000000000000000000000000000000000000000000233334444332222222222222322333444432222222221230003233332232222333332333333330002222222233233233222212222222223121121111222111111122212321223211111111111111111",
        "met_1min": [ 1.2,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,1.2,0.9,1.1,1.2,1.1,1.1,0.9,0.9,0.9,1.1,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,1.2,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.3,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.3,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.2,0.9,0.9,0.9,1.1,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.9,2.7,2.8,1.6,1.8,1.5,1.5,1.8,1.6,1.9,1.4,1.9,1.4,1.5,1.7,1.7,1.4,1.5,1.5,1.7,1.3,1.7,1.7,1.9,1.5,1.4,1.8,2.2,1.4,1.6,1.7,1.7,1.4,1.5,1.6,1.4,1.4,1.7,1.6,1.3,1.3,1.4,1.3,2.6,1.6,1.7,1.5,1.6,1.6,1.8,1.9,1.8,1.7,2,1.8,2,1.7,1.5,1.3,2.4,1.4,1.6,2,2.8,1.8,1.5,1.8,1.6,1.5,1.8,1.8,1.4,1.6,1.7,1.7,1.6,1.5,1.5,1.8,1.8,1.7,1.8,1.8,1.5,2.4,1.9,1.3,1.2,1.4,1.3,1.5,1.2,1.4,1.4,1.6,1.5,1.6,1.4,1.4,1.6,1.6,1.6,1.8,1.7,1.3,1.9,1.3,1.2,1.2,1.3,1.5,1.4,1.4,1.3,1.7,1.2,1.3,1.5,1.7,1.5,2.6,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.9,3.6,0.9,0.1,0.1,0.1,0.1,0.1,3.3,3.8,3.6,2.3,3.1,3.2,3.5,4.3,3.6,1.7,1.6,2.8,2.1,3.3,4.9,3.3,1.8,5,4.6,5.3,4.9,4.9,5.4,5.4,5.2,5.3,4.5,5.3,4.5,4.4,5,5.3,4.8,4.6,1.8,4.4,3.6,3.5,2.9,2.6,3.1,0.9,0.1,2.9,3.8,1.7,2.8,1.8,1.5,1.4,1.4,1.3,1.4,1.3,1.4,1.3,1.3,1.2,1.3,1.6,1.5,1.5,1.4,1.8,1.3,1.4,1.3,1.4,1.6,1.6,1.4,1.3,1.4,1.4,1.6,1.5,1.4,2,1.5,1.4,1.4,1.3,1.2,1.3,1.3,1.6,1.6,1.5,1.5,1.8,1.5,1.2,1.2,1.5,1.6,1.5,1.7,1.7,1.5,1.6,2.5,1.5,1.3,1.2,1.4,1.6,1.3,1.6,1.7,2,1.2,1.3,1.9,3.3,2.8,1.7,1.4,1.4,1.4,1.5,1.4,1.5,1.3,2,1.4,1.2,1.5,1.2,1.2,1.8,2.4,3,4.6,4,3.6,2.2,0.9,4,3.3,2.6,4.4,2.3,4.5,5.2,5.2,5,5.3,5,4.6,5.4,5.7,5.5,5.2,5.5,3.8,5,5,4.4,4.8,5.5,4.1,4.5,3.2,3.3,2.6,4,3.4,2.1,1.5,1.5,1.4,1.4,1.5,1.3,1.3,1.5,1.4,1.2,1.2,1.4,1.2,1.2,1.2,1.2,1.1,1.3,1.6,1.8,1.5,1.3,1.5,1.5,1.6,1.5,1.6,1.4,1.4,1.4,1.3,1.3,1.3,1.3,1.2,1.3,1.2,1.2,1.2,0.9,1.1,1.1,1.1,1.1,1.7,1.1,0.9,0.9,0.9,1.1,1.1,0.9,1.1,0.9,1.2,1.3,2.4,2.2,1.6,0.9,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,2.4,2.7,1.3,1.4,1.3,1.2,1.3,1.2,1.4,1.4,2.2,1.7,2.9,1.3,1.4,1.2,1.3,1.8,2.1,2.2,2.5,1.9,2.3,2.7,2.3,2,1.7,2,2.1,1.7,1.8,1.2,1.2,0.9,0.9,1.3,1.4,1.2,1.6,1.7,2.4,2.4,2,1.2,1.3,1.3,1.2,1.3,2.4,1.2,1.2,1.3,2,1.3,1.8,1.2,1.2,1.2,1.2,1.8,1.7,1.3,1.3,1.6,1.8,2.2,1.3,1.5,1.5,1.8,1.3,1.7,1.8,2.1,2,1.9,1.6,2,1.8,2,1.6,1.2,1.7,1.5,1.5,2.3,2.6,3.3,3.3,1.5,1.2,1.3,1.5,1.3,1.5,1.5,3.7,2.4,3.3,3,3.7,4.5,2.8,1.3,1.9,2.2,1.6,1.3,1.2,1.3,1.3,2.9,3.3,2,2.2,2.6,2.7,4.5,3.2,4.5,3.3,2.1,3.4,3,2.7,3.3,2.1,2.3,1.7,1.7,2.8,0.9,2.2,0.9,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,1.4,1.6,1.2,1.2,1.3,1.7,1.3,1.5,1.3,1.3,1.3,1.3,1.5,2.9,1.5,1.2,1.4,1.2,1.3,1.3,1.4,1.3,1.4,1.4,1.2,1.2,1.3,1.2,1.2,1.2,1.2,1.4,1.4,1.3,1.2,1.2,1.2,1.9,1.4,1.3,1.4,1.3,1.7,1.3,2.1,2.9,1.9,1.8,1.6,1.4,1.4,1.7,1.2,1.5,1.6,1.9,1.5,1.8,1.3,1.2,1.8,2.3,2,2.2,1.7,1.5,1.2,1.2,1.2,1.1,1.1,1.4,3.3,2,1.5,2.4,2.4,1.6,2.6,2.5,2.3,1.5,1.2,1.2,1.2,1.3,1.2,1.2,1.3,2,1.5,1.7,1.2,1.3,1.6,1.5,1.4,1.4,1.4,1.2,1.2,1.1,1.1,0.9,0.9,1.3,0.9,0.9,0.9,0.9,0.9,1.3,1.1,1.1,1.3,0.9,0.9,1.3,0.9,1.5,2.1,2.1,1.2,1.2,1.3,1.2,1.2,1.5,1.4,1.3,1.2,1.2,1.3,1.3,1.2,1.3,1.2,1.2,1.2,1.2,1.2,1.4,1.2,1.5,1.5,1.4,1.4,1.5,1.5,1.3,1.2,1.2,0.9,2.3,1.8,1.3,1.2,1.2,1.1,0.9,0.9,0.9,1.2,1.6,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,1.9,1.2,1.3,1.1,1.3,1.1,0.9,0.9,0.9,1.2,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,1.1,0.9,0.9,0.9,0.9,1.2,0.9,0.9,0.9,1.1,0.9,0.9,1.2,1.6,1.4,1.3,1.4,1.5,1.2,1.2,1.1,0.9,0.9,1.1,1.1,0.9,0.9,1.1,1.1,0.9,0.9,0.9,0.9,0.9,1.1,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,1.1,1.3,0.9,1.3,1.1,1.1,0.9,1.1,0.9,1.1,0.9,1.3,1.2,0.9,1.1,0.9,0.9,0.9,1.1,0.9,0.9,1.1,1.2,1.6,0.9,1.1,1.4,3.7,2.8,3.2,2.7,1.2,1.2,1.3,1.3,1.3,1.2,1.2,0.9,0.9,0.9,1.1,1.1,0.9,1.1,1.3,0.9,1.1,1.1,1.1,1.3,4.1,1.5,1.7,1.2,1.2,1.2,1.2,1.2,1.2,1.2,1.1,0.9,0.9,0.9,1.1,1.3,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,1.1,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,1.1,0.9,0.9,0.9,0.9,0.9,0.9,0.9,1.1,0.9,1.3,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9 ],
        "rest_mode_state": 0
    }
    */
}
