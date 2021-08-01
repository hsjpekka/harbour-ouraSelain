import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "./utils/datab.js" as DataB
import "pages"

ApplicationWindow
{
    id: applicationWindow
    initialPage: Component {
        FirstPage { }
    }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    Component.onCompleted: {
        readDb()
        if (personalAccessToken > "") {
            console.log("uusien tietojen luku");
            downloadOuraCloud()
        } else {
            var dialog = applicationWindow.pageStack.push(Qt.resolvedUrl("pages/Settings.qml"))
            //dialog.accepted.connect(function () {
            //} )
            //setUp.start()
        }
        startingUp = false
    }

    property var db: null
    property date latestStored: new Date(0)
    property string personalAccessToken: ""
    property bool startingUp: true
    onPersonalAccessTokenChanged: {
        if (!startingUp && personalAccessToken > "") {
            //downloadOuraCloud()
        }
    }

    signal ouraActivityReady();
    signal ouraBedTimesReady();
    signal ouraReadinessReady();
    signal ouraSleepReady();
    signal ouraUserReady();

    Connections {
        target: oura
        onFinishedActivity: {
            console.log("onFinishedActivity")
            DataB.storeCloudRecords(DataB.keyActivity, oura.printActivity())
            ouraActivityReady()
        }
        onFinishedSleep: {
            console.log("onFinishedSleep")
            DataB.storeCloudRecords(DataB.keySleep, oura.printSleep())
            ouraSleepReady()
        }
        onFinishedReadiness: {
            console.log("onFinishedReadiness")
            DataB.storeCloudRecords(DataB.keyReadiness, oura.printReadiness())
            ouraReadinessReady()
        }
        onFinishedBedTimes: {
            console.log("onFinishedBedTimes")
            DataB.storeCloudRecords(DataB.keyBedTime, oura.printBedTimes())
            ouraBedTimesReady()
        }
        onFinishedInfo: {
            console.log("onFinishedInfo")
            DataB.storeCloudRecords(DataB.keyUserInfo, oura.printInfo())
            ouraUserReady()
        }
    }

    function downloadOuraCloud(){
        oura.downloadOuraCloud();
        return;
    }

    function readDb() {
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
        console.log("vanhojen tietojen luku");
        DataB.readCloudDb(); // read all || since date1 || date1 - date2

        personalAccessToken = DataB.getSetting(DataB.keyPersonalToken, "");
        if (personalAccessToken > "") {
            oura.setPersonalAccessToken(personalAccessToken);
        }
        //DataB.log(personalAccessToken);

        return;
    }

    function setUpNow() {
        var subPage = pageContainer.push(Qt.resolvedUrl("Settings.qml"), {
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
                personalAccessToken = newTkn
                oura.setPersonalAccessToken(newTkn)
                //downloadOuraCloud()
            })
        })

        return
    }

}
