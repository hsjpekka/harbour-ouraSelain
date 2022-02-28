import QtQuick 2.0
import QtQml 2.2
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "./utils/datab.js" as DataB
import "./utils/scripts.js" as Scripts
import "pages"
import "cover"

ApplicationWindow
{
    id: applicationWindow
    initialPage: mainPage
    cover: coverPage
    allowedOrientations: defaultAllowedOrientations
    Component.onCompleted: {
        if (openDb() === 0) {
            readSettings()
            settingsReady()
            //startReadingRecords()
            console.log("melkolailla valmista")
            oldRecordsReader.start()
        }
        //coverPage.currentChart = 0
        //coverPage.title = DataB.getSetting("ch0" + DataB.keyChartTitle) //initialPage.chartTitle(coverPage.currentChart)
        if (personalAccessToken > "") {
            //downloadOuraCloud()
        } else {
            setUpNow()
        }
        //startingUp = false
    }

    signal storedDataRead()
    signal settingsReady()

    property int daysToRead: 0// if 0, reads all, else daysToRead at a time
    property var db: null
    property int msDay: 24*60*60*1000
    property string personalAccessToken: ""
    property int readRecords: 0
    //property bool startingUp: true

    MainPage {
        id: mainPage
        onRefreshOuraCloud: downloadOuraCloud()
        onOpenSettings: setUpNow()
    }

    CoverPage {
        id: coverPage
        currentChart: 0
        onNextPressed: {
            currentChart++
            if (currentChart >= initialPage.chartCount) {
                currentChart = 0
            }

            title = initialPage.chartTitle(currentChart)
            value = initialPage.chartLatestValue(currentChart)
        }
        onStatusChanged: {
            if (status === Cover.Active) {
                title = initialPage.chartTitle(currentChart)
                value = initialPage.chartLatestValue(currentChart)
            }
        }
    }

    Timer {
        id: timerOldRecords
        interval: 10*1000
        repeat: true // true to read few records at a time
        running: daysToRead > 0 ? true : false
        onTriggered: {
            var date = firstDateToRead, more
            more = readOldRecords(firstDateToRead, latestDateToRead)
            if (more >= 0 && daysToRead > 0) {
                storedDataRead()
                firstDateToRead = new Date(firstDateToRead.getTime() - daysToRead*msDay)
                latestDateToRead = new Date(latestDateToRead.getTime() - daysToRead*msDay)
            } else {
                repeat = false
            }
        }

        property date firstDateToRead
        property date latestDateToRead
    }

    Timer {
        id: oldRecordsReader
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            startReadingRecords()
        }
    }

    Connections {
        target: ouraCloud
        onFinishedActivity: {
            DataB.storeCloudRecords(DataB.keyActivity, ouraCloud.printActivity())
        }
        onFinishedSleep: {
            DataB.storeCloudRecords(DataB.keySleep, ouraCloud.printSleep())
        }
        onFinishedReadiness: {
            DataB.storeCloudRecords(DataB.keyReadiness, ouraCloud.printReadiness())
        }
        onFinishedBedTimes: {
            DataB.storeCloudRecords(DataB.keyBedTime, ouraCloud.printBedTimes())
        }
        onFinishedInfo: {
            DataB.storeCloudRecords(DataB.keyUserInfo, ouraCloud.printInfo())
        }
    }

    RemorsePopup {
        id: remorse
    }

    function downloadOuraCloud(){
        var lastDate = ouraCloud.lastDate();
        if (lastDate.getFullYear() !== 0) {
            lastDate.setHours(12);
            lastDate.setTime(lastDate.getTime() - msDay);
            ouraCloud.setStartDate(lastDate.getFullYear(), lastDate.getMonth()+1,
                                   lastDate.getDate());
        }

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
        var compare = "", i, notDefined, oldRecs, ymdp1, ymdp2, result;

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
        if (i === 0) {
            result = -1;
        } else {
            result = 0;
        }

        readRecords += i;

        return result;
    }

    function readSettings() {
        DataB.readSettingsDb();

        personalAccessToken = DataB.getSetting(DataB.keyPersonalToken, "");
        if (personalAccessToken > "") {
            ouraCloud.setPersonalAccessToken(personalAccessToken);
        }

        return;
    }

    function setDatesToRead() {
        var dateToShowFirst, extraDays, now; // read full weeks

        if (daysToRead < 1) { // read all records
            return;
        }

        now = new Date();
        extraDays = now.getDay() - Scripts.firstDayOfWeek;

        if (extraDays < 0) { // week starts on Monday (not on Sunday)
            if (daysToRead > 0) {
                extraDays = extraDays + Math.min(7, daysToRead);
            } else {
                extraDays = extraDays + 7;
            }
        }

        //the days to read first
        dateToShowFirst = new Date(now.getTime() - msDay*(daysToRead + extraDays));
        //the days to read a bit later
        timerOldRecords.latestDateToRead = new Date(dateToShowFirst.getTime() - msDay);
        timerOldRecords.firstDateToRead = new Date(dateToShowFirst.getTime() - daysToRead*msDay);

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

            remorse.execute(msg, function() {
                DataB.storeSettings(DataB.keyPersonalToken, newTkn);
                ouraCloud.setPersonalAccessToken(newTkn);
                personalAccessToken = newTkn;
                if (personalAccessToken > "")
                    downloadOuraCloud();
            })
        });

        return;
    }

    function startReadingRecords() {
        var firstDateToRead;
        firstDateToRead = setDatesToRead();
        readOldRecords(firstDateToRead);
        storedDataRead();
        return;
    }

    function generalSettings() {
    }
}
