.pragma library

var lastDate = ""; // "2016-03-23", date of the last fetched summary
var personalAccessToken = "";
var firstDayOfWeek = Qt.locale().firstDayOfWeek; // 0 - Sunday, 1 - Monday, ...
var iGloba = 0;

function dateString(date, month, year) {
    var now = new Date(), str="";
    if (typeof date === typeof now) {
        year = date.getFullYear();
        month = date.getMonth() + 1;
        date = date.getDate();
    } else {
        if (year === undefined)
            year = now.getFullYear();
        if (month === undefined)
            month = now.getMonth() + 1;
        if (date === undefined)
            date = now.getDate();
    }
    str += year + "-";
    if (month < 10) {
        str += "0";
    }
    str += month + "-";
    if (date < 10) {
        str += "0";
    }
    str += date;

    return str;
}

function dayStr(day){
    var result;
    if (day === 0)
        result = qsTr("Sun")
    else if (day === 1)
        result = qsTr("Mon")
    else if (day === 2)
        result = qsTr("Tue")
    else if (day === 3)
        result = qsTr("Wed")
    else if (day === 4)
        result = qsTr("Thu")
    else if (day === 5)
        result = qsTr("Fri")
    else if (day === 6)
        result = qsTr("Sat");
    return result;
}

function ouraToNumber(val, nanValue) {
    if (nanValue === undefined) {
        nanValue = 0;
    }

    if (val === "-") {
        return nanValue;
    } else {
        return val*1.0;
    }
}

function secToHM(sec) {
    var hours, mins, result;

    mins = (sec-sec%60)/60;
    hours = (mins - mins%60)/60;
    mins = mins - hours*60;

    result = hours + ":";
    if (mins < 10) {
        result += "0";
    }
    result += mins;

    return result;
}

function weekNumber(dateMs) {
    // dateMs = ms since 1970-1-1 0:0:0.000 GMT
    // the first day of the year is on week 1, if
    // a) Sunday starts the week and the first day of year is Sun-Wed
    // b) Monday starts the week and the first day of year is Mon-Thu
    // otherwise it's on the last week of the previous year
    var minMs = 60*1000;
    var year = new Date(dateMs).getFullYear();
    var firstDayOfYear = new Date(year, 0, 1, 0, 0, 0);
    var lastDayOfYear = new Date(year, 11, 31, 0, 0, 0);
    var wkDay = weekDay(firstDayOfYear.getTime()); // 0-6 Sun - Sat, or 1-7 Mon - Sun
    var lastDay = weekDay(lastDayOfYear.getTime());
    var wknow, diffMs, dayMs = 24*60*60*1000;
    var wk1Start; // day starting week 1
    var timeZoneNow, timeZoneWinter;

    if (wkDay > 3.5 + firstDayOfWeek) { // last years last week
        wk1Start = new Date(year, 0, firstDayOfWeek + 8 - wkDay, 0, 0, 0, 0);
    } else { // first week of this year
        if (wkDay === firstDayOfWeek)
            wk1Start = new Date(year, 0, 1, 0, 0, 0, 0)
        else // the first week starts on the previous year
            wk1Start = new Date(year-1, 11, 32 + firstDayOfWeek - wkDay, 0, 0, 0, 0);
    }

    timeZoneNow = new Date(dateMs).getTimezoneOffset();
    timeZoneWinter = firstDayOfYear.getTimezoneOffset();

    diffMs = dateMs - wk1Start.getTime() - (timeZoneNow - timeZoneWinter)*minMs; // ms since the first day of week 1
    if (diffMs < 0)
        wknow = weekNumber(new Date(year-1, 11, 31, 12, 0, 0).getTime())
    else
        wknow = Math.floor(diffMs/(7*dayMs)) + 1;

    if (iGloba < 15)
        console.log("ma " + firstDayOfWeek + " 1.1. " + wkDay + " eka ma " +
                    wk1Start.getDate() + " wknow " + diffMs/(7*dayMs));
    iGloba++;

    return wknow;
}

function weekDay(dateMs) {
    // if week starts on Monday, returns 1 - Monday, 7 - Sunday
    // else returns 0 - Sunday, 6 - Saturday
    var day = new Date(dateMs).getDay();

    if (firstDayOfWeek === 1 && day === 0)
        day = 7;

    return day;
}

