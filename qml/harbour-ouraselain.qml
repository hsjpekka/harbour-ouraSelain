import QtQuick 2.0
import QtQml 2.2
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "./utils/datab.js" as DataB
import "./utils/scripts.js" as Scripts
import "pages"

ApplicationWindow
{
    id: applicationWindow
    initialPage: Component { MainPage {
            onRefreshOuraCloud: downloadOuraCloud()
            onOpenSettings: setUpNow()
        }
    }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    //allowedOrientations: defaultAllowedOrientations
    Component.onCompleted: {
        var firstDateToRead
        if (openDb() === 0) {
            readSettings()
            settingsReady()
            firstDateToRead = setDatesToRead()
            readOldRecords(firstDateToRead)
        }
        console.log("- - - - - \n" + " vanhat luettu \n" + "- - - - -")
        if (personalAccessToken > "") {
            downloadOuraCloud()
        } else {
            setUpNow()
        }
        startingUp = false
        //generalSettings()
        console.log("- - - - - \n" + " alkukomennot tehty \n" + "- - - - -")
    }

    property var db: null
    property string personalAccessToken: ""
    property bool startingUp: true

    signal storedDataRead()
    signal settingsReady()

    Timer {
        id: timerOldRecords
        interval: 10*1000
        repeat: false // true to read few records at a time
        running: true
        onTriggered: {
            var noDef

            readOldRecords(noDef, lastDate)
            storedDataRead()
        }

        property date lastDate
    }

    Connections {
        target: ouraCloud
        onFinishedActivity: {
            console.log("onFinishedActivity")
            DataB.storeCloudRecords(DataB.keyActivity, ouraCloud.printActivity())
        }
        onFinishedSleep: {
            console.log("onFinishedSleep")
            DataB.storeCloudRecords(DataB.keySleep, ouraCloud.printSleep())
        }
        onFinishedReadiness: {
            console.log("onFinishedReadiness")
            DataB.storeCloudRecords(DataB.keyReadiness, ouraCloud.printReadiness())
        }
        onFinishedBedTimes: {
            console.log("onFinishedBedTimes")
            DataB.storeCloudRecords(DataB.keyBedTime, ouraCloud.printBedTimes())
        }
        onFinishedInfo: {
            console.log("onFinishedInfo")
            DataB.storeCloudRecords(DataB.keyUserInfo, ouraCloud.printInfo())
        }
    }

    RemorsePopup {
        id: remorse
    }

    function downloadOuraCloud(){
        var lastDate = ouraCloud.lastDate(), msDay = 24*60*60*1000;
        if (lastDate.getFullYear() !== 0) {
            lastDate.setTime(lastDate.getTime() - msDay);
            ouraCloud.setStartDate(lastDate.getFullYear(), lastDate.getMonth()+1,
                                   lastDate.getDate());
        }
        console.log("viimeisin aiemmin luettu päivä " + Scripts.dateString(lastDate) )

        ouraCloud.downloadOuraCloud();
        return;
    }

    function openDb() {
        var result = 0;

        if(db === null) {
            try {
                db = LocalStorage.openDatabaseSync("oura", "0.1", "daily records", 10000);
            } catch (err) {
                DataB.log("Error in opening the database: " + err);
                result = -1;
            };
        }

        if (result >= 0) {
            DataB.dbas = db;
            result = DataB.createTables();
        }

        return result;
    }

    function readOldRecords(firstDate, lastDate) {
        // reads dates > firstDate and dates < lastDate
        var compare = "", i, notDefined, oldRecs, ymdp1, ymdp2;        

        DataB.log("readOldRecords: > " + (firstDate? firstDate.toDateString() : "-") + ", < " +
                    (lastDate? lastDate.toDateString() : "-"))

        if (firstDate === undefined) {
            ymdp1 = -1;
        } else {
            ymdp1 = DataB.ymdp(firstDate.getFullYear(), firstDate.getMonth(),
                               firstDate.getDate());
        }

        if (lastDate === undefined) {
            ymdp2 = -1;
        } else {
            ymdp2 = DataB.ymdp(lastDate.getFullYear(), lastDate.getMonth(), lastDate.getDate());
        }

        oldRecs = DataB.readCloudDb(notDefined, ymdp1, ymdp2, true); // type, start, end, verbal
        i = 0;
        while (i < oldRecs.rows.length) {
            ouraCloud.storeOldRecords(oldRecs.rows[i][DataB.keyType], oldRecs.rows[i][DataB.keyRec]);
            i++;
        }
        /*
        if (oldRecs.rows.length > 0) {
            console.log("ensimmäinen tallennettu " + ouraCloud.firstDate());
            console.log("viimeinen tallennettu " + ouraCloud.lastDate());
        }
        // */

        return;
    }

    function readSettings() {
        DataB.readSettingsDb();

        personalAccessToken = DataB.getSetting(DataB.keyPersonalToken, "");
        console.log("tunniste " + personalAccessToken)
        if (personalAccessToken > "") {
            ouraCloud.setPersonalAccessToken(personalAccessToken);
        }

        return;
    }

    function setDatesToRead() {
        var dateToShowFirst = new Date()
        var extraDays = dateToShowFirst.getDay() - Scripts.firstDayOfWeek
        var msDay = 24*60*60*1000
        var fullWeeks = 9

        if (extraDays < 0) { // week starts on Monday (to Saturday)
            extraDays = extraDays + 7
        }
        dateToShowFirst = new Date(dateToShowFirst.getTime() - msDay*(fullWeeks*7 + extraDays));
        timerOldRecords.lastDate = new Date(dateToShowFirst.getTime() - msDay);

        //console.log(" ensimmäinen ladattava päivä " + dateToShowFirst.toDateString());
        return dateToShowFirst;
    }

    function setUpNow() {
        var subPage = pageStack.push(Qt.resolvedUrl("pages/Settings.qml"), {
                                             "token": personalAccessToken
                                         });
        subPage.setToken.connect(function () {
            var msg, newTkn = subPage.token;
            if (newTkn === "") {
                msg = qsTr("Clearing token!");
            } else {
                msg = qsTr("Changing token to %1.").arg(newTkn);
            }

            DataB.log("new token >>" + newTkn.slice(0, 8) + "... <<");

            remorse.execute(msg, function() {
                console.log("remorse alkaa")
                DataB.storeSettings(DataB.keyPersonalToken, newTkn);
                ouraCloud.setPersonalAccessToken(newTkn);
                personalAccessToken = newTkn;
                if (personalAccessToken > "")
                    downloadOuraCloud();
            })
        });

        return;
    }

    function generalSettings() {
    }
}
