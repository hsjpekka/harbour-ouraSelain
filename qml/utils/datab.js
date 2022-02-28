.pragma library
var dbas, settingsTable = []; // settingsTable = [];
var appLog = [];
var keyPersonalToken = "personalToken";
var dbTable = "ouraCloud", keyYMDP = "ymdp", keyType = "type", keyRec = "record";
// oura-keys
var keyActivity = "activity", keyBedTime = "ideal_bedtimes",
    keyReadiness = "readiness", keySleep = "sleep", keyUserInfo = "userInfo";
var keyPeriod = "period_id", keyDate = "summary_date", keyDateBT = "date",
    keyChartTimeScale = "cvTimeScale", keyNrCharts = "cvCount";
var chartTypeSingle = "ctSingle", chartTypeMin = "ctMin",
    chartTypeMaxmin = "ctMaxmin", chartTypeSleep = "ctSleepTypes";
var keyChartTable = "chartTable", keyChartType = "chartType",
    keyChartValue1 = "chartValue1", keyChartHigh = "chartHigh",
    keyChartLow = "chartLow", keyChartValue2 = "chartValue2",
    keyChartValue3 = "chartValue3", keyChartValue4 = "chartValue4",
    keyChartMax = "chartMax", keyChartTitle = "chartTitle";

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
    try {
        dbas.transaction(function(tx){
            result = tx.executeSql(query)
        })
    } catch (err) {
        log("Error adding to " + dbTable + "-table in database: " + err);
        return;
    }

    return;
}

function addToSettings(key, value, toDb) {
    settingsTable.push({"key": key, "value": value});

    if (toDb) {
        log("addToSettings: " + key + " " + value + " " + toDb)
        if(dbas === null) {
            log("addToSettings: database not opened!")
            return;
        }
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
    var result = 0;
    result += createTblCloud(); // oura cloud
    result += createTblSettings(); // this app

    return result;
}

function createTblCloud() {
    var query;
    // OuraCloud-records
    // {"index", "type", "record"}
    //   int,    string,  string
    // index = year*100*100*10 + month*100*10 + date*10 + period

    if(dbas === null) return;

    query = "CREATE TABLE IF NOT EXISTS " + dbTable +
            " (" + keyYMDP + " INTEGER, " + keyType + " TEXT, " + keyRec + " TEXT)";
    try {
        dbas.transaction(function(tx){
            tx.executeSql(query);
        });
    } catch (err) {
        log("Error creating " + dbTable + "-table in database: " + err + "\n    " + query);
        return -1;
    }

    return 0;
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
        return -1;
    };

    return 0;
}

function findSetting(key) {
    var i=0, N, result = -1;

    if (settingsTable.length === undefined)
        return -2;

    N = settingsTable.length;

    while (i < N) {
        if (settingsTable[i].key === key) {
            result = i;
            i = N;
        }
        i++;
    }

    return result;
}

function getSetting(key, defVal) {
    var i=0, result;

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
    }
    return str;
}

function readCloudDb(type, ymdp1, ymdp2, verbal) {
    // reads records of type - all if type is undefined
    //       records after date ymdp1 and/or before date ymdp2
    var i, iN, query, result, tbl, change;

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

    try {
        dbas.transaction(function(tx) {
            tbl = tx.executeSql(query);
        });
    } catch (err) {
        log("Error reading from " + dbTable + " -table in database: " + err + "\n    " + query);
        result = {"rows": {"length": -4}};
    };

    if (tbl === undefined) {
        result = {"rows": {"length": -1}};
    } else if (tbl.rows === undefined) {
        log(qsTr("sql.rows === undefined !!"));
        result = {"rows": {"length": -2}};
    } else if (tbl.rows.length === undefined) {
        log(qsTr("sql.rows.length === undefined !!"));
        result = {"rows": {"length": -3}};
    } else {
        if (verbal) {
            log(qsTr("Read oura-records from %1 days.").arg(tbl.rows.length));
        }
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

    if (N === 0) { // no errors
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
    var i, mj, result = 0;
    mj = "DELETE FROM settings WHERE key = '" + key + "'";

    if(dbas === null) {
        return -1;
    } else {
        try {
            dbas.transaction(function(tx){
                tx.executeSql(mj);
            });
        } catch (err) {
            log("Error deleting from settings-table in database: " + err);
            log("  -- " + mj + " -- ")
            result = -1;
        }
    }

    i = findSetting(key);
    if (i >= 0) {
        settingsTable.splice(i, 1);
    }
    if (result === 0) {
        result = i;
    }

    return result;
}

function storeCloudRecords(type, cloudRecord) {
    var jsonCloud = JSON.parse(cloudRecord);
    var result = 0, i=0, iN; // 0 - onnistui, 1 - parseError
    var records;
    if (jsonCloud[keyActivity] !== undefined) {
        type = keyActivity;
        records = jsonCloud[keyActivity];
    } else if (jsonCloud[keyReadiness] !== undefined) {
        type = keyReadiness;
        records = jsonCloud[keyReadiness];
    } else if (jsonCloud[keySleep] !== undefined) {
        type = keySleep;
        records = jsonCloud[keySleep];
    } else if (jsonCloud[keyBedTime] !== undefined) {
        type = keyBedTime;
        records = jsonCloud[keyBedTime];
    } else if (type === keyUserInfo) {
        records = jsonCloud;
    } else {
        log("____unknown record____\n" + cloudRecord.substring(0,60) + " ....")
    }

    // records = [{"summary_date": "2016-10-11", ...}, {"summary_date": "2016-10-12", ...}, ...]
    if (Array.isArray(records)) {
        iN = records.length;
        for(i=0; i<iN; i++) {
            storeRecord(type, records[i]);
        }
    } else {
        storeRecord(type, records);
    }
    return;
}

function storeRecord(type, jsonRecord) {
    // jsonRecord = {"summary_date": "2016-10-11", ...}
    var year=0, month=0, date=0, period=0, ymd, ind;
    var result, record, dateKey;

    if (type === keyActivity || type === keyReadiness || type === keySleep) {
        dateKey = keyDate;
    } else if (type === keyBedTime) {
        dateKey = keyDateBT;
    }

    if (type !== keyUserInfo) {
        if (jsonRecord[dateKey] === undefined) {
            log("No " + dateKey + " in the " + type + "-record.");
            return 1;
        } else {
            ymd = convertToYearMonthDate(jsonRecord[keyDate]);
            year = ymd.year;
            month = ymd.month;
            date = ymd.date;
        }
    }

    if (jsonRecord[keyPeriod] === undefined) {
        period = 0;
    } else {
        period = jsonRecord[keyPeriod];
    }

    ind = ymdp(year, month, date, period);
    result = readCloudDb(type, ind, ind, false);
    record = JSON.stringify(jsonRecord);
    if (result.rows !== undefined) {
        if (result.rows.length > 0) {
            return updateCloudRecord(ind, type, record);
        } else {
            return addCloudRecord(ind, type, record);
        }
    } else {
        return addCloudRecord(ind, type, record);
    }
}

function storeSettings(key, value, toDb) {
    var i, result;

    if (toDb === undefined) {
        toDb = true;
    }

    i = findSetting(key);
    if (i >= 0) {
        result = updateSettings(key, value, toDb);
    } else {
        result = addToSettings(key, value, toDb);
    }

    return result;
}

function updateCloudRecord(ind, type, str) {
    var query, result;
    str = modifyQuotes(str);
    query = "UPDATE " + dbTable + " SET " + keyRec + " = '" + str +
            "' WHERE "+ keyYMDP + " = " + ind + " AND " + keyType + " = '" + type + "'";

    try {
        dbas.transaction(function(tx){
            result = tx.executeSql(query)
        })
    } catch (err) {
        log("Error adding to " + dbTable + "-table in database: " + err);
        return;
    }

    return;
}

function updateSettings(key, value, toDb) {
    var i, mj = "UPDATE settings SET value = '" + value + "' WHERE key = '" + key + "'"
    if(dbas === null) return;

    i = findSetting(key);
    if (i >= 0) {
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
