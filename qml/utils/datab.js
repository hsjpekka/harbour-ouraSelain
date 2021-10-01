.pragma library
var dbas, settingsTable = []; // settingsTable = [];
var appLog = [];
// database keys
var keyPersonalToken = "personalToken";
var dbTable = "ouraCloud", keyYMDP = "ymdp", keyType = "type", keyRec = "record";
// oura-keys
var keyActivity = "activity", keyBedTime = "ideal_bedtimes", keyReadiness = "readiness";
var keySleep = "sleep", keyUserInfo = "userInfo";
var keyPeriod = "period_id", keyDate = "summary_date", keyDateBT = "date";

// tables in database:
// 'ouraCloud'
// {"index", "type", "record"}
//   int,    string,  string
// type = "activity" || "readiness" || "sleep" || "ideal_bedtimes"
//
// 'settings'
// {"key", "value"}
//  string, string

function addCloudRecord(ind, type, str) {
    var query, result;
    str = modifyQuotes(str);
    query = "INSERT INTO " + dbTable + " (" + keyYMDP + ", " + keyType + ", " + keyRec + ") " +
            "VALUES (" + ind + ", '" + type + "', '" + str + "')";
    log("adding: " + query.slice(query.indexOf("VALUES"),query.indexOf("VALUES")+ 50));

    try {
        dbas.transaction(function(tx){
            result = tx.executeSql(query)
        })
    } catch (err) {
        log("Error adding to " + dbTable + "-table in database: " + err);
        return;
    }
    //log("insert result: " + result.rows.length + " <===> " + result);
    return;
}

function addToSettings(key, value, toDb) {

    if(dbas === null) return;

    if (toDb === undefined) {
        toDb = true;
    }

    if (toDb) {
        try {
            dbas.transaction(function(tx){
                tx.executeSql("INSERT INTO settings (key, value)" +
                              " VALUES ('" + key + "', '" + value + "')" )
            })
        } catch (err) {
            log("Error adding to settings-table in database: " + err);
            return;
        }
    }

    //readSettingsDb();

    settingsTable.push({"key": key, "value": value });

    return;

}

function convertToYearMonthDate(dateStr) {
    // yyyy-mm-dd -> result.year, result.month, result.date
    var result = {"year": 1, "month":14, "date": 34}, year, month, date;
    var arr, reg = /^\d\d\d\d-\d\d?-\d\d?/;
    if (reg.test(dateStr)) {
        arr = dateStr.split("-");
        result.year = arr[0]*1.0;
        result.month = arr[1]*1.0;
        result.date = arr[2]*1.0;
    } else {
        result.year = 0;
        result.month = 0;
        result.date = 0;
    }
    return result;
}

function createTables() {
    createTblCloud(); // oura cloud
    //createTblReadiness(); // oura cloud
    createTblSettings(); // this app
    //createTblSleep(); // oura cloud

    return;
}

function createTblCloud() {
    var query;
    // OuraCloud-records
    // {"index", "type", "record"}
    //   int,    string,  string
    // index = year*100*100*10 + month*100*10 + date*10 + period

    if(dbas === null) return;

    //             tx.executeSql("CREATE TABLE IF NOT EXISTS activityJson (date INTEGER," + " record TEXT)");

    query = "CREATE TABLE IF NOT EXISTS " + dbTable +
            " (" + keyYMDP + " INTEGER, " + keyType + " TEXT, " + keyRec + " TEXT)";
    try {
        dbas.transaction(function(tx){
            tx.executeSql(query);
        });
    } catch (err) {
        log("Error creating " + dbTable + "-table in database: " + err + "\n    " + query);
    }

    return;
}

function createTblSettings() {
    // settings-table
    // {"key", "value"}
    // string,  string
    var query;

    if(dbas === null) return;

    query = "CREATE TABLE IF NOT EXISTS settings (key TEXT, value TEXT)";
    try {
        dbas.transaction(function(tx){
            tx.executeSql(query);
        });
    } catch (err) {
        log("Error creating settings-table in database: " + err + "\n    " + query);
    };

    return
}

function findSetting(key) {
    var i=0, N, result = -1;

    if (settingsTable.length === undefined)
        return -2;

    N = settingsTable.length;

    while (i<N) {
        if (settingsTable[i].key === key) {
            result = i;
            i = N;
        }
        i++;
    }

    return result;
}

function getSetting(key, defVal) {
    var i=0, N=-1, result;

    i = findSetting(key);
    if (i >= 0) {
        result = settingsTable[i].value;
    } else {
        result = defVal;
    }

    return result;
}

function log(msg, consoleOrStore) {
    // 0 - only to internal log array
    // 1 - to internal array and console
    // 2 - console.log only
    msg = appLog.length + ": " + msg;
    if (consoleOrStore === undefined)
        consoleOrStore = 1;
    if (consoleOrStore < 2) {
        appLog.push(msg);
    }
    if (consoleOrStore > 0) {
        console.log(msg);
    }
    return;
}

function modifyQuotes(str) {
    var i=0, j=0, iN = str.length;
    i = str.indexOf("'");
    while (i < iN && i >= 0) {
        str = str.substring(0,i) + "'" + str.substring(i+1);
        i = str.indexOf("'", i+2);
        j++;
        if (j>8) {
            console.log("löytyi monta hipsua " + j);
            i= iN+1;
        }
    }
    return str;
}

function readCloudDb(type, ymdp1, ymdp2, verbal) { // from date ymdp1 to ymdp2
    var i, iN, query, result, tbl, change;

    console.log("" + type + " " + ymdp1 + " " + ymdp2 + " " + verbal)

    if (verbal === undefined) {
        verbal = true;
    }
    if (ymdp2 > 0 && ymdp1 > ymdp2) {
        change = ymdp1;
        ymdp1 = ymdp2;
        ymdp2 = change;
    }

    if(dbas === null) return {"rows": {"length": -5}};

    query = "SELECT * FROM " + dbTable;
    if ((ymdp1 > 0) && (ymdp2 > 0) && (type > "")) {
        query += " WHERE " + keyType + "='" + type + "' AND " + keyYMDP + ">=" + ymdp1 +
                 " AND " + keyYMDP + "<=" + ymdp2;
    } else if (ymdp1 > 0 && ymdp2 > 0) {
        query += " WHERE " + keyYMDP + ">=" + ymdp1 + " AND " + keyYMDP + "<=" + ymdp2;
    } else if ((ymdp1 > 0) && (type > "")) {
            query += " WHERE " + keyType + "='" + type + "' AND " + keyYMDP + ">=" + ymdp1;
    } else if ((ymdp2 > 0) && (type > "")) {
            query += " WHERE " + keyType + "='" + type + "' AND " + keyYMDP + "<=" + ymdp2;
    } else if (ymdp1 > 0) {
        query += " WHERE " + keyYMDP + ">=" + ymdp1;
    } else if (ymdp2 > 0) {
        query += " WHERE " + keyYMDP + "<=" + ymdp2;
    } else if (type) {
        query += " WHERE " + keyType + "='" + type + "'";
    }

    console.log(query)

    try {
        dbas.transaction(function(tx) {
            tbl = tx.executeSql(query);
        });
    } catch (err) {
        log("Error reading from " + dbTable + " -table in database: " + err + "\n    " + query);
        result = {"rows": {"length": -4}};
    };

    if (tbl === undefined) {
        console.log("ei taulukkoa: " + query);
        result = {"rows": {"length": -1}};
    } else if (tbl.rows === undefined) {
        log(qsTr("sql.rows === undefined !!"));
        result = {"rows": {"length": -2}};
    } else if (tbl.rows.length === undefined) {
        log(qsTr("sql.rows.length === undefined !!"));
        result = {"rows": {"length": -3}};
    } else {
        if (verbal) {
            log(qsTr("Read %1 oura-records.").arg(tbl.rows.length));
        }
        //console.log(query);
        //iN = tbl.rows.length;
        //i = 0;
        //while (i < iN) {
            //oura.storeOldRecords(tbl.rows[i][keyType], tbl.rows[i][keyRec]);
            //i++;
        //}
        result = tbl;
    }

    return result;
}

function readSettingsDb() {
    var query, i, N = 0, tbl;

    if(dbas === null) return -2;

    query = "SELECT * FROM settings";
    try {
        dbas.transaction(function(tx){
            tbl = tx.executeSql(query);
        });
        if (tbl === undefined) {
            N = -1;
            log("settingsTable undefined");
        } else if (tbl.rows === undefined) {
            N = -4;
            log("settingsTable.rows undefined");
        } else if (tbl.rows.length === undefined) {
            N = -5;
            log("settingsTable.rows.length undefined");
        }
    } catch (err) {
        log("Error reading from settings-table in database: " + err + "\n    " + query);
        N = -3;
    };

    if (N === 0) {
        i = 0;
        N = tbl.rows.length;
        while (i < N) {
            addToSettings(tbl.rows[i].key, tbl.rows[i].value, false);
            i++;
        }
    }

    return N;
}

function removeFromSettings(key) {
    var mj = "DELETE settings WHERE key = '" + key + "'"

    if(dbas === null) return -1;

    try {
        dbas.transaction(function(tx){
            tx.executeSql(mj);
        });
    } catch (err) {
        log("Error deleting from settings-table in database: " + err);
        return -1;
    };

    return 0;
}

/*
function removeTableCloud() {
    var query;
    query = "DROP TABLE " + dbTable;    
    try {
        dbas.transaction(function(tx){
            tx.executeSql(query);
        });
    } catch (err) {
        log("Error removing " + dbTable + "-table in database: " + err + "\n    " + query);
    };

    console.log("taulukko poistettu " + query)

    return
}
// */

function storeRecord(type, jsonRecord) {
    // jsonRecord = {"summary_date": "2016-10-11", ...}
    var year=0, month=0, date=0, period=0, ymd, ind;
    var result, record, dateKey;

    if (type === keyActivity || type === keyReadiness || type === keySleep) {
        dateKey = keyDate;
    } else if (type === keyBedTime) {
        dateKey = keyDateBT;
    }

    if (jsonRecord[dateKey] === undefined) {
        log("No " + dateKey + " in the " + type + "-record.");
        return 1;
    } else {
        ymd = convertToYearMonthDate(jsonRecord[keyDate]);
        year = ymd.year;
        month = ymd.month;
        date = ymd.date;
    }

    if (jsonRecord[keyPeriod] === undefined) {
        period = 0;
    } else {
        period = jsonRecord[keyPeriod];
    }

    /*
    if (type === keyActivity || type === keyReadiness || type === keySleep) {
        if (jsonRecord[keyDate] === undefined) {
            log("No summary_date in the " + type + "-record.");
            return 1;
        } else {
            ymd = convertToYearMonthDate(jsonRecord[keyDate]);
            year = ymd.year;
            month = ymd.month;
            date = ymd.date;
        }
        if (jsonRecord[keyPeriod] === undefined) {
            period = 0;
        } else {
            period = jsonRecord[keyPeriod];
        }
    } else if (type === keyBedTime) {
        if (jsonRecord[keyDateBT] === undefined) {
            log("No date in the " + type + "-record.");
            return 1;
        } else {
            ymd = convertToYearMonthDate(jsonRecord[keyDateBT]);
            year = ymd.year;
            month = ymd.month;
            date = ymd.date;
            period = 0;
        }
    }
    // */

    ind = ymdp(year, month, date, period);
    result = readCloudDb(type, ind, ind, false);
    record = JSON.stringify(jsonRecord);
    //console.log("" + record.slice(0,29) + " ::: " + jsonRecord + " ... " + result);
    if (result.rows !== undefined) {
        if (result.rows.length > 0) {
            console.log("updating ._._. " + record.slice(0,29) + " ... ");
            return updateCloudRecord(ind, type, record);
        } else {
            return addCloudRecord(ind, type, record);
        }
    } else {
        return addCloudRecord(ind, type, record);
    }
}

//*
function storeCloudRecords(type, cloudRecord) {
    //console.log("alkaa " + type + " :::: " + cloudRecord.splice(0, 20));
    // cloudRecord = '{
    // "sleep": [{"summary_date": "2016-10-11", ...}, {"summary_date": "2016-10-12", ...}, ...]
    // }'
    var jsonCloud = JSON.parse(cloudRecord);
    var result = 0, i=0, iN; // 0 - onnistui, 1 - parseError
    var records;
    if (jsonCloud[keyActivity] !== undefined) {
        console.log("_____store activity_____");
        type = keyActivity;
        records = jsonCloud[keyActivity];
    } else if (jsonCloud[keyReadiness] !== undefined) {
        console.log("_____store readiness_____");
        type = keyReadiness;
        records = jsonCloud[keyReadiness];
    } else if (jsonCloud[keySleep] !== undefined) {
        console.log("_____store sleep_____");
        type = keySleep;
        records = jsonCloud[keySleep];
    } else if (jsonCloud[keyBedTime] !== undefined) {
        console.log("_____store bedtime_____");
        type = keyBedTime;
        records = jsonCloud[keyBedTime];
    } else if (type === keyUserInfo) {
        console.log("_____store info_____");
        records = jsonCloud;
    } else {
        log("____unknown record____\n" + cloudRecord.substring(0,60) + " ....")
    }

    // records = [{"summary_date": "2016-10-11", ...}, {"summary_date": "2016-10-12", ...}, ...]
    if (Array.isArray(records)) {
        iN = records.length;
        for(i=0; i<iN; i++) {
            //if (i===0) {
                //console.log("i == " + i + " - " + JSON.stringify(records[i]).slice(0,28));
            //}
            storeRecord(type, records[i]);
        }
    } else {
        console.log("_____object_____\n" + "  " + JSON.stringify(records).slice(0,28));
        storeRecord(type, records);
    }
    return;
}
// */

function updateCloudRecord(ind, type, str) {
    var query, result;
    str = modifyQuotes(str);
    query = "UPDATE " + dbTable + " SET " + keyRec + " = '" + str +
            "' WHERE "+ keyYMDP + " = " + ind + " AND " + keyType + " = '" + type + "'";
    log("updating: " + query.slice(17,36) + "___ " + query.slice(query.indexOf("WHERE")));

    try {
        dbas.transaction(function(tx){
            result = tx.executeSql(query)
        })
    } catch (err) {
        log("Error adding to " + dbTable + "-table in database: " + err);
        return;
    }
    //log("insert result: " + result.rows + " <===> " + result);
    return;
}

function updateSettings(key, value) {
    var i, mj = "UPDATE settings SET value = '" + value + "' WHERE key = '" + value + "'"
    // tunnus string, arvo string
    if(dbas === null) return;

    i = findSetting(key);
    if ( i < 0) {
        log("update -> insert " + key + ", " + value)
        return addToSettings(key, value);
    } else {
        settingsTable[i].value = value;
    }

    try {
        dbas.transaction(function(tx){
            tx.executeSql(mj);
        });
    } catch (err) {
        log("Error modifying settings-table in database: " + err);
    };

    return;
}

function ymdp(year, month, date, period) {
    if (month === undefined) {
        month = 0;
    }
    if (date === undefined) {
        date = 0;
    }
    if (period === undefined) {
        period = 0;
    }

    return ((year*20 + month)*50 + date)*100 + period;
}

/*
function addRecord(type, time, record) {
    var date = 0, i=0, sign = 1, str;
    if (typeof time === "number") {
        date = time;
    } else if (typeof time === "string"){ // "2015-03-22"
        date = calculateDbTime(time);
    }

    log("" + type, + ", " + date + " (" + time + ")");

    if (type === keyActivity)
        return addToActivity(date, record)
    else if (type === keyReadiness)
        return addToReadiness(date, record)
    else if (type === keySleep)
        return addToSleep(date, record);

    return -2;
}

function addToActivity(time, record) {

    if(dbas === null) return;

    try {
        dbas.transaction(function(tx){
            tx.executeSql("INSERT INTO activityJson (date, record)" +
                          " VALUES ('" + time + "', '" + record + "')" )
        })
    } catch (err) {
        log("Error adding to activityJson-table in database: " + err);
        return;
    }

    addToActivityArray(time, record);

    return;
}

function addToActivityArray(time, record) {
    var arr = [];
    arr.push(time);
    arr.push(record);

    activityTable.push(arr);

    return;
}

function addToReadiness(time, record) {

    if(dbas === null) return;

    try {
        dbas.transaction(function(tx){
            tx.executeSql("INSERT INTO readinessJson (date, record)" +
                          " VALUES ('" + time + "', '" + record + "')" )
        })
    } catch (err) {
        log("Error adding to readinessJson-table in database: " + err);
        return;
    }

    addToReadinessArray(time, record);

    return;
}

function addToReadinessArray(time, record) {
    var arr = [];
    arr.push(time);
    arr.push(record);

    readinessTable.push(arr);

    return;
}

function addToSleep(time, record) {
    if(dbas === null) return;

    try {
        dbas.transaction(function(tx){
            tx.executeSql("INSERT INTO sleepJson (date, record)" +
                          " VALUES ('" + time + "', '" + record + "')" )
        })
    } catch (err) {
        log("Error adding to sleepJson-table in database: " + err);
        return;
    }

    addToSleepArray(time, record);

    return;
}

function addToSleepArray(time, record) {
    var arr = [];
    arr.push(time);
    arr.push(record);

    sleepTable.push(arr);

    return;
}

function calculateDbTime(timeStr) {
    var i = 0, result, sign, strs;

    strs = timeStr.split("-");

    if (strs[i] === "") {
        sign = -1;
        i++;
    }

    if (strs.length < i+3)
        return -1;

    result = sign*(strs[i]*100*100 + strs[i+1]*100 + strs[i+2]);

    return result;
}

function createTblActivity() {
    // activity-summaries from OuraCloud as JSON-text
    // {"date", "record"} 20200827, "{}"
    // int, string

    if(dbas === null) return;

    try {
        dbas.transaction(function(tx){
            tx.executeSql("CREATE TABLE IF NOT EXISTS activityJson (date INTEGER," +
                          " record TEXT)");
        });
    } catch (err) {
        log("Error creating activityJson-table in database: " + err);
    };

    return
}

function createTblReadiness() {
    // readiness-summaries from OuraCloud as JSON-text
    // {"date", "record"} = 20200827, "{}"
    // int, string

    if(dbas === null) return;

    try {
        dbas.transaction(function(tx){
            tx.executeSql("CREATE TABLE IF NOT EXISTS readinessJson (date INTEGER," +
                          " record TEXT)");
        });
    } catch (err) {
        log("Error creating readinessJson-table in database: " + err);
    };

    return
}

function createTblSleep() {
    // sleep-summaries from OuraCloud as JSON-text
    // {"date", "record"} = 20200827, "{}"
    // int, string

    if(dbas === null) return;

    try {
        dbas.transaction(function(tx){
            tx.executeSql("CREATE TABLE IF NOT EXISTS sleepJson (date INTEGER," +
                          " record TEXT)");
        });
    } catch (err) {
        log("Error creating sleepJson-table in database: " + err);
    };

    return
}

function getQueryTimes(year1, month1, day1, year2, month2, day2) {
    // if year1 === undefined, all
    // else if month1 === undefinded, year1.1.1 - year1.12.31
    // else if day1 === undefinded, year1.month1.1 - year1.month1.31
    // if year2 === undefinded, time2 = today
    // else if month2 === undefinded, time2 = year2.12.31
    // else if day2 === undefinded, time2 = year2.month2.31
    var result = "", t1, t2, t3, tmin, tmax;
    if (year1 !== undefined) {
        t1 = year1*100*100;
        if (month1 === undefined) {
            t2 = t1 + 12*100 + 31;
        } else {
            t1 += month1*100;
            if (day1 === undefined) {
                t2 = t1 + 31;
            } else
                t1 += day1;
        }
    }

    if (year2 !== undefined) {
        t2 = year2*100*100;
        if (month2 === undefined) {
            t2 += 12*100 + 31;
        } else {
            t2 += month2*100;
            if (day2 === undefined) {
                t2 += 31;
            } else {
                t2 += day2;
            }
        }
    }

    if (t1 > t2) {
        t3 = t1;
        t1 = t2;
        t2 = t3;
    }

    if (t1 !== undefined)
        tmin = "date >= " + t1;

    if (t2 !== undefined)
        tmax = "date <= " + t2;

    if (tmin > "") {
        result = " WHERE " + tmin;
        if (tmax > "")
            result += " AND " + tmax;
    } else if (tmax > "") {
        result = " WHERE " + tmax;
    }

    return result;
}

function indexCloud(type, time) {
    var i, N, arr;

    if (type === keyActivity)
        arr = activityTable
    else if (type === keyReadiness)
        arr = readinessTable
    else if (type === keySleep)
        arr = sleepTable;

    for (i=0; i<N; i++) {
        if (arr[i][0] === time)
            return i;
    }
    return -1;
}

function updateCloud(type, time, record) {
    var mj, tbl = type + "Json", i
    mj = "UPDATE " + tbl + " SET record = '" + record +
            "' WHERE date = '" + time + "'"
    // tunnus string, arvo string
    if(dbas === null) return;

    try {
        dbas.transaction(function(tx){
            tx.executeSql(mj);
        });
    } catch (err) {
        log("Error modifying " + tbl + "-table in database: " + err);
        return -1;
    };

    i = indexCloud(type, time)
    if (i >= 0 ) {
        if (type === keyActivity) {
            activityTable[i][1] = record
        } else if (type === keyReadiness) {
            readinessTable[i][1] = record
        } else if (type === keySleep) {
            sleepTable[i][1] = record
        }
    }

    return i;
}

function removeFromCloud(type, time, record) {
    var mj, tbl = type + "Json", i
    mj = "DELETE " + tbl + " WHERE date = '" + time + "'"
    // tunnus string, arvo string
    if(dbas === null) return;

    try {
        dbas.transaction(function(tx){
            tx.executeSql(mj);
        });
    } catch (err) {
        log("Error deleting from " + tbl + "-table in database: " + err);
        return -1;
    };

    i = indexCloud(type, time)
    if (i >= 0 ) {
        if (type === keyActivity) {
            activityTable.splice(i, 1)
        } else if (type === keyReadiness) {
            readinessTable.splice(i, 1)
        } else if (type === keySleep) {
            sleepTable.splice(i, 1)
        }
    }

    return i;
}

function readCloudDb(year1, month1, day1, year2, month2, day2) {
    // read all || year || year, month || since date1 || upto date2 || date1 - date2
    var r1, r2, r3;
    r1 = readActivityDb(year1, month1, day1, year2, month2, day2);
    r2 = readReadinessDb(year1, month1, day1, year2, month2, day2);
    r3 = readSleepDb(year1, month1, day1, year2, month2, day2);
    return Math.min(r1, r2, r3);
}

function readActivityDb(year1, month1, day1, year2, month2, day2) {
    // records between time1 - time2
    var query, N=-1;
    query = "SELECT * FROM activityJson"
            + getQueryTimes(year1, month1, day1, year2, month2, day2);

    // tunnus string, arvo string
    if(dbas === null) return -2;

    try {
        dbas.transaction(function(tx){
            activityTable = tx.executeSql(query);
        });
        if (activityTable.rows === undefined) {
            N = -4;
        } else if (activityTable.rows.length === undefined) {
            N = -5;
        } else {
            N = activityTable.rows.length;
        }
    } catch (err) {
        log("Error reading from activity-table in database: " + err);
        N = -3;
    };

    return N;
}

function readReadinessDb(year1, month1, day1, year2, month2, day2) {
    // records between time1 - time2
    var query, N=-1;
    query = "SELECT * FROM readinessJson"
            + getQueryTimes(year1, month1, day1, year2, month2, day2);

    // tunnus string, arvo string
    if(dbas === null) return -2;

    try {
        dbas.transaction(function(tx){
            readinessTable = tx.executeSql(query);
        });
        if (readinessTable.rows === undefined) {
            N = -4;
        } else if (readinessTable.rows.length === undefined) {
            N = -5;
        } else {
            N = readinessTable.rows.length;
        }
    } catch (err) {
        log("Error reading from readiness-table in database: " + err);
        N = -3;
    };

    return N;
}

function readSleepDb(year1, month1, day1, year2, month2, day2) {
    // records between time1 - time2
    var query, N=-1;
    query = "SELECT * FROM sleepJson"
            + getQueryTimes(year1, month1, day1, year2, month2, day2);

    if(dbas === null) return -2;

    try {
        dbas.transaction(function(tx){
            sleepTable = tx.executeSql(query);
        });
        if (sleepTable.rows === undefined) {
            N = -4;
        } else if (sleepTable.rows.length === undefined) {
            N = -5;
        } else {
            N = sleepTable.rows.length;
        }
    } catch (err) {
        log("Error reading from sleep-table in database: " + err);
        N = -3;
    };

    return N;
}
// */
