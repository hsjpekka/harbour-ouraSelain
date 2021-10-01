import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/datab.js" as DataB
import "../components/"

Page {
    id: page

    // "index", "type", "record"
    property string pageTitle: qsTr("Database viewer")

    ListModel {
        id: records

        ListElement {
            card: "" // yyyymmddpp
            dataKey: ""
            dataValue: ""
        }

        function add(section, key, data) {
            records.append({ "card": section + "", "dataKey": key + "", "dataValue": data + "" })
        }
    }

    /*
    ListModel {
        id: recordsActivity

        ListElement {
            index: ""
            type: ""
            record: ""
        }

        function add(ind, category, data) {
            recordsInfo.append({ "index": ind, "type": category, "record": data })
        }
    }

    ListModel {
        id: recordsBedtimes

        ListElement {
            index: ""
            type: ""
            record: ""
        }

        function add(ind, category, data) {
            recordsInfo.append({ "index": ind, "type": category, "record": data })
        }
    }

    ListModel {
        id: recordsReadiness

        ListElement {
            index: ""
            type: ""
            record: ""
        }

        function add(ind, category, data) {
            recordsInfo.append({ "index": ind, "type": category, "record": data })
        }
    }

    ListModel {
        id: recordsSleep

        ListElement {
            index: ""
            type: ""
            record: ""
        }

        function add(ind, category, data) {
            recordsInfo.append({ "index": ind, "type": category, "record": data })
        }
    }

    ListModel {
        id: ouraRespond

        ListElement {
            index: ""
            type: ""
            record: ""
        }

        function add(ind, category, data) {
            recordsInfo.append({ "index": ind, "type": category, "record": data })
        }
    }
    // */

    Component {
        id: dataFieldView

        Item {
            width: page.width - 2*x
            height: dataTxt.y + dataTxt.height
            x: Theme.horizontalPageMargin

            property bool singleRow: true
            property string lblTxt: dataKey
            property string dbTxt: dataValue

            Label {
                id: lbl
                width: parent.width
                text: parent.lblTxt + " :"
                color: Theme.secondaryHighlightColor
            }

            Label {
                id: dataTxt
                x: Theme.paddingLarge
                y: lbl.height + Theme.paddingSmall
                width: parent.width - x
                wrapMode: parent.singleRow ? Text.NoWrap : Text.WrapAtWordBoundaryOrAnywhere
                truncationMode: TruncationMode.Fade
                text: parent.dbTxt
            }

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onClicked: {
                    parent.singleRow = !parent.singleRow
                }
            }

        }
    }

    Label { // empty page hint
        id: emptyLabel
        text: qsTr("use the pull down menu")
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeLarge
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 2*x
        x: Theme.horizontalPageMargin
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    }

    SilicaListView {
       height: page.height
       width: parent.width

       PullDownMenu {
           MenuItem {
               text: qsTr("activity")
               onClicked: {
                   changeRecord(DataB.keyActivity)
               }
           }
           MenuItem {
               text: qsTr("ideal bed times")
               onClicked: {
                   changeRecord(DataB.keyBedTime)
               }
           }
           MenuItem {
               text: qsTr("readiness")
               onClicked: {
                   changeRecord(DataB.keyReadiness)
               }
           }
           MenuItem {
               text: qsTr("sleep")
               onClicked: {
                   changeRecord(DataB.keySleep)
               }
           }
           MenuItem {
               text: qsTr("oura cloud")
               onClicked: {
                   changeRecord("OuraCloud")
               }
           }
       }

       model: records
       header: Component {
           PageHeader {
               title: pageTitle
           }
       }
       delegate: dataFieldView
       section.property: "card"
       section.delegate: SectionHeader {
           text: section
       }

       VerticalScrollDecorator {}
   }

    function changeRecord(recordType) {
        var i=0, iN, rec, key, list, sect, table;
        emptyLabel.visible = false;
        records.clear();
        if (recordType === "OuraCloud") {
            rec = JSON.parse(oura.printInfo());
            for (key in rec) {
                records.add("User Info", key, rec[key]);
            }

            rec = JSON.parse(oura.printActivity());
            if (rec[DataB.keyActivity] && rec[DataB.keyActivity].length) {
                list = rec[DataB.keyActivity];
                iN = list.length;
                while (i < iN) {
                    sect = "Activity, " + (i+1);
                    rec = list[i];
                    for(key in rec) {
                        records.add(sect, key, rec[key]);
                    }
                    i++;
                }
            }

            i = 0;
            rec = JSON.parse(oura.printBedTimes());
            if (rec[DataB.keyBedTime] && rec[DataB.keyBedTime].length) {
                list = rec[DataB.keyBedTime];
                iN = list.length;
                while (i < iN) {
                    sect = "Ideal bed times, " + (i+1);
                    rec = list[i];
                    for(key in rec) {
                        records.add(sect, key, rec[key]);
                    }
                    i++;
                }
            }

            i = 0;
            rec = JSON.parse(oura.printReadiness());
            if (rec[DataB.keyReadiness] && rec[DataB.keyReadiness].length) {
                list = rec[DataB.keyReadiness];
                iN = list.length;
                while (i < iN) {
                    sect = "Readiness, " + (i+1);
                    rec = list[i];
                    for(key in rec) {
                        records.add(sect, key, rec[key]);
                    }
                    i++;
                }
            }

            i = 0;
            rec = JSON.parse(oura.printSleep());
            if (rec[DataB.keySleep] && rec[DataB.keySleep].length) {
                list = rec[DataB.keySleep];
                iN = list.length;
                while (i < iN) {
                    sect = "Sleep, " + (i+1);
                    rec = list[i];
                    for(key in rec) {
                        records.add(sect, key, rec[key]);
                    }
                    i++;
                }
            }
        } else {
            table = DataB.readCloudDb(recordType);
            iN = table.rows.length;
            while( i < iN) {
                rec = table.rows[i];
                for (key in rec) {
                    if (i === 0) {
                        console.log(key + " :: " + rec[key]);
                    }
                    records.add(i, key, rec[key]);
                }
                i++;
                if (i > 5) {
                    i=iN+1;
                }
            }

            //iN = oura.numberOfRecords(recordType);
            //while (i < iN) {
            //    rec = oura.recordNr(recordType, i);
            //    for (key in rec) {
            //        records.add(i, key, rec[key])
            //    }
            //    i++;
            //}
        }

    }

    Component.onCompleted: {
        records.clear();
    }
}
