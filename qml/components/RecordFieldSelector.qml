import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/datab.js" as DataB

ComboBox {
    property string record
    //property alias activityModel: activityItemList
    //property alias readinessModel: readinessItemList
    //property alias sleepModel: sleepItemList
    property bool showArrays: false
    signal selected(string selectedStr, real max, string titleStr)

    menu: ContextMenu {
        Repeater {
            model: record === DataB.keyActivity? activityItemList :
                        record === DataB.keyReadiness? readinessItemList :
                            record === DataB.keySleep? sleepItemList: 0
            MenuItem {
                text: model.field
                visible: showArrays? true : !model.array
                onClicked: {
                    selected(text, max, desc)
                }
                property real max: model.max
                property string desc: model.desc
            }
        }
    }

    ActivityList {
        id: activityItemList
    }

    ReadinessList {
        id: readinessItemList
    }

    SleepList {
        id: sleepItemList
    }

    function checkIndex(str) {
        //console.log("max " + str + "_" + activityModel.count + "." + readinessModel.count + "." + sleepModel.count)
        var i=0, ind=-1, model;
        if (record === DataB.keyActivity) {
            model = activityItemList;
        } else if (record === DataB.keyReadiness) {
            model = readinessItemList;
        } else if (record === DataB.keySleep) {
            model = sleepItemList;
        }

        if (model !== undefined) {
            while (i<model.count) {
                if (str === model.get(i).field) {
                    ind = i;
                }
                i++;
            }
        }
        //console.log("max " + str + " " + ind)

        return ind;
    }
}
