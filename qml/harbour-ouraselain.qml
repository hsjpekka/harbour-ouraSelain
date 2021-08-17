import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "./utils/datab.js" as DataB
import "pages"

ApplicationWindow
{
    id: applicationWindow
    initialPage: Component {
        FirstPage {
            onRefreshOuraCloud: downloadOuraCloud()
            onOpenSettings: setUpNow()
        }
    }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    //allowedOrientations: defaultAllowedOrientations
    Component.onCompleted: {
        readDb()
        if (personalAccessToken > "") {
            downloadOuraCloud()
        } else {
            setUpNow()
        }
        startingUp = false
    }

    property var db: null
    property date latestStored: new Date(0)
    property string personalAccessToken: ""
    property bool startingUp: true

    signal storedDataRead()

    Timer {
        interval: 10*1000
        repeat: false // true to read few records at a time
        running: true
        onTriggered: {
            var oldRecs, i=0, iN;

            oldRecs = DataB.readCloudDb(); // read all || since date1 || date1 - date2
            while (i < oldRecs.rows.length) {
                oura.storeOldRecords(oldRecs.rows[i][DataB.keyType], oldRecs.rows[i][DataB.keyRec]);
                i++;
            }

            if (oldRecs.rows.length > 0) {
                console.log("ensimmäinen tallenne " + oura.firstDate());
                console.log("viimeinen tallenne " + oura.lastDate());
                storedDataRead();
            }
        }
    }

    Connections {
        target: oura
        onFinishedActivity: {
            console.log("onFinishedActivity")
            DataB.storeCloudRecords(DataB.keyActivity, oura.printActivity())
            //ouraActivityReady()
        }
        onFinishedSleep: {
            console.log("onFinishedSleep")
            DataB.storeCloudRecords(DataB.keySleep, oura.printSleep())
            //ouraSleepReady()
        }
        onFinishedReadiness: {
            console.log("onFinishedReadiness")
            DataB.storeCloudRecords(DataB.keyReadiness, oura.printReadiness())
            //ouraReadinessReady()
        }
        onFinishedBedTimes: {
            console.log("onFinishedBedTimes")
            DataB.storeCloudRecords(DataB.keyBedTime, oura.printBedTimes())
            //ouraBedTimesReady()
        }
        onFinishedInfo: {
            console.log("onFinishedInfo")
            DataB.storeCloudRecords(DataB.keyUserInfo, oura.printInfo())
            //ouraUserReady()
        }
    }

    RemorsePopup {
        id: remorse
    }

    function downloadOuraCloud(){
        oura.downloadOuraCloud();
        return;
    }

    function readDb() {
        var oldRecs, i=0, iN;
        if(db === null) {
            try {
                db = LocalStorage.openDatabaseSync("oura", "0.1", "daily records", 10000);
            } catch (err) {
                DataB.log("Error in opening the database: " + err);
                return -1;
            };
        }

        DataB.dbas = db;
        DataB.createTables();
        DataB.readSettingsDb();
        personalAccessToken = DataB.getSetting(DataB.keyPersonalToken, "");
        if (personalAccessToken > "") {
            oura.setPersonalAccessToken(personalAccessToken);
        }

        //console.log("vanhojen tietojen luku");
        //oldRecs = DataB.readCloudDb(); // read all || since date1 || date1 - date2
        //while (i < oldRecs.rows.length) {
        //    oura.storeOldRecords(oldRecs.rows[i][DataB.keyType], oldRecs.rows[i][DataB.keyRec]);
        //    i++;
        //}

        //if (oldRecs.rows.length > 0) {
        //    console.log("ensimmäinen tallennettu " + oura.firstDate());
        //    console.log("viimeinen tallennettu " + oura.lastDate());
        //}
        return;
    }

    function setUpNow() {
        var subPage = pageStack.push(Qt.resolvedUrl("pages/Settings.qml"), {
                                             "token": personalAccessToken
                                         })
        subPage.setToken.connect(function () {
            var msg, newTkn = subPage.token
            if (newTkn === "") {
                msg = qsTr("Clearing token!")
            } else {
                msg = qsTr("Changing token to %1.").arg(newTkn)
            }

            DataB.log("new token >>" + newTkn.slice(0, 8) + "... <<")

            remorse.execute(msg, function() {
                DataB.updateSettings(DataB.keyPersonalToken, newTkn)
                oura.setPersonalAccessToken(newTkn)
                personalAccessToken = newTkn
                downloadOuraCloud()
            })
        })

        return
    }

}
