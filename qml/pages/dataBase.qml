import QtQuick 2.0
import Sailfish.Silica 1.0
import "../utils/datab.js" as DataB
import "../components/"

Page {
    id: page
    Component.onCompleted: {
        records.clear();
    }

    // "index", "type", "record"
    property string pageTitle: qsTr("Database viewer")
    property string selectedKey

    ListModel { // {card, dataKey, dataValue}
        id: records

        /*
        ListElement {
            card: "" // yyyymmddpp
            dataKey: ""
            dataValue: ""
        }
        //*/

        function add(sctn, key, data) {
            records.append({ "card": sctn + "", "dataKey": key + "", "dataValue": data + "" })
        }
    }

    Component {
        id: dataFieldView

        ListItem {
            id: dataLabel
            width: page.width - 2*x
            contentHeight: dataTxt.y + dataTxt.height
            x: Theme.horizontalPageMargin
            onClicked: {
                singleRow = !singleRow
                selectedKey = dataKey //lblTxt
                if (singleRow) {
                    dataTxt.wrapMode = Text.NoWrap
                } else {
                    dataTxt.wrapMode = Text.WrapAtWordBoundaryOrAnywhere
                }
            }
            onPressAndHold: {
                selectedKey = dataKey //lblTxt
            }

            menu: Component {
                id: dbItemMenu
                ContextMenu {
                    MenuItem {
                        text: qsTr("remove")
                        onClicked: {
                            DataB.removeFromSettings(selectedKey)
                            dataLabel.remove();
                        }
                    }
                }
            }

            property bool singleRow: true
            property string lblTxt: dataKey
            property string dbTxt: dataValue
            property string recordType: card

            function remove() {
                remorseDelete(function () {
                    records.remove(index);
                });
                return;
            }

            Label {
                id: lbl
                width: parent.width
                text: dataKey + " :" //parent.lblTxt + " :"
                color: Theme.secondaryHighlightColor
            }

            Label {
                id: dataTxt
                x: Theme.paddingLarge
                y: lbl.height + Theme.paddingSmall
                width: parent.width - x
                wrapMode: Text.NoWrap//Text.WrapAtWordBoundaryOrAnywhere
                //visible: parent.singleRow
                truncationMode: TruncationMode.Fade
                text: dataValue //parent.dbTxt
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
               text: qsTr("settings")
               onClicked: {
                   changeRecord("settings")
               }
           }
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
        pageTitle = recordType;
        if (recordType === "OuraCloud") {
            rec = JSON.parse(ouraCloud.printInfo());
            for (key in rec) {
                records.add("User Info", key, rec[key]);
            }

            rec = JSON.parse(ouraCloud.printActivity());
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
            rec = JSON.parse(ouraCloud.printBedTimes());
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
            rec = JSON.parse(ouraCloud.printReadiness());
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
            rec = JSON.parse(ouraCloud.printSleep());
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
        } else if (recordType === "settings") {
            iN = DataB.settingsTable.length;
            while (i < iN) {
                records.add(i, DataB.settingsTable[i].key,
                            DataB.settingsTable[i].value);
                i++;
            }
        } else {
            table = DataB.readCloudDb(recordType);
            iN = table.rows.length;
            while( i < iN) {
                rec = table.rows[i];
                for (key in rec) {
                    records.add(i, key, rec[key]);
                }
                i++;
            }
        }

        return;
    }
}
