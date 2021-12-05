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
      "summary_date": "2017-11-05",
      "period_id": 0,
      "is_longest": 1,
      "timezone": 120,
      "bedtime_start": "2017-11-06T02:13:19+02:00",
      "bedtime_end": "2017-11-06T08:12:19+02:00",
      "score": 70,
      "score_total": 57,
      "score_disturbances": 83,
      "score_efficiency": 99,
      "score_latency": 88,
      "score_rem": 97,
       "score_deep": 59,
      "score_alignment": 31,
      "total": 20310,
      "duration": 21540,
      "awake": 1230,
      "light": 10260,
      "rem": 7140,
      "deep": 2910,
      "onset_latency": 480,
      "restless": 39,
      "efficiency": 94,
      "midpoint_time": 11010,
      "hr_lowest": 49,
      "hr_average": 56.375,
      "rmssd": 54
      "breath_average": 13,
      "temperature_delta": -0.06,
      "hypnogram_5min": "443432222211222333321112222222222111133333322221112233333333332232222334",
      "hr_5min": [0, 53, 51, 0, 50, 50, 49, 49, 50, 50, 51, 52, 52, 51, 53, 58, 60, 60, 59, 58, 58, 58, 58, 55, 55, 55, 55, 56, 56, 55, 53, 53, 53, 53, 53, 53, 57, 58, 60, 60, 59, 57, 59, 58, 56, 56, 56, 56, 55, 55, 56, 56, 57, 58, 55, 56, 57, 60, 58, 58, 59, 57, 54, 54, 53, 52, 52, 55, 53, 54, 56, 0],
      "rmssd_5min": [0, 0, 62, 0, 75, 52, 56, 56, 64, 57, 55, 78, 77, 83, 70, 35, 21, 25, 49, 44, 48, 48, 62, 69, 66, 64, 79, 59, 67, 66, 70, 63, 53, 57, 53, 57, 38, 26, 18, 24, 30, 35, 36, 46, 53, 59, 50, 50, 53, 53, 57, 52, 41, 37, 49, 47, 48, 35, 32, 34, 52, 57, 62, 57, 70, 81, 81, 65, 69, 72, 64, 0]
    }
    // */
    ListElement {
        field: "score"
        max: 100
        desc: qsTr("sleep")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_total"
        max: 100
        desc: qsTr("sleep time")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_disturbances"
        max: 100
        desc: qsTr("sleep disturbances")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_efficiency"
        max: 100
        desc: qsTr("sleep efficiency")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_latency"
        max: 100
        desc: qsTr("sleep latency")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_rem"
        max: 100
        desc: qsTr("REM sleep")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_deep"
        max: 100
        desc: qsTr("deep sleep")
        unit: ""
        array: false
    }
    ListElement {
        field: "score_alignment"
        max: 100
        desc: qsTr("sleep alignment")
        unit: ""
        array: false
    }
    ListElement {
        field: "total"
        max: 32400 // 9 h
        desc: qsTr("total sleep time")
        unit: "second"
        array: false
    }
    ListElement {
        field: "duration"
        max: 36000 // 10 h
        desc: qsTr("bed time")
        unit: "second"
        array: false
    }
    ListElement {
        field: "awake"
        max: 7200 // 2 h
        desc: qsTr("night time awake")
        unit: "second"
        array: false
    }
    ListElement {
        field: "light"
        max: 14400 // 4 h
        desc: qsTr("light sleep")
        unit: "second"
        array: false
    }
    ListElement {
        field: "rem"
        max: 14400 // 4 h
        desc: qsTr("REM sleep")
        unit: "second"
        array: false
    }
    ListElement {
        field: "deep"
        max: 14400 // 4 h
        desc: qsTr("deep sleep")
        unit: "second"
        array: false
    }
    ListElement {
        field: "onset_latency"
        max: 7200 // 2 h
        desc: qsTr("sleep latency")
        unit: "second"
        array: false
    }
    ListElement {
        field: "restless"
        max: 100 // %
        desc: qsTr("restless sleep %")
        unit: "%"
        array: false
    }
    ListElement {
        field: "efficiency"
        max: 100
        desc: qsTr("sleep efficiency %")
        unit: "%"
        array: false
    }
    ListElement {
        field: "midpoint_time"
        max: 18000 // 5 h
        desc: qsTr("time to midpoint")
        unit: "second"
        array: false
    }
    ListElement {
        field: "hr_lowest"
        max: 50
        desc: qsTr("lowest hearth beat rate")
        unit: "/min"
        array: false
    }
    ListElement {
        field: "hr_average"
        max: 60
        desc: qsTr("average hearth beat rate")
        unit: "/min"
        array: false
    }
    ListElement {
        field: "rmssd"
        max: 100
        desc: qsTr("hearth beat rate variation")
        unit: "ms"
        array: false
    }
    ListElement {
        field: "breath_average"
        max: 20
        desc: qsTr("average breath rate")
        unit: "/min"
        array: false
    }
    ListElement {
        field: "temperature_delta"
        max: 3
        desc: qsTr("temperature change")
        unit: "C"
        array: false
    }
    ListElement {
        field: "hypnogram_5min"
        max: 4
        desc: qsTr("sleep levels")
        unit: ""
        array: true
    }
    ListElement {
        field: "hr_5min"
        max: 60
        desc: qsTr("5 min average hearth rate")
        unit: "/min"
        array: true
    }
    ListElement {
        field: "rmssd_5min"
        max: 150
        desc: qsTr("5 min average hearth rate variation")
        unit: "ms"
        array: true
    }
}
