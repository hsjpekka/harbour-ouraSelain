import QtQuick 2.2
import Sailfish.Silica 1.0
import "../utils/datab.js" as DataB
import "../components/"

Dialog {
    id: page

    property string chartTitle
    property string chartType
    property string chartTable
    property string chartValue1
    property string chartValue2
    property string chartValue3
    property string chartValue4
    property string chartLowBar
    property string chartHighBar
    property int chartMaxValue

    onAccepted: {
        if (chartTable === DataB.keySleep &&
                chartType === DataB.chartTypeSleep) {
            chartTitle = qsTr("sleep modes")
            chartValue1 = "deep"
            chartValue2 = "light"
            chartValue3 = "rem"
            chartValue4 = "awake"
            chartMaxValue = 10*60*60
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            DialogHeader {
                title: qsTr("Chart properties")
            }

            ComboBox {
                id: recordType
                label: qsTr("record")
                width: parent.width
                currentIndex: checkIndex(chartTable)
                menu: ContextMenu {
                    ListModel {
                        id: recordsModel
                        ListElement {
                            value: "activity" //DataB.keyActivity
                        }
                        ListElement {
                            value: "readiness" //DataB.keyReadiness
                        }
                        ListElement {
                            value: "sleep" //DataB.keySleep
                        }
                    }

                    Repeater {
                        model: recordsModel
                        MenuItem {
                            text: model.value
                            onClicked: {
                                chartTable = text
                            }
                        }
                    }
                    /*
                    MenuItem {
                        text: DataB.keyActivity
                        onClicked: {
                            _chartTable = DataB.keyActivity
                        }
                    }
                    MenuItem {
                        text: DataB.keyReadiness
                        onClicked: {
                            _chartTable = DataB.keyReadiness
                        }
                    }
                    MenuItem {
                        text: DataB.keySleep
                        onClicked: {
                            _chartTable = DataB.keySleep
                        }
                    }
                    // */
                }

                function checkIndex(str) {
                    console.log("tallenne " + str + " " + recordsModel.count)
                    var i=0, ind=-1;
                    while (i<recordsModel.count) {
                        if (str === recordsModel.get(i).value) {
                            ind = i;
                        }
                        console.log(recordsModel.get(i).value + " " + str)
                        i++;
                    }
                    console.log("tallenne " + str + " " + ind)
                    return ind;
                }
            }

            ComboBox {
                label: qsTr("chart type")
                width: parent.width
                currentIndex: checkIndex(chartType)
                menu: ContextMenu {
                    ListModel {
                        id: typesModelA
                        ListElement {
                            text: qsTr("single column")
                            value: "ctSingle" //DataB.chartTypeSingle
                        }
                        ListElement {
                            text: qsTr("column and cross bar")
                            value: "ctMin" //DataB.chartTypeMin
                        }
                        ListElement {
                            text: qsTr("column and limits")
                            value: "ctMaxmin"//DataB.chartTypeMaxmin
                        }
                    }
                    ListModel {
                        id: typesModelB
                        ListElement {
                            text: qsTr("single column")
                            value: "ctSingle" //DataB.chartTypeSingle
                        }
                        ListElement {
                            text: qsTr("column and cross bar")
                            value: "ctMin" //DataB.chartTypeMin
                        }
                        ListElement {
                            text: qsTr("column and limits")
                            value: "ctMaxmin"//DataB.chartTypeMaxmin
                        }
                        ListElement {
                            text: qsTr("sleep types")
                            value: "ctSleepTypes" //DataB.chartTypeSleep
                        }
                    }

                    Repeater {
                        model: chartTable === "sleep"?
                                   typesModelB : typesModelA
                        MenuItem {
                            text: model.text
                            onClicked: {
                                chartType = val
                            }
                            property string val: model.value
                        }
                    }
                    /*
                    MenuItem {
                        text: qsTr("single column")
                        onClicked: {
                            _chartType = DataB.chartTypeSingle
                        }
                    }
                    MenuItem {
                        text: qsTr("column and cross bar")
                        onClicked: {
                            _chartType = DataB.chartTypeMin
                        }
                    }
                    MenuItem {
                        text: qsTr("column and cross bar")
                        onClicked: {
                            _chartType = DataB.chartTypeMin
                        }
                    }
                    MenuItem {
                        text: qsTr("sleep types")
                        visible: _chartTable === DataB.keySleep
                        onClicked: {
                            _chartType = DataB.chartTypeSleep
                        }
                    }
                    // */
                }

                function checkIndex(str) {
                    console.log("kuvaaja " + str + " - " + typesModelA.count + "_" + typesModelB.count)
                    var i=0, ind=-1, model;
                    if (chartTable === "sleep") {
                        model = typesModelB
                    } else {
                        model = typesModelA
                    }

                    while (i<model.count) {
                        if (str === model.get(i).value) {
                            ind = i;
                        }
                        i++;
                    }
                    console.log("kuvaaja " + str + " " + ind)
                    return ind;
                }
            }

            RecordFieldSelector {
                //width: parent.width
                label: chartType === DataB.chartTypeSingle?
                           qsTr("value") : qsTr("column")
                record: chartTable
                visible: chartType !== DataB.chartTypeSleep
                currentIndex: checkIndex(chartValue1)
                onSelected: {
                    chartValue1 = selectedStr
                    chartMaxValue = max
                    maxInput.text = max
                    chartTitle = titleStr
                }

                function checkIndex(str) {
                    console.log("pylväs " + str + "_" + activityModel.count + "." + readinessModel.count + "." + sleepModel.count)
                    var i=0, ind=-1, model;
                    if (record === DataB.keyActivity) {
                        model = activityModel;
                    } else if (record === DataB.keyReadiness) {
                        model = readinessModel;
                    } else if (record === DataB.keySleep) {
                        model = sleepModel;
                    }

                    if (model !== undefined) {
                        while (i<model.count) {
                            if (str === model.get(i).text) {
                                ind = i;
                            }
                            i++;
                        }
                    }
                    console.log("pylväs " + str + " " + ind)

                    return ind;
                }
            }
            RecordFieldSelector {
                //width: parent.width
                label: chartType === DataB.chartTypeMaxmin?
                           qsTr("lower limit") : qsTr("cross bar")
                record: chartTable
                visible: (chartType === DataB.chartTypeMin ||
                          chartType === DataB.chartTypeMaxmin)
                currentIndex: checkIndex(chartLowBar)
                onSelected: {
                    chartLowBar = selectedStr
                }

                function checkIndex(str) {
                    console.log("min " + str + "_" + activityModel.count + "." + readinessModel.count + "." + sleepModel.count)
                    var i=0, ind=-1, model;
                    if (record === DataB.keyActivity) {
                        model = activityModel;
                    } else if (record === DataB.keyReadiness) {
                        model = readinessModel;
                    } else if (record === DataB.keySleep) {
                        model = sleepModel;
                    }

                    if (model !== undefined) {
                        while (i<model.count) {
                            if (str === model.get(i).text) {
                                ind = i;
                            }
                            i++;
                        }
                    }
                    console.log("min " + str + " " + ind)

                    return ind;
                }
            }
            RecordFieldSelector {
                //width: parent.width
                label: qsTr("upper limit")
                record: chartTable
                visible: chartType === DataB.chartTypeMaxmin
                currentIndex: checkIndex(chartHighBar)
                onSelected: {
                    chartHighBar = selectedStr
                }

                function checkIndex(str) {
                    //console.log("max " + str + "_" + activityModel.count + "." + readinessModel.count + "." + sleepModel.count)
                    var i=0, ind=-1, model;
                    if (record === DataB.keyActivity) {
                        model = activityModel;
                    } else if (record === DataB.keyReadiness) {
                        model = readinessModel;
                    } else if (record === DataB.keySleep) {
                        model = sleepModel;
                    }

                    if (model !== undefined) {
                        while (i<model.count) {
                            if (str === model.get(i).text) {
                                ind = i;
                            }
                            i++;
                        }
                    }
                    //console.log("max " + str + " " + ind)

                    return ind;
                }
            }

            TextField {
                id: maxInput
                text: chartMaxValue
                label: qsTr("chart maximum")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: IntValidator {bottom: 0}
                EnterKey.onClicked: {
                    chartMaxValue = text
                    focus = false
                }
            }
        }
    }
}
